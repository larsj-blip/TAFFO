#!/bin/bash

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM SIGKILL

SCRIPTPATH=$(dirname "$BASH_SOURCE")
cd "$SCRIPTPATH"

TIMEOUT='timeout'
if [[ -z $(which $TIMEOUT) ]]; then
  TIMEOUT='gtimeout'
fi
if [[ ! ( -z $(which $TIMEOUT) ) ]]; then
  TIMEOUT="$TIMEOUT 600"
else
  printf 'warning: timeout command not found\n'
  TIMEOUT=''
fi

if [[ -z $(which taffo) ]]; then
  echo -e '\031[33m'"Error"'\033[39m'" taffo command not found. Install taffo and make sure the place where you installed it is in your PATH!";
fi
if [[ -z $LLVM_DIR ]]; then
  llvmbin=$(taffo -print-llvm-bin-dir)
else
  llvmbin="$LLVM_DIR/bin/";
fi
if [[ -z "$OPT" ]]; then OPT=${llvmbin}opt; fi


compile_one()
{
  benchpath=$1
  xparams=$2
  benchdir=$(dirname $benchpath)
  benchname=$(basename $benchdir)
  $TIMEOUT taffo \
    -o build/"$benchname".out \
    -float-output build/"$benchname".float.out \
    -temp-dir build \
    "$benchpath" \
    ./utilities/polybench.c \
    -I"$benchdir" \
    -I./utilities \
    -I./ \
    $xparams \
    $MIXIMI  \
    -debug-taffo \
    -lm \
    2> build/${benchname}.log || return $?

#build/seidel-2d.ll.1.taffotmp.ll is the name of the IR for the floating point implementation. rename to float.ll
#/usr/lib/llvm-15/bin/clang -I./stencils/seidel-2d -I./utilities -I./ -DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS -DCONF_GOOD -DMEDIUM_DATASET -lm -O3 -Xclang -no-opaque-pointers build/seidel-2d.ll.1.taffotmp.ll -S -emit-llvm -o build/seidel-2d.float.ll
#is the command used to compile to float.


#the llvmbin variable ends with a /, so we skip the / when using a variable. This is tied to taffo behavior.
"$llvmbin"clang -I"$benchpath" -I./utilities -I./ -DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS -DCONF_GOOD -DMEDIUM_DATASET -lm -O3 -Xclang -no-opaque-pointers build/"$benchname".out.5.taffotmp.ll -o build/unmodified/"$benchname".fixed.out
"$llvmbin"clang -I"$benchpath" -I./utilities -I./ -DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS -DCONF_GOOD -DMEDIUM_DATASET -lm -O3 -Xclang -no-opaque-pointers build/"$benchname".out.1.taffotmp.ll -o build/unmodified/"$benchname".float.out


# taffo script copies the final intermediate .ll file to the name "$benchname".ll, and likewise the first intermediate
# .ll file is copied to the name "$benchname".float.ll
# if you specify an output -o for taffo as well as -S -emit-llvm, the output file will be named .out not .ll .
# IN ADDITION TO THIS you do not have to specify -emit-llvm to get llvm-ir output, this is created anyways under
#out.5.taffotmp.ll for the fixed point implementation
#out.1.taffotmp.ll for the standard float implementation
  cp ./build/"$benchname".out.1.taffotmp.ll  ./build/faultinjectable_IR/"$benchname".float.ll
  cp ./build/"$benchname".out.5.taffotmp.ll ./build/faultinjectable_IR/"$benchname".ll

# pauses execution until you press enter. Sourcing preserves variables from the scope of this
# script by running the script in the same shell instead of spawning a new shell
source ./recompile_fault_injected_files.sh


}

read_opts()
{
  benchpath=$1
  optspath=$(dirname ${benchpath})/$(basename ${benchpath} .c).opts
  if [ -a ${optspath} ]; then
    opts=$(tr '\n' ' ' < ${optspath})
  else
    opts=
  fi
  if [[ "$opts" != *-Xerr* ]]; then
      opts="$opts -Xerr -nounroll -Xerr -startonly"
  fi
  if [[ "$opts" != *-Xvra* ]]; then
      opts="$opts -Xvra -max-unroll=0"
  fi
  
  # filter opts if errorprop is disabled
  if [[ -z $ERRORPROP ]]; then
    skip=0
    for opt in $opts; do
      if [[ ( $opt == '-Xerr' ) && ( $skip -eq 0 ) ]]; then
        skip=$((skip + 2))
      fi
      if [[ $skip -eq 0 ]]; then
        printf '%s ' "$opt"
      else
        skip=$((skip - 1))
      fi
    done
  else
    echo "$opts"
  fi
}


D_MINI_DATASET="MINI_DATASET"
D_SMALL_DATASET="SMALL_DATASET"
D_STANDARD_DATASET="MEDIUM_DATASET"
D_LARGE_DATASET="LARGE_DATASET"
D_EXTRALARGE_DATASET="EXTRALARGE_DATASET"
D_DATA_TYPE='DATA_TYPE_IS_FLOAT'
ONLY='.*'
TOT='32'
D_CONF="CONF_GOOD"
RUN_METRICS=0
ERRORPROP='-enable-err'
MIXIMODE=""



for arg; do
  case $arg in
    64bit)
      TOT='64'
      D_DATA_TYPE='DATA_TYPE_IS_DOUBLE'
      ;;
    [A-Z]*_DATASET)
      D_MINI_DATASET=$arg
      D_SMALL_DATASET=$arg
      D_STANDARD_DATASET=$arg
      D_LARGE_DATASET=$arg
      D_EXTRALARGE_DATASET=$arg
      ;;
    CONF_[A-Z]*)
      D_CONF=$arg
      ;;
    --only=*)
      ONLY="${arg#*=}"
      ;;
    --tot=*)
      TOT="${arg#*=}"
      ;;
    --no-err)
      ERRORPROP=''
      ;;
    -costmodelfilename=*)
    MIXIMODE="${MIXIMODE} -mixedmode ${arg}"  
    ;;

    -instructionsetfile=*)
    MIXIMODE="${MIXIMODE} ${arg}" 
    ;;
    metrics)
      RUN_METRICS=1
      ;;
    *)
      echo Unrecognized option $arg
      exit 1
  esac
done

mkdir -p build
mkdir build/faultinjectable_IR
mkdir build/faultinjected
mkdir build/unmodified
rm -f build.log

all_benchs=$(cat ./utilities/benchmark_list)
skipped_all=1
for bench in $all_benchs; do
  if [[ "$bench" =~ $ONLY ]]; then
    skipped_all=0
    printf '[....] %s' "$bench"
    opts=$(read_opts ${bench})
    compile_one "$bench" \
      "-O3 \
      -DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS \
      -D$D_CONF -D$D_STANDARD_DATASET $MIXIMODE \
      -Xdta -totalbits -Xdta $TOT \
      $ERRORPROP $opts"
    bpid_fc=$?
    if [[ $bpid_fc == 0 ]]; then
      bpid_fc=' ok '
    fi
    printf '\033[1G[%4s] %s\n' "$bpid_fc" "$bench"
  fi
done

if [[ $skipped_all -eq 1 ]]; then
  echo 'warning: you specified to skip all tests'
fi

