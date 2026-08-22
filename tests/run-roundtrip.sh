#!/bin/bash

# Round-trip test for the Core pretty-printer / Core parser pair:
# for every ci test that elaborates, check that the output of --pp=core
# can be re-parsed by the Core parser and that pretty-printing has
# reached a fixpoint (re-parsing the second print and printing again is
# byte-identical).

TESTSDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${TESTSDIR}

# This initialises citests and skip
source ./tests.sh

# Load function for setting up CERB and CERB_INSTALL_PREFIX
source ./common.sh

mkdir -p tmp

pass=0
fail=0
skipped=0
stable=0

function doSkip {
  for f in "${skip[@]}"; do [[ $f == $1 ]] && return 0; done
  return 1
}

if [[ $# == 1 ]]; then
  citests=($(basename $1))
fi

# Setup CERB and CERB_INSTALL_PREFIX (see common.sh)
set_cerberus_exec "cerberus"

for file in "${citests[@]}"
do
  if [ ! -f ./ci/$file ]; then
    echo -e "Test $file: \033[1m\033[33mNOT FOUND\033[0m";
    fail=$((fail+1));
    continue
  fi

  if doSkip $file; then
    echo -e "Test $file: \033[1m\033[33mSKIPPING\033[0m";
    continue
  fi

  # The initial print; files that do not elaborate are skipped
  # (elaboration failures are not a pretty-printer/parser concern)
  if ! $CERB --nolibc --pp=core ci/$file > tmp/rt1.core 2> tmp/stderr; then
    skipped=$((skipped+1));
    continue
  fi

  # The Core parser only accepts programs with a startup function, so
  # dumps without a main (some of the syntax-only tests) are skipped
  if ! grep -q "proc main \|fun main " tmp/rt1.core; then
    skipped=$((skipped+1));
    continue
  fi

  # First re-parse and second print
  if ! $CERB --nolibc --pp=core tmp/rt1.core > tmp/rt2.core 2> tmp/stderr; then
    echo -e "Test $file: \033[1m\033[31mFAILED!\033[0m (--pp=core output does not re-parse)"
    cat tmp/stderr
    fail=$((fail+1));
    continue
  fi

  # Second re-parse and third print
  if ! $CERB --nolibc --pp=core tmp/rt2.core > tmp/rt3.core 2> tmp/stderr; then
    echo -e "Test $file: \033[1m\033[31mFAILED!\033[0m (second print does not re-parse)"
    cat tmp/stderr
    fail=$((fail+1));
    continue
  fi

  if ! cmp --silent tmp/rt2.core tmp/rt3.core; then
    echo -e "Test $file: \033[1m\033[31mFAILED!\033[0m (print/parse/print is not a fixpoint)"
    fail=$((fail+1));
    continue
  fi

  if cmp --silent tmp/rt1.core tmp/rt2.core; then
    stable=$((stable+1));
  fi

  echo -e "Test $file: \033[1m\033[32mPASSED!\033[0m"
  pass=$((pass+1))
done

echo "ROUNDTRIP PASSED: $pass (of which byte-stable on the first re-parse: $stable)"
echo "ROUNDTRIP FAILED: $fail"
echo "ROUNDTRIP SKIPPED (no elaboration or no main): $skipped"

[ $fail -eq 0 ]
