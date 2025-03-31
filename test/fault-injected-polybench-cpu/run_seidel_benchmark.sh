#!/bin/bash

./compile.sh --only=./stencils/seidel-2d/seidel-2d.c;
./run.sh --only=./stencils/seidel-2d/seidel-2d.c;
wait;
./validate.py --only=./stencils/seidel-2d/seidel-2d.c
