# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
FindCUDAToolkit
---------------

.. versionadded:: 3.17

This script locates the NVIDIA CUDA toolkit and the associated libraries, but
does not require the ``CUDA`` language be enabled for a given project. This
module does not search for the NVIDIA CUDA Samples.

.. versionadded:: 3.19
  QNX support.

Search Behavior
^^^^^^^^^^^^^^^

The CUDA Toolkit search behavior uses the following order:

1. If the ``CUDA`` language has been enabled we will use the directory
   containing the compiler as the first search location for ``nvcc``.

2. If the ``CUDAToolkit_ROOT`` cmake configuration variable (e.g.,
   ``-DCUDAToolkit_ROOT=/some/path``) *or* environment variable is defined, it
   will be searched.  If both an environment variable **and** a
   configuration variable are specified, the *configuration* variable takes
   precedence.

   The directory specified here must be such that the executable ``nvcc`` or
   the appropriate ``version.txt`` or ``version.json`` file can be found
   underneath the specified directory.

3. If the CUDA_PATH environment variable is defined, it will be searched
   for ``nvcc``.

4. The user's path is searched for ``nvcc`` using :command:`find_program`.  If
   this is found, no subsequent search attempts are performed.  Users are
   responsible for ensuring that the first ``nvcc`` to show up in the path is
   the desired path in the event that multiple CUDA Toolkits are installed.

5. On Unix systems, if the symbolic link ``/usr/local/cuda`` exists, this is
   used.  No subsequent search attempts are performed.  No default symbolic link
   location exists for the Windows platform.

6. The platform specific default install locations are searched.  If exactly one
   candidate is found, this is used.  The default CUDA Toolkit install locations
   searched are:

   +-------------+-------------------------------------------------------------+
   | Platform    | Search Pattern                                              |
   +=============+=============================================================+
   | macOS       | ``/Developer/NVIDIA/CUDA-X.Y``                              |
   +-------------+-------------------------------------------------------------+
   | Other Unix  | ``/usr/local/cuda-X.Y``                                     |
   +-------------+-------------------------------------------------------------+
   | Windows     | ``C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\vX.Y`` |
   +-------------+-------------------------------------------------------------+

   Where ``X.Y`` would be a specific version of the CUDA Toolkit, such as
   ``/usr/local/cuda-9.0`` or
   ``C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v9.0``

   .. note::

       When multiple CUDA Toolkits are installed in the default location of a
       system (e.g., both ``/usr/local/cuda-9.0`` and ``/usr/local/cuda-10.0``
       exist but the ``/usr/local/cuda`` symbolic link does **not** exist), this
       package is marked as **not** found.

       There are too many factors involved in making an automatic decision in
       the presence of multiple CUDA Toolkits being installed.  In this
       situation, users are encouraged to either (1) set ``CUDAToolkit_ROOT`` or
       (2) ensure that the correct ``nvcc`` executable shows up in ``$PATH`` for
       :command:`find_program` to find.

Arguments
^^^^^^^^^

``[<version>]``
    The ``[<version>]`` argument requests a version with which the package found
    should be compatible. See :ref:`find_package version format <FIND_PACKAGE_VERSION_FORMAT>`
    for more details.

Options
^^^^^^^

``REQUIRED``
    If specified, configuration will error if a suitable CUDA Toolkit is not
    found.

``QUIET``
    If specified, the search for a suitable CUDA Toolkit will not produce any
    messages.

``EXACT``
    If specified, the CUDA Toolkit is considered found only if the exact
    ``VERSION`` specified is recovered.

Imported targets
^^^^^^^^^^^^^^^^

An :ref:`imported target <Imported targets>` named ``CUDA::toolkit`` is provided.

This module defines :prop_tgt:`IMPORTED` targets for each
of the following libraries that are part of the CUDAToolkit:

- :ref:`CUDA Runtime Library<cuda_toolkit_rt_lib>`
- :ref:`CUDA Driver Library<cuda_toolkit_driver_lib>`
- :ref:`cuBLAS<cuda_toolkit_cuBLAS>`
- :ref:`cuDLA<cuda_toolkit_cuDLA>`
- :ref:`cuFile<cuda_toolkit_cuFile>`
- :ref:`cuFFT<cuda_toolkit_cuFFT>`
- :ref:`cuRAND<cuda_toolkit_cuRAND>`
- :ref:`cuSOLVER<cuda_toolkit_cuSOLVER>`
- :ref:`cuSPARSE<cuda_toolkit_cuSPARSE>`
- :ref:`cuPTI<cuda_toolkit_cupti>`
- :ref:`NPP<cuda_toolkit_NPP>`
- :ref:`nvBLAS<cuda_toolkit_nvBLAS>`
- :ref:`nvGRAPH<cuda_toolkit_nvGRAPH>`
- :ref:`nvJPEG<cuda_toolkit_nvJPEG>`
- :ref:`nvidia-ML<cuda_toolkit_nvML>`
- :ref:`nvPTX Compiler<cuda_toolkit_nvptx>`
- :ref:`nvRTC<cuda_toolkit_nvRTC>`
- :ref:`nvToolsExt<cuda_toolkit_nvToolsExt>`
- :ref:`nvtx3<cuda_toolkit_nvtx3>`
- :ref:`OpenCL<cuda_toolkit_opencl>`
- :ref:`cuLIBOS<cuda_toolkit_cuLIBOS>`

.. _`cuda_toolkit_rt_lib`:

CUDA Runtime Library
""""""""""""""""""""

The CUDA Runtime library (cudart) are what most applications will typically
need to link against to make any calls such as `cudaMalloc`, and `cudaFree`.

Targets Created:

- ``CUDA::cudart``
- ``CUDA::cudart_static``

.. _`cuda_toolkit_driver_lib`:

CUDA Driver Library
""""""""""""""""""""

The CUDA Driver library (cuda) are used by applications that use calls
such as `cuMemAlloc`, and `cuMemFree`.

Targets Created:

- ``CUDA::cuda_driver``

.. _`cuda_toolkit_cuBLAS`:

cuBLAS
""""""

The `cuBLAS <https://docs.nvidia.com/cuda/cublas/index.html>`_ library.

Targets Created:

- ``CUDA::cublas``
- ``CUDA::cublas_static``
- ``CUDA::cublasLt`` starting in CUDA 10.1
- ``CUDA::cublasLt_static`` starting in CUDA 10.1

.. _`cuda_toolkit_cuDLA`:

cuDLA
""""""

.. versionadded:: 3.27

The NVIDIA Tegra Deep Learning Accelerator `cuDLA <https://docs.nvidia.com/cuda/cublas/index.html>`_ library.

Targets Created:

- ``CUDA::cudla`` starting in CUDA 11.6

.. _`cuda_toolkit_cuFile`:

cuFile
""""""

.. versionadded:: 3.25

The NVIDIA GPUDirect Storage `cuFile <https://docs.nvidia.com/gpudirect-storage/api-reference-guide/index.html>`_ library.

Targets Created:

- ``CUDA::cuFile`` starting in CUDA 11.4
- ``CUDA::cuFile_static`` starting in CUDA 11.4
- ``CUDA::cuFile_rdma`` starting in CUDA 11.4
- ``CUDA::cuFile_rdma_static`` starting in CUDA 11.4

.. _`cuda_toolkit_cuFFT`:

cuFFT
"""""

The `cuFFT <https://docs.nvidia.com/cuda/cufft/index.html>`_ library.

Targets Created:

- ``CUDA::cufft``
- ``CUDA::cufftw``
- ``CUDA::cufft_static``
- ``CUDA::cufft_static_nocallback`` starting in CUDA 9.2, requires CMake 3.23+
- ``CUDA::cufftw_static``

cuRAND
""""""

The `cuRAND <https://docs.nvidia.com/cuda/curand/index.html>`_ library.

Targets Created:

- ``CUDA::curand``
- ``CUDA::curand_static``

.. _`cuda_toolkit_cuSOLVER`:

cuSOLVER
""""""""

The `cuSOLVER <https://docs.nvidia.com/cuda/cusolver/index.html>`_ library.

Targets Created:

- ``CUDA::cusolver``
- ``CUDA::cusolver_static``

.. _`cuda_toolkit_cuSPARSE`:

cuSPARSE
""""""""

The `cuSPARSE <https://docs.nvidia.com/cuda/cusparse/index.html>`_ library.

Targets Created:

- ``CUDA::cusparse``
- ``CUDA::cusparse_static``

.. _`cuda_toolkit_cupti`:

cupti
"""""

The `NVIDIA CUDA Profiling Tools Interface <https://developer.nvidia.com/cupti>`_.

Targets Created:

- ``CUDA::cupti``
- ``CUDA::cupti_static``

.. versionadded:: 3.27

  - ``CUDA::nvperf_host``         starting in CUDA 10.2
  - ``CUDA::nvperf_host_static``  starting in CUDA 10.2
  - ``CUDA::nvperf_target``       starting in CUDA 10.2
  - ``CUDA::pcsamplingutil``      starting in CUDA 11.3

.. _`cuda_toolkit_NPP`:

NPP
"""

The `NPP <https://docs.nvidia.com/cuda/npp/index.html>`_ libraries.

Targets Created:

- `nppc`:

  - ``CUDA::nppc``
  - ``CUDA::nppc_static``

- `nppial`: Arithmetic and logical operation functions in `nppi_arithmetic_and_logical_operations.h`

  - ``CUDA::nppial``
  - ``CUDA::nppial_static``

- `nppicc`: Color conversion and sampling functions in `nppi_color_conversion.h`

  - ``CUDA::nppicc``
  - ``CUDA::nppicc_static``

- `nppicom`: JPEG compression and decompression functions in `nppi_compression_functions.h`
  Removed starting in CUDA 11.0, use :ref:`nvJPEG<cuda_toolkit_nvJPEG>` instead.

  - ``CUDA::nppicom``
  - ``CUDA::nppicom_static``

- `nppidei`: Data exchange and initialization functions in `nppi_data_exchange_and_initialization.h`

  - ``CUDA::nppidei``
  - ``CUDA::nppidei_static``

- `nppif`: Filtering and computer vision functions in `nppi_filter_functions.h`

  - ``CUDA::nppif``
  - ``CUDA::nppif_static``

- `nppig`: Geometry transformation functions found in `nppi_geometry_transforms.h`

  - ``CUDA::nppig``
  - ``CUDA::nppig_static``

- `nppim`: Morphological operation functions found in `nppi_morphological_operations.h`

  - ``CUDA::nppim``
  - ``CUDA::nppim_static``

- `nppist`: Statistics and linear transform in `nppi_statistics_functions.h` and `nppi_linear_transforms.h`

  - ``CUDA::nppist``
  - ``CUDA::nppist_static``

- `nppisu`: Memory support functions in `nppi_support_functions.h`

  - ``CUDA::nppisu``
  - ``CUDA::nppisu_static``

- `nppitc`: Threshold and compare operation functions in `nppi_threshold_and_compare_operations.h`

  - ``CUDA::nppitc``
  - ``CUDA::nppitc_static``

- `npps`:

  - ``CUDA::npps``
  - ``CUDA::npps_static``

.. _`cuda_toolkit_nvBLAS`:

nvBLAS
""""""

The `nvBLAS <https://docs.nvidia.com/cuda/nvblas/index.html>`_ libraries.
This is a shared library only.

Targets Created:

- ``CUDA::nvblas``

.. _`cuda_toolkit_nvGRAPH`:

nvGRAPH
"""""""

The `nvGRAPH <https://web.archive.org/web/20201111171403/https://docs.nvidia.com/cuda/nvgraph/index.html>`_ library.
Removed starting in CUDA 11.0

Targets Created:

- ``CUDA::nvgraph``
- ``CUDA::nvgraph_static``


.. _`cuda_toolkit_nvJPEG`:

nvJPEG
""""""

The `nvJPEG <https://docs.nvidia.com/cuda/nvjpeg/index.html>`_ library.
Introduced in CUDA 10.

Targets Created:

- ``CUDA::nvjpeg``
- ``CUDA::nvjpeg_static``

.. _`cuda_toolkit_nvPTX`:

nvPTX Compiler
""""""""""""""

.. versionadded:: 3.25

The `nvPTX <https://docs.nvidia.com/cuda/ptx-compiler-api/index.html>`_ (PTX Compilation) library.
The PTX Compiler APIs are a set of APIs which can be used to compile a PTX program into GPU assembly code.
Introduced in CUDA 11.1
This is a static library only.

Targets Created:

- ``CUDA::nvptxcompiler_static`` starting in CUDA 11.1

.. _`cuda_toolkit_nvRTC`:

nvRTC
"""""

The `nvRTC <https://docs.nvidia.com/cuda/nvrtc/index.html>`_ (Runtime Compilation) library.

Targets Created:

- ``CUDA::nvrtc``

.. versionadded:: 3.26

  - ``CUDA::nvrtc_builtins``
  - ``CUDA::nvrtc_static`` starting in CUDA 11.5
  - ``CUDA::nvrtc_builtins_static`` starting in CUDA 11.5

.. _`cuda_toolkit_nvjitlink`:

nvJitLink
"""""""""

The `nvJItLink <https://docs.nvidia.com/cuda/>`_ (Runtime LTO Linking) library.

Targets Created:

- ``CUDA::nvJitLink`` starting in CUDA 12.0
- ``CUDA::nvJitLink_static``  starting in CUDA 12.0

.. _`cuda_toolkit_nvml`:

nvidia-ML
"""""""""

The `NVIDIA Management Library <https://developer.nvidia.com/nvidia-management-library-nvml>`_.
This is a shared library only.

Targets Created:

- ``CUDA::nvml``

.. _`cuda_toolkit_nvToolsExt`:

nvToolsExt
""""""""""

.. deprecated:: 3.25 With CUDA 10.0+, use :ref:`nvtx3 <cuda_toolkit_nvtx3>`.

The `NVIDIA Tools Extension <https://docs.nvidia.com/nvtx/>`_.
This is a shared library only.

Targets Created:

- ``CUDA::nvToolsExt``

.. _`cuda_toolkit_nvtx3`:

nvtx3
"""""

.. versionadded:: 3.25

The header-only `NVIDIA Tools Extension Library <https://nvidia.github.io/NVTX/doxygen/index.html>`_.
Introduced in CUDA 10.0.

Targets created:

- ``CUDA::nvtx3``

.. _`cuda_toolkit_opencl`:

OpenCL
""""""

The `NVIDIA OpenCL Library <https://developer.nvidia.com/opencl>`_.
This is a shared library only.

Targets Created:

- ``CUDA::OpenCL``

.. _`cuda_toolkit_cuLIBOS`:

cuLIBOS
"""""""

The cuLIBOS library is a backend thread abstraction layer library which is
static only.  The ``CUDA::cublas_static``, ``CUDA::cusparse_static``,
``CUDA::cufft_static``, ``CUDA::curand_static``, and (when implemented) NPP
libraries all automatically have this dependency linked.

Target Created:

- ``CUDA::culibos``

**Note**: direct usage of this target by consumers should not be necessary.

.. _`cuda_toolkit_cuRAND`:



Result variables
^^^^^^^^^^^^^^^^

``CUDAToolkit_FOUND``
    A boolean specifying whether or not the CUDA Toolkit was found.

``CUDAToolkit_VERSION``
    The exact version of the CUDA Toolkit found (as reported by
    ``nvcc --version``, ``version.txt``, or ``version.json``).

``CUDAToolkit_VERSION_MAJOR``
    The major version of the CUDA Toolkit.

``CUDAToolkit_VERSION_MINOR``
    The minor version of the CUDA Toolkit.

``CUDAToolkit_VERSION_PATCH``
    The patch version of the CUDA Toolkit.

``CUDAToolkit_BIN_DIR``
    The path to the CUDA Toolkit library directory that contains the CUDA
    executable ``nvcc``.

``CUDAToolkit_INCLUDE_DIRS``
    The path to the CUDA Toolkit ``include`` folder containing the header files
    required to compile a project linking against CUDA.

``CUDAToolkit_LIBRARY_DIR``
    The path to the CUDA Toolkit library directory that contains the CUDA
    Runtime library ``cudart``.

``CUDAToolkit_LIBRARY_ROOT``
    .. versionadded:: 3.18

    The path to the CUDA Toolkit directory containing the nvvm directory and
    either version.txt or version.json.

``CUDAToolkit_TARGET_DIR``
    The path to the CUDA Toolkit directory including the target architecture
    when cross-compiling. When not cross-compiling this will be equivalent to
    the parent directory of ``CUDAToolkit_BIN_DIR``.

``CUDAToolkit_NVCC_EXECUTABLE``
    The path to the NVIDIA CUDA compiler ``nvcc``.  Note that this path may
    **not** be the same as
    :variable:`CMAKE_CUDA_COMPILER <CMAKE_<LANG>_COMPILER>`.  ``nvcc`` must be
    found to determine the CUDA Toolkit version as well as determining other
    features of the Toolkit.  This variable is set for the convenience of
    modules that depend on this one.


#]=======================================================================]

# NOTE: much of this was simply extracted from FindCUDA.cmake.

#   James Bigler, NVIDIA Corp (nvidia.com - jbigler)
#   Abe Stephens, SCI Institute -- http://www.sci.utah.edu/~abe/FindCuda.html
#
#   Copyright (c) 2008 - 2009 NVIDIA Corporation.  All rights reserved.
#
#   Copyright (c) 2007-2009
#   Scientific Computing and Imaging Institute, University of Utah
#
#   This code is licensed under the MIT License.  See the FindCUDA.cmake script
#   for the text of the license.

# The MIT License
#
# License for the specific language governing rights and limitations under
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
###############################################################################

# The toolkit is located during compiler detection for CUDA and stored in CMakeCUDACompiler.cmake as
# CMAKE_CUDA_COMPILER_TOOLKIT_ROOT and CMAKE_CUDA_COMPILER_LIBRARY_ROOT.
# We compute the rest based on those here to avoid re-searching and to avoid finding a possibly
# different installation.
if(CMAKE_CUDA_COMPILER_TOOLKIT_ROOT)
  set(CUDAToolkit_ROOT_DIR "${CMAKE_CUDA_COMPILER_TOOLKIT_ROOT}")
  set(CUDAToolkit_LIBRARY_ROOT "${CMAKE_CUDA_COMPILER_LIBRARY_ROOT}")
  set(CUDAToolkit_BIN_DIR "${CUDAToolkit_ROOT_DIR}/bin")
  set(CUDAToolkit_NVCC_EXECUTABLE "${CUDAToolkit_BIN_DIR}/nvcc${CMAKE_EXECUTABLE_SUFFIX}")
  set(CUDAToolkit_VERSION "${CMAKE_CUDA_COMPILER_TOOLKIT_VERSION}")

  if(CUDAToolkit_VERSION MATCHES [=[([0-9]+)\.([0-9]+)\.([0-9]+)]=])
    set(CUDAToolkit_VERSION_MAJOR "${CMAKE_MATCH_1}")
    set(CUDAToolkit_VERSION_MINOR "${CMAKE_MATCH_2}")
    set(CUDAToolkit_VERSION_PATCH "${CMAKE_MATCH_3}")
  endif()
else()
  function(_CUDAToolkit_find_root_dir )
    cmake_parse_arguments(arg "" "" "SEARCH_PATHS;FIND_FLAGS" ${ARGN})

    if(NOT CUDAToolkit_BIN_DIR)
      if(NOT CUDAToolkit_SENTINEL_FILE)
        find_program(CUDAToolkit_NVCC_EXECUTABLE
          NAMES nvcc nvcc.exe
          PATHS ${arg_SEARCH_PATHS}
          ${arg_FIND_FLAGS}
        )
      endif()

      if(NOT CUDAToolkit_NVCC_EXECUTABLE)
        find_file(CUDAToolkit_SENTINEL_FILE
          NAMES version.txt version.json
          PATHS ${arg_SEARCH_PATHS}
          NO_DEFAULT_PATH
        )
      endif()

      if(EXISTS "${CUDAToolkit_NVCC_EXECUTABLE}")
        # If NVCC exists  then invoke it to find the toolkit location.
        # This allows us to support wrapper scripts (e.g. ccache or colornvcc), CUDA Toolkit,
        # NVIDIA HPC SDK, and distro's splayed layouts
        execute_process(COMMAND ${CUDAToolkit_NVCC_EXECUTABLE} "-v" "__cmake_determine_cuda"
          OUTPUT_VARIABLE _CUDA_NVCC_OUT ERROR_VARIABLE _CUDA_NVCC_OUT)
        if(_CUDA_NVCC_OUT MATCHES "\\#\\$ TOP=([^\r\n]*)")
          get_filename_component(CUDAToolkit_BIN_DIR "${CMAKE_MATCH_1}/bin" ABSOLUTE)
        else()
          get_filename_component(CUDAToolkit_BIN_DIR "${CUDAToolkit_NVCC_EXECUTABLE}" DIRECTORY)
        endif()
        unset(_CUDA_NVCC_OUT)

        set(CUDAToolkit_BIN_DIR "${CUDAToolkit_BIN_DIR}" CACHE PATH "" FORCE)
        mark_as_advanced(CUDAToolkit_BIN_DIR)
      endif()

      if(CUDAToolkit_SENTINEL_FILE)
        get_filename_component(CUDAToolkit_BIN_DIR ${CUDAToolkit_SENTINEL_FILE} DIRECTORY ABSOLUTE)
        set(CUDAToolkit_BIN_DIR "${CUDAToolkit_BIN_DIR}/bin")

        set(CUDAToolkit_BIN_DIR "${CUDAToolkit_BIN_DIR}" CACHE PATH "" FORCE)
        mark_as_advanced(CUDAToolkit_BIN_DIR)
      endif()
    endif()

    if(CUDAToolkit_BIN_DIR)
      get_filename_component(CUDAToolkit_ROOT_DIR ${CUDAToolkit_BIN_DIR} DIRECTORY ABSOLUTE)
      set(CUDAToolkit_ROOT_DIR "${CUDAToolkit_ROOT_DIR}" PARENT_SCOPE)
    endif()

  endfunction()

  function(_CUDAToolkit_find_version_file result_variable)
    # We first check for a non-scattered installation to prefer it over a scattered installation.
    set(version_files version.txt version.json)
    foreach(vf IN LISTS version_files)
      if(CUDAToolkit_ROOT AND EXISTS "${CUDAToolkit_ROOT}/${vf}")
        set(${result_variable} "${CUDAToolkit_ROOT}/${vf}" PARENT_SCOPE)
        break()
      elseif(CUDAToolkit_ROOT_DIR AND EXISTS "${CUDAToolkit_ROOT_DIR}/${vf}")
        set(${result_variable} "${CUDAToolkit_ROOT_DIR}/${vf}" PARENT_SCOPE)
        break()
      elseif(CMAKE_SYSROOT_LINK AND EXISTS "${CMAKE_SYSROOT_LINK}/usr/lib/cuda/${vf}")
        set(${result_variable} "${CMAKE_SYSROOT_LINK}/usr/lib/cuda/${vf}" PARENT_SCOPE)
        break()
      elseif(EXISTS "${CMAKE_SYSROOT}/usr/lib/cuda/${vf}")
        set(${result_variable} "${CMAKE_SYSROOT}/usr/lib/cuda/${vf}" PARENT_SCOPE)
        break()
      endif()
    endforeach()
  endfunction()

  function(_CUDAToolkit_parse_version_file version_file)
    if(version_file)
      file(READ "${version_file}" file_conents)
      cmake_path(GET version_file EXTENSION LAST_ONLY version_ext)
      if(version_ext STREQUAL ".json")
        string(JSON cuda_version_info GET "${file_conents}" "cuda" "version")
        set(cuda_version_match_regex [=[([0-9]+)\.([0-9]+)\.([0-9]+)]=])
      elseif(version_ext STREQUAL ".txt")
        set(cuda_version_info "${file_conents}")
        set(cuda_version_match_regex [=[CUDA Version ([0-9]+)\.([0-9]+)\.([0-9]+)]=])
      endif()

      if(cuda_version_info MATCHES "${cuda_version_match_regex}")
        set(CUDAToolkit_VERSION_MAJOR "${CMAKE_MATCH_1}" PARENT_SCOPE)
        set(CUDAToolkit_VERSION_MINOR "${CMAKE_MATCH_2}" PARENT_SCOPE)
        set(CUDAToolkit_VERSION_PATCH "${CMAKE_MATCH_3}" PARENT_SCOPE)
        set(CUDAToolkit_VERSION "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}" PARENT_SCOPE)
        message(STATUS "_CUDAToolkit_parse_version_file")
      endif()
    endif()
  endfunction()

  # For NVCC we can easily deduce the SDK binary directory from the compiler path.
  if(CMAKE_CUDA_COMPILER_LOADED AND NOT CUDAToolkit_BIN_DIR AND CMAKE_CUDA_COMPILER_ID STREQUAL "NVIDIA")
    get_filename_component(CUDAToolkit_BIN_DIR "${CMAKE_CUDA_COMPILER}" DIRECTORY)
    set(CUDAToolkit_BIN_DIR "${CUDAToolkit_BIN_DIR}" CACHE PATH "")
    # Try language provided path first.
    _CUDAToolkit_find_root_dir(SEARCH_PATHS "${CUDAToolkit_BIN_DIR}" FIND_FLAGS NO_DEFAULT_PATH)
    mark_as_advanced(CUDAToolkit_BIN_DIR)
  endif()

  # Try user provided path
  if(NOT CUDAToolkit_ROOT_DIR AND CUDAToolkit_ROOT)
    _CUDAToolkit_find_root_dir(SEARCH_PATHS "${CUDAToolkit_ROOT}" FIND_FLAGS PATH_SUFFIXES bin NO_DEFAULT_PATH)
  endif()
  if(NOT CUDAToolkit_ROOT_DIR)
    _CUDAToolkit_find_root_dir(FIND_FLAGS PATHS ENV CUDA_PATH PATH_SUFFIXES bin)
  endif()

  # If the user specified CUDAToolkit_ROOT but the toolkit could not be found, this is an error.
  if(NOT CUDAToolkit_ROOT_DIR AND (DEFINED CUDAToolkit_ROOT OR DEFINED ENV{CUDAToolkit_ROOT}))
    # Declare error messages now, print later depending on find_package args.
    set(fail_base "Could not find nvcc executable in path specified by")
    set(cuda_root_fail "${fail_base} CUDAToolkit_ROOT=${CUDAToolkit_ROOT}")
    set(env_cuda_root_fail "${fail_base} environment variable CUDAToolkit_ROOT=$ENV{CUDAToolkit_ROOT}")

    if(CUDAToolkit_FIND_REQUIRED)
      if(DEFINED CUDAToolkit_ROOT)
        message(FATAL_ERROR ${cuda_root_fail})
      elseif(DEFINED ENV{CUDAToolkit_ROOT})
        message(FATAL_ERROR ${env_cuda_root_fail})
      endif()
    else()
      if(NOT CUDAToolkit_FIND_QUIETLY)
        if(DEFINED CUDAToolkit_ROOT)
          message(STATUS ${cuda_root_fail})
        elseif(DEFINED ENV{CUDAToolkit_ROOT})
          message(STATUS ${env_cuda_root_fail})
        endif()
      endif()
      set(CUDAToolkit_FOUND FALSE)
      unset(fail_base)
      unset(cuda_root_fail)
      unset(env_cuda_root_fail)
      return()
    endif()
  endif()

  # CUDAToolkit_ROOT cmake / env variable not specified, try platform defaults.
  #
  # - Linux: /usr/local/cuda-X.Y
  # - macOS: /Developer/NVIDIA/CUDA-X.Y
  # - Windows: C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\vX.Y
  #
  # We will also search the default symlink location /usr/local/cuda first since
  # if CUDAToolkit_ROOT is not specified, it is assumed that the symlinked
  # directory is the desired location.
  if(NOT CUDAToolkit_ROOT_DIR)
    if(UNIX)
      if(NOT APPLE)
        set(platform_base "/usr/local/cuda-")
      else()
        set(platform_base "/Developer/NVIDIA/CUDA-")
      endif()
    else()
      set(platform_base "C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\v")
    endif()

    # Build out a descending list of possible cuda installations, e.g.
    file(GLOB possible_paths "${platform_base}*")
    # Iterate the glob results and create a descending list.
    set(versions)
    foreach(p ${possible_paths})
      # Extract version number from end of string
      string(REGEX MATCH "[0-9][0-9]?\\.[0-9]$" p_version ${p})
      if(IS_DIRECTORY ${p} AND p_version)
        list(APPEND versions ${p_version})
      endif()
    endforeach()

    # Sort numerically in descending order, so we try the newest versions first.
    list(SORT versions COMPARE NATURAL ORDER DESCENDING)

    # With a descending list of versions, populate possible paths to search.
    set(search_paths)
    foreach(v ${versions})
      list(APPEND search_paths "${platform_base}${v}")
    endforeach()

    # Force the global default /usr/local/cuda to the front on Unix.
    if(UNIX)
      list(INSERT search_paths 0 "/usr/local/cuda")
    endif()

    # Now search for the toolkit again using the platform default search paths.
    _CUDAToolkit_find_root_dir(SEARCH_PATHS "${search_paths}" FIND_FLAGS PATH_SUFFIXES bin)

    # We are done with these variables now, cleanup for caller.
    unset(platform_base)
    unset(possible_paths)
    unset(versions)
    unset(search_paths)

    if(NOT CUDAToolkit_ROOT_DIR)
      if(CUDAToolkit_FIND_REQUIRED)
        message(FATAL_ERROR "Could not find nvcc, please set CUDAToolkit_ROOT.")
      elseif(NOT CUDAToolkit_FIND_QUIETLY)
        message(STATUS "Could not find nvcc, please set CUDAToolkit_ROOT.")
      endif()

      set(CUDAToolkit_FOUND FALSE)
      return()
    endif()
  endif()

  _CUDAToolkit_find_version_file( _CUDAToolkit_version_file )
  if(_CUDAToolkit_version_file)
    # CUDAToolkit_LIBRARY_ROOT contains the device library and version file.
    get_filename_component(CUDAToolkit_LIBRARY_ROOT "${_CUDAToolkit_version_file}" DIRECTORY ABSOLUTE)
  endif()
  unset(_CUDAToolkit_version_file)

  if(CUDAToolkit_NVCC_EXECUTABLE AND
     CMAKE_CUDA_COMPILER_VERSION AND
     CUDAToolkit_NVCC_EXECUTABLE STREQUAL CMAKE_CUDA_COMPILER)
    # Need to set these based off the already computed CMAKE_CUDA_COMPILER_VERSION value
    # This if statement will always match, but is used to provide variables for MATCH 1,2,3...
    if(CMAKE_CUDA_COMPILER_VERSION MATCHES [=[([0-9]+)\.([0-9]+)\.([0-9]+)]=])
      set(CUDAToolkit_VERSION_MAJOR "${CMAKE_MATCH_1}")
      set(CUDAToolkit_VERSION_MINOR "${CMAKE_MATCH_2}")
      set(CUDAToolkit_VERSION_PATCH "${CMAKE_MATCH_3}")
      set(CUDAToolkit_VERSION "${CMAKE_CUDA_COMPILER_VERSION}")
    endif()
  elseif(CUDAToolkit_NVCC_EXECUTABLE)
    # Compute the version by invoking nvcc
    execute_process(COMMAND ${CUDAToolkit_NVCC_EXECUTABLE} "--version" OUTPUT_VARIABLE NVCC_OUT)
    if(NVCC_OUT MATCHES [=[ V([0-9]+)\.([0-9]+)\.([0-9]+)]=])
      set(CUDAToolkit_VERSION_MAJOR "${CMAKE_MATCH_1}")
      set(CUDAToolkit_VERSION_MINOR "${CMAKE_MATCH_2}")
      set(CUDAToolkit_VERSION_PATCH "${CMAKE_MATCH_3}")
      set(CUDAToolkit_VERSION "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}")
    endif()
    unset(NVCC_OUT)
  else()
    _CUDAToolkit_find_version_file(version_file)
    _CUDAToolkit_parse_version_file("${version_file}")
  endif()
endif()

# Find target directory when crosscompiling.
if(CMAKE_CROSSCOMPILING)
  if(CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7-a")
    # Support for NVPACK
    set(CUDAToolkit_TARGET_NAMES "armv7-linux-androideabi")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
    set(CUDAToolkit_TARGET_NAMES "armv7-linux-gnueabihf")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    if(ANDROID_ARCH_NAME STREQUAL "arm64")
      set(CUDAToolkit_TARGET_NAMES "aarch64-linux-androideabi")
    elseif (CMAKE_SYSTEM_NAME STREQUAL "QNX")
      set(CUDAToolkit_TARGET_NAMES "aarch64-qnx")
    else()
      set(CUDAToolkit_TARGET_NAMES "aarch64-linux" "sbsa-linux")
    endif()
  elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    set(CUDAToolkit_TARGET_NAMES "x86_64-linux")
  endif()

  foreach(CUDAToolkit_TARGET_NAME IN LISTS CUDAToolkit_TARGET_NAMES)
    if(EXISTS "${CUDAToolkit_ROOT_DIR}/targets/${CUDAToolkit_TARGET_NAME}")
      set(CUDAToolkit_TARGET_DIR "${CUDAToolkit_ROOT_DIR}/targets/${CUDAToolkit_TARGET_NAME}")
      # add known CUDA target root path to the set of directories we search for programs, libraries and headers
      list(PREPEND CMAKE_FIND_ROOT_PATH "${CUDAToolkit_TARGET_DIR}")

      # Mark that we need to pop the root search path changes after we have
      # found all cuda libraries so that searches for our cross-compilation
      # libraries work when another cuda sdk is in CMAKE_PREFIX_PATH or
      # PATh
      set(_CUDAToolkit_Pop_ROOT_PATH True)
      break()
    endif()
  endforeach()
endif()

# If not already set we can simply use the toolkit root or it's a scattered installation.
if(NOT CUDAToolkit_TARGET_DIR)
  # Not cross compiling
  set(CUDAToolkit_TARGET_DIR "${CUDAToolkit_ROOT_DIR}")
  # Now that we have the real ROOT_DIR, find components inside it.
  list(APPEND CMAKE_PREFIX_PATH ${CUDAToolkit_ROOT_DIR})

  # Mark that we need to pop the prefix path changes after we have
  # found the cudart library.
  set(_CUDAToolkit_Pop_Prefix True)
endif()

# CUDAToolkit_TARGET_DIR always points to the directory containing the include directory.
# On a scattered installation /usr, on a non-scattered something like /usr/local/cuda or /usr/local/cuda-10.2/targets/aarch64-linux.
if(EXISTS "${CUDAToolkit_TARGET_DIR}/include/cuda_runtime.h")
  set(CUDAToolkit_INCLUDE_DIR "${CUDAToolkit_TARGET_DIR}/include")
elseif(NOT CUDAToolkit_FIND_QUIETLY)
  message(STATUS "Unable to find cuda_runtime.h in \"${CUDAToolkit_TARGET_DIR}/include\" for CUDAToolkit_INCLUDE_DIR.")
endif()

# The NVHPC layout moves math library headers and libraries to a sibling directory and it could be nested under
# the version of the CUDA toolchain
# Create a separate variable so this directory can be selectively added to math targets.
if(NOT EXISTS "${CUDAToolkit_INCLUDE_DIR}/cublas_v2.h")
  file(REAL_PATH "${CUDAToolkit_TARGET_DIR}" CUDAToolkit_MATH_INCLUDE_DIR)
  cmake_path(APPEND CUDAToolkit_MATH_INCLUDE_DIR "../../math_libs/")
  if(EXISTS "${CUDAToolkit_MATH_INCLUDE_DIR}/${CUDAToolkit_VERSION_MAJOR}.${CUDAToolkit_VERSION_MINOR}/")
    cmake_path(APPEND CUDAToolkit_MATH_INCLUDE_DIR "${CUDAToolkit_VERSION_MAJOR}.${CUDAToolkit_VERSION_MINOR}/")
  endif()
  cmake_path(APPEND CUDAToolkit_MATH_INCLUDE_DIR "include")
  cmake_path(NORMAL_PATH CUDAToolkit_MATH_INCLUDE_DIR)

  if(NOT EXISTS "${CUDAToolkit_MATH_INCLUDE_DIR}/cublas_v2.h")
    if(NOT CUDAToolkit_FIND_QUIETLY)
      message(STATUS "Unable to find cublas_v2.h in either \"${CUDAToolkit_INCLUDE_DIR}\" or \"${CUDAToolkit_MATH_INCLUDE_DIR}\"")
    endif()
    unset(CUDAToolkit_MATH_INCLUDE_DIR)
  endif()
endif()

# Find the CUDA Runtime Library libcudart
find_library(CUDA_CUDART
  NAMES cudart
  PATH_SUFFIXES lib64 lib/x64
)
find_library(CUDA_CUDART
  NAMES cudart
  PATH_SUFFIXES lib64/stubs lib/x64/stubs
)

if(NOT CUDA_CUDART AND NOT CUDAToolkit_FIND_QUIETLY)
  message(STATUS "Unable to find cudart library.")
endif()

if(_CUDAToolkit_Pop_Prefix)
  list(REMOVE_AT CMAKE_PREFIX_PATH -1)
  unset(_CUDAToolkit_Pop_Prefix)
endif()

#-----------------------------------------------------------------------------
# Perform version comparison and validate all required variables are set.
include(${CMAKE_CURRENT_LIST_DIR}/FindPackageHandleStandardArgs.cmake)
find_package_handle_standard_args(CUDAToolkit
  REQUIRED_VARS
    CUDAToolkit_INCLUDE_DIR
    CUDA_CUDART
    CUDAToolkit_BIN_DIR
  VERSION_VAR
    CUDAToolkit_VERSION
)

unset(CUDAToolkit_ROOT_DIR)
mark_as_advanced(CUDA_CUDART
                 CUDAToolkit_INCLUDE_DIR
                 CUDAToolkit_NVCC_EXECUTABLE
                 CUDAToolkit_SENTINEL_FILE
                 )

#-----------------------------------------------------------------------------
# Construct result variables
if(CUDAToolkit_FOUND)
  set(CUDAToolkit_INCLUDE_DIRS ${CUDAToolkit_INCLUDE_DIR})
  get_filename_component(CUDAToolkit_LIBRARY_DIR ${CUDA_CUDART} DIRECTORY ABSOLUTE)

  # Build search paths without any symlinks
  file(REAL_PATH "${CUDAToolkit_LIBRARY_DIR}" _cmake_search_dir)
  set(CUDAToolkit_LIBRARY_SEARCH_DIRS "${_cmake_search_dir}")

  # Detect we are in a splayed nvhpc toolkit layout and add extra
  # search paths without symlinks
  if(CUDAToolkit_LIBRARY_DIR  MATCHES ".*/cuda/${CUDAToolkit_VERSION_MAJOR}.${CUDAToolkit_VERSION_MINOR}/lib64$")
    # Search location for math_libs/
    block(SCOPE_FOR POLICIES)
      cmake_policy(SET CMP0152 NEW)
      file(REAL_PATH "${CUDAToolkit_LIBRARY_DIR}/../../../../../" _cmake_search_dir)
      list(APPEND CUDAToolkit_LIBRARY_SEARCH_DIRS "${_cmake_search_dir}")

      # Search location for extras like cupti
      file(REAL_PATH "${CUDAToolkit_LIBRARY_DIR}/../../../" _cmake_search_dir)
      list(APPEND CUDAToolkit_LIBRARY_SEARCH_DIRS "${_cmake_search_dir}")
    endblock()
  endif()

  # If no `CUDAToolkit_LIBRARY_ROOT` exists set it based on CUDAToolkit_LIBRARY_DIR
  if(NOT DEFINED CUDAToolkit_LIBRARY_ROOT)
    foreach(CUDAToolkit_search_loc IN LISTS CUDAToolkit_LIBRARY_DIR CUDAToolkit_BIN_DIR)
      get_filename_component(CUDAToolkit_possible_lib_root "${CUDAToolkit_search_loc}" DIRECTORY ABSOLUTE)
      if(EXISTS "${CUDAToolkit_possible_lib_root}/nvvm/")
        set(CUDAToolkit_LIBRARY_ROOT "${CUDAToolkit_possible_lib_root}")
        break()
      endif()
    endforeach()
    unset(CUDAToolkit_search_loc)
    unset(CUDAToolkit_possible_lib_root)
  endif()
endif()


#-----------------------------------------------------------------------------
# Construct import targets
if(CUDAToolkit_FOUND)

  function(_CUDAToolkit_find_and_add_import_lib lib_name)
    cmake_parse_arguments(arg "" "" "ALT;DEPS;EXTRA_PATH_SUFFIXES;EXTRA_INCLUDE_DIRS" ${ARGN})

    set(search_names ${lib_name} ${arg_ALT})

    find_library(CUDA_${lib_name}_LIBRARY
      NAMES ${search_names}
      HINTS ${CUDAToolkit_LIBRARY_SEARCH_DIRS}
            ENV CUDA_PATH
      PATH_SUFFIXES nvidia/current lib64 lib/x64 lib
                    # Support NVHPC splayed math library layout
                    math_libs/${CUDAToolkit_VERSION_MAJOR}.${CUDAToolkit_VERSION_MINOR}/lib64
                    math_libs/lib64
                    ${arg_EXTRA_PATH_SUFFIXES}
    )
    # Don't try any stub directories until we have exhausted all other
    # search locations.
    set(CUDA_IMPORT_PROPERTY IMPORTED_LOCATION)
    set(CUDA_IMPORT_TYPE     UNKNOWN)
    if(NOT CUDA_${lib_name}_LIBRARY)
      find_library(CUDA_${lib_name}_LIBRARY
        NAMES ${search_names}
        HINTS ${CUDAToolkit_LIBRARY_SEARCH_DIRS}
              ENV CUDA_PATH
        PATH_SUFFIXES lib64/stubs lib/x64/stubs lib/stubs stubs
      )
      if(CUDA_${lib_name}_LIBRARY AND NOT WIN32)
        # Use `IMPORTED_IMPLIB` so that we don't add a `-rpath` entry for stub directories
        set(CUDA_IMPORT_PROPERTY IMPORTED_IMPLIB)
        set(CUDA_IMPORT_TYPE     SHARED)
      endif()
    endif()

    mark_as_advanced(CUDA_${lib_name}_LIBRARY)

    if (NOT TARGET CUDA::${lib_name} AND CUDA_${lib_name}_LIBRARY)
      add_library(CUDA::${lib_name} ${CUDA_IMPORT_TYPE} IMPORTED)
      target_include_directories(CUDA::${lib_name} SYSTEM INTERFACE "${CUDAToolkit_INCLUDE_DIRS}")
      if(DEFINED CUDAToolkit_MATH_INCLUDE_DIR)
        string(FIND ${CUDA_${lib_name}_LIBRARY} "math_libs" math_libs)
        if(NOT ${math_libs} EQUAL -1)
          target_include_directories(CUDA::${lib_name} SYSTEM INTERFACE "${CUDAToolkit_MATH_INCLUDE_DIR}")
        endif()
      endif()
      set_property(TARGET CUDA::${lib_name} PROPERTY ${CUDA_IMPORT_PROPERTY} "${CUDA_${lib_name}_LIBRARY}")
      foreach(dep ${arg_DEPS})
        if(TARGET CUDA::${dep})
          target_link_libraries(CUDA::${lib_name} INTERFACE CUDA::${dep})
        endif()
      endforeach()
      if(arg_EXTRA_INCLUDE_DIRS)
        target_include_directories(CUDA::${lib_name} SYSTEM INTERFACE "${arg_EXTRA_INCLUDE_DIRS}")
      endif()
    endif()
  endfunction()

  if(NOT TARGET CUDA::toolkit)
    add_library(CUDA::toolkit IMPORTED INTERFACE)
    target_include_directories(CUDA::toolkit SYSTEM INTERFACE "${CUDAToolkit_INCLUDE_DIRS}")
    target_link_directories(CUDA::toolkit INTERFACE "${CUDAToolkit_LIBRARY_DIR}")
  endif()

  _CUDAToolkit_find_and_add_import_lib(cuda_driver ALT cuda)

  _CUDAToolkit_find_and_add_import_lib(cudart)
  _CUDAToolkit_find_and_add_import_lib(cudart_static)

  # setup dependencies that are required for cudart_static when building
  # on linux. These are generally only required when using the CUDA toolkit
  # when CUDA language is disabled
  if(NOT TARGET CUDA::cudart_static_deps
     AND TARGET CUDA::cudart_static)

    add_library(CUDA::cudart_static_deps IMPORTED INTERFACE)
    target_link_libraries(CUDA::cudart_static INTERFACE CUDA::cudart_static_deps)

    if(UNIX AND (CMAKE_C_COMPILER OR CMAKE_CXX_COMPILER))
      find_package(Threads REQUIRED)
      target_link_libraries(CUDA::cudart_static_deps INTERFACE Threads::Threads ${CMAKE_DL_LIBS})
    endif()

    if(UNIX AND NOT APPLE AND NOT (CMAKE_SYSTEM_NAME STREQUAL "QNX"))
      # On Linux, you must link against librt when using the static cuda runtime.
      find_library(CUDAToolkit_rt_LIBRARY rt)
      mark_as_advanced(CUDAToolkit_rt_LIBRARY)
      if(NOT CUDAToolkit_rt_LIBRARY)
        message(WARNING "Could not find librt library, needed by CUDA::cudart_static")
      else()
        target_link_libraries(CUDA::cudart_static_deps INTERFACE ${CUDAToolkit_rt_LIBRARY})
      endif()
    endif()
  endif()

  if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 12.0.0)
    _CUDAToolkit_find_and_add_import_lib(nvJitLink)
    _CUDAToolkit_find_and_add_import_lib(nvJitLink_static DEPS cudart_static_deps)
  endif()

  _CUDAToolkit_find_and_add_import_lib(culibos) # it's a static library
  foreach (cuda_lib cublasLt cufft nvjpeg)
    _CUDAToolkit_find_and_add_import_lib(${cuda_lib})
    _CUDAToolkit_find_and_add_import_lib(${cuda_lib}_static DEPS cudart_static_deps culibos)
  endforeach()
  foreach (cuda_lib curand nppc)
    _CUDAToolkit_find_and_add_import_lib(${cuda_lib})
    _CUDAToolkit_find_and_add_import_lib(${cuda_lib}_static DEPS culibos)
  endforeach()

  _CUDAToolkit_find_and_add_import_lib(cusparse DEPS nvJitLink)
  _CUDAToolkit_find_and_add_import_lib(cusparse_static DEPS nvJitLink_static culibos)

  if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 11.0.0)
    # cublas depends on cublasLt
    # https://docs.nvidia.com/cuda/archive/11.0/cublas/index.html#static-library
    _CUDAToolkit_find_and_add_import_lib(cublas DEPS cublasLt culibos)
    _CUDAToolkit_find_and_add_import_lib(cublas_static DEPS cublasLt_static culibos)
  else()
    _CUDAToolkit_find_and_add_import_lib(cublas DEPS culibos)
    _CUDAToolkit_find_and_add_import_lib(cublas_static DEPS culibos)
  endif()

  if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 11.4)
    _CUDAToolkit_find_and_add_import_lib(cuFile DEPS culibos)
    _CUDAToolkit_find_and_add_import_lib(cuFile_static DEPS culibos)

    _CUDAToolkit_find_and_add_import_lib(cuFile_rdma DEPS cuFile culibos)
    _CUDAToolkit_find_and_add_import_lib(cuFile_rdma_static DEPS cuFile_static culibos)
  endif()

    if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 11.6)
    _CUDAToolkit_find_and_add_import_lib(cudla)
  endif()


  # cuFFTW depends on cuFFT
  _CUDAToolkit_find_and_add_import_lib(cufftw DEPS cufft)
  _CUDAToolkit_find_and_add_import_lib(cufftw_static DEPS cufft_static)
  if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 9.2)
    _CUDAToolkit_find_and_add_import_lib(cufft_static_nocallback DEPS culibos)
  endif()

  # cuSOLVER depends on cuBLAS, and cuSPARSE
  set(cusolver_deps cublas cusparse)
  set(cusolver_static_deps cublas_static cusparse_static culibos)
  if(CUDAToolkit_VERSION VERSION_GREATER 11.2.1)
    # cusolver depends on libcusolver_metis and cublasLt
    # https://docs.nvidia.com/cuda/archive/11.2.2/cusolver/index.html#link-dependency
    list(APPEND cusolver_deps cublasLt)
    _CUDAToolkit_find_and_add_import_lib(cusolver_metis_static ALT metis_static) # implementation detail static lib
    list(APPEND cusolver_static_deps cusolver_metis_static cublasLt_static)
  endif()
  if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 10.1.2)
    # cusolver depends on liblapack_static.a starting with CUDA 10.1 update 2,
    # https://docs.nvidia.com/cuda/archive/11.5.0/cusolver/index.html#static-link-lapack
    _CUDAToolkit_find_and_add_import_lib(cusolver_lapack_static ALT lapack_static) # implementation detail static lib
    list(APPEND cusolver_static_deps cusolver_lapack_static)
  endif()
  _CUDAToolkit_find_and_add_import_lib(cusolver DEPS ${cusolver_deps})
  _CUDAToolkit_find_and_add_import_lib(cusolver_static DEPS ${cusolver_static_deps})
  unset(cusolver_deps)
  unset(cusolver_static_deps)

  # nvGRAPH depends on cuRAND, and cuSOLVER.
  _CUDAToolkit_find_and_add_import_lib(nvgraph DEPS curand cusolver)
  _CUDAToolkit_find_and_add_import_lib(nvgraph_static DEPS curand_static cusolver_static)

  # Process the majority of the NPP libraries.
  foreach (cuda_lib nppial nppicc nppidei nppif nppig nppim nppist nppitc npps nppicom nppisu)
    _CUDAToolkit_find_and_add_import_lib(${cuda_lib} DEPS nppc)
    _CUDAToolkit_find_and_add_import_lib(${cuda_lib}_static DEPS nppc_static)
  endforeach()

  find_path(CUDAToolkit_CUPTI_INCLUDE_DIR cupti.h PATHS
      "${CUDAToolkit_ROOT_DIR}/extras/CUPTI/include"
      "${CUDAToolkit_INCLUDE_DIR}/../extras/CUPTI/include"
      "${CUDAToolkit_INCLUDE_DIR}"
      NO_DEFAULT_PATH)
  mark_as_advanced(CUDAToolkit_CUPTI_INCLUDE_DIR)

  if(CUDAToolkit_CUPTI_INCLUDE_DIR)
    set(_cmake_cupti_extra_paths extras/CUPTI/lib64/
                                 extras/CUPTI/lib/
                                 ../extras/CUPTI/lib64/
                                 ../extras/CUPTI/lib/)
    _CUDAToolkit_find_and_add_import_lib(cupti
                                        EXTRA_PATH_SUFFIXES ${_cmake_cupti_extra_paths}
                                        EXTRA_INCLUDE_DIRS "${CUDAToolkit_CUPTI_INCLUDE_DIR}")
    _CUDAToolkit_find_and_add_import_lib(cupti_static
                                        EXTRA_PATH_SUFFIXES ${_cmake_cupti_extra_paths}
                                        EXTRA_INCLUDE_DIRS "${CUDAToolkit_CUPTI_INCLUDE_DIR}")
    if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 10.2.0)
      _CUDAToolkit_find_and_add_import_lib(nvperf_host
                                          EXTRA_PATH_SUFFIXES ${_cmake_cupti_extra_paths}
                                          EXTRA_INCLUDE_DIRS "${CUDAToolkit_CUPTI_INCLUDE_DIR}")
      _CUDAToolkit_find_and_add_import_lib(nvperf_host_static
                                          EXTRA_PATH_SUFFIXES ${_cmake_cupti_extra_paths}
                                          EXTRA_INCLUDE_DIRS "${CUDAToolkit_CUPTI_INCLUDE_DIR}")
      _CUDAToolkit_find_and_add_import_lib(nvperf_target
                                          EXTRA_PATH_SUFFIXES ${_cmake_cupti_extra_paths}
                                          EXTRA_INCLUDE_DIRS "${CUDAToolkit_CUPTI_INCLUDE_DIR}")
    endif()
    if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 11.3.0)
      _CUDAToolkit_find_and_add_import_lib(pcsamplingutil
                                          EXTRA_PATH_SUFFIXES ${_cmake_cupti_extra_paths}
                                          EXTRA_INCLUDE_DIRS "${CUDAToolkit_CUPTI_INCLUDE_DIR}")
    endif()
  endif()

  if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 11.1.0)
    if(NOT TARGET CUDA::nvptxcompiler_static)
      _CUDAToolkit_find_and_add_import_lib(nvptxcompiler_static DEPS cuda_driver)
      if(TARGET CUDA::nvptxcompiler_static)
        target_link_libraries(CUDA::nvptxcompiler_static INTERFACE CUDA::cudart_static_deps)
      endif()
    endif()
  endif()

  _CUDAToolkit_find_and_add_import_lib(nvrtc_builtins ALT nvrtc-builtins DEPS cuda_driver)
  _CUDAToolkit_find_and_add_import_lib(nvrtc DEPS nvrtc_builtins nvJitLink)
  if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 11.5.0)
    _CUDAToolkit_find_and_add_import_lib(nvrtc_builtins_static ALT nvrtc-builtins_static DEPS cuda_driver)
    if(NOT TARGET CUDA::nvrtc_static)
      _CUDAToolkit_find_and_add_import_lib(nvrtc_static DEPS nvrtc_builtins_static nvptxcompiler_static nvJitLink_static)
      if(TARGET CUDA::nvrtc_static AND WIN32 AND NOT (BORLAND OR MINGW OR CYGWIN))
        target_link_libraries(CUDA::nvrtc_static INTERFACE Ws2_32.lib)
      endif()
    endif()
  endif()

  _CUDAToolkit_find_and_add_import_lib(nvml ALT nvidia-ml nvml)

  if(WIN32)
    # nvtools can be installed outside the CUDA toolkit directory
    # so prefer the NVTOOLSEXT_PATH windows only environment variable
    # In addition on windows the most common name is nvToolsExt64_1
    find_library(CUDA_nvToolsExt_LIBRARY
      NAMES nvToolsExt64_1 nvToolsExt64 nvToolsExt
      PATHS ENV NVTOOLSEXT_PATH
            ENV CUDA_PATH
      PATH_SUFFIXES lib/x64 lib
    )
  endif()
  _CUDAToolkit_find_and_add_import_lib(nvToolsExt ALT nvToolsExt64)

  if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL 10.0)
    # nvToolsExt is deprecated since nvtx3 introduction.
    # Warn only if the project requires a sufficiently new CMake to make migration possible.
    if(TARGET CUDA::nvToolsExt AND CMAKE_MINIMUM_REQUIRED_VERSION VERSION_GREATER_EQUAL 3.25)
      set_property(TARGET CUDA::nvToolsExt PROPERTY DEPRECATION "nvToolsExt has been superseded by nvtx3 since CUDA 10.0 and CMake 3.25. Use CUDA::nvtx3 and include <nvtx3/nvToolsExt.h> instead.")
    endif()

    # Header-only variant. Uses dlopen().
    if(NOT TARGET CUDA::nvtx3)
      add_library(CUDA::nvtx3 INTERFACE IMPORTED)
      target_include_directories(CUDA::nvtx3 SYSTEM INTERFACE "${CUDAToolkit_INCLUDE_DIRS}")
      target_link_libraries(CUDA::nvtx3 INTERFACE ${CMAKE_DL_LIBS})
    endif()
  endif()

  _CUDAToolkit_find_and_add_import_lib(OpenCL)
endif()

if(_CUDAToolkit_Pop_ROOT_PATH)
  list(REMOVE_AT CMAKE_FIND_ROOT_PATH 0)
  unset(_CUDAToolkit_Pop_ROOT_PATH)
endif()
