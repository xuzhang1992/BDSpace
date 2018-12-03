from __future__ import division, print_function
import numbers
import numpy as np

from cython import boundscheck, wraparound

from cpython.array cimport array, clone
from libc.math cimport fabs, sin, cos, atan2, acos, sqrt, M_PI


cdef double __reduce_angle(double angle, bint center=True, bint positive=False):
    """
    Adjusts angle to be in the range [-2*pi; 2*pi]
    :param angle: angle or array-like of input angle
    :param center: if True (default) adjust angle to be within [-pi; pi]
    :param half: if True (default False) adjust angle to be within [0; pi]
    :return: reduced angle or array of reduced angles
    """
    cdef:
        double reduced_angle
    if fabs(angle) > 2 * M_PI:
        reduced_angle = angle - 2 * M_PI * (angle // (2 * M_PI))
    else:
        reduced_angle = angle
    if center:
        if reduced_angle < -M_PI:
            reduced_angle += 2 * M_PI
        elif reduced_angle > M_PI:
            reduced_angle -= 2 * M_PI
    if positive:
        if reduced_angle < 0:
            reduced_angle += 2 * M_PI
    return reduced_angle


@boundscheck(False)
@wraparound(False)
cdef double[:] __reduce_angles(double[:] angles, bint center=True, bint positive=False):
    cdef:
        int i
        Py_ssize_t s = angles.size
        array[double] reduced_angles, template = array('d')
    reduced_angles = clone(template, s, zero=False)
    for i in range(s):
        reduced_angles[i] = __reduce_angle(angles[i], center=center, positive=positive)
    return reduced_angles


def reduce_angle(angle, keep_sign=False):
    """
    Adjusts rotation angle to be in the range [-2*pi; 2*pi]
    :param angle: angle or array-like of input angle
    :param keep_sign: if False (default) adjust angle to be within [0; 2*pi]
    :return: reduced angle or array of reduced angles
    """
    if isinstance(angle, numbers.Number):
        return __reduce_angle(np.double(angle), center=False, positive=not keep_sign)
    elif isinstance(angle, (np.ndarray, tuple, list)):
        angles = np.array(angle, dtype=np.double)
        return np.asarray(__reduce_angles(angles.ravel(), center=False, positive=not keep_sign)).reshape(angles.shape)
    else:
        raise ValueError('Input angle must be either number or iterable of numbers.')


@boundscheck(False)
@wraparound(False)
cpdef double vector_norm(double[:] v):
    cdef:
        int i
        double result = 0.0
    for i in range(v.size):
        result += v[i] * v[i]
    return sqrt(result)


@boundscheck(False)
@wraparound(False)
cpdef double[:] unit_vector(double[:] v):
    """
    returns unit vector for given vector v
    :param v: input vector
    :return: unit vector u parallel v of length 1
    """
    cdef:
        int i
        Py_ssize_t s = v.size
        double length = vector_norm(v)
        array[double] result, template = array('d')
    result = clone(template, s, zero=False)

    if length == 0:
        for i in range(s):
            result[i] = 0.0
    else:
        for i in range(s):
            result[i] = v[i] / length
    return result


@boundscheck(False)
@wraparound(False)
cdef double[:] __extend_vector_dimensions(double[:] v, Py_ssize_t s):
    cdef:
        Py_ssize_t s1 = v.size
        array[double] result, template = array('d')
        int i
    result = clone(template, s, False)
    for i in range(s):
        if i < s1:
            result[i] = v[i]
        else:
            result[i] = 0.0
    return result


@boundscheck(False)
@wraparound(False)
cpdef double angles_between_vectors(double[:] v1, double[:] v2):
    cdef:
        int i
        Py_ssize_t s1 = v1.size, s2 = v2.size
        Py_ssize_t s = s1
        double [:] v1_u = unit_vector(v1)
        double [:] v2_u = unit_vector(v2)
        double cos_angle = 0
    if s1 > s2:
        v2_u = __extend_vector_dimensions(v2_u, s)
    elif s1 < s2:
        s = s2
        v1_u = __extend_vector_dimensions(v1_u, s)
    for i in range(s):
        cos_angle += v1_u[i] * v2_u[i]
    return acos(cos_angle)


@boundscheck(False)
@wraparound(False)
cdef double[:] __cartesian_to_spherical_point(double[:] xyz):
    cdef:
        Py_ssize_t s = xyz.size
        array[double] r_theta_phi, template = array('d')
        double xy
    if s < 3:
        xyz = __extend_vector_dimensions(xyz, 3)
    r_theta_phi = clone(template, 3, False)
    xy = xyz[0]*xyz[0] + xyz[1]*xyz[1]
    r_theta_phi[0] = sqrt(xy + xyz[2]*xyz[2])
    r_theta_phi[1] = atan2(sqrt(xy), xyz[2])
    r_theta_phi[2] = __reduce_angle(atan2(xyz[1], xyz[0]), center=False, positive=True)
    return r_theta_phi


@boundscheck(False)
@wraparound(False)
cdef double[:] __cartesian_to_spherical_points(double[:] xyz):
    cdef:
        Py_ssize_t s = xyz.size
        array[double] r_theta_phi, template = array('d')
        int i
        double xy
    r_theta_phi = clone(template, s, False)
    for i in range(0, s, 3):
        xy = xyz[i]*xyz[i] + xyz[i + 1]*xyz[i + 1]
        r_theta_phi[i] = sqrt(xy + xyz[i + 2]*xyz[i + 2])
        r_theta_phi[i + 1] = atan2(sqrt(xy), xyz[i + 2])
        r_theta_phi[i + 2] = __reduce_angle(atan2(xyz[i + 1], xyz[i]), center=False, positive=True)
    return r_theta_phi


def cartesian_to_spherical(xyz):
    """
    convert cartesian to spherical coordinates
    :param xyz: Cartesian coordinates (at least 3)
    :return: spherical coordinates r, theta, phi
    """
    if xyz.size <= 3:
        return np.asarray(__cartesian_to_spherical_point(xyz))
    else:
        if len(xyz.shape) == 2 and xyz.shape[1] == 3:
            return np.asarray(__cartesian_to_spherical_points(xyz.ravel())).reshape(xyz.shape)
        else:
            raise ValueError('N-points array shape must be (N, 3)')


@boundscheck(False)
@wraparound(False)
cdef double[:] __spherical_to_cartesian_point(double[:] r_theta_phi):
    cdef:
        Py_ssize_t s = r_theta_phi.size
        array[double] xyz, template = array('d')
        double xy
    if s < 3:
        r_theta_phi = __extend_vector_dimensions(r_theta_phi, 3)
    xyz = clone(template, 3, False)
    r_theta_phi[2] = __reduce_angle(r_theta_phi[2], center=False, positive=True)
    xy = r_theta_phi[0] * sin(r_theta_phi[1])
    xyz[0] = xy * cos(r_theta_phi[2])
    xyz[1] = xy * sin(r_theta_phi[2])
    xyz[2] = r_theta_phi[0] * cos(r_theta_phi[1])
    return xyz


@boundscheck(False)
@wraparound(False)
cdef double[:] __spherical_to_cartesian_points(double[:] r_theta_phi):
    cdef:
        Py_ssize_t s = r_theta_phi.size
        array[double] xyz, template = array('d')
        int i
        double xy
    xyz = clone(template, s, False)
    for i in range(0, s, 3):
        r_theta_phi[i + 2] = __reduce_angle(r_theta_phi[i + 2], center=False, positive=True)
        xy = r_theta_phi[i] * sin(r_theta_phi[i + 1])
        xyz[i] = xy * cos(r_theta_phi[i + 2])
        xyz[i + 1] = xy * sin(r_theta_phi[i + 2])
        xyz[i + 2] = r_theta_phi[i] * cos(r_theta_phi[i + 1])
    return xyz


def spherical_to_cartesian(r_theta_phi):
    """
    convert spherical to cartesian coordinates
    :param r_theta_phi: spherical coordinates (at least 3)
    :return: cartesian coordinates x, y, z
    """
    if r_theta_phi.size <= 3:
        return np.asarray(__spherical_to_cartesian_point(r_theta_phi))
    else:
        if len(r_theta_phi.shape) == 2 and r_theta_phi.shape[1] == 3:
            return np.asarray(__spherical_to_cartesian_points(r_theta_phi.ravel())).reshape(r_theta_phi.shape)
        else:
            raise ValueError('N-points array shape must be (N, 3)')


@boundscheck(False)
@wraparound(False)
cdef double[:] __cartesian_to_cylindrical_point(double[:] xyz):
    cdef:
        Py_ssize_t s = xyz.size
        array[double] rho_phi_z, template = array('d')
    if s < 3:
        xyz = __extend_vector_dimensions(xyz, 3)
    rho_phi_z = clone(template, 3, False)
    rho_phi_z[0] = sqrt(xyz[0] * xyz[0] + xyz[1] * xyz[1])
    rho_phi_z[1] = atan2(xyz[1], xyz[0])
    rho_phi_z[2] = xyz[2]
    return rho_phi_z


@boundscheck(False)
@wraparound(False)
cdef double[:] __cartesian_to_cylindrical_points(double[:] xyz):
    cdef:
        Py_ssize_t s = xyz.size
        array[double] rho_phi_z, template = array('d')
        int i
    rho_phi_z = clone(template, s, False)
    for i in range(0, s, 3):
        rho_phi_z[i] = sqrt(xyz[i] * xyz[i] + xyz[i + 1] * xyz[i + 1])
        rho_phi_z[i + 1] = atan2(xyz[i + 1], xyz[i])
        rho_phi_z[i + 2] = xyz[i + 2]
    return rho_phi_z


def cartesian_to_cylindrical(xyz):
    """
    convert cartesian to cylindrical coordinates
    :param xyz: cartesian coordinates (at least 3)
    :return: cylindrical coordinates rho, phi, z
    """
    if xyz.size <= 3:
        return np.asarray(__cartesian_to_cylindrical_point(xyz))
    else:
        if len(xyz.shape) == 2 and xyz.shape[1] == 3:
            return np.asarray(__cartesian_to_cylindrical_points(xyz.ravel())).reshape(xyz.shape)
        else:
            raise ValueError('N-points array shape must be (N, 3)')


@boundscheck(False)
@wraparound(False)
cdef double[:] __cylindrical_to_cartesian_point(double[:] rho_phi_z):
    cdef:
        Py_ssize_t s = rho_phi_z.size
        array[double] xyz, template = array('d')
    if s < 3:
        rho_phi_z = __extend_vector_dimensions(rho_phi_z, 3)
    xyz = clone(template, 3, False)
    rho_phi_z[1] = __reduce_angle(rho_phi_z[1], center=False, positive=True)
    xyz[0] = rho_phi_z[0] * cos(rho_phi_z[1])
    xyz[1] = rho_phi_z[0] * sin(rho_phi_z[1])
    xyz[2] = rho_phi_z[2]
    return xyz


@boundscheck(False)
@wraparound(False)
cdef double[:] __cylindrical_to_cartesian_points(double[:] rho_phi_z):
    cdef:
        Py_ssize_t s = rho_phi_z.size
        array[double] xyz, template = array('d')
        int i
    if s < 3:
        rho_phi_z = __extend_vector_dimensions(rho_phi_z, 3)
    xyz = clone(template, s, False)
    for i in range(0, s, 3):
        rho_phi_z[i + 1] = __reduce_angle(rho_phi_z[i + 1], center=False, positive=True)
        xyz[i] = rho_phi_z[i] * cos(rho_phi_z[i + 1])
        xyz[i + 1] = rho_phi_z[i] * sin(rho_phi_z[i + 1])
        xyz[i + 2] = rho_phi_z[i + 2]
    return xyz


def cylindrical_to_cartesian(rho_phi_z):
    """
    convert cylindrical to cartesian coordinates
    :param rho_phi_z: cylindrical coordinates (at least 3)
    :return: cartesian coordinates x, y, z
    """
    if rho_phi_z.size <= 3:
        return np.asarray(__cylindrical_to_cartesian_point(rho_phi_z))
    else:
        if len(rho_phi_z.shape) == 2 and rho_phi_z.shape[1] == 3:
            return np.asarray(__cylindrical_to_cartesian_points(rho_phi_z.ravel())).reshape(rho_phi_z.shape)
        else:
            raise ValueError('N-points array shape must be (N, 3)')


@boundscheck(False)
@wraparound(False)
cdef double[:] __spherical_to_cylindrical_point(double[:] r_theta_phi):
    cdef:
        Py_ssize_t s = r_theta_phi.size
        array[double] rho_phi_z, template = array('d')
    if s < 3:
        r_theta_phi = __extend_vector_dimensions(r_theta_phi, 3)
    rho_phi_z = clone(template, 3, False)
    rho_phi_z[0] = r_theta_phi[0] * sin(r_theta_phi[1])
    rho_phi_z[1] = r_theta_phi[2]
    rho_phi_z[2] = r_theta_phi[0] * cos(r_theta_phi[1])
    return rho_phi_z


@boundscheck(False)
@wraparound(False)
cdef double[:] __spherical_to_cylindrical_points(double[:] r_theta_phi):
    cdef:
        Py_ssize_t s = r_theta_phi.size
        array[double] rho_phi_z, template = array('d')
        int i
    rho_phi_z = clone(template, s, False)
    for i in range(0, s, 3):
        rho_phi_z[i] = r_theta_phi[i] * sin(r_theta_phi[i + 1])
        rho_phi_z[i + 1] = r_theta_phi[i + 2]
        rho_phi_z[i + 2] = r_theta_phi[i] * cos(r_theta_phi[i + 1])
    return rho_phi_z



def spherical_to_cylindrical(r_theta_phi):
    """
    convert spherical to cylindrical coordinates
    :param r_theta_phi: spherical coordinates (at least 3)
    :return: cylindrical coordinates rho, phi, z
    """
    if r_theta_phi.size <= 3:
        return np.asarray(__spherical_to_cylindrical_point(r_theta_phi))
    else:
        if len(r_theta_phi.shape) == 2 and r_theta_phi.shape[1] == 3:
            return np.asarray(__spherical_to_cylindrical_points(r_theta_phi.ravel())).reshape(r_theta_phi.shape)
        else:
            raise ValueError('N-points array shape must be (N, 3)')


@boundscheck(False)
@wraparound(False)
cdef double[:] __cylindrical_to_spherical_point(double[:] rho_phi_z):
    cdef:
        Py_ssize_t s = rho_phi_z.size
        array[double] r_theta_phi, template = array('d')
    if s < 3:
        rho_phi_z = __extend_vector_dimensions(rho_phi_z, 3)
    r_theta_phi = clone(template, 3, False)
    r_theta_phi[0] = sqrt(rho_phi_z[0] * rho_phi_z[0] + rho_phi_z[2] * rho_phi_z[2])
    r_theta_phi[1] = atan2(rho_phi_z[0], rho_phi_z[2])
    r_theta_phi[2] = rho_phi_z[1]
    return r_theta_phi


@boundscheck(False)
@wraparound(False)
cdef double[:] __cylindrical_to_spherical_points(double[:] rho_phi_z):
    cdef:
        Py_ssize_t s = rho_phi_z.size
        array[double] r_theta_phi, template = array('d')
        int i
    r_theta_phi = clone(template, s, False)
    for i in range(0, s, 3):
        r_theta_phi[i] = sqrt(rho_phi_z[i] * rho_phi_z[i] + rho_phi_z[i + 2] * rho_phi_z[i + 2])
        r_theta_phi[i + 1] = atan2(rho_phi_z[i], rho_phi_z[i + 2])
        r_theta_phi[i + 2] = rho_phi_z[i + 1]
    return r_theta_phi


def cylindrical_to_spherical(rho_phi_z):
    """
    convert spherical to cylindrical coordinates
    :param rho_phi_z: cylindrical coordinates (at least 3)
    :return: spherical coordinates r, theta, phi
    """
    if rho_phi_z.size <= 3:
        return np.asarray(__cylindrical_to_spherical_point(rho_phi_z))
    else:
        if len(rho_phi_z.shape) == 2 and rho_phi_z.shape[1] == 3:
            return np.asarray(__cylindrical_to_spherical_points(rho_phi_z.ravel())).reshape(rho_phi_z.shape)
        else:
            raise ValueError('N-points array shape must be (N, 3)')
