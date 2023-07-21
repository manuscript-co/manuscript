cmake_minimum_required(VERSION 3.21)
project(road-to-jsc)

set(CMAKE_CXX_STANDARD 23)

add_library(rtj STATIC road-to-jsc.cpp)

target_include_directories(rtj PUBLIC "${JSC}")
target_include_directories(rtj PUBLIC "${JSC}/JavaScriptCore/Headers")
target_include_directories(rtj PUBLIC "${JSC}/JavaScriptCore/PrivateHeaders")
target_include_directories(rtj PUBLIC "${JSC}/WTF/Headers")
target_include_directories(rtj PUBLIC "${JSC}/bmalloc/Headers")

target_link_directories(rtj PUBLIC "${JSC}/lib")
target_link_libraries(rtj libbmalloc libJavaScriptCore libWTF)
