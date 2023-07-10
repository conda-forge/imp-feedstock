#!/bin/bash

# Help CMake to find CGAL
export CGAL_DIR=${PREFIX}/lib/cmake/CGAL

# Make sure the default encoding for files opened by Python 3 is UTF8
export LANG=en_US.UTF-8

# Don't build the scratch or cnmultifit modules
DISABLED=scratch:cnmultifit

# Avoid running out of memory on by splitting up IMP.cgal and IMP.spb
PERCPPCOMP="-DIMP_PER_CPP_COMPILATION=cgal:spb"

# Force C++17 compilation to build successfully with newer protobuf
if [ `uname -s` = "Darwin" ]; then
  CMAKE_ARGS="-DCMAKE_CXX_FLAGS=-std=c++17"
fi

mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DIMP_DISABLED_MODULES=${DISABLED} \
      -G Ninja \
      -DIMP_USE_SYSTEM_RMF=on \
      -DIMP_USE_SYSTEM_IHM=on \
      ${CMAKE_ARGS} ${PERCPPCOMP} \
      -DUSE_PYTHON2=off \
      -DPython3_FIND_FRAMEWORK=NEVER \
      ..

# Make sure all modules we asked for were found (this is tested for
# in the final package, but quicker to abort here if they're missing)
python "${RECIPE_DIR}/check_disabled_modules.py" ${DISABLED} || exit 1

if [ `uname -s` = "Darwin" ]; then
  ninja install
else
  # On some Linux platforms (notably aarch64 with Drone) builds can fail due to
  # running out of memory. If this happens, try the build again; if it
  # still fails, restrict to one core.
  ninja install -j 2 -k 0 || ninja install -j 2 -k 0 || ninja install -j 1
fi

# Don't distribute example application
rm -f ${PREFIX}/bin/imp_example_app
