cmake_minimum_required(VERSION 3.13...3.27)

if(NOT DEFINED OUTPUT_NAME)
  set(OUTPUT_NAME environim)
endif()

# Set CMake build type. Debug, Release, MinSizeRel, RelWithDebInfo
set(CMAKE_BUILD_TYPE Debug)

# Set standards
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# initialize pico-sdk from GIT
# (note this can come from environment, CMake cache etc)
# set(PICO_SDK_FETCH_FROM_GIT on)
# set(PICO_SDK_PATH ENV{PICO_SDK_PATH})

# Set board type here
if(NOT DEFINED PICO_BOARD)
  set(PICO_BOARD pico_w) # Set by piconim
endif()

# Support C++ exceptions with Nim
set(PICO_CXX_ENABLE_EXCEPTIONS 1)

# Uncomment to disable picotool binary info
# set(PICO_NO_BINARY_INFO 1)

execute_process(
  COMMAND nimble path picostdlib
  OUTPUT_VARIABLE PICOSTDLIB_DIR
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

set(pico_generate_pio_header_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")

# note: this must happen before project()
include(${PICOSTDLIB_DIR}/picostdlib/cmake/pico_sdk_import.cmake)

project(${OUTPUT_NAME} C CXX ASM)

# initialize the Raspberry Pi Pico SDK
pico_sdk_init()

include(${PICOSTDLIB_DIR}/picostdlib/cmake/picostdlib.cmake)

add_executable(${OUTPUT_NAME})

picostdlib_target(${OUTPUT_NAME} ${OUTPUT_NAME})

# set_target_properties(${OUTPUT_NAME} PROPERTIES LINKER_LANGUAGE CXX)

target_include_directories(${OUTPUT_NAME} PRIVATE
  ${CMAKE_SOURCE_DIR}/csource
)

execute_process(
  COMMAND nimble path pimoroni_pico
  OUTPUT_VARIABLE PIMORONI_PICO_DIR
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
include(${PIMORONI_PICO_DIR}/pimoroni_pico/cmake/pimoroni_pico.cmake)

target_link_libraries(${OUTPUT_NAME}
  # Additional libraries
  bsec2 # bme68x
)

target_compile_definitions(${OUTPUT_NAME} PRIVATE
  # CYW43_HOST_NAME="PicoW"
  PICO_STDIO_USB_CONNECT_WAIT_TIMEOUT_MS=2000
)

# enable usb output, disable uart output
pico_enable_stdio_usb(${OUTPUT_NAME} 1)
pico_enable_stdio_uart(${OUTPUT_NAME} 0)

# create map/bin/hex/uf2 file etc.
pico_add_extra_outputs(${OUTPUT_NAME})

# add url via pico_set_program_url
# pico_set_program_url(${OUTPUT_NAME} "")
