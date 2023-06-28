import std/strformat, std/strutils
import picostdlib/pico/platform
import pimoroni_pico/drivers/bme68x
import pimoroni_pico/libraries/bsec2
import pimoroni_pico/drivers/bh1745
import ../common

# var bme688Sensor: Bme68x
var bsecSensor: Bsec2
var bh1745Sensor: Bh1745

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
    BSEC_OUTPUT_GAS_PERCENTAGE,
  ]

proc bsecDataCallback(data: Bme68xData; outputs: BsecOutputs; bsec: var Bsec2) =
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
    of BSEC_OUTPUT_STATIC_IAQ:
      if accuracy > 0:
        echo "Static IAQ = ", signal, " (", accuracy, ")"
    of BSEC_OUTPUT_CO2_EQUIVALENT:
      if accuracy > 0:
        echo "CO2e = ", signal, " ppm (", accuracy, ")"
    of BSEC_OUTPUT_BREATH_VOC_EQUIVALENT:
      if accuracy > 0:
        echo "bVOCe = ", signal, " ppm (", accuracy, ")"
    of BSEC_OUTPUT_RAW_TEMPERATURE:
      echo "Raw Temperature = ", signal, " C"
    of BSEC_OUTPUT_RAW_HUMIDITY:
      echo "Raw Humidity = ", signal, " %"
    of BSEC_OUTPUT_RAW_PRESSURE:
      echo "Raw Pressure = ", signal / 100, " hPa"
    of BSEC_OUTPUT_RAW_GAS:
      echo "Raw Gas = ", signal, " Ohm"
    of BSEC_OUTPUT_STABILIZATION_STATUS:
      echo "Stabilization status = ", signal.bool
    of BSEC_OUTPUT_RUN_IN_STATUS:
      echo "Run-in status = ", signal.bool
    of BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_TEMPERATURE:
      echo "Temperature = ", signal, " C"
    of BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_HUMIDITY:
      echo "Humidity = ", signal, " %"
    of BSEC_OUTPUT_GAS_PERCENTAGE:
      if accuracy > 0:
        echo "Gas = ", signal, " %"
    else: discard

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

  bsecSensor.setTemperatureOffset(2.5)

  if not bsecSensor.updateSubscription(bsecSensorList, BSEC_SAMPLE_RATE_LP):
    echo "BSEC: Unable to set sensor list! ", bsecSensor.status
    return

  bsecSensor.setCallback(bsecDataCallback)

  # bme688Sensor = createBme68x(debug = true)
  # if not bme688Sensor.begin(i2c, address = Bme68xI2cAddrHigh):
  #   echo "BME68x init failed"

  # echo "BME68x init OK!"
  # var data: Bme68xData

  while true:
    # echo bme688Sensor.readForced(data)
    # echo data
    if not bsecSensor.run():
      echo "BSEC error! ", bsecSensor.status
    # let colour = bh1745Sensor.getRgbcRaw()
    # echo "Colour: ", colour
    # echo "Colour Temperature: ", colour.toColourTemperature(), "K"
    # echo "Light level: ", colour.toLux(), " lx"
    # sleepMs(3000)
    tightLoopContents()

