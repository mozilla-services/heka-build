# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

cmake_minimum_required(VERSION 2.8 FATAL_ERROR)
project(heka-build C)
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Heka")
set(CPACK_PACKAGE_VERSION_MAJOR 0)
set(CPACK_PACKAGE_VERSION_MINOR 2)
set(CPACK_PACKAGE_VERSION_PATCH 0)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

if(CMAKE_HOST_UNIX)
	find_library(MATH_LIBRARY m)
	include(external_lua)
endif(CMAKE_HOST_UNIX)

include_directories(${CMAKE_BINARY_DIR}/external/include)
add_subdirectory(src/github.com/mozilla-services/heka/sandbox)
