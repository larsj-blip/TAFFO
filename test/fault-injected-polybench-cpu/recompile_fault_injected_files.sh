#!/bin/bash
if [[ -z $benchname ]]; then
  benchname='seidel-2d'
fi

if [[ -z $LLVM_DIR ]]; then
  llvmbin=$(taffo -print-llvm-bin-dir)
else
  llvmbin="$LLVM_DIR/bin/";
fi

read -p "specify which bit is being injected by writing a number. press enter if done. > "

until [[ -z $REPLY ]]; do

  "$llvmbin"clang -I./stencils/seidel-2d -I./utilities -I./ -DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS -DCONF_GOOD -DMEDIUM_DATASET -lm -O3 -Xclang -no-opaque-pointers build/faultinjectable_IR/"$benchname".ll  -o build/faultinjected/"$benchname"_bit_no_"$REPLY".fixed.out;
  "$llvmbin"clang -I./stencils/seidel-2d -I./utilities -I./ -DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS -DCONF_GOOD -DMEDIUM_DATASET -lm -O3 -Xclang -no-opaque-pointers build/faultinjectable_IR/"$benchname".float.ll -o build/faultinjected/"$benchname"_bit_no_"$REPLY".float.out;

  read -p "specify which bit is being injected by writing a number. press enter if done. > "

done