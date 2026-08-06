cmake_minimum_required(VERSION 3.13)

include(pico_sdk_import.cmake)

project(fm_project C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

add_executable(pico_vaccel main.c video.c)

pico_enable_stdio_uart(pico_vaccel 1)
pico_enable_stdio_usb(pico_vaccel 1)

pico_add_extra_outputs(pico_vaccel)

target_compile_options(pico_vaccel PRIVATE -Wall -Wextra)

target_link_libraries(pico_vaccel

    pico_stdlib
    hardware_dma
    hardware_irq
    hardware_pio
    hardware_pwm
)

pico_generate_pio_header(pico_vaccel ${CMAKE_CURRENT_LIST_DIR}/qspi_dma.pio)



target_include_directories(pico_vaccel PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}
)