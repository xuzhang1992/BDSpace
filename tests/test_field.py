from __future__ import division
import unittest
import numpy as np
from BDSpace.Coordinates import Cartesian
from BDSpace.Field import Field
from BDSpace.Coordinates._utils import check_points_array
from BDQuaternions import Conventions


class TestField(unittest.TestCase):

    def setUp(self):
        self.Field = Field('My Field', 'The Type of My Field')

    def test_name(self):
        self.assertEqual(self.Field.name, 'My Field')
        self.Field.name = 'Another name for My Field'
        self.assertEqual(self.Field.name, 'Another name for My Field')

    def test_type(self):
        self.assertEqual(self.Field.type, 'The Type of My Field')
        self.Field.type = 'Another type for My Field'
        self.assertEqual(self.Field.type, 'Another type for My Field')
        with self.assertRaises(TypeError):
            self.Field.type = 3.14

    def test_elements(self):
        with self.assertRaises(NotImplementedError):
            self.Field.add_element(Field('My another Field', 'The Type of My Field'))
        with self.assertRaises(NotImplementedError):
            self.Field.remove_element(Field('My another Field', 'The Type of My Field'))

    def test_scalar_field(self):
        xyz = np.ones((100, 3), dtype=np.double)
        result = self.Field.scalar_field(xyz)
        np.testing.assert_allclose(result, np.zeros(100, dtype=np.double))

    def test_vector_field(self):
        xyz = np.ones((100, 3), dtype=np.double)
        result = self.Field.vector_field(xyz)
        np.testing.assert_allclose(result, np.zeros((100, 3), dtype=np.double))