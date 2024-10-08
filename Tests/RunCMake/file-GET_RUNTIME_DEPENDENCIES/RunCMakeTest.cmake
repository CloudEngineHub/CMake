cmake_minimum_required(VERSION 3.16)
include(RunCMake)

# Function to build and install a project.
function(run_install_test case)
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/${case}-build)
  run_cmake(${case})
  set(RunCMake_TEST_NO_CLEAN 1)
  run_cmake_command(${case}-build ${CMAKE_COMMAND} --build . --config Debug)
  # Check "all" components.
  set(CMAKE_INSTALL_PREFIX ${RunCMake_TEST_BINARY_DIR}/root-all)
  set(maybe_stderr "${case}-all-stderr-${CMAKE_C_COMPILER_ID}.txt")
  if(EXISTS "${RunCMake_SOURCE_DIR}/${maybe_stderr}")
    set(RunCMake-stderr-file "${maybe_stderr}")
  endif()
  run_cmake_command(${case}-all ${CMAKE_COMMAND} --install . --prefix ${CMAKE_INSTALL_PREFIX} --config Debug)
endfunction()

# Function to check the contents of the output files.
function(check_contents filename contents_regex)
  if(EXISTS "${CMAKE_INSTALL_PREFIX}/${filename}")
    file(READ "${CMAKE_INSTALL_PREFIX}/${filename}" contents)
    if(NOT contents MATCHES "${contents_regex}")
      string(APPEND RunCMake_TEST_FAILED "File contents:
  ${contents}
do not match what we expected:
  ${contents_regex}
in file:
  ${CMAKE_INSTALL_PREFIX}/${filename}\n")
      set(RunCMake_TEST_FAILED "${RunCMake_TEST_FAILED}" PARENT_SCOPE)
    endif()
  else()
    string(APPEND RunCMake_TEST_FAILED "File ${CMAKE_INSTALL_PREFIX}/${filename} does not exist")
    set(RunCMake_TEST_FAILED "${RunCMake_TEST_FAILED}" PARENT_SCOPE)
  endif()
endfunction()

if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
  if(NOT CMake_INSTALL_NAME_TOOL_BUG)
    run_install_test(macos)
    run_install_test(macos-rpath)
    run_install_test(macos-unresolved)
    run_install_test(macos-conflict)
    run_install_test(macos-notfile)
    run_install_test(macos-parent-rpath-propagation)
    run_install_test(file-filter)
  endif()
  run_cmake(project)
  run_cmake(badargs1)
  run_cmake(badargs2)
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
  run_install_test(windows)
  run_install_test(windows-unresolved)
  run_install_test(windows-conflict)
  run_install_test(windows-notfile)
  run_install_test(file-filter)
  run_cmake(project)
  run_cmake(badargs1)
  run_cmake(badargs2)
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
  if(DEFINED ENV{LDFLAGS})
    # Some setups prebake disable-new-dtags into LDFLAGS
    string(REPLACE "-Wl,--disable-new-dtags" "" new_ldflags "$ENV{LDFLAGS}")
    set(ENV{LDFLAGS} "${new_ldflags}")
  endif()

  if(NOT CMake_COMPILER_FORCES_NEW_DTAGS)
    run_install_test(linux)
    run_install_test(linux-parent-rpath-propagation)
    run_install_test(file-filter)
  endif()
  run_install_test(linux-unresolved)
  run_install_test(linux-conflict)
  run_install_test(linux-notfile)
  run_install_test(linux-indirect-dependencies)
  run_cmake(project)
  run_cmake(badargs1)
  run_cmake(badargs2)
else()
  run_cmake(unsupported)
endif()

run_install_test(variable-propagation)
