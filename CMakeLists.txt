cmake_minimum_required(VERSION 3.13)

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

# note: this must happen before project()
include(${PICOSTDLIB_DIR}/picostdlib/cmake/pico_sdk_import.cmake)

project(${OUTPUT_NAME} C CXX ASM)

# initialize the Raspberry Pi Pico SDK
pico_sdk_init()


# # fetch and initialize FreeRTOS-Kernel
# include(FetchContent)
# FetchContent_Declare( freertos_kernel
#   GIT_REPOSITORY https://github.com/FreeRTOS/FreeRTOS-Kernel.git
#   GIT_TAG        V10.5.1
# )
# FetchContent_Populate(freertos_kernel)
# set(FREERTOS_KERNEL_PATH ${freertos_kernel_SOURCE_DIR})
# include(${FREERTOS_KERNEL_PATH}/portable/ThirdParty/GCC/RP2040/FreeRTOS_Kernel_import.cmake)

include(${PICOSTDLIB_DIR}/picostdlib/cmake/picostdlib.cmake)

add_executable(${OUTPUT_NAME})

picostdlib_target(${OUTPUT_NAME} ${OUTPUT_NAME})

# set_target_properties(${OUTPUT_NAME} PROPERTIES LINKER_LANGUAGE CXX)

target_include_directories(${OUTPUT_NAME} PUBLIC
  ${CMAKE_SOURCE_DIR}/csource
)

execute_process(
  COMMAND nimble path pimoroni_pico
  OUTPUT_VARIABLE PIMORONI_PICO_DIR
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
include(${PIMORONI_PICO_DIR}/pimoroni_pico/cmake/pimoroni_pico.cmake)

# Pico SDK patches needed
pico_sdk_patch_source("src/rp2_common/pico_standard_link/crt0.S" "${PIMORONI_PICO_DIR}/pico_sdk_crt0.patch" pico_standard_link)
pico_sdk_patch_source("src/rp2_common/pico_runtime/runtime.c" "${PIMORONI_PICO_DIR}/pico_sdk_runtime.patch" pico_runtime)


# Additional libraries
target_link_libraries(${OUTPUT_NAME}
  # For wifi and tls/https
  pico_cyw43_arch_lwip_threadsafe_background pico_lwip_mbedtls pico_mbedtls
  bsec2 # bme68x
)
# haven't got sockets to work with freertos yet...
# pico_cyw43_arch_lwip_sys_freertos FreeRTOS-Kernel-Heap3

target_compile_definitions(${OUTPUT_NAME} PRIVATE
  # CYW43_HOST_NAME="PicoW"
  PICO_STDIO_USB_CONNECT_WAIT_TIMEOUT_MS=2000
)

# target_compile_options(${OUTPUT_NAME} PRIVATE -fshort-enums -Wvla)

# enable usb output, disable uart output
pico_enable_stdio_usb(${OUTPUT_NAME} 1)
pico_enable_stdio_uart(${OUTPUT_NAME} 0)

# create map/bin/hex/uf2 file etc.
pico_add_extra_outputs(${OUTPUT_NAME})

# add url via pico_set_program_url
# pico_set_program_url(${OUTPUT_NAME} "")
