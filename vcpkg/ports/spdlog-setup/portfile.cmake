vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO paulbuechner/spdlog_setup
  REF 20fdf00a3d06f09580e98f8b8c2a929d9e2319a0
  SHA512 c2f7b62fb11ba4f2c5c9c79459817fd7e4769380656e066c4ef1b2ded8ad13cc6fe9abcdb2b2cea83ffecd291f5e6da7fdb19f980cd592fb67eea791d32b1b23
  HEAD_REF master
  )

set(VCPKG_BUILD_TYPE release) # header-only port

vcpkg_cmake_configure(
  SOURCE_PATH ${SOURCE_PATH}
  OPTIONS
  -DSPDLOG_SETUP_INSTALL=ON
  -DSPDLOG_SETUP_CPPTOML_EXTERNAL=OFF
  -DSPDLOG_SETUP_INCLUDE_UNIT_TESTS=OFF
  )

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/spdlog_setup PACKAGE_NAME spdlog_setup)

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/lib)

# Handle copyright
configure_file("${SOURCE_PATH}/LICENSE" "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright" COPYONLY)
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
