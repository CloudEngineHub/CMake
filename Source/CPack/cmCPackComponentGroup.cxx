/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file LICENSE.rst or https://cmake.org/licensing for details.  */
#include "cmCPackComponentGroup.h"

#include <string>

#include "cmStringAlgorithms.h"
#include "cmSystemTools.h"

unsigned long cmCPackComponent::GetInstalledSize(
  std::string const& installDir) const
{
  if (this->TotalSize != 0) {
    return this->TotalSize;
  }

  for (std::string const& file : this->Files) {
    std::string path = cmStrCat(installDir, '/', file);
    this->TotalSize += cmSystemTools::FileLength(path);
  }

  return this->TotalSize;
}

unsigned long cmCPackComponent::GetInstalledSizeInKbytes(
  std::string const& installDir) const
{
  unsigned long result = (this->GetInstalledSize(installDir) + 512) / 1024;
  return result ? result : 1;
}
