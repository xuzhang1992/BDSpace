from __future__ import division, print_function
import numpy as np

from Space.Coordinates import Cartesian
from Space import Space
from Space.Figure import Figure
from Space.Curve import Curve
from Space.Field import Field


coordinate_system = Cartesian(origin=np.array([0, 0, 0]), euler_angles_convention='canova')
print(coordinate_system)

my_space = Space('My new space', coordinate_system=coordinate_system)
print(my_space)

my_figure = Figure('My figure')
my_space.add_element(my_figure)
print(my_figure)

my_curve = Curve('My curve')
my_space.add_element(my_curve)
print(my_curve)

my_field = Field('My Field', field_type='My Field type')
my_figure.add_element(my_field)
print(my_field)