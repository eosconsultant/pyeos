import json
from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.map cimport map
from eostypes_ cimport *
#import eostypes_
from typing import Dict, Tuple, List

cdef extern from "<fc/log/logger.hpp>":
    void ilog(char *log)

cdef extern from "eosapi_.hpp":
    ctypedef int bool
    void quit_app_()
    
    object get_info_ ()
    object get_block_(char *num_or_id)
    object get_account_(char *name)
    object get_accounts_(char *public_key)
    int create_account_(string creator, string newaccount, string owner, string active, int sign,string& result)
    object get_controlled_accounts_(char *account_name);
    object create_key_()

    int get_transaction_(string& id,string& result);
    int get_transactions_(string& account_name,int skip_seq,int num_seq,string& result);
    
    int transfer_(string& sender,string& recipient,int amount,string memo,bool sign,string& result);
    int push_message_(string& contract,string& action,string& args,vector[string] scopes,map[string,string]& permissions,bool sign,string& ret);
    int set_contract_(string& account,string& wastPath,string& abiPath,int vmtype,bool sign,string& result);
    int get_code_(string& name,string& wast,string& abi,string& code_hash,int& vm_type);
    int get_table_(string& scope,string& code,string& table,string& result);

    int setcode_(char *account_,char *wast_file,char *abi_file,char *ts_buffer,int length) 
    int exec_func_(char *code_,char *action_,char *json_,char *scope,char *authorization,char *ts_result,int length)

class JsonStruct:
    def __init__(self, js):
        if isinstance(js,bytes):
            js = js.decode('utf8')
            js = json.loads(js)
            if isinstance(js,str):
                js = json.loads(js)
        for key in js:
            value = js[key]
            if isinstance(value,dict):
                self.__dict__[key] = JsonStruct(value)
            elif isinstance(value,list):
                for i in range(len(value)):
                    v = value[i]
                    if isinstance(v,dict):
                        value[i] = JsonStruct(v)
                self.__dict__[key] = value
            else:
                self.__dict__[key] = value
    def __str__(self):
        return str(self.__dict__)
    def __repr__(self):
        return str(self.__dict__)
    
def toobject(bstr):
    return JsonStruct(bstr)

def tobytes(ustr:str):
    if type(ustr) == str:
        ustr = bytes(ustr,'utf8')
    return ustr

def get_info():
    info = get_info_()
    return JsonStruct(info)

def get_block(id:str)->str:
    if type(id) == int:
        id = bytes(id)
    if type(id) == str:
        id = bytes(id,'utf8')
    return get_block_(id)

def get_account(name:str):
    if isinstance(name,str):
        name = bytes(name,'utf8')
    result = get_account_(name)
    return JsonStruct(result)

def get_accounts(public_key:str)->List[str]:
    if type(public_key) == str:
        public_key = bytes(public_key,'utf8')
    return get_accounts_(public_key)

def get_controlled_accounts(account_name:str)->List[str]:
    if type(account_name) == str:
        account_name = bytes(account_name,'utf8')

    return get_controlled_accounts_(account_name);

def create_account(creator:str,newaccount:str,owner_key:str,active_key:str,sign=True)->str:
    cdef string result
    if type(creator) == str:
        creator = bytes(creator,'utf8')
    
    if type(newaccount) == str:
        newaccount = bytes(newaccount,'utf8')
    
    if type(owner_key) == str:
        owner_key = bytes(owner_key,'utf8')
    
    if type(active_key) == str:
        active_key = bytes(active_key,'utf8')
    if sign:
        sign = 1
    else:
        sign = 0

    if 0 == create_account_(creator,newaccount,owner_key,active_key, sign,result):
        return JsonStruct(result)
    return None

def create_key():
    cdef string pub
    cdef string priv
    key = create_key_()
    return JsonStruct(key)

def get_transaction(id:str)->str:
    cdef string result
    if type(id) == int:
        id = str(id)
    id = tobytes(id)
    if 0 == get_transaction_(id,result):
        return JsonStruct(result)
    return None

def get_transactions(account_name:str,skip_seq:int,num_seq:int)->str:
    cdef string result
    account_name = tobytes(account_name)
    if 0 == get_transactions_(account_name,skip_seq,num_seq,result):
        return result
    return None

def transfer(sender:str,recipient:str,int amount,memo:str,sign)->str:
    cdef string result
    sender = tobytes(sender)
    recipient = tobytes(recipient)
    memo = tobytes(memo)
    if sign:
        sign = 1
    else:
        sign = 0
    if 0 == transfer_(sender,recipient,amount,memo,sign,result):
        return result
    return None

def push_message(contract:str,action:str,args:str,scopes:List[str],permissions:Dict,sign):
    cdef string ret
    cdef vector[string] scopes_;
    cdef map[string,string] permissions_;
    contract = tobytes(contract)
    action = tobytes(action)
    args = tobytes(args)
    
    for scope in scopes:
        scopes_.push_back(tobytes(scope))
    for per in permissions:
        key = permissions[per]
        per = tobytes(per)
        key = tobytes(key)
        permissions_[per] = key

    if sign:
        sign = 1
    else:
        sign = 0

    if 0 == push_message_(contract,action,args,scopes_,permissions_,sign,ret):
        return JsonStruct(ret)
    return None

def set_contract(account:str,wast_file:str,abi_file:str,vmtype:int,sign)->str:
    cdef string result
    ilog("set_contract.....");
    account = tobytes(account)
    wast_file = tobytes(wast_file)
    abi_file = tobytes(abi_file)
    if sign:
        sign = 1
    else:
        sign = 0

    if 0 == set_contract_(account,wast_file,abi_file,vmtype,sign,result):
        return JsonStruct(result)
    return None

def get_code(name:str):
    cdef string wast
    cdef string abi
    cdef string code_hash
    cdef int vm_type
    name = tobytes(name)
    vm_type = 0
    if 0 == get_code_(name,wast,abi,code_hash,vm_type):
        return [wast,abi,code_hash,vm_type]
    return []

def get_table(scope,code,table):
    cdef string result
    scope = tobytes(scope)
    code = tobytes(code)
    table = tobytes(table)

    if 0 == get_table_(scope,code,table,result):
        return JsonStruct(result)
    return None

def exec_func(code_:str,action_:str,json_:str,scope_:str,authorization_:str)->str:
    pass

def quit_app():
    quit_app_();

import signal
import sys
import time
app_quit = False
def signal_handler(signal, frame):
    global app_quit
    if app_quit:
        sys.exit(0)
        return
    print('shutting down... you should wait for database closed successfully,\nthen press Ctrl+C again to exit application!sorry about that.')
    quit_app()
    app_quit = True
    
#    while not app_isshutdown_():
#        time.sleep(0.2) # wait for app shutdown
#    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)



import sys
from importlib.abc import Loader, MetaPathFinder
from importlib.util import spec_from_file_location

class CodeLoader(Loader):
    def __init__(self,code):
        self.code = code
    def create_module(self, spec):
        return None # use default module creation semantics
    def exec_module(self, module):
        exec(self.code, vars(module))

class MetaFinder(MetaPathFinder):
    def find_spec(self, contract_name, path, target=None):
        print(contract_name,path,target)
        code = get_code(contract_name)
        if not code:
            return None
        if code[-1] != 1:
            return None
        return spec_from_file_location(contract_name, None, loader=CodeLoader(code[0]),submodule_search_locations=None)

def install():
    sys.meta_path.insert(0, MetaFinder())

'''
cdef class PyMessage:
    cdef Message* msg      # hold a C++ instance which we're wrapping
    def __cinit__(self,code,funcName,authorization,data):
#        cdef AccountName code_
#        cdef FuncName funcName_
        cdef Vector[AccountPermission] authorization_
        cdef Bytes data_
        for a in authorization:
            account = bytes(a[0],'utf8')
            permission = bytes(a[1],'utf8')
            authorization_.push_back(AccountPermission(Name(account),Name(permission)))
        for d in bytearray(data,'utf8'):
            data_.push_back(<char>d)
        self.msg = new Message(AccountName(bytes(code,'utf8')),FuncName(bytes(funcName,'utf8')),authorization_,data_)
    def __dealloc__(self):
        del self.msg
'''
