# add compile options to warning_options to ensure unused-function throws a warning
# if warning_options is NOT DEFINED, assume compiler doesn't support warning as error
macro(get_warning_options warning_options lang)
  if (CMAKE_${lang}_COMPILER_ID MATCHES "^(GNU|Clang|AppleClang|XLClang|IBMClang|LCC|IntelLLVM|NVHPC)$")
    set(${warning_options} "-Wall")
  elseif (CMAKE_${lang}_COMPILER_ID STREQUAL "MSVC"
          OR (CMAKE_${lang}_COMPILER_ID STREQUAL "Intel" AND CMAKE_${lang}_SIMULATE_ID MATCHES "MSVC"))
    set(${warning_options} "-W4")
  elseif (CMAKE_${lang}_COMPILER_ID STREQUAL "NVIDIA"
      AND CMAKE_${lang}_COMPILER_VERSION VERSION_GREATER_EQUAL 10.2.89)
    if(CMAKE_${lang}_SIMULATE_ID MATCHES "MSVC")
      set(${warning_options} "-Xcompiler=-W4")
    else()
      set(${warning_options} "-Xcompiler=-Wall")
    endif()
  elseif (CMAKE_${lang}_COMPILER_ID STREQUAL "Intel")
    set(${warning_options} "-w3")
  elseif (CMAKE_${lang}_COMPILER_ID STREQUAL "XL")
    set(${warning_options} "-qinfo=all")
  elseif (CMAKE_${lang}_COMPILER_ID STREQUAL "SunPro")
    if(lang STREQUAL CXX)
      set(${warning_options} "+w;+w2")
    else()
      set(${warning_options} "")
    endif()
  elseif (CMAKE_${lang}_COMPILER_ID STREQUAL "Fujitsu")
    set(${warning_options} "SHELL:-w 8")
  endif()

  if(${lang} STREQUAL Swift)
    # No extra flags required for Swift
    set(${warning_options} "")
  endif()
endmacro()
