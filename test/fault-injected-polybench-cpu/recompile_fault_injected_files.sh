#!/bin/bash
if [[ -z $benchname ]]; then
  benchname='seidel-2d'
fi
if [[ -z $llvmbin ]]; then
  llvmbin=/opt/llvm-15-d/bin/
fi


  taffo ./build/"$benchname".out.5.taffotmp.ll -o ./build/unmodified/"$benchname".fixed.out
  "${llvmbin}"clang ./build/"$benchname".ll ./build/polybench.ll -o build/unmodified/"$benchname".float.out
  read -pr "specify which bit is being injected by writing a number. press enter if done. > "

  until [[ -n $REPLY ]]; do
  "${llvmbin}"clang ./build/faultinjectable_IR/"$benchname".ll ./build/polybench.ll -o build/faultinjected/"$benchname"_bit_no_"$REPLY".fixed.out
  taffo ./build/faultinjectable_IR/"$benchname".out.5.taffotmp.ll -o ./build/faultinjected/"$benchname"_bit_no_"$REPLY".float.out
  unset "$REPLY"
  read -pr "specify which bit is being injected by writing a number. press enter if done. > "
 done