include(RunCMake)

# Isolate our ctest runs from external environment.
unset(ENV{CTEST_PARALLEL_LEVEL})
unset(ENV{CTEST_OUTPUT_ON_FAILURE})

if(RunCMake_GENERATOR STREQUAL "Borland Makefiles" OR
   RunCMake_GENERATOR STREQUAL "Watcom WMake")
  set(fs_delay 3)
else()
  set(fs_delay 1.125)
endif()

function(run_GoogleTest DISCOVERY_MODE)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTest-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake_with_options(GoogleTest -DCMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE=${DISCOVERY_MODE})

  run_cmake_command(GoogleTest-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target fake_gtest
  )

  run_cmake_command(GoogleTest-property-timeout-exe
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target property_timeout_test
  )

  run_cmake_command(GoogleTest-test1
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -L TEST1
    --no-label-summary
  )

  run_cmake_command(GoogleTest-test2
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -L TEST2
    --no-label-summary
  )

  run_cmake_command(GoogleTest-test3
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -L TEST3
    --no-label-summary
  )

  run_cmake_command(GoogleTest-test4
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -L TEST4
    --no-label-summary
  )

  run_cmake_command(GoogleTest-test5
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -L TEST5
    --no-label-summary
  )

  run_cmake_command(GoogleTest-test6
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -L TEST6
    --no-label-summary
  )

  run_cmake_command(GoogleTest-test7
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -L TEST7
    --no-label-summary
  )

  run_cmake_command(GoogleTest-test-missing
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -R no_tests_defined
    --no-label-summary
  )

  run_cmake_command(GoogleTest-property-timeout1
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -R property_timeout\\.case_no_discovery
    --no-label-summary
  )

  run_cmake_command(GoogleTest-property-timeout2
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -R property_timeout\\.case_with_discovery
    --no-label-summary
  )

  run_cmake_command(GoogleTest-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target skip_test
  )

  run_cmake_command(GoogleTest-skip-test
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -R skip_test
    --no-label-summary
  )
endfunction()

function(run_Launcher_CMP0178 DISCOVERY_MODE cmp0178)
  if(CMAKE_C_COMPILER_ID STREQUAL "MSVC" AND CMAKE_C_COMPILER_VERSION VERSION_LESS "14.0")
    return()
  endif()
  if(CMAKE_VS_PLATFORM_NAME STREQUAL "ARM64" AND CMAKE_C_COMPILER_ID STREQUAL "MSVC" AND CMAKE_C_COMPILER_VERSION VERSION_LESS "19.36")
    return()
  endif()

  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/Launcher-CMP0178-${cmp0178}-build)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()

  run_cmake_with_options(Launcher-CMP0178-${cmp0178}
    -DCMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE=${DISCOVERY_MODE}
  )

  set(RunCMake_TEST_NO_CLEAN 1)

  # do not issue any warnings on stderr that would cause the build to fail
  set(RunCMake_TEST_OUTPUT_MERGE 1)
  run_cmake_command(Launcher-CMP0178-${cmp0178}-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
  )
  unset(RunCMake_TEST_OUTPUT_MERGE)

  run_cmake_command(Launcher-CMP0178-${cmp0178}-test
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -V
    --no-label-summary
  )
endfunction()

function(run_GoogleTestXML DISCOVERY_MODE)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTestXML-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake_with_options(GoogleTestXML -DCMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE=${DISCOVERY_MODE})

  run_cmake_command(GoogleTestXML-discovery
  ${CMAKE_COMMAND}
  --build .
  --config Debug
  --target xml_output
  )

  run_cmake_command(GoogleTestXML-result
  ${CMAKE_CTEST_COMMAND}
  -C Debug
  -R GoogleTestXML
  --no-label-summary
  )

  run_cmake_command(GoogleTestXML-special-result
  ${CMAKE_CTEST_COMMAND}
  -C Debug
  -R GoogleTestXMLSpecial
  --no-label-summary
  )
endfunction()

function(run_GoogleTest_discovery_timeout DISCOVERY_MODE)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTest-discovery-timeout)
  set(RunCMake_TEST_NO_CLEAN 1)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake_with_options(GoogleTestDiscoveryTimeout -DDISCOVERY_MODE=${DISCOVERY_MODE})

  set(RunCMake_TEST_OUTPUT_MERGE 1)
  run_cmake_command(GoogleTest-discovery-${DISCOVERY_MODE}-timeout-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target discovery_timeout_test
  )
  set(RunCMake_TEST_OUTPUT_MERGE 0)

  run_cmake_command(GoogleTest-discovery-${DISCOVERY_MODE}-timeout-test
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -R discovery_timeout_test
    --no-label-summary
  )
endfunction()

function(run_GoogleTest_discovery_arg_change DISCOVERY_MODE)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTest-discovery-arg-change)
  set(RunCMake_TEST_NO_CLEAN 1)
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake_with_options(GoogleTestDiscoveryArgChange
    -DCMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE=${DISCOVERY_MODE}
    -DTEST_FILTER=basic
  )
  run_cmake_command(GoogleTest-discovery-arg-change-build
    ${CMAKE_COMMAND}
    --build .
    --config Release
    --target fake_gtest
  )
  run_cmake_command(GoogleTest-discovery-arg-change-basic
    ${CMAKE_CTEST_COMMAND}
    -C Release
    -N
  )
  execute_process(COMMAND ${CMAKE_COMMAND} -E sleep ${fs_delay}) # handle 1s resolution
  run_cmake_with_options(GoogleTestDiscoveryArgChange
    -DCMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE=${DISCOVERY_MODE}
    -DTEST_FILTER=typed
  )
  run_cmake_command(GoogleTest-discovery-arg-change-build
    ${CMAKE_COMMAND}
    --build .
    --config Release
    --target fake_gtest
  )
  run_cmake_command(GoogleTest-discovery-arg-change-typed
    ${CMAKE_CTEST_COMMAND}
    -C Release
    -N
  )
endfunction()

function(run_GoogleTest_discovery_multi_config)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTest-discovery-multi-config)
  set(RunCMake_TEST_NO_CLEAN 1)
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake(GoogleTestDiscoveryMultiConfig)

  run_cmake_command(GoogleTest-build-release
    ${CMAKE_COMMAND}
    --build .
    --config Release
    --target configuration_gtest
  )
  run_cmake_command(GoogleTest-build-debug
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target configuration_gtest
  )
  run_cmake_command(GoogleTest-configuration-release
    ${CMAKE_CTEST_COMMAND}
    -C Release
    -L CONFIG
    -N
  )
  run_cmake_command(GoogleTest-configuration-debug
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -L CONFIG
    -N
  )

endfunction()

function(run_GoogleTest_discovery_test_list DISCOVERY_MODE)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTest-discovery-test-list-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake_with_options(GoogleTestDiscoveryTestList -DCMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE=${DISCOVERY_MODE})

  run_cmake_command(GoogleTest-discovery-test-list-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target test_list_test
  )

  run_cmake_command(GoogleTest-discovery-test-list-test
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    --no-label-summary
  )
endfunction()

function(run_GoogleTest_discovery_flush_script DISCOVERY_MODE)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTest-discovery-flush-script-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake_with_options(GoogleTestDiscoveryFlushScript -DCMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE=${DISCOVERY_MODE})

  run_cmake_command(GoogleTest-discovery-flush-script-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target flush_script_test
  )

  run_cmake_command(GoogleTest-discovery-flush-script-test
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    --no-label-summary
  )
endfunction()

function(run_GoogleTest_discovery_test_list_scoped DISCOVERY_MODE)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTest-discovery-test-list-scoped-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake_with_options(GoogleTestDiscoveryTestListScoped -DCMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE=${DISCOVERY_MODE})

  run_cmake_command(GoogleTest-discovery-test-list-scoped-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target test_list_scoped_test
  )

  run_cmake_command(GoogleTest-discovery-test-list-scoped-test
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    --no-label-summary
  )
endfunction()

function(run_GoogleTest_discovery_test_list_extra_args DISCOVERY_MODE)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTest-discovery-test-list-extra-args-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake_with_options(GoogleTestDiscoveryTestListExtraArgs -DCMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE=${DISCOVERY_MODE})

  run_cmake_command(GoogleTest-discovery-test-list-extra-args-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target test_list_extra_args
  )

  run_cmake_command(GoogleTest-discovery-test-list-extra-args-test
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    --no-label-summary
  )
endfunction()

function(run_GoogleTest_LegacyParser)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTestLegacyParser-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  set(ENV{NO_GTEST_JSON_OUTPUT} 1)

  run_cmake(GoogleTestLegacyParser)

  run_cmake_command(GoogleTestLegacyParser-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target fake_gtest
  )

  set(RunCMake-stdout-file GoogleTest-test1-stdout.txt)
  run_cmake_command(GoogleTestLegacyParser-test
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    --no-label-summary
  )

  unset(ENV{NO_GTEST_JSON_OUTPUT})
endfunction()

function(run_GoogleTest_DEF_SOURCE_LINE)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/GoogleTest-DEF_SOURCE_LINE-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake(GoogleTestDefSourceLine)

  run_cmake_command(GoogleTest-DEF_SOURCE_LINE-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target fake_gtest
  )
  run_cmake_command(GoogleTest-DEF_SOURCE_LINE
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    -R "^basic\\.case_"
    --show-only=json-v1
  )
endfunction()

foreach(DISCOVERY_MODE POST_BUILD PRE_TEST)
  message(STATUS "Testing ${DISCOVERY_MODE} discovery mode via CMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE global override...")
  run_GoogleTest(${DISCOVERY_MODE})
  run_GoogleTestXML(${DISCOVERY_MODE})
  run_Launcher_CMP0178(${DISCOVERY_MODE} NEW)
  run_Launcher_CMP0178(${DISCOVERY_MODE} OLD)
  run_Launcher_CMP0178(${DISCOVERY_MODE} WARN)
  message(STATUS "Testing ${DISCOVERY_MODE} discovery mode via DISCOVERY_MODE option...")
  run_GoogleTest_discovery_timeout(${DISCOVERY_MODE})
  run_GoogleTest_discovery_arg_change(${DISCOVERY_MODE})
  run_GoogleTest_discovery_test_list(${DISCOVERY_MODE})
  run_GoogleTest_discovery_test_list_scoped(${DISCOVERY_MODE})
  run_GoogleTest_discovery_test_list_extra_args(${DISCOVERY_MODE})
  run_GoogleTest_discovery_flush_script(${DISCOVERY_MODE})
endforeach()

if(RunCMake_GENERATOR_IS_MULTI_CONFIG)
  message(STATUS "Testing PRE_TEST discovery multi configuration...")
  run_GoogleTest_discovery_multi_config()
endif()

block(SCOPE_FOR VARIABLES)
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/WorkDirWithSpaces-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(RunCMake_TEST_OPTIONS -DCMAKE_BUILD_TYPE=Debug)
  endif()
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake(WorkDirWithSpaces)

  run_cmake_command(WorkDirWithSpaces-build
    ${CMAKE_COMMAND}
    --build .
    --config Debug
    --target test_workdir
  )

  run_cmake_command(WorkDirWithSpaces-test
    ${CMAKE_CTEST_COMMAND}
    -C Debug
    --no-label-summary
    --output-on-failure
  )
endblock()

run_GoogleTest_LegacyParser()
run_GoogleTest_DEF_SOURCE_LINE()
