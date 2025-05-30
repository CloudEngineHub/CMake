cmake_minimum_required(VERSION 3.10)
project(FortranModules Fortran)

if("${CMAKE_Fortran_COMPILER_ID};${CMAKE_Fortran_SIMULATE_ID}" MATCHES "^Intel(LLVM)?;MSVC$")
  string(APPEND CMAKE_Fortran_FLAGS_DEBUG " -Z7")
  string(APPEND CMAKE_Fortran_FLAGS_RELWITHDEBINFO " -Z7")
endif()

if(NOT DEFINED CMake_TEST_NESTED_MAKE_PROGRAM AND NOT CMAKE_GENERATOR MATCHES "Visual Studio")
  set(CMake_TEST_NESTED_MAKE_PROGRAM "${CMAKE_MAKE_PROGRAM}")
endif()

if(NOT DEFINED CMake_TEST_Fortran_SUBMODULES AND (
    # FIXME(#18925): We do not support Cray's module file names.
    CMAKE_Fortran_COMPILER_ID STREQUAL "Cray"
    ))
  set(CMake_TEST_Fortran_SUBMODULES 0)
endif()

if(NOT DEFINED CMake_TEST_Fortran_SUBMODULES)
  include(CheckFortranSourceCompiles)
  check_fortran_source_compiles([[
module parent
  interface
    module function id(x)
       real, intent(in) :: x
       real :: id
    end function id
  end interface
end module parent
submodule ( parent ) child
contains
  module procedure id
    id = x
  end procedure id
end submodule child
program main
end program
]] HAVE_SUBMODULES SRC_EXT F90)
  set(CMake_TEST_Fortran_SUBMODULES ${HAVE_SUBMODULES})
elseif(CMake_TEST_Fortran_SUBMODULES)
  message(STATUS "Enabling Fortran submodule tests by explicit request.")
endif()

add_executable(test_module
  test_module_main.f90
  test_module_implementation.f90
  test_module_interface.f90)

add_executable(test_multi_module
  # Place this first so that we do not get "lucky" and find the module provided
  # by compiling `test_multi_module.f90` first.
  test_multi_module_main.f90
  test_multi_module.f90)
set_property(TARGET test_multi_module PROPERTY
  JOB_POOL_COMPILE multi_module_serial)
set_property(GLOBAL APPEND PROPERTY
  JOB_POOLS multi_module_serial=1)

add_executable(test_use_in_comment_fixedform
  test_use_in_comment_fixedform.f)
set_property(SOURCE test_use_in_comment_fixedform.f PROPERTY Fortran_FORMAT FIXED)
add_executable(test_use_in_comment_freeform
  test_use_in_comment_freeform.f90)
set_property(SOURCE test_use_in_comment_freeform.f90 PROPERTY Fortran_FORMAT FREE)

add_executable(test_in_interface
  in_interface/main.f90
  in_interface/module.f90)

add_definitions(-DFOO -DBAR=1)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
add_executable(test_preprocess test_preprocess.F90 test_preprocess_module.F90)

add_executable(test_non_pp_include test_non_pp_include_main.f90 test_non_pp_include_module.f90)

# Build the external project separately using a custom target.
# Make sure it uses the same build configuration as this test.
get_property(_isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(_isMultiConfig)
  set(External_CONFIG_TYPE -C "${CMAKE_CFG_INTDIR}")
  set(External_BUILD_TYPE)
else()
  set(External_CONFIG_TYPE)
  set(External_BUILD_TYPE -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE})
endif()
set(External_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/External")
set(External_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/External")
if("${CMAKE_CURRENT_BINARY_DIR}" MATCHES " ")
  # Our build tree has a space, so the build tool supports spaces.
  # Test using modules from a path with spaces.
  string(APPEND External_BINARY_DIR " Build")
endif()
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/ExternalProject
  COMMAND ${CMAKE_CTEST_COMMAND}
  ARGS ${External_CONFIG_TYPE}
       --build-and-test
       ${External_SOURCE_DIR}
       ${External_BINARY_DIR}
       --build-noclean
       --build-two-config
       --build-project ExtFort
       --build-generator ${CMAKE_GENERATOR}
       --build-generator-platform "${CMAKE_GENERATOR_PLATFORM}"
       --build-generator-toolset "${CMAKE_GENERATOR_TOOLSET}"
       --build-options -DCMAKE_Fortran_COMPILER:STRING=${CMAKE_Fortran_COMPILER}
                       -DCMAKE_Fortran_FLAGS:STRING=${CMAKE_Fortran_FLAGS}
                       -DCMAKE_Fortran_FLAGS_DEBUG:STRING=${CMAKE_Fortran_FLAGS_DEBUG}
                       -DCMAKE_Fortran_FLAGS_RELEASE:STRING=${CMAKE_Fortran_FLAGS_RELEASE}
                       -DCMAKE_Fortran_FLAGS_MINSIZEREL:STRING=${CMAKE_Fortran_FLAGS_MINSIZEREL}
                       -DCMAKE_Fortran_FLAGS_RELWITHDEBINFO:STRING=${CMAKE_Fortran_FLAGS_RELWITHDEBINFO}
                       -DCMAKE_MAKE_PROGRAM:FILEPATH=${CMake_TEST_NESTED_MAKE_PROGRAM}
                       ${External_BUILD_TYPE}
  VERBATIM
  )
add_custom_target(ExternalTarget ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/ExternalProject)

# Test module output directory if available.
if(CMAKE_Fortran_MODDIR_FLAG)
  set(Library_MODDIR "${CMAKE_CURRENT_BINARY_DIR}/Library/modules")
else()
  set(Library_MODDIR "${CMAKE_CURRENT_BINARY_DIR}/Library")
endif()

add_subdirectory(Library)
add_subdirectory(Subdir)
add_subdirectory(Executable)

if(CMake_TEST_Fortran_SUBMODULES)
  add_subdirectory(Submodules)
endif()

add_subdirectory(Issue25112)
add_subdirectory(Issue25223)
if( # Intel Fortran VS Integration breaks on custom targets with Fortran sources
    NOT CMAKE_GENERATOR MATCHES "Visual Studio")
  add_subdirectory(Issue25252)
  add_subdirectory(Issue25252-iface-target)
endif()
add_subdirectory(Issue25252-iface-sources)

add_subdirectory(Issue25365-target-objects)
add_subdirectory(Issue25365-target-objects-iface)

# Issue#25425
add_subdirectory(ModulesViaTargetObjectsSource)
add_subdirectory(ModulesViaSubdirTargetObjectsSource)
add_subdirectory(ModulesViaTargetObjectsLink)
add_subdirectory(ModulesViaSubdirTargetObjectsLink)
