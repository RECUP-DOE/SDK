#! /usr/bin/env bash

echo "$0"

# pyperfdump library not found in PYTHONPATH
if ! python -c 'import pyperfdump' 2>/dev/null ; then
  echo "PyPerfDump module not found"
  exit 1
fi

# pyperfdump requires papi
if ! which papi_avail >/dev/null 2>&1 ; then
  echo "PyPerfDump requires PAPI"
  exit 1
fi

# In order for a test to succeed, we need at least 1 valid counter
# To avoid arbitrarily selecting a counter that isn't available,
# we will just list all potential counters as "selected" counters
# (a valid subset of counters will be automatically chosen)
PAPI_EVENTS="$(papi_native_avail | grep "::" | awk '{print $2}')"
for event in $PAPI_EVENTS ; do
  [ -n "$PDUMP_EVENTS" ] && PDUMP_EVENTS=",$PDUMP_EVENTS"
  PDUMP_EVENTS="$event$PDUMP_EVENTS"
done
PAPI_EVENTS="$(papi_avail | grep -E "Yes[ ]+(No|Yes)" | awk '{print $1}')"
for event in $PAPI_EVENTS ; do
  [ -n "$PDUMP_EVENTS" ] && PDUMP_EVENTS=",$PDUMP_EVENTS"
  PDUMP_EVENTS="$event$PDUMP_EVENTS"
done
# If no counters are found then PAPI won't work
if [ -z "$PDUMP_EVENTS" ] ; then
  echo "No possible PAPI counters found

(Possible issue with kernel paranoia setting)
https://www.kernel.org/doc/Documentation/sysctl/kernel.txt
perf_event_paranoid:

Controls use of the performance events system by unprivileged
users (without CAP_SYS_ADMIN).  The default value is 2.

 -1: Allow use of (almost) all events by all users
     Ignore mlock limit after perf_event_mlock_kb without CAP_IPC_LOCK
>=0: Disallow ftrace function tracepoint by users without CAP_SYS_ADMIN
     Disallow raw tracepoint access by users without CAP_SYS_ADMIN
>=1: Disallow CPU event access by users without CAP_SYS_ADMIN
>=2: Disallow kernel profiling by users without CAP_SYS_ADMIN
"
  echo "$ cat /proc/sys/kernel/perf_event_paranoid"
  cat /proc/sys/kernel/perf_event_paranoid
  exit 1
fi

# The path for the output dump file
PDUMP_DUMP_DIR="$(pwd)"
export PDUMP_DUMP_DIR
# The PAPI events we found earlier, any in the list that work can be chosen
export PDUMP_EVENTS
# Set output format to hdf5, if we don't have hdf5 support it will create a csv
PDUMP_OUTPUT_FORMAT=hdf5
export PDUMP_OUTPUT_FORMAT

# Only check for hdf5 output if we have the h5dump command
if which h5dump >/dev/null 2>&1 ; then
  echo "h5dump command found"
  havehdf5=0
else
  echo "h5dump command not found"
  havehdf5=1
fi

# Determine whether PyPerfDump was built with MPI
if python3 -c 'import pyperfdump ; pyperfdump.init()' 2>/dev/null ; then
  echo "PyPerfDump built without MPI"
  havempi=1
else
  echo "PyPerfDump built with MPI"
  if which mpiexec >/dev/null 2>&1 ; then
    echo "mpiexec command found"
    if mpiexec -n 1 python3 -c 'from mpi4py import MPI' 2>/dev/null ; then
      echo "mpi4py found"
    else
      echo "mpi4py not found"
      exit 1
    fi
  else
    echo "mpiexec command not found"
    exit 1
  fi
  havempi=0
fi

# Get run command and output filenames
if [ "$havempi" -eq 0 ] ; then
  echo "###"
  echo -n "# Running test with MPI"
  [ "$havehdf5" -eq 0 ] && echo " and PHDF5" || echo ""
  echo "###"
  cmd="mpiexec --oversubscribe -n 2 python3 demo.py"
  h5file="perf_dump.2.h5"
else
  echo "###"
  echo -n "# Running test without MPI"
  [ "$havehdf5" -eq 0 ] && echo " and with HDF5" || echo ""
  echo "###"
  cmd="python3 demo.py"
  h5file="perf_dump.h5"
fi
# It will be the same csv output filename with or without MPI
csvfile="perf_dump.csv"
# Ensure output files don't exist
[ -f "$h5file" ] && rm "$h5file"
[ -f "$csvfile" ] && rm "$csvfile"

# Print the command and run the test
echo "$cmd"
$cmd

# If we could have an hdf5 output file
if [ "$havehdf5" -eq 0 ] ; then
  # There is no hdf5 file
  if [ ! -f "$h5file" ] ; then
    # the output was written to a csv file, pyperfdump was built without hdf5
    if [ -f "$csvfile" ] ; then
      echo "PyPerfDump built without HDF5"
      havehdf5=1
    else
      echo "No HDF5 or csv output file"
      exit 1
    fi
  elif [ ! -s "$h5file" ] ; then
    echo "HDF5 output file is empty and shouldn't be"
  elif ! h5dump "$h5file" | grep -q "Runtime" ; then
    echo "HDF5 file output doesn't contain Runtime and should"
  else
    echo "HDF5 output appears correct"
  fi
  if [ "$havehdf5" -eq 0 ] ; then
    # Generate a csv output now
    export PDUMP_OUTPUT_FORMAT=csv
    echo "$cmd"
    $cmd
  fi
fi

# We should have a csv output file
if [ ! -f "$csvfile" ] ; then
  echo "No csv output file"
  exit 1
elif [ ! -s "$csvfile" ] ; then
  echo "csv output file is empty and shouldn't be"
  exit 1
elif ! grep -q "Runtime" "$csvfile" ; then
  echo "csv output doesn't contain Runtime and should"
  exit 1
else
  echo "csv output appears correct"
fi

echo "Test successful"
exit 0
