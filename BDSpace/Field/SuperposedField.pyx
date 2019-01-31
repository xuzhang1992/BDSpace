from __future__ import division, print_function
import numpy as np

from cpython.array cimport array, clone

from .Field cimport Field


cdef class SuperposedField(Field):

    def __init__(self, name, fields):
        self.__fields = None
        self.type = None
        self.fields = fields
        super(SuperposedField, self).__init__(name, self.type)

    @property
    def fields(self):
        return self.__fields

    @fields.setter
    def fields(self, list fields):
        for field in fields:
            if not isinstance(field, Field):
                raise ValueError('Fields must be iterable of Field class instances')
            if self.type is None:
                self.type = field.type
            if self.type != field.type:
                raise ValueError('All fields must be iterable of Field class instances')

        self.__fields = fields

    cpdef double[:] scalar_field(self, double[:, :] xyz):
        """
        Calculates scalar field value at points xyz
        :param xyz: array of N points with shape (N, 3)
        :return: scalar values array
        """
        cdef:
            Py_ssize_t i, s = xyz.shape[0]
            double[:] field_contribution, total_field = self.__points_scalar(xyz, 0.0)
        for field in self.fields:
            field_contribution = field.scalar_field(field.to_local_coordinate_system(xyz))
            for i in range(s):
                total_field[i] += field_contribution[i]
        return total_field

    cpdef double[:, :] vector_field(self, double[:, :] xyz):
        """
        Calculates vector field value at points xyz
        :param xyz: array of N points with shape (N, 3)
        :return: vector field values array
        """
        cdef:
            Py_ssize_t i, j, s = xyz.shape[0], c = xyz.shape[1]
            array[double] template = array('d')
            double[:, :] field_contribution
            double[:, :] total_field = self.__points_vector(xyz, clone(template, xyz.shape[1], zero=True))
        for field in self.fields:
            field_contribution = field.vector_field(field.to_local_coordinate_system(xyz))
            field_contribution = field.to_global_coordinate_system(field_contribution)
            for i in range(s):
                for j in range(c):
                    total_field[i][j] += field_contribution[i][j]
        return total_field