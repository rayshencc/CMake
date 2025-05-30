/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file Copyright.txt or https://cmake.org/licensing#kwsys for details.  */
#include "kwsysPrivate.h"
#include KWSYS_HEADER(Status.hxx)
#include KWSYS_HEADER(Encoding.hxx)

// Work-around CMake dependency scanning limitation.  This must
// duplicate the above list of headers.
#if 0
#  include "Encoding.hxx.in"
#  include "Status.hxx.in"
#endif

#include <cerrno>
#include <cstring>
#include <string>

#if defined(_WIN32)
#  include <windows.h>
#endif

namespace KWSYS_NAMESPACE {

Status Status::POSIX_errno()
{
  return Status::POSIX(errno);
}

#ifdef _WIN32
Status Status::Windows_GetLastError()
{
  return Status::Windows(GetLastError());
}
#endif

std::string Status::GetString() const
{
  std::string err;
  switch (this->Kind_) {
    case Kind::Success:
      err = "Success";
      break;
    case Kind::POSIX:
      err = strerror(this->POSIX_);
      break;
#ifdef _WIN32
    case Kind::Windows: {
      LPWSTR message = NULL;
      DWORD size = FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
          FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL, this->Windows_, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPWSTR)&message, 0, NULL);
      err = kwsys::Encoding::ToNarrow(message);
      LocalFree(message);
    } break;
#endif
    default:
      break;
  }
  return err;
}

} // namespace KWSYS_NAMESPACE
