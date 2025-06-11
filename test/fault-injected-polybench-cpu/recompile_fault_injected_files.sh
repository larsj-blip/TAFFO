#!/bin/bash
if [[ -z $benchname ]]; then
  benchname='seidel-2d'
fi
if [[ -z $llvmbin ]]; then
  llvmbin=/opt/llvm-15-d/bin/
fi


  read -p "specify which bit is being injected and press enter. Only write numbers!"


  ${llvmbin}clang ./build/faultinjectable_IR/"$benchname".ll ./build/polybench.ll -o build/faultinjected/"$benchname"_bit_no_"$REPLY".fixed.out
  ${llvmbin}clang ./build/"$benchname".ll ./build/polybench.ll -o build/unmodified/"$benchname".fixed.out
  taffo ./build/faultinjectable_IR/"$benchname".out.5.taffotmp.ll -o ./build/faultinjected/"$benchname"_bit_no_"$REPLY".float.out
  taffo ./build/"$benchname".out.5.taffotmp.ll -o ./build/unmodified/"$benchname".float.out

