cmake_minimum_required(VERSION 3.10)
set(CMAKE_SUPPRESS_REGENERATION 1)
project(LIB1)

set(SOURCES lib1.cpp)

add_library(lib1 ${SOURCES})
