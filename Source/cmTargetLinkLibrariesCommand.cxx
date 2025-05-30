/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file LICENSE.rst or https://cmake.org/licensing for details.  */
#include "cmTargetLinkLibrariesCommand.h"

#include <cassert>
#include <cstddef>
#include <memory>
#include <sstream>
#include <unordered_set>
#include <utility>

#include <cm/optional>
#include <cm/string_view>

#include "cmExecutionStatus.h"
#include "cmGeneratorExpression.h"
#include "cmGlobalGenerator.h"
#include "cmListFileCache.h"
#include "cmMakefile.h"
#include "cmMessageType.h"
#include "cmPolicies.h"
#include "cmState.h"
#include "cmStateTypes.h"
#include "cmStringAlgorithms.h"
#include "cmSystemTools.h"
#include "cmTarget.h"
#include "cmTargetLinkLibraryType.h"

namespace {

enum ProcessingState
{
  ProcessingLinkLibraries,
  ProcessingPlainLinkInterface,
  ProcessingKeywordLinkInterface,
  ProcessingPlainPublicInterface,
  ProcessingKeywordPublicInterface,
  ProcessingPlainPrivateInterface,
  ProcessingKeywordPrivateInterface
};

char const* LinkLibraryTypeNames[3] = { "general", "debug", "optimized" };

struct TLL
{
  cmMakefile& Makefile;
  cmTarget* Target;
  bool WarnRemoteInterface = false;
  bool RejectRemoteLinking = false;
  bool EncodeRemoteReference = false;
  std::string DirectoryId;
  std::unordered_set<std::string> Props;

  TLL(cmMakefile& mf, cmTarget* target);
  ~TLL();

  bool HandleLibrary(ProcessingState currentProcessingState,
                     std::string const& lib, cmTargetLinkLibraryType llt);
  void AppendProperty(std::string const& prop, std::string const& value);
  void AffectsProperty(std::string const& prop);
};

} // namespace

static void LinkLibraryTypeSpecifierWarning(cmMakefile& mf, int left,
                                            int right);

bool cmTargetLinkLibrariesCommand(std::vector<std::string> const& args,
                                  cmExecutionStatus& status)
{
  // Must have at least one argument.
  if (args.empty()) {
    status.SetError("called with incorrect number of arguments");
    return false;
  }

  cmMakefile& mf = status.GetMakefile();

  // Alias targets cannot be on the LHS of this command.
  if (mf.IsAlias(args[0])) {
    status.SetError("can not be used on an ALIAS target.");
    return false;
  }

  // Lookup the target for which libraries are specified.
  cmTarget* target = mf.GetGlobalGenerator()->FindTarget(args[0]);
  if (!target) {
    for (auto const& importedTarget : mf.GetOwnedImportedTargets()) {
      if (importedTarget->GetName() == args[0] &&
          !importedTarget->IsForeign()) {
        target = importedTarget.get();
        break;
      }
    }
  }
  if (!target) {
    mf.IssueMessage(MessageType::FATAL_ERROR,
                    cmStrCat("Cannot specify link libraries for target \"",
                             args[0],
                             "\" which is not built by this project."));
    cmSystemTools::SetFatalErrorOccurred();
    return true;
  }

  // Having a UTILITY library on the LHS is a bug.
  if (target->GetType() == cmStateEnums::UTILITY) {
    mf.IssueMessage(
      MessageType::FATAL_ERROR,
      cmStrCat(
        "Utility target \"", target->GetName(),
        "\" must not be used as the target of a target_link_libraries call."));
    return false;
  }

  // But we might not have any libs after variable expansion.
  if (args.size() < 2) {
    return true;
  }

  TLL tll(mf, target);

  // Keep track of link configuration specifiers.
  cmTargetLinkLibraryType llt = GENERAL_LibraryType;
  bool haveLLT = false;

  // Start with primary linking and switch to link interface
  // specification if the keyword is encountered as the first argument.
  ProcessingState currentProcessingState = ProcessingLinkLibraries;

  // Accumulate consecutive non-keyword arguments into one entry in
  // order to handle unquoted generator expressions containing ';'.
  std::size_t genexNesting = 0;
  cm::optional<std::string> currentEntry;
  auto processCurrentEntry = [&]() -> bool {
    // FIXME: Warn about partial genex if genexNesting > 0?
    genexNesting = 0;
    if (currentEntry) {
      assert(!haveLLT);
      if (!tll.HandleLibrary(currentProcessingState, *currentEntry,
                             GENERAL_LibraryType)) {
        return false;
      }
      currentEntry = cm::nullopt;
    }
    return true;
  };
  auto extendCurrentEntry = [&currentEntry](std::string const& arg) {
    if (currentEntry) {
      currentEntry = cmStrCat(*currentEntry, ';', arg);
    } else {
      currentEntry = arg;
    }
  };

  // Keep this list in sync with the keyword dispatch below.
  static std::unordered_set<std::string> const keywords{
    "LINK_INTERFACE_LIBRARIES",
    "INTERFACE",
    "LINK_PUBLIC",
    "PUBLIC",
    "LINK_PRIVATE",
    "PRIVATE",
    "debug",
    "optimized",
    "general",
  };

  // Add libraries, note that there is an optional prefix
  // of debug and optimized that can be used.
  for (unsigned int i = 1; i < args.size(); ++i) {
    if (keywords.count(args[i])) {
      // A keyword argument terminates any accumulated partial genex.
      if (!processCurrentEntry()) {
        return false;
      }

      // Process this keyword argument.
      if (args[i] == "LINK_INTERFACE_LIBRARIES") {
        currentProcessingState = ProcessingPlainLinkInterface;
        if (i != 1) {
          mf.IssueMessage(
            MessageType::FATAL_ERROR,
            "The LINK_INTERFACE_LIBRARIES option must appear as the "
            "second argument, just after the target name.");
          return true;
        }
      } else if (args[i] == "INTERFACE") {
        if (i != 1 &&
            currentProcessingState != ProcessingKeywordPrivateInterface &&
            currentProcessingState != ProcessingKeywordPublicInterface &&
            currentProcessingState != ProcessingKeywordLinkInterface) {
          mf.IssueMessage(MessageType::FATAL_ERROR,
                          "The INTERFACE, PUBLIC or PRIVATE option must "
                          "appear as the second argument, just after the "
                          "target name.");
          return true;
        }
        currentProcessingState = ProcessingKeywordLinkInterface;
      } else if (args[i] == "LINK_PUBLIC") {
        if (i != 1 &&
            currentProcessingState != ProcessingPlainPrivateInterface &&
            currentProcessingState != ProcessingPlainPublicInterface) {
          mf.IssueMessage(
            MessageType::FATAL_ERROR,
            "The LINK_PUBLIC or LINK_PRIVATE option must appear as the "
            "second argument, just after the target name.");
          return true;
        }
        currentProcessingState = ProcessingPlainPublicInterface;
      } else if (args[i] == "PUBLIC") {
        if (i != 1 &&
            currentProcessingState != ProcessingKeywordPrivateInterface &&
            currentProcessingState != ProcessingKeywordPublicInterface &&
            currentProcessingState != ProcessingKeywordLinkInterface) {
          mf.IssueMessage(MessageType::FATAL_ERROR,
                          "The INTERFACE, PUBLIC or PRIVATE option must "
                          "appear as the second argument, just after the "
                          "target name.");
          return true;
        }
        currentProcessingState = ProcessingKeywordPublicInterface;
      } else if (args[i] == "LINK_PRIVATE") {
        if (i != 1 &&
            currentProcessingState != ProcessingPlainPublicInterface &&
            currentProcessingState != ProcessingPlainPrivateInterface) {
          mf.IssueMessage(
            MessageType::FATAL_ERROR,
            "The LINK_PUBLIC or LINK_PRIVATE option must appear as the "
            "second argument, just after the target name.");
          return true;
        }
        currentProcessingState = ProcessingPlainPrivateInterface;
      } else if (args[i] == "PRIVATE") {
        if (i != 1 &&
            currentProcessingState != ProcessingKeywordPrivateInterface &&
            currentProcessingState != ProcessingKeywordPublicInterface &&
            currentProcessingState != ProcessingKeywordLinkInterface) {
          mf.IssueMessage(MessageType::FATAL_ERROR,
                          "The INTERFACE, PUBLIC or PRIVATE option must "
                          "appear as the second argument, just after the "
                          "target name.");
          return true;
        }
        currentProcessingState = ProcessingKeywordPrivateInterface;
      } else if (args[i] == "debug") {
        if (haveLLT) {
          LinkLibraryTypeSpecifierWarning(mf, llt, DEBUG_LibraryType);
        }
        llt = DEBUG_LibraryType;
        haveLLT = true;
      } else if (args[i] == "optimized") {
        if (haveLLT) {
          LinkLibraryTypeSpecifierWarning(mf, llt, OPTIMIZED_LibraryType);
        }
        llt = OPTIMIZED_LibraryType;
        haveLLT = true;
      } else if (args[i] == "general") {
        if (haveLLT) {
          LinkLibraryTypeSpecifierWarning(mf, llt, GENERAL_LibraryType);
        }
        llt = GENERAL_LibraryType;
        haveLLT = true;
      }
    } else if (haveLLT) {
      // The link type was specified by the previous argument.
      haveLLT = false;
      assert(!currentEntry);
      if (!tll.HandleLibrary(currentProcessingState, args[i], llt)) {
        return false;
      }
      llt = GENERAL_LibraryType;
    } else {
      // Track the genex nesting level.
      {
        cm::string_view arg = args[i];
        for (std::string::size_type pos = 0; pos < arg.size(); ++pos) {
          cm::string_view cur = arg.substr(pos);
          if (cmHasLiteralPrefix(cur, "$<")) {
            ++genexNesting;
            ++pos;
          } else if (genexNesting > 0 && cmHasLiteralPrefix(cur, ">")) {
            --genexNesting;
          }
        }
      }

      // Accumulate this argument in the current entry.
      extendCurrentEntry(args[i]);

      // Process this entry if it does not end inside a genex.
      if (genexNesting == 0) {
        if (!processCurrentEntry()) {
          return false;
        }
      }
    }
  }

  // Process the last accumulated partial genex, if any.
  if (!processCurrentEntry()) {
    return false;
  }

  // Make sure the last argument was not a library type specifier.
  if (haveLLT) {
    mf.IssueMessage(MessageType::FATAL_ERROR,
                    cmStrCat("The \"", LinkLibraryTypeNames[llt],
                             "\" argument must be followed by a library."));
    cmSystemTools::SetFatalErrorOccurred();
  }

  return true;
}

static void LinkLibraryTypeSpecifierWarning(cmMakefile& mf, int left,
                                            int right)
{
  mf.IssueMessage(
    MessageType::AUTHOR_WARNING,
    cmStrCat(
      "Link library type specifier \"", LinkLibraryTypeNames[left],
      "\" is followed by specifier \"", LinkLibraryTypeNames[right],
      "\" instead of a library name.  The first specifier will be ignored."));
}

namespace {

TLL::TLL(cmMakefile& mf, cmTarget* target)
  : Makefile(mf)
  , Target(target)
{
  if (&this->Makefile != this->Target->GetMakefile()) {
    // The LHS target was created in another directory.
    switch (this->Makefile.GetPolicyStatus(cmPolicies::CMP0079)) {
      case cmPolicies::WARN:
        this->WarnRemoteInterface = true;
        CM_FALLTHROUGH;
      case cmPolicies::OLD:
        this->RejectRemoteLinking = true;
        break;
      case cmPolicies::NEW:
        this->EncodeRemoteReference = true;
        break;
    }
  }
  if (this->EncodeRemoteReference) {
    cmDirectoryId const dirId = this->Makefile.GetDirectoryId();
    this->DirectoryId = cmStrCat(CMAKE_DIRECTORY_ID_SEP, dirId.String);
  }
}

bool TLL::HandleLibrary(ProcessingState currentProcessingState,
                        std::string const& lib, cmTargetLinkLibraryType llt)
{
  if (this->Target->GetType() == cmStateEnums::INTERFACE_LIBRARY &&
      currentProcessingState != ProcessingKeywordLinkInterface) {
    this->Makefile.IssueMessage(
      MessageType::FATAL_ERROR,
      "INTERFACE library can only be used with the INTERFACE keyword of "
      "target_link_libraries");
    return false;
  }
  if (this->Target->IsImported() &&
      currentProcessingState != ProcessingKeywordLinkInterface) {
    this->Makefile.IssueMessage(
      MessageType::FATAL_ERROR,
      "IMPORTED library can only be used with the INTERFACE keyword of "
      "target_link_libraries");
    return false;
  }

  cmTarget::TLLSignature sig =
    (currentProcessingState == ProcessingPlainPrivateInterface ||
     currentProcessingState == ProcessingPlainPublicInterface ||
     currentProcessingState == ProcessingKeywordPrivateInterface ||
     currentProcessingState == ProcessingKeywordPublicInterface ||
     currentProcessingState == ProcessingKeywordLinkInterface)
    ? cmTarget::KeywordTLLSignature
    : cmTarget::PlainTLLSignature;
  if (!this->Target->PushTLLCommandTrace(
        sig, this->Makefile.GetBacktrace().Top())) {
    std::ostringstream e;
    // If the sig is a keyword form and there is a conflict, the existing
    // form must be the plain form.
    char const* existingSig =
      (sig == cmTarget::KeywordTLLSignature ? "plain" : "keyword");
    e << "The " << existingSig
      << " signature for target_link_libraries has "
         "already been used with the target \""
      << this->Target->GetName()
      << "\".  All uses of target_link_libraries with a target must "
      << " be either all-keyword or all-plain.\n";
    this->Target->GetTllSignatureTraces(e,
                                        sig == cmTarget::KeywordTLLSignature
                                          ? cmTarget::PlainTLLSignature
                                          : cmTarget::KeywordTLLSignature);
    this->Makefile.IssueMessage(MessageType::FATAL_ERROR, e.str());
    return false;
  }

  // Handle normal case where the command was called with another keyword than
  // INTERFACE / LINK_INTERFACE_LIBRARIES or none at all. (The "LINK_LIBRARIES"
  // property of the target on the LHS shall be populated.)
  if (currentProcessingState != ProcessingKeywordLinkInterface &&
      currentProcessingState != ProcessingPlainLinkInterface) {

    if (this->RejectRemoteLinking) {
      this->Makefile.IssueMessage(
        MessageType::FATAL_ERROR,
        cmStrCat("Attempt to add link library \"", lib, "\" to target \"",
                 this->Target->GetName(),
                 "\" which is not built in this "
                 "directory.\nThis is allowed only when policy CMP0079 "
                 "is set to NEW."));
      return false;
    }

    cmTarget* tgt = this->Makefile.GetGlobalGenerator()->FindTarget(lib);

    if (tgt && (tgt->GetType() != cmStateEnums::STATIC_LIBRARY) &&
        (tgt->GetType() != cmStateEnums::SHARED_LIBRARY) &&
        (tgt->GetType() != cmStateEnums::UNKNOWN_LIBRARY) &&
        (tgt->GetType() != cmStateEnums::OBJECT_LIBRARY) &&
        (tgt->GetType() != cmStateEnums::INTERFACE_LIBRARY) &&
        !tgt->IsExecutableWithExports()) {
      this->Makefile.IssueMessage(
        MessageType::FATAL_ERROR,
        cmStrCat(
          "Target \"", lib, "\" of type ",
          cmState::GetTargetTypeName(tgt->GetType()),
          " may not be linked into another target. One may link only to "
          "INTERFACE, OBJECT, STATIC or SHARED libraries, or to "
          "executables with the ENABLE_EXPORTS property set."));
    }

    this->AffectsProperty("LINK_LIBRARIES");
    this->Target->AddLinkLibrary(this->Makefile, lib, llt);
  }

  if (this->WarnRemoteInterface) {
    this->Makefile.IssueMessage(
      MessageType::AUTHOR_WARNING,
      cmStrCat(
        cmPolicies::GetPolicyWarning(cmPolicies::CMP0079), "\nTarget\n  ",
        this->Target->GetName(),
        "\nis not created in this "
        "directory.  For compatibility with older versions of CMake, link "
        "library\n  ",
        lib,
        "\nwill be looked up in the directory in which "
        "the target was created rather than in this calling directory."));
  }

  // Handle (additional) case where the command was called with PRIVATE /
  // LINK_PRIVATE and stop its processing. (The "INTERFACE_LINK_LIBRARIES"
  // property of the target on the LHS shall only be populated if it is a
  // STATIC library.)
  if (currentProcessingState == ProcessingKeywordPrivateInterface ||
      currentProcessingState == ProcessingPlainPrivateInterface) {
    if (this->Target->GetType() == cmStateEnums::STATIC_LIBRARY ||
        this->Target->GetType() == cmStateEnums::OBJECT_LIBRARY) {
      // TODO: Detect and no-op `$<COMPILE_ONLY>` genexes here.
      std::string configLib =
        this->Target->GetDebugGeneratorExpressions(lib, llt);
      if (cmGeneratorExpression::IsValidTargetName(lib) ||
          cmGeneratorExpression::Find(lib) != std::string::npos) {
        configLib = "$<LINK_ONLY:" + configLib + ">";
      }
      this->AppendProperty("INTERFACE_LINK_LIBRARIES", configLib);
    }
    return true;
  }

  // Handle general case where the command was called with another keyword than
  // PRIVATE / LINK_PRIVATE or none at all. (The "INTERFACE_LINK_LIBRARIES"
  // property of the target on the LHS shall be populated.)
  this->AppendProperty("INTERFACE_LINK_LIBRARIES",
                       this->Target->GetDebugGeneratorExpressions(lib, llt));
  return true;
}

void TLL::AppendProperty(std::string const& prop, std::string const& value)
{
  this->AffectsProperty(prop);
  this->Target->AppendProperty(prop, value, this->Makefile.GetBacktrace());
}

void TLL::AffectsProperty(std::string const& prop)
{
  if (!this->EncodeRemoteReference) {
    return;
  }
  // Add a wrapper to the expression to tell LookupLinkItem to look up
  // names in the caller's directory.
  if (this->Props.insert(prop).second) {
    this->Target->AppendProperty(prop, this->DirectoryId,
                                 this->Makefile.GetBacktrace());
  }
}

TLL::~TLL()
{
  for (std::string const& prop : this->Props) {
    this->Target->AppendProperty(prop, CMAKE_DIRECTORY_ID_SEP,
                                 this->Makefile.GetBacktrace());
  }
}

} // namespace
