# Space

**Space** is a python package to simplify positioning, movement, and trajectory calculation for many
different technical problems. It is mainly for multiple interacting bodies systems like coordinate stages
and machining tools, multiple robotic arms, manipulators, etc.

**Space** provides following basic features:

|Feature                               |Staus             |
|--------------------------------------|------------------|
|Cartesian coordinate systems          |done              |
|Spherical coordinates                 |done              |
|Cylindrical coordinates               |done              |
|Conversion between coordinate systems |done              |
|Multiple nested coordinate systems    |done              |
|Parametric curves                     |done              |
|Trajectory builder (Pathfinder module)|endless work      |
|Planes and plane geometry             |work in progress  |
|...                                   |discussion is open|

## Installation

Space depends on numpy and [Quaternions](https://github.com/bond-anton/Quaternions) packages only.
It is compatible with Python 2 and Python 3.

To install Space in the root directory of Space distribution run
```shell
python setup.py install
```
## Usage

Please see the demo directory for the usage examples.

## License

Space is free open source software licensed under Apache license version 2.0
