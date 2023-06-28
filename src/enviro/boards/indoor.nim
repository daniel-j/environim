import std/strformat, std/strutils
import ../common
import pimoroni_pico/drivers/bme68x
import pimoroni_pico/libraries/bsec2
import pimoroni_pico/drivers/bh1745

var bme688Sensor: Bme68x
var bh1745Sensor: Bh1745

proc initBoardIndoor*(i2c: var I2c) =
  bh1745Sensor = createBh1745(i2c)
  if not bh1745Sensor.init():
    echo "Failed to set up light/colour sensor"
    return

  echo "Hello bsec!"
  var version: BsecVersionT
  if bsec_get_version(version.addr) != BSEC_OK:
    echo "Unable to get bsec version!"
    return
  echo &"BSEC version: {version.major}.{version.minor}.{version.major_bugfix}.{version.minor_bugfix}"

  bme688Sensor = createBme68x(debug = true)
  if not bme688Sensor.begin(i2c, address = Bme68xI2cAddrHigh):
    echo "BME68x init failed"

  echo "BME68x init OK!"
  var data: Bme68xData
  while true:
    echo bme688Sensor.readForced(data)
    echo data
    let colour = bh1745Sensor.getRgbcRaw()
    echo "Colour: ", colour
    echo "Colour Temperature: ", colour.toColourTemperature(), "K"
    echo "Light level: ", colour.toLux(), " lx"
    sleepMs(3000)
