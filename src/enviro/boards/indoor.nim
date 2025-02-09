import std/strformat
import std/strutils
import std/json
import picostdlib/pico/platform #tightLoopContents
import pimoroni_pico/libraries/bsec2
import pimoroni_pico/drivers/bh1745
import ../common

var bsecSensor: Bsec2
var bh1745Sensor: Bh1745

var indoorReadingCb*: proc (data: JsonNode)

const sampleRate = BSEC_SAMPLE_RATE_ULP
let TEMP_OFFSET_ULP = 3.0
let TEMP_OFFSET_ULP_WIFI = 5.2
let TEMP_OFFSET_LP = 3.0
let TEMP_OFFSET_LP_WIFI = 5.6

let initState = static:
  const parsed = parseHexStr(staticRead("../../../state_" & (if sampleRate == BSEC_SAMPLE_RATE_ULP: "ulp" else: "lp") & ".txt").strip().replace("\n", ""))
  var st: array[parsed.len, uint8]
  for i in 0..<st.len:
    st[i] = parsed[i].uint8
  st

# Desired subscription list of BSEC2 outputs
let bsecSensorList = [
    BSEC_OUTPUT_IAQ,
    BSEC_OUTPUT_STATIC_IAQ,
    BSEC_OUTPUT_CO2_EQUIVALENT,
    BSEC_OUTPUT_BREATH_VOC_EQUIVALENT,
    BSEC_OUTPUT_RAW_TEMPERATURE,
    BSEC_OUTPUT_RAW_HUMIDITY,
    BSEC_OUTPUT_RAW_PRESSURE,
    BSEC_OUTPUT_RAW_GAS,
    BSEC_OUTPUT_STABILIZATION_STATUS,
    BSEC_OUTPUT_RUN_IN_STATUS,
    BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_TEMPERATURE,
    BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_HUMIDITY,
    BSEC_OUTPUT_GAS_PERCENTAGE
  ]

proc bsecDataCallback(data: Bme68xData; outputs: BsecOutputs; bsec: var Bsec2) =
  var readings = %* {}
  echo data
  for i in 0..<outputs.nOutputs.int:
    let sensor = outputs.output[i]
    if i == 0:
      echo "Timestamp: ", sensor.timestamp div 1_000_000_000
    let signal = sensor.signal
    let accuracy = sensor.accuracy
    case cast[BsecVirtualSensorT](sensor.sensor_id):
    of BSEC_OUTPUT_IAQ:
      if accuracy > 0:
        echo "IAQ = ", signal, " [0-500] (", accuracy, ")"
        readings{"iaq"} = %signal
    of BSEC_OUTPUT_STATIC_IAQ:
      if accuracy > 0:
        echo "Static IAQ = ", signal, " (", accuracy, ")"
        readings{"iaq_static"} = %signal
    of BSEC_OUTPUT_CO2_EQUIVALENT:
      if accuracy > 0:
        echo "CO2e = ", signal, " ppm (", accuracy, ")"
        readings{"co2e"} = %signal
    of BSEC_OUTPUT_BREATH_VOC_EQUIVALENT:
      if accuracy > 0:
        echo "bVOCe = ", signal, " ppm (", accuracy, ")"
        readings{"bvoce"} = %signal
    of BSEC_OUTPUT_RAW_TEMPERATURE:
      echo "Raw Temperature = ", signal, " C"
      readings{"temperature_raw"} = %signal
    of BSEC_OUTPUT_RAW_HUMIDITY:
      echo "Raw Humidity = ", signal, " %"
      readings{"humidity_raw"} = %signal
    of BSEC_OUTPUT_RAW_PRESSURE:
      echo "Raw Pressure = ", signal / 100, " hPa"
      readings{"pressure"} = %(signal / 100)
    of BSEC_OUTPUT_RAW_GAS:
      echo "Raw Gas = ", signal, " Ohm"
      readings{"gas_raw"} = %signal
    of BSEC_OUTPUT_STABILIZATION_STATUS:
      echo "Stabilization status = ", signal.bool
    of BSEC_OUTPUT_RUN_IN_STATUS:
      echo "Run-in status = ", signal.bool
    of BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_TEMPERATURE:
      echo "Temperature = ", signal, " C"
      readings{"temperature"} = %signal
    of BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_HUMIDITY:
      echo "Humidity = ", signal, " %"
      readings{"humidity"} = %signal
    of BSEC_OUTPUT_GAS_PERCENTAGE:
      if accuracy > 0:
        echo "Gas = ", signal, " %"
        readings{"gas"} = %signal
    else: discard

  let colour = bh1745Sensor.getRgbcRaw()
  echo "Colour: ", colour
  echo "Colour Temperature: ", colour.toColourTemperature(), "K"
  echo "Light level: ", colour.toLux(), " lx"

  readings{"color_temperature"} = %colour.toColourTemperature()
  readings{"luminance"} = %colour.toLux()

  # var config: array[BSEC_MAX_PROPERTY_BLOB_SIZE, uint8]
  # if bsecSensor.getConfig(config[0].addr):
  #   var res = ""
  #   for b in config: res.add(toHex(b))
  #   echo "config: " & res

  var state: array[BSEC_MAX_STATE_BLOB_SIZE, uint8]
  if bsecSensor.getState(state[0].addr):
    var res = ""
    for b in state: res.add(toHex(b))
    echo "state: " & res

  if not indoorReadingCb.isNil:
    indoorReadingCb(readings)

proc initBoardIndoor*(i2c: var I2c) =
  bh1745Sensor = createBh1745(i2c, Bh1745I2cAddrDefault)
  if not bh1745Sensor.init():
    echo "Failed to set up light/colour sensor"
    return

  bsecSensor = createBsec2()

  if not bsecSensor.begin(i2c, Bme68xI2cAddrHigh):
    echo "BSEC init failed! ", bsecSensor.status
    return

  echo &"BSEC version: {bsecSensor.version.major}.{bsecSensor.version.minor}.{bsecSensor.version.major_bugfix}.{bsecSensor.version.minor_bugfix}"

  if sampleRate == BSEC_SAMPLE_RATE_ULP:
    echo "setting temp offset to ", TEMP_OFFSET_ULP_WIFI
    bsecSensor.setTemperatureOffset(TEMP_OFFSET_ULP_WIFI)
  elif sampleRate == BSEC_SAMPLE_RATE_LP:
    echo "setting temp offset to ", TEMP_OFFSET_LP_WIFI
    bsecSensor.setTemperatureOffset(TEMP_OFFSET_LP_WIFI)
  else:
    echo "no temp offset"

  echo "sample rate: ", sampleRate

  if not bsecSensor.setState(cast[ptr uint8](initState[0].addr)):
    echo "BSEC: Unable to set state! ", bsecSensor.status
    return

  # Subsribe to the desired BSEC2 outputs
  if not bsecSensor.updateSubscription(bsecSensorList, sampleRate):
    echo "BSEC: Unable to set sensor list! ", bsecSensor.status
    #return

  bsecSensor.setCallback(bsecDataCallback)

  while true:
    if not bsecSensor.run():
      echo "BSEC error! ", bsecSensor.status
    # sleepMs(3000)
    tightLoopContents()
