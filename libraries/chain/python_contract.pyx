from libcpp.string cimport string
from libcpp.vector cimport vector
import imp
import logging as log
cdef extern from "":
    ctypedef unsigned long long uint64_t
    int PyGILState_GetThisThreadState() nogil
    int PyGILState_Check() nogil
    ctypedef int PyGILState_STATE
    PyGILState_STATE PyGILState_Ensure() nogil 
    void PyGILState_Release(PyGILState_STATE state) nogil

cdef extern from "<fc/log/logger.hpp>":
    void ilog(string& str)
    
#from typing import Dict, Tuple, List

code_map = {}

cdef extern int python_load(string& name,string& code) with gil:
    global code_map
    cdef PyGILState_STATE state
    cdef int ret
    ret = 0
    module = code_map.get(name)
    cdef bytes code_ = code
    if not module or (module.__code != code_):
        try:
            new_module = imp.new_module(str(name))
            exec(code,vars(new_module))
            code_map[name] = new_module
            new_module.__code = code
        except Exception as e:
            log.exception(e)
            ret = -1
    return ret;

cdef extern int python_call(string& name,string& function,vector[uint64_t] args) with gil:
    global code_map
    cdef PyGILState_STATE state
    cdef int ret
    ret = -1
    func = function
    func = func.decode('utf8')
    try:
        module = code_map[name]
        func = getattr(module,func)
        func(*args)
        ret = 0
    except Exception as e:
        log.exception(e)