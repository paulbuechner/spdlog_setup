vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO paulbuechner/spdlog_setup
  REF c4658e3d1618bd32237e28ad7de32b66aba1b7ea
  SHA512 b80ce4021d30e00391cf4636058c50ba9e33947307c11e8e53f39de1c0249945a4bc239075660b920bcb5f4bc59635e9f11a83a7bf608bdf4500e272a9110e2a
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
