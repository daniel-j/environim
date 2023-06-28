# Package

version       = "0.0.1"
author        = "djazz"
description   = "Pimoroni Enviro firmware written in Nim"
license       = "BSD-3-Clause"
srcDir        = "src"
bin           = @["environim"]


# Dependencies

requires "nim >= 1.6.0"
requires "picostdlib >= 1.0.0"
requires "pimoroni_pico >= 0.1.0"

include picostdlib/build_utils/tasks
