#!/bin/bash
#if [[ -z $TAFFO_POLYBENCH_FAULT_INJECTION ]]
#then
#fi
#
./compile_benchmark_to_LLVMIR.sh --only=."/stencils/seidel-2d/seidel-2d.c";

./run_faultinjected.sh --only="./stencils/seidel-2d/seidel-2d.c";
wait;
./validate.py --only="./stencils/seidel-2d/seidel-2d.c";
