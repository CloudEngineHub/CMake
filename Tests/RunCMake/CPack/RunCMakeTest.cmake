cmake_minimum_required(VERSION 3.10)

include(RunCMake)
include("${RunCMake_SOURCE_DIR}/CPackTestHelpers.cmake")

# A debugedit binary is required for these tests, so skip them if it's not found
find_program(DEBUGEDIT debugedit)
find_program(BRPALT brp-alt PATHS /usr/lib/rpm/)

# run_cpack_test args: TEST_NAME "GENERATORS" RUN_CMAKE_BUILD_STEP "PACKAGING_TYPES"
run_cpack_test(CUSTOM_BINARY_SPEC_FILE "RPM.CUSTOM_BINARY_SPEC_FILE" false "MONOLITHIC;COMPONENT")
run_cpack_test(CUSTOM_NAMES "RPM.CUSTOM_NAMES;DEB.CUSTOM_NAMES;TGZ;DragNDrop" true "COMPONENT")
run_cpack_test(AUTO_SUFFIXES "RPM.AUTO_SUFFIXES;DEB.AUTO_SUFFIXES" false "MONOLITHIC")
run_cpack_test(DEBUGINFO "DEB.DEBUGINFO" true "COMPONENT")
if(DEBUGEDIT AND NOT BRPALT)
  run_cpack_test(DEBUGINFO "RPM.DEBUGINFO" true "COMPONENT")
endif()
run_cpack_test(DEBUGINFO "DEB.DEBUGINFO" true "MONOLITHIC")
run_cpack_test_subtests(DEFAULT_PERMISSIONS "CMAKE_var_set;CPACK_var_set;both_set;invalid_CMAKE_var;invalid_CPACK_var" "RPM.DEFAULT_PERMISSIONS;DEB.DEFAULT_PERMISSIONS" false "MONOLITHIC;COMPONENT")
run_cpack_test(DEPENDENCIES "DEB.DEPENDENCIES" true "COMPONENT")
if(DEBUGEDIT AND NOT BRPALT)
  run_cpack_test(DEPENDENCIES "RPM.DEPENDENCIES" true "COMPONENT")
endif()
run_cpack_test(DIST "RPM.DIST" false "MONOLITHIC")
run_cpack_test(DMG_SLA "DragNDrop" false "MONOLITHIC")
run_cpack_test(DMG_SLA_FILE "DragNDrop" false "MONOLITHIC")
run_cpack_test(DMG_SLA_OFF "DragNDrop" false "MONOLITHIC")
run_cpack_test(EMPTY_DIR "RPM.EMPTY_DIR;DEB.EMPTY_DIR;TGZ" true "MONOLITHIC;COMPONENT")
run_cpack_test(VERSION "RPM.VERSION;DEB.VERSION" false "MONOLITHIC;COMPONENT")
run_cpack_test(EXTRA "DEB.EXTRA" false "COMPONENT")
run_cpack_test_subtests(GENERATE_SHLIBS "soversion_not_zero;soversion_zero" "DEB.GENERATE_SHLIBS" true "COMPONENT")
run_cpack_test(GENERATE_SHLIBS_LDCONFIG "DEB.GENERATE_SHLIBS_LDCONFIG" true "COMPONENT")
run_cpack_test_subtests(INSTALL_SCRIPTS "default;no_scripts" "RPM.INSTALL_SCRIPTS" false "COMPONENT")
if(DEBUGEDIT AND NOT BRPALT)
  run_cpack_test_subtests(INSTALL_SCRIPTS "single_debug_info;no_scripts_single_debug_info" "RPM.INSTALL_SCRIPTS" false "COMPONENT")
endif()
run_cpack_test(LONG_FILENAMES "DEB.LONG_FILENAMES" false "MONOLITHIC")
run_cpack_test_subtests(MAIN_COMPONENT "invalid;found" "RPM.MAIN_COMPONENT" false "COMPONENT")
run_cpack_test(MINIMAL "RPM.MINIMAL;DEB.MINIMAL;7Z;TBZ2;TGZ;TXZ;TZ;ZIP;STGZ;TAR;External" false "MONOLITHIC;COMPONENT")
run_cpack_test_package_target(MINIMAL "RPM.MINIMAL;DEB.MINIMAL;7Z;TBZ2;TGZ;TXZ;TZ;ZIP;STGZ;TAR;External" false "MONOLITHIC;COMPONENT")
run_cpack_test_package_target(THREADED_ALL "TXZ;DEB" false "MONOLITHIC;COMPONENT")
run_cpack_test_package_target(THREADED "TXZ;DEB" false "MONOLITHIC;COMPONENT")
run_cpack_test_subtests(PACKAGE_CHECKSUM "invalid;MD5;SHA1;SHA224;SHA256;SHA384;SHA512" "TGZ" false "MONOLITHIC")
run_cpack_test(PARTIALLY_RELOCATABLE_WARNING "RPM.PARTIALLY_RELOCATABLE_WARNING" false "COMPONENT")
run_cpack_test(PER_COMPONENT_FIELDS "RPM.PER_COMPONENT_FIELDS;DEB.PER_COMPONENT_FIELDS" false "COMPONENT")
run_cpack_test_subtests(SINGLE_DEBUGINFO "no_main_component" "RPM.SINGLE_DEBUGINFO" true "CUSTOM")
if(DEBUGEDIT AND NOT BRPALT)
  run_cpack_test_subtests(SINGLE_DEBUGINFO "one_component;one_component_main;no_debuginfo;one_component_no_debuginfo;no_components;valid" "RPM.SINGLE_DEBUGINFO" true "CUSTOM")
endif()
if(DEBUGEDIT AND NOT BRPALT)
  run_cpack_test(EXTRA_SLASH_IN_PATH "RPM.EXTRA_SLASH_IN_PATH" true "COMPONENT")
endif()
if(NOT BRPALT)
  run_cpack_source_test(SOURCE_PACKAGE "RPM.SOURCE_PACKAGE")
endif()
run_cpack_test(SUGGESTS "RPM.SUGGESTS" false "MONOLITHIC")
run_cpack_test(ENHANCES "RPM.ENHANCES" false "MONOLITHIC")
run_cpack_test(RECOMMENDS "RPM.RECOMMENDS" false "MONOLITHIC")
run_cpack_test(SUPPLEMENTS "RPM.SUPPLEMENTS" false "MONOLITHIC")
run_cpack_test(SYMLINKS "RPM.SYMLINKS;TGZ" false "MONOLITHIC;COMPONENT")
set(ENVIRONMENT "SOURCE_DATE_EPOCH=123456789")
run_cpack_test(TIMESTAMPS "DEB.TIMESTAMPS;TGZ" false "COMPONENT")
unset(ENVIRONMENT)
run_cpack_test(USER_FILELIST "RPM.USER_FILELIST" false "MONOLITHIC")
run_cpack_test(MD5SUMS "DEB.MD5SUMS" false "MONOLITHIC;COMPONENT")
run_cpack_test_subtests(CPACK_INSTALL_SCRIPTS "singular;plural;both" "ZIP" false "MONOLITHIC")
run_cpack_test(CPACK_CUSTOM_INSTALL_VARIABLES "ZIP" false "MONOLITHIC")
run_cpack_test(DEB_PACKAGE_VERSION_BACK_COMPATIBILITY "DEB.DEB_PACKAGE_VERSION_BACK_COMPATIBILITY" false "MONOLITHIC;COMPONENT")
run_cpack_test_subtests(EXTERNAL "none;good;good_multi;bad_major;bad_minor;invalid_good;invalid_bad;stage_and_package" "External" false "MONOLITHIC;COMPONENT")
run_cpack_test_subtests(
  DEB_DESCRIPTION
  "CPACK_DEBIAN_PACKAGE_DESCRIPTION;CPACK_PACKAGE_DESCRIPTION;CPACK_COMPONENT_COMP_DESCRIPTION;CPACK_PACKAGE_DESCRIPTION_FILE;CPACK_NO_PACKAGE_DESCRIPTION"
  "DEB.DEB_DESCRIPTION"
  false
  "MONOLITHIC;COMPONENT"
)
if(NOT BRPALT)
  run_cpack_test(PROJECT_META "RPM.PROJECT_META;DEB.PROJECT_META" false "MONOLITHIC;COMPONENT")
else()
  run_cpack_test(PROJECT_META "DEB.PROJECT_META" false "MONOLITHIC;COMPONENT")
endif()
run_cpack_test_package_target(PRE_POST_SCRIPTS "ZIP" false "MONOLITHIC;COMPONENT")
run_cpack_test_subtests(DUPLICATE_FILE "success;conflict_file;conflict_symlink" "TGZ" false "COMPONENT;GROUP")
run_cpack_test(COMPONENT_WITH_SPECIAL_CHARS "RPM.COMPONENT_WITH_SPECIAL_CHARS;DEB.COMPONENT_WITH_SPECIAL_CHARS;7Z;TBZ2;TGZ;TXZ;TZ;ZIP;STGZ;TAR" false "MONOLITHIC;COMPONENT;GROUP")
run_cpack_test_package_target(COMPONENT_WITH_SPECIAL_CHARS "RPM.COMPONENT_WITH_SPECIAL_CHARS;DEB.COMPONENT_WITH_SPECIAL_CHARS;7Z;TBZ2;TGZ;TXZ;TZ;ZIP;STGZ;TAR" false "MONOLITHIC;COMPONENT;GROUP")
run_cpack_test_subtests(MULTIARCH "same;foreign;allowed;fail" "DEB.MULTIARCH" false "MONOLITHIC;COMPONENT")
