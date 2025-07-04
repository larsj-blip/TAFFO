#!/bin/bash
if [[ -z $benchname ]]; then
  benchname='seidel-2d'
fi
if [[ -z $llvmbin ]]; then
  llvmbin=/opt/llvm-15-d/bin/
fi

read -p "specify which bit is being injected by writing a number. press enter if done. > "

until [[ -z $REPLY ]]; do

  $TIMEOUT taffo build/faultinjectable_IR/"$benchname".ll -o build/"$benchname"_bit_no_"$REPLY".fixed.out
  ${llvmbin}clang -DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS -DCONF_GOOD -DMEDIUM_DATASET -lm -O3 -Xclang -no-opaque-pointers build/faultinjectable_IR/"$benchname".float.ll -o build/unmodified/"$benchname"_bit_no_"$REPLY".float.out

  read -p "specify which bit is being injected by writing a number. press enter if done. > "

done