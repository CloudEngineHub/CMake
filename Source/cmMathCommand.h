/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file LICENSE.rst or https://cmake.org/licensing for details.  */
#pragma once

#include "cmConfigure.h" // IWYU pragma: keep

#include <string>
#include <vector>

class cmExecutionStatus;

/// Mathematical expressions: math(EXPR ...) command.
bool cmMathCommand(std::vector<std::string> const& args,
                   cmExecutionStatus& status);
