#!/bin/bash

./compile.sh --only=./stencils/seidel-2d/faulty-seidel-2d.c;
./run.sh --only=./stencils/seidel-2d/faulty-seidel-2d.c;
wait;
./validate.py --only=./stencils/seidel-2d/faulty-seidel-2d.c
