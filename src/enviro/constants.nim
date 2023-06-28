import picostdlib/hardware/gpio
import picostdlib/pico

# version
const EnviroNimVersion* = "0.0.1"

type
  # modules
  EnviroBoard* = enum
    # EnviroUnknown = 0
    EnviroIndoor
    EnviroGrow
    EnviroWeather
    EnviroUrban
    # EnviroCamera

const
  # common pins
  PinHoldSysEn*               = 2.Gpio
  PinExternalInterrupt*       = 3.Gpio
  PinActivityLed*             = 6.Gpio
  PinPokeButton*              = 7.Gpio
  PinRtcAlarm*                = 8.Gpio
  PinRain*                    = 10.Gpio

let
  # system pins
  PinI2cSda*                  = PicoDefaultI2cSdaPin
  PicI2cScl*                  = PicoDefaultI2cSclPin
  PinWifiCs*                  = 25.Gpio # PicoDefaultLedPin

type
  # wake reasons
  WakeReason* = enum
    # WakeReasonUnknown = 0
    WakeReasonProvision
    WakeReasonPokeButtonPress
    WakeReasonRtcAlarm
    WakeReasonExternalTrigger
    WakeReasonRainTrigger
    WakeReasonUsbPowered

  # warning led states
  WarnLedState* = enum
    WarnLedOff
    WarnLedOn
    WarnLedBlink

  # upload status
  UploadStatus* = enum
    UploadSuccess
    UploadFailed
    UploadRateLimited
    UploadLostSync
    UploadSkipFile

const
  # humidity
  WATER_VAPOR_SPECIFIC_GAS_CONSTANT* = 461.5
  CRITICAL_WATER_TEMPERATURE* = 647.096
  CRITICAL_WATER_PRESSURE* = 22064000
