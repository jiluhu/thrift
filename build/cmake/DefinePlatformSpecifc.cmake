#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#

# Uncomment this to show some basic cmake variables about platforms
# include (NewPlatformDebug)

# Visual Studio specific options
if(MSVC)
    #For visual studio the library naming is as following:
    # Dynamic libraries:
    #  - thrift.dll  for release library
    #  - thriftd.dll for debug library
    #
    # Static libraries:
    #  - thriftmd.lib for /MD release build
    #  - thriftmt.lib for /MT release build
    #
    #  - thriftmdd.lib for /MD debug build
    #  - thriftmtd.lib for /MT debug build
    #
    # the same holds for other libraries like libthriftz etc.

    # For Debug build types, append a "d" to the library names.
    set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Set debug library postfix" FORCE)
    set(CMAKE_RELEASE_POSTFIX "" CACHE STRING "Set release library postfix" FORCE)
    set(CMAKE_RELWITHDEBINFO_POSTFIX "" CACHE STRING "Set release library postfix" FORCE)

    # Build using /MT option instead of /MD if the WITH_MT options is set
    if(WITH_MT)
        set(CompilerFlags
                CMAKE_CXX_FLAGS
                CMAKE_CXX_FLAGS_DEBUG
                CMAKE_CXX_FLAGS_RELEASE
                CMAKE_CXX_FLAGS_RELWITHDEBINFO
                CMAKE_C_FLAGS
                CMAKE_C_FLAGS_DEBUG
                CMAKE_C_FLAGS_RELEASE
                CMAKE_C_FLAGS_RELWITHDEBINFO
                )
        foreach(CompilerFlag ${CompilerFlags})
          string(REPLACE "/MD" "/MT" ${CompilerFlag} "${${CompilerFlag}}")
        endforeach()
        set(STATIC_POSTFIX "mt" CACHE STRING "Set static library postfix" FORCE)
    else(WITH_MT)
        set(STATIC_POSTFIX "md" CACHE STRING "Set static library postfix" FORCE)
    endif(WITH_MT)

    # Disable Windows.h definition of macros for min and max
    add_definitions("-DNOMINMAX")

    # Disable boost auto linking pragmas - cmake includes the right files
    add_definitions("-DBOOST_ALL_NO_LIB")

    # Windows build does not know how to make a shared library yet
    # as there are no __declspec(dllexport) or exports files in the project.
    if (WITH_SHARED_LIB)
      message (FATAL_ERROR "Windows build does not support shared library output yet, please set -DWITH_SHARED_LIB=off")
    endif()

    add_definitions("/MP") # parallel build
    add_definitions("/W3") # warning level 3

    # VS2010 does not provide inttypes which we need for "PRId64" used in many places
    find_package(Inttypes)
    if (Inttypes_FOUND)
      include_directories(${INTTYPES_INCLUDE_DIRS})
      # OpenSSL conflicts with the definition of PRId64 unless it is defined first
      add_definitions("/FIinttypes.h")
    endif ()
elseif(UNIX)
  find_program( MEMORYCHECK_COMMAND valgrind )
  set( MEMORYCHECK_COMMAND_OPTIONS "--gen-suppressions=all --leak-check=full" )
  set( MEMORYCHECK_SUPPRESSIONS_FILE "${PROJECT_SOURCE_DIR}/test/valgrind.suppress" )
endif()

add_definitions("-D__STDC_FORMAT_MACROS")

# WITH_*THREADS selects which threading library to use
if(WITH_BOOSTTHREADS)
  add_definitions("-DUSE_BOOST_THREAD=1")
elseif(WITH_STDTHREADS)
  add_definitions("-DUSE_STD_THREAD=1")
endif()

# GCC and Clang: use C++11
if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER "4.6.4")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  endif()
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -Wall -Wextra -pedantic")
endif()

# If gcc older than 4.8 is detected and plugin support was requested, fail fast
if (CMAKE_CXX_COMPILER_ID MATCHES "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.8" AND WITH_PLUGIN)
  message(SEND_ERROR "Thrift compiler plug-in support is not possible with older gcc ( < 4.8 ) compiler")
endif()

