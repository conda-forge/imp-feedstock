#!/bin/bash

# Help CMake to find CGAL
export CGAL_DIR=${PREFIX}/lib/cmake/CGAL

# Make sure the default encoding for files opened by Python 3 is UTF8
export LANG=en_US.UTF-8

# Don't build the scratch or cnmultifit modules
DISABLED=scratch:cnmultifit

# Avoid running out of memory on ARM by splitting up IMP.cgal
if [ `uname -m` = "aarch64" ]; then
  PERCPPCOMP="-DIMP_PER_CPP_COMPILATION=cgal"
else
  PERCPPCOMP=""
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

# On some platforms (notably aarch64 with Drone) builds can fail due to
# running out of memory. If this happens, try the build again; if it
# still fails, restrict to one core.
ninja install -k 0 || ninja install -k 0 || ninja install -j 1

# Don't distribute example application
rm -f ${PREFIX}/bin/imp_example_app
