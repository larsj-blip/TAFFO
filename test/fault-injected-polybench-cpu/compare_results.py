#!/usr/bin/env python3

import sys
from pathlib import Path

class Comparator:
    def __init__(self, control_data_path:Path, data_folder_path:Path):
        self.control_data_path = control_data_path
        self.data_folder_path = data_folder_path
        self.control_data = []
        self.results = {}

    def compare(self):
        with open(self.control_data_path) as control:
            string_data_representation = control.read().strip().split()
            self.control_data = self.cast_string_data_to_float(string_data_representation)
        for file in self.iterate_through_all_data_except_control():
            with open(file) as file_object:
                file_data = file_object.read().strip().split()
                data = self.cast_string_data_to_float(file_data)
                total_difference = 0
                for index, value in enumerate(data):
                    total_difference += abs(value - self.control_data[index])
                self.results[file.name] = total_difference

    def cast_string_data_to_float(self, string_data_representation):
        return [float(value) for value in string_data_representation]

    def iterate_through_all_data_except_control(self):
        return filter(lambda file: file.name != self.control_data_path.name, self.data_folder_path.iterdir())

    def get_results(self):
        if len(self.results) == 0:
            return Result({})
        return Result(self.results)



class Result:
    def __init__(self, data:dict):
        self.data = data

    def get_difference(self, path:Path):
        return self.data[str(path.name)]



if __name__ == '__main__':
    if sys.argv[1] == '-h' or sys.argv[1] == '--help':
        print('Usage: compare_results <control_data_file_path> <data_folder_path>')
    else:
        comparator = Comparator(Path(sys.argv[1]), Path(sys.argv[2]))
        comparator.compare()
        print(comparator.results)
