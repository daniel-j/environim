import std/json
import picostdlib
import ./common
import ./boards/indoor
import ./destinations/mqtt
import picostdlib/memoryinfo

const WIFI_SSID {.strdefine.} = ""
const WIFI_PASSWORD {.strdefine.} = ""

stdioInitAll()

var i2c = i2cInit()

proc connectToWifi() =
  cyw43ArchEnableStaMode()

  echo "Connecting to Wifi ", WIFI_SSID

  let err = cyw43ArchWifiConnectTimeoutMs(WIFI_SSID.cstring, WIFI_PASSWORD.cstring, AuthWpa2AesPsk, 30000)
  if err != PicoErrorNone:
    echo "Failed to connect! Error: ", $err
    return
  else:
    echo "Connected"

proc sendReadings(data: JsonNode) =
  echo "sending readings: ", data
  uploadReadingMqtt("Enviro-" & uid, "enviro-indoor-02", $(%* {
    "readings": data,
    #"timestamp": "TODO"
  }))
  echo GC_getStatistics()
  echo (getUsedHeap(), getTotalHeap())

if cyw43ArchInit() != PicoErrorNone:
  echo "Wifi init failed!"
else:
  connectToWifi()

  indoorReadingCb = sendReadings
  initBoardIndoor(i2c)

while true:
  tightLoopContents()
