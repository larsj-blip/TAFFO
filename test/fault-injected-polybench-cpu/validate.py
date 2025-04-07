#!/usr/bin/env python3

import sys
import os
from pathlib import Path
import math
from decimal import *
import argparse
import re
import pandas as pd
from functools import *
import statistics as stat


def PolybenchRootDir() -> Path:
  return Path(os.path.abspath(__file__)).parent


def BenchmarkList():
  blpath = PolybenchRootDir().joinpath(Path('./utilities/benchmark_list'))
  listtext = blpath.read_text()
  res = listtext.strip().split('\n')
  return res


def BenchmarkName(bpath):
  return os.path.basename(os.path.dirname(bpath))


def ReadValues(filename):
  with open(filename, 'r') as f:
    l = f.readline()
    while l != '':
      for v in l.strip().split():
        if v != '':
          yield v
      l = f.readline()


def ComputeDifference(fixed_point_data, floating_point_data):
  successful_iterations = 0
  total_difference_between_floating_point_and_fixed_point_values = Decimal(0)
  total_floating_point_value = Decimal(0)
  fixed_point_invalid_result_count = 0
  floating_point_invalid_result_count = 0
  error_threshold = Decimal('0.01')

  for single_value_fixed_point, single_value_floating_point in zip(fixed_point_data, floating_point_data):
    fixed_point_value, floating_point_value = Decimal(single_value_fixed_point), Decimal(single_value_floating_point)


    if not fixed_point_value.is_finite():
      fixed_point_invalid_result_count += 1
    elif not floating_point_value.is_finite():
      floating_point_invalid_result_count += 1
      fixed_point_invalid_result_count += 1
    elif ((floating_point_value + fixed_point_value).copy_abs() - (floating_point_value.copy_abs() + fixed_point_value.copy_abs())) > error_threshold:
      fixed_point_invalid_result_count += 1
    else:
      successful_iterations += 1
      total_difference_between_floating_point_and_fixed_point_values += (floating_point_value - fixed_point_value).copy_abs()
      total_floating_point_value += floating_point_value
      
  average_error_percentage = (total_difference_between_floating_point_and_fixed_point_values / total_floating_point_value * 100) if total_floating_point_value != 0 and successful_iterations > 0 else -1
  average_absolute_error = (total_difference_between_floating_point_and_fixed_point_values / successful_iterations) if successful_iterations > 0 else -1
      
  return {'fixed_point_invalid_result_count': fixed_point_invalid_result_count if successful_iterations > 0 else "no successful iterations", \
          'floating_point_invalid_result_count': floating_point_invalid_result_count if successful_iterations > 0 else "no successful iterations",\
          'avg_percentage_error': str(average_error_percentage) + " %" if average_error_percentage != -1 else "no successful iterations",
          'avg_absolute_error': average_absolute_error if average_absolute_error != -1 else "no successful iterations"}
          
          
def ComputeSpeedups(float_times, fixp_times):
  float_list = [Decimal(di) for di in float_times]
  fixp_list = [Decimal(di) for di in fixp_times]
  float_avg = stat.median(float_list)
  fixp_avg = stat.median(fixp_list)
  speedup = float_avg / fixp_avg if fixp_avg != 0 else -1
  return {'fixed_point_time_average': str(fixp_avg) + " seconds", 'floating_point_time_average': str(float_avg) + " seconds", 'speedup': speedup if speedup != -1 else "data error"}

          
def PrettyPrint(table):
  df = pd.DataFrame.from_dict(table)
  df = df.transpose()
  return df.to_string(justify="left")
          

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Validates Polybench output')
  parser.add_argument('--only', dest='only', action='store', default='.*',
                      help='regex of benchmarks to include (default=".*")')
  args = parser.parse_args()

  g_res = {}
  for bench in BenchmarkList():
    if not re.search(args.only, bench):
      continue
    name = BenchmarkName(bench)
    floating_point_data_path = PolybenchRootDir() / 'results-out' / (name + '.float.csv')
    floating_point_data = ReadValues(str(floating_point_data_path))
    floating_point_times_path = PolybenchRootDir() / 'results-out' / (name + '.float.time.txt')
    floating_point_times = ReadValues(str(floating_point_times_path))
    fixed_point_data_path = PolybenchRootDir() / 'results-out' / (name + '.csv')
    fixed_point_data = ReadValues(str(fixed_point_data_path))
    fixed_point_execution_times_path = PolybenchRootDir() / 'results-out' / (name + '.time.txt')
    fixed_point_execution_times = ReadValues(str(fixed_point_execution_times_path))
    try:
      res = ComputeDifference(fixed_point_data, floating_point_data)
      res.update(ComputeSpeedups(floating_point_times, fixed_point_execution_times))
      g_res[BenchmarkName(bench)] = res
    except Exception as inst:
      print("Problem With " + name + ": " + str(inst))

    
  print(PrettyPrint(g_res))
    

