import picostdlib
import ./common
import ./boards/indoor

stdioInitAll()

var i2c = i2cInit()

initBoardIndoor(i2c)

while true:
  tightLoopContents()
