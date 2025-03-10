/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file LICENSE.rst or https://cmake.org/licensing for details.  */
#pragma once

#include "cmConfigure.h" // IWYU pragma: keep

#include <array>
#include <cstddef> // IWYU pragma: keep
#include <cstdint>
#include <cstdio>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include <cm3p/uv.h>

class cmUVProcessChain;

class cmUVProcessChainBuilder
{
public:
  enum Stream
  {
    Stream_INPUT = 0,
    Stream_OUTPUT = 1,
    Stream_ERROR = 2,
  };

  cmUVProcessChainBuilder();

  cmUVProcessChainBuilder& AddCommand(std::vector<std::string> arguments);
  cmUVProcessChainBuilder& SetBuiltinLoop();
  cmUVProcessChainBuilder& SetExternalLoop(uv_loop_t& loop);
  cmUVProcessChainBuilder& SetNoStream(Stream stdio);
  cmUVProcessChainBuilder& SetBuiltinStream(Stream stdio);
  cmUVProcessChainBuilder& SetMergedBuiltinStreams();
  cmUVProcessChainBuilder& SetExternalStream(Stream stdio, int fd);
  cmUVProcessChainBuilder& SetExternalStream(Stream stdio, FILE* stream);
  cmUVProcessChainBuilder& SetWorkingDirectory(std::string dir);
  cmUVProcessChainBuilder& SetDetached();

  uv_loop_t* GetLoop() const;

  cmUVProcessChain Start() const;

private:
  enum StdioType
  {
    None,
    Builtin,
    External,
  };

  friend class cmUVProcessChain;

  struct StdioConfiguration
  {
    StdioType Type = None;
    int FileDescriptor = -1;
  };

  struct ProcessConfiguration
  {
    std::vector<std::string> Arguments;
  };

  std::array<StdioConfiguration, 3> Stdio;
  std::vector<ProcessConfiguration> Processes;
  std::string WorkingDirectory;
  bool MergedBuiltinStreams = false;
  bool Detached = false;
  uv_loop_t* Loop = nullptr;
};

class cmUVProcessChain
{
public:
  enum class ExceptionCode
  {
    None,
    Fault,
    Illegal,
    Interrupt,
    Numerical,
    Spawn,
    Other,
  };

  struct Status
  {
    int SpawnResult;
    bool Finished;
    int64_t ExitStatus;
    int TermSignal;

    std::pair<ExceptionCode, std::string> GetException() const;
  };

  cmUVProcessChain(cmUVProcessChain const& other) = delete;
  cmUVProcessChain(cmUVProcessChain&& other) noexcept;

  ~cmUVProcessChain();

  cmUVProcessChain& operator=(cmUVProcessChain const& other) = delete;
  cmUVProcessChain& operator=(cmUVProcessChain&& other) noexcept;

  uv_loop_t& GetLoop();

  // FIXME: Add stdin support
  int OutputStream();
  int ErrorStream();

  bool Valid() const;
  bool Wait(uint64_t milliseconds = 0);
  std::vector<Status const*> GetStatus() const;
  Status const& GetStatus(std::size_t index) const;
  bool Finished() const;

private:
  friend class cmUVProcessChainBuilder;

  cmUVProcessChain();

  struct InternalData;
  std::unique_ptr<InternalData> Data;
};
