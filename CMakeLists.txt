cmake_minimum_required(VERSION 3.24)

# project variables
project(spdlog_setup
        VERSION 0.3.3
        HOMEPAGE_URL "https://github.com/paulbuechner/spdlog_setup"
        DESCRIPTION "Header-only spdlog file-based setup library for convenience in initializing spdlog. Inspired by spdlog-config for using TOML configuration, a format that is simple and easy-to-read."
        LANGUAGES CXX)

set(SPDLOG_MIN_VERSION "1.0.0")
set(CPPTOML_MIN_VERSION "0.1.0")

# Needed to set the namespace for both the export targets and the alias libraries
set(cmake_package_name spdlog_setup CACHE INTERNAL "")

# ---------------------------------------------------------------------------------------
# Compiler config
# ---------------------------------------------------------------------------------------
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 20)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

# make sure __cplusplus is defined when using msvc and enable parallel build
if(MSVC)
  string(APPEND CMAKE_CXX_FLAGS " /Zc:__cplusplus /MP")
endif()

# general compiler settings
if(MSVC)
  set(DEBUG_FLAGS /W4)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /bigobj")
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  # using regular Clang or AppleClang
  set(DEBUG_FLAGS -Wall)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -stdlib=libc++")
else()
  set(DEBUG_FLAGS -Wall)
endif()

add_compile_options("$<$<CONFIG:DEBUG>:${DEBUG_FLAGS}>")

#---------------------------------------------------------------------------------------
# Set SPDLOG_SETUP_MASTER_PROJECT to ON if we are building spdlog_setup
#---------------------------------------------------------------------------------------
# Check if spdlog_setup is being used directly or via add_subdirectory, but allow overriding
if(NOT DEFINED SPDLOG_SETUP_MASTER_PROJECT)
  if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(SPDLOG_SETUP_MASTER_PROJECT ON)
  else()
    set(SPDLOG_SETUP_MASTER_PROJECT OFF)
  endif()
endif()

include(GNUInstallDirs)

option(SPDLOG_SETUP_INSTALL "Generate the install target" ${SPDLOG_SETUP_MASTER_PROJECT})

option(SPDLOG_SETUP_INCLUDE_UNIT_TESTS "Build with unittests." OFF)

option(SPDLOG_SETUP_CPPTOML_EXTERNAL "Use external cpptoml library instead of bundled." OFF)

# allow thread library to be used for linking
set(THREADS_PREFER_PTHREAD_FLAG ON)
set(THREADS_PTHREAD_ARG "0" CACHE STRING "Result from TRY_RUN" FORCE)
find_package(Threads REQUIRED)

# add library
add_library(${PROJECT_NAME} INTERFACE)
add_library(${cmake_package_name}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

target_include_directories(${PROJECT_NAME} INTERFACE
                           "$<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>"
                           "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_INCLUDEDIR}>"
                           )

# Use local spdlog if it exists (development), otherwise use installed version
if(EXISTS ${CMAKE_SOURCE_DIR}/deps/spdlog/CMakeLists.txt)
  add_subdirectory(deps/spdlog)
else()
  find_package(spdlog ${SPDLOG_MIN_VERSION} CONFIG REQUIRED)
endif()

# ---------------------------------------------------------------------------------------
# Use cpptoml package if using external cpptoml
# ---------------------------------------------------------------------------------------
if(SPDLOG_SETUP_CPPTOML_EXTERNAL)
  if(NOT TARGET cpptoml)
    # Use local cpptoml if it exists (development), otherwise use installed version
    if(EXISTS ${CMAKE_SOURCE_DIR}/deps/cpptoml/CMakeLists.txt)
      add_subdirectory(deps/cpptoml)
    else()
      find_package(cpptoml ${CPPTOML_MIN_VERSION} CONFIG REQUIRED)
    endif()
  endif()
  target_compile_definitions(${PROJECT_NAME} INTERFACE SPDLOG_SETUP_CPPTOML_EXTERNAL)

  target_link_libraries(${PROJECT_NAME} INTERFACE cpptoml)

  set(PKG_CONFIG_REQUIRES cpptoml) # add dependency to pkg-config
endif()

# ---------------------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------------------
if(SPDLOG_SETUP_INSTALL)
  message(STATUS "Generating install")
  set(project_config_in "${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}-config.cmake.in")
  set(project_config_out "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake")
  set(config_targets_file "${PROJECT_NAME}-targets.cmake")
  set(version_config_file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake")
  set(export_dest_dir "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

  # ---------------------------------------------------------------------------------------
  # Include files
  # ---------------------------------------------------------------------------------------
  install(DIRECTORY include/ DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}" PATTERN "cpptoml" EXCLUDE)

  install(
    TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

  if(NOT SPDLOG_SETUP_CPPTOML_EXTERNAL)
    install(DIRECTORY include/${PROJECT_NAME}/cpptoml/
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}/cpptoml/")
  endif()

  # ---------------------------------------------------------------------------------------
  # Install CMake config files
  # ---------------------------------------------------------------------------------------
  export(TARGETS ${PROJECT_NAME} NAMESPACE ${PROJECT_NAME}:: FILE "${CMAKE_CURRENT_BINARY_DIR}/${config_targets_file}")
  install(EXPORT ${PROJECT_NAME} DESTINATION ${export_dest_dir} NAMESPACE ${PROJECT_NAME}:: FILE ${config_targets_file})

  include(CMakePackageConfigHelpers)
  configure_package_config_file("${project_config_in}" "${project_config_out}" INSTALL_DESTINATION ${export_dest_dir})

  write_basic_package_version_file("${version_config_file}" COMPATIBILITY SameMajorVersion)
  install(FILES "${project_config_out}" "${version_config_file}" DESTINATION "${export_dest_dir}")

  # ---------------------------------------------------------------------------------------
  # Support creation of installable packages
  # ---------------------------------------------------------------------------------------
  include(cmake/spdlog_setup-cpack.cmake)
endif()

# spdlog_setup_unit_test
if(SPDLOG_SETUP_INCLUDE_UNIT_TESTS)
  FILE(GLOB unit_test_cpps src/unit_test/*.cpp)

  add_executable(spdlog_setup_unit_test
                 ${unit_test_cpps})

  set_property(TARGET spdlog_setup_unit_test PROPERTY CXX_STANDARD 20)

  enable_testing()
  add_test(spdlog_setup_unit_test spdlog_setup_unit_test -s)

  # Use local Catch2 if it exists (development), otherwise use installed version
  if(EXISTS ${CMAKE_SOURCE_DIR}/deps/Catch2/CMakeLists.txt)
    add_subdirectory(deps/Catch2)
  else()
    # allow usage of installed dependency
    find_package(Catch2 CONFIG REQUIRED)
  endif()

  if(SPDLOG_SETUP_CPPTOML_EXTERNAL)
    target_compile_definitions(spdlog_setup_unit_test PRIVATE SPDLOG_SETUP_CPPTOML_EXTERNAL)
    target_link_libraries(spdlog_setup_unit_test PRIVATE
                          cpptoml)
  endif()

  target_link_libraries(spdlog_setup_unit_test PRIVATE
                        spdlog_setup
                        spdlog::spdlog_header_only
                        Catch2::Catch2WithMain
                        Threads::Threads)

  if(SPDLOG_SETUP_INCLUDE_TEST_COVERAGE)
    target_compile_options(spdlog_setup_unit_test PRIVATE
                           -coverage)

    target_link_libraries(spdlog_setup_unit_test PRIVATE
                          --coverage)
  endif()
endif()
