c++ -O3 -Wall -shared -std=c++11 -fPIC `python3 -m pybind11 --includes` mesh_processor.cpp -o mesh_processor`python3-config --extension-suffix`
