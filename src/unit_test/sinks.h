/**
 * Unit tests implementation.
 * @author Chen Weiguang
 * @version 0.3.3-pre
 */

#pragma once

#include "conf.h"

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>

inline auto generate_stdout_sink_st() -> std::shared_ptr<cpptoml::table> {
    namespace names = spdlog_setup::details::names;

    auto sink_table = cpptoml::make_table();
    sink_table->insert(names::TYPE, std::string("stdout_sink_st"));
    return sink_table;
}

inline auto generate_stderr_sink_st() -> std::shared_ptr<cpptoml::table> {
    namespace names = spdlog_setup::details::names;

    auto sink_table = cpptoml::make_table();
    sink_table->insert(names::TYPE, std::string("stderr_sink_st"));
    return sink_table;
}

inline auto generate_stdout_sink_mt() -> std::shared_ptr<cpptoml::table> {
    namespace names = spdlog_setup::details::names;

    auto sink_table = cpptoml::make_table();
    sink_table->insert(names::TYPE, std::string("stdout_sink_mt"));
    return sink_table;
}

inline auto generate_stderr_sink_mt() -> std::shared_ptr<cpptoml::table> {
    namespace names = spdlog_setup::details::names;

    auto sink_table = cpptoml::make_table();
    sink_table->insert(names::TYPE, std::string("stderr_sink_mt"));
    return sink_table;
}
