cmake_minimum_required(VERSION 3.26)

project(manuscript)

set(CMAKE_GENERATOR "Ninja")

if (CMAKE_BINARY_DIR STREQUAL CMAKE_SOURCE_DIR)
    message(FATAL_ERROR "Source and build directories cannot be the same.")
endif()

include_directories(${CMAKE_SOURCE_DIR}/staging/cpython/include/python3.13d)

add_executable(msr src/m.c)
target_link_libraries(msr ${CMAKE_SOURCE_DIR}/staging/cpython/lib/libpython3.13d.a)
