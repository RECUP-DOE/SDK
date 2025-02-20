#! /usr/bin/env bash

# pyperfdump requires papi
if ! which papi_avail >/dev/null 2>&1 ; then
  echo "PyPerfDump requires PAPI"
  exit 1
fi

# Optional dependencies for variant features
# The demo.py script always tries to import mpi4py
# Use of HDF5 or PHDF5 depends on whether MPI is available
if mpiexec -n 1 python -c 'from mpi4py import MPI' 2>/dev/null ; then
  usempi="ON"
else
  usempi="OFF"
fi
# hdf5 check for the h5dump bin
if which h5dump >/dev/null 2>&1 ; then
  enablehdf5="ON"
else
  enablehdf5="OFF"
fi

# the pyperfdump directory
[ ! -d "pyperfdump/" ] && git clone https://github.com/RECUP-DOE/pyperfdump.git

# fresh build directory
[ -d "build/" ] && rm -rf build/
mkdir build && cd build || exit 1
cmake "-DUSE_MPI:BOOL=$usempi" \
      "-DENABLE_HDF5:BOOL=$enablehdf5" \
      "../pyperfdump/"
make
make install

