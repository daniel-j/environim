import picostdlib/pico/unique_id
import pimoroni_pico/common/pimoroni_i2c
import ./constants

export pimoroni_i2c

let uid* = picoGetUniqueBoardIdString()

proc i2cInit*(): I2c =
  result.init(PinI2cSda, PicI2cScl, 100000)

  echo "i2c initialized ", result

