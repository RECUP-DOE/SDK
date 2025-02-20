#! /usr/bin/env bash

# pyperfdump requires papi
if ! which papi_avail >/dev/null 2>&1 ; then
  echo "PyPerfDump requires PAPI"
  exit 1
fi

# Optional dependencies for variant features
# The demo.py script always tries to import mpi4py
# Use of HDF5 or PHDF5 depends on whether MPI is available
mpiexec -n 1 python -c 'from mpi4py import MPI' 2>/dev/null
havempi="$?"
[ "$havempi" -eq 0 ] && usempi="ON" || usempi="OFF"
# hdf5 check for the h5dump bin
which h5dump >/dev/null 2>&1
havehdf5="$?"
[ "$havehdf5" -eq 0 ] && enablehdf5="ON" || enablehdf5="OFF"

# fresh build directory
set -e
rm -rf build/ && mkdir build && cd build
set +e
cmake "-DUSE_MPI:BOOL=$usempi" \
      "-DENABLE_HDF5:BOOL=$enablehdf5" \
      "../pyperfdump/"
make
make install

