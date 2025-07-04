#!/bin/bash


if [[ -z $(ls results-out 2> /dev/null) ]]; then
  read -p "are you sure you want to recompile the benchmark? y: yes, n (or anything else): exit >" answer
  if [[ $answer == "y" ]]; then
    ./compile_benchmark_to_LLVMIR.sh --only=."/stencils/seidel-2d/seidel-2d.c" & wait;
    ./run.sh --only="./stencils/seidel-2d/seidel-2d.c" & wait;
#    ./run_faultinjected.sh --only="./stencils/seidel-2d/seidel-2d.c" & wait;
    ./validate.py --only="./stencils/seidel-2d/seidel-2d.c" & wait;
  else
    echo "exiting: did nothing"
  fi
else
  ./compile_benchmark_to_LLVMIR.sh --only=."/stencils/seidel-2d/seidel-2d.c" & wait;
  ./run_faultinjected.sh --only="./stencils/seidel-2d/seidel-2d.c" & wait;
  ./validate.py --only="./stencils/seidel-2d/seidel-2d.c" & wait;
fi
