# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

include(ExternalProject)

set(_BASE_PATH "${CMAKE_BINARY_DIR}/external")
set_property(DIRECTORY PROPERTY EP_PREFIX ${_BASE_PATH})
set(PLATFORM "posix")

if (APPLE)
    set(PLATFORM "macosx")
endif(APPLE)

if(UNIX)
    externalproject_add(
        lua-5_1_5
        URL http://www.lua.org/ftp/lua-5.1.5.tar.gz
        URL_MD5 2e115fe26e435e33b0d5c022e4490567
        PATCH_COMMAND patch -p1 < ${CMAKE_CURRENT_LIST_DIR}/lua-5_1_5.patch
        CONFIGURE_COMMAND ""
        BUILD_IN_SOURCE 1
        BUILD_COMMAND make ${PLATFORM}
        INSTALL_COMMAND make install INSTALL_TOP="${_BASE_PATH}"
    )
endif()
#todo Windows
