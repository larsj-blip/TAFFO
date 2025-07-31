#!/bin/bash

# run ./compare_results.py --help if you do not understand the parameters
if [[ -n $(ls results-out) ]]; then
  read -p "Are you sure you want to recompile the benchmark? \n This will overwrite the existing values in the directory results-out. \n y: yes, n (or anything else): exit\n >" answer
  if [[ $answer == "y" ]]; then
    ./compile_benchmark_to_LLVMIR.sh --only=."/stencils/seidel-2d/seidel-2d.c";
    ./run_faultinjected.sh --only="./stencils/seidel-2d/seidel-2d.c";
    ./compare_results.py ./results-out/seidel-2d.float.txt ./results-out/
  else
    echo "exiting: did nothing"
  fi
else
  ./compile_benchmark_to_LLVMIR.sh --only=."/stencils/seidel-2d/seidel-2d.c";
  ./run_faultinjected.sh --only="./stencils/seidel-2d/seidel-2d.c";
  ./compare_results.py ./results-out/seidel-2d.float.txt ./results-out/
fi
