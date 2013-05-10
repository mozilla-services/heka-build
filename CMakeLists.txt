# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

cmake_minimum_required(VERSION 2.8 FATAL_ERROR)
project(heka C)
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Heka")
set(CPACK_PACKAGE_VERSION_MAJOR 0)
set(CPACK_PACKAGE_VERSION_MINOR 2)
set(CPACK_PACKAGE_VERSION_PATCH 0)
set(CPACK_PACKAGE_VENDOR "Mozilla Services")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")
include(CTest)

if (MINGW)
    set(ADDRESS_MODEL 64)
    set(CPACK_GENERATOR "ZIP")
    set(GO_PATH ${GO_PATH} ENV GOROOT)
    set(GIT_PATH ${GIT_PATH} "c:/Program Files (x86)/Git")

    find_program(GO_EXE go PATHS GO_PATH)
    execute_process(COMMAND go version OUTPUT_VARIABLE GO_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    if (GO_VERSION MATCHES "windows/386$")
        set(ADDRESS_MODEL 32)
    endif()

    add_custom_target(gopackages ALL ${GO_EXE} get code.google.com/p/go-uuid/uuid
    COMMAND ${GO_EXE} get code.google.com/p/goprotobuf/proto
    COMMAND ${GO_EXE} get code.google.com/p/goprotobuf/protoc-gen-go
    COMMAND ${GO_EXE} get github.com/bitly/go-simplejson
    COMMAND ${GO_EXE} get github.com/rafrombrc/go-notify
    COMMAND ${GO_EXE} get github.com/bbangert/toml
    COMMAND ${GO_EXE} install code.google.com/p/gomock/mockgen)

    add_custom_target(flood ALL ${GO_EXE} install github.com/mozilla-services/heka/cmd/flood DEPENDS gopackages)
    install(PROGRAMS ${CMAKE_SOURCE_DIR}/bin/flood.exe DESTINATION bin)

    add_custom_target(sbmgr ALL ${GO_EXE} install github.com/mozilla-services/heka/cmd/sbmgr DEPENDS gopackages)
    install(PROGRAMS ${CMAKE_SOURCE_DIR}/bin/sbmgr.exe DESTINATION bin)

    set(HEKA_PATH "${CMAKE_SOURCE_DIR}/src/github.com/mozilla-services/heka")
    install(FILES "${HEKA_PATH}/examples/sbmgr.toml" "${HEKA_PATH}/examples/hekad.toml" DESTINATION bin)
    install(FILES "${HEKA_PATH}/sandbox/lua/testsupport/hekabench_cbuf_counter.lua" DESTINATION bin)
    install(PROGRAMS ${CMAKE_SOURCE_DIR}/LICENSE.txt DESTINATION .)
    set(PACKAGE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}_${CPACK_PACKAGE_VERSION_MINOR}_${CPACK_PACKAGE_VERSION_PATCH}_w${ADDRESS_MODEL}")
    add_test(message ${GO_EXE} test github.com/mozilla-services/heka/message)
    # todo: need to fix the test hang issue
    # add_test(pipeline ${GO_EXE} test github.com/mozilla-services/heka/pipeline)
    # add_test(sandbox ${GO_EXE} test github.com/mozilla-services/heka/sandbox/lua)
else()
    set(PACKAGE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}_${CPACK_PACKAGE_VERSION_MINOR}_${CPACK_PACKAGE_VERSION_PATCH}")
    set(CPACK_GENERATOR "TGZ")
endif()

set(CPACK_PACKAGE_FILE_NAME ${PACKAGE_NAME})
set(CMAKE_INSTALL_PREFIX ${PACKAGE_NAME})
include(CPack)

find_program(PATCH_EXE patch PATHS "${GIT_PATH}/bin")

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(external_lua)

set(LUA_SANDBOX_GO "${CMAKE_SOURCE_DIR}/src/github.com/mozilla-services/heka/sandbox/lua/lua_sandbox.go")
configure_file("${LUA_SANDBOX_GO}.in" ${LUA_SANDBOX_GO} @ONLY)

if (MINGW)
    add_custom_target(hekad ALL ${GO_EXE} install github.com/mozilla-services/heka/cmd/hekad)
    add_dependencies(hekad gopackages lua-5_1_5)

    # copy the Lua dll to where the tests will run
    set(LUA_DLL_PATH ${LUA_LIB_PATH}/liblua.dll)
    add_custom_target(dll4pipeline ALL ${CMAKE_COMMAND} -E copy ${LUA_DLL_PATH} ${HEKA_PATH}/pipeline/. DEPENDS hekad)
    add_custom_target(dll4sandbox ALL ${CMAKE_COMMAND} -E copy ${LUA_DLL_PATH} ${HEKA_PATH}/sandbox/lua/. DEPENDS hekad)

    install(PROGRAMS ${CMAKE_SOURCE_DIR}/bin/hekad.exe DESTINATION bin)
    install(FILES ${LUA_DLL_PATH} DESTINATION bin)
endif()
