# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

include(ExternalProject)

set(EXTERNAL_PATH "${CMAKE_BINARY_DIR}/external")
set(LUA_INCLUDE_PATH "${EXTERNAL_PATH}/include")
set(LUA_LIB_PATH "${EXTERNAL_PATH}/lib")
set_property(DIRECTORY PROPERTY EP_PREFIX ${EXTERNAL_PATH})

externalproject_add(
    lua-5_1_5
    URL http://www.lua.org/ftp/lua-5.1.5.tar.gz
    URL_MD5 2e115fe26e435e33b0d5c022e4490567
    PATCH_COMMAND ${PATCH_EXE} -p1 < ${CMAKE_CURRENT_LIST_DIR}/lua-5_1_5.patch
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNAL_PATH} -DADDRESS_MODEL=${ADDRESS_MODEL} --no-warn-unused-cli
    INSTALL_DIR ${EXTERNAL_PATH}
)
