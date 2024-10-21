"""
Author: Josh Spisak <jspisak@andrew.cmu.edu>
Date: 8/26/2021
Description: stores information on various hosts that have been interacted with
"""
import os
import sys
import time
import math
import json
import ifcfg
import threading
import hashlib
import dotenv
import _thread

def load_files(files):
    def merge_config(config_base, config_top):
        for k in config_base:
            if k not in config_top:
                config_top[k] = config_base[k]
        return config_top

    host_info = {}
    for file in files:
        if not os.path.exists(file):
            print("[WARN]: unale to load file [%s]"%file, file=sys.stderr)
        ending = os.path.splitext(file)[1]
        try:
            if ending == ".conf" or ending == ".env":
                new_info = dotenv.dotenv_values(file)
                host_info = merge_config(new_info, host_info)
            ## Currently can't load yaml files...
            # elif ending == ".yaml" or ending == ".yaml":
            #     with open(file, 'r') as f:
            #         new_info = yaml.load(f)
            #         host_info = merge_config(new_info, host_info)
            else:
                raise Exception("Unknown config type [%s]"%(ending))
        except Exception as err:
            print("[WARN] unable to load file [%s]: %s"%(file, str(err)), file=sys.stderr)
    return host_info

class LocalHostInfo():
    def __init__(self, hostname, const_param_files = []):
        self.hostname = hostname
        self.const_params = load_files(const_param_files)
        self.const_param_files = const_param_files
        self.params = {}
        self.param_mutex = threading.Lock()

    def deconflictParams(self):
        for k in self.const_params:
            if k in self.params:
                self.params.pop(k)

    def reloadConstParams(self):
        self.param_mutex.acquire()
        self.const_params = load_files(self.const_param_files)
        for k in self.const_params:
            if k in self.params:
                self.params.pop(k)
        self.param_mutex.release()
        print("WARN: loading info from file, params are now: %s"%str(self.getParams()), file=sys.stderr)

    def getParams(self, include_const = True):
        self.param_mutex.acquire()
        params_result = {}
        for k in self.params:
            params_result[k] = self.params[k]
        if include_const:
            for k in self.const_params:
                params_result[k] = self.const_params[k]
        self.param_mutex.release()
        return params_result

    def setParam(self, name, value):
        self.param_mutex.acquire()
        if name in self.const_params:
            self.param_mutex.release()
            raise Exception("Cannot set [%s] to [%s], const parameter."%(name, str(value)))
        if value is None:
            self.params.pop(name)
        else:
            self.params[name] = value
        self.param_mutex.release()

    def serialize(self):
        return {
            "hostname": self.hostname,
            "ip_addr": "127.0.1.1",
            "last_update": time.time(),
            "params": self.getParams()
        }

class HostDatabase():
    class HostInfo():
        def serialize(self):
            return {
                "hostname": self.hostname,
                "ip_addr": self.ip_addr,
                "last_update": self.last_update,
                "params": self.params
            }
        hostname = None
        ip_addr = None
        last_update = None
        params = None
        old = None

    def __init__(self, local_hostname, const_param_files = [], cache_file = None, cache_timeout=-1.0):
        self.local_host = LocalHostInfo(local_hostname, const_param_files)
        self.host_lists = {}
        self.cache_file = cache_file
        self.mutex = threading.Lock()

        now = time.time()
        try:
            if cache_file is not None and os.path.exists(cache_file):
                host_listing = []
                with open(cache_file, "r") as f:
                    data = json.loads(f.read())
                    if "host_listing" in data:
                        host_listing = data["host_listing"]
                    if "local_parameters" in data:
                        self.local_host.params = data["local_parameters"]
                        self.local_host.deconflictParams()

                for host in host_listing:
                    if math.fabs(now - host["last_update"]) > cache_timeout:
                        continue
                    nh = HostDatabase.HostInfo()
                    nh.hostname = host["hostname"]
                    nh.ip_addr = host["ip_addr"]
                    nh.last_update = host["last_update"]
                    nh.params = host["params"]
                    nh.old = True
                    self.host_lists[nh.hostname] = nh
                    print("INFO: Loaded %s from cache."%nh.hostname, file=sys.stderr)
        except Exception as err:
            print("ERR: unable to load cache file %s: %s"%(cache_file, str(err)), file=sys.stderr)

    def invalidateParamsCache(self):
        print("WARN: invalidating cache", file=sys.stderr)
        self.mutex.acquire()
        for host in self.host_lists:
            self.host_lists[host].old = True
        self.mutex.release()

    def getLocalParams(self, name = None):
        params = self.local_host.getParams()
        if name is None:
            return params
        elif name in params:
            return {name: params[name]}
        else:
            return {}
    
    def setLocalParam(self, name, value):
        print("INFO: attempting to set %s to %s"%(name, str(value)))
        self.local_host.setParam(name, value)
        self.cache()

    def wantsParamDump(self, hostname):
        res = False
        self.mutex.acquire()
        if hostname not in self.host_lists:
            res = True
        else:
            res = self.host_lists[hostname].old
        self.mutex.release()
        return res

    def updateHost(self, hostname, ip_addr, update_time, params, force = False):
        """
        This function assumes the mutex is held and doesn't try to claim it!
        """
        self.mutex.acquire()
        try:
            if hostname not in self.host_lists:
                entry = HostDatabase.HostInfo()
                entry.hostname = hostname
                entry.ip_addr = ip_addr
                entry.last_update = time.time()
                entry.params = params
                entry.old = False
                self.host_lists[hostname] = entry
            else:
                entry = self.host_lists[hostname]
                if force or entry.last_update < update_time:
                    entry.last_update = update_time
                    if entry.ip_addr != ip_addr:
                        print("WARN: Host [%s] ip changed from [%s] to [%s]"%(hostname, entry.ip_addr, ip_addr), file=sys.stderr)
                        entry.ip_addr = ip_addr
            if params is not None:
                entry.params = params
                entry.old = False
        except Exception as err:
            print("ERROR: unable to update host - %s"%(str(err)), file=sys.stderr)
        self.mutex.release()

    def processHostID(self, host_id, ip_addr, params=None):
        """
        Handles when a HOST_ID message is received
        """
        return self.updateHost(host_id, ip_addr, time.time(), params, force=True)

    def getHostListings(self, ignore_self = False):
        """
        Generate serialized list of hosts / update_times / hash
        """
        listings = []
        self.mutex.acquire()
        try:
            for host in self.host_lists:
                listings.append(self.host_lists[host].serialize())
            if self.local_host is not None and not ignore_self:
                listings.append(self.local_host.serialize())

        except Exception as err:
            self.mutex.release()
            raise err

        self.mutex.release()
        return listings

    def cache(self):
        print("INFO: Caching to %s"%self.cache_file, file=sys.stderr)
        with open(self.cache_file, "w+") as f:
            data = {}
            data["local_parameters"] = self.local_host.getParams(include_const = False)
            data["host_listing"] = self.getHostListings(ignore_self = True)
            f.write(json.dumps(data))

    def cacheOnInterval(self,cache_interval = 10.):
        while True:
            self.cache()
            time.sleep(cache_interval)

    def spawn_cache_thread(self, cache_interval = 10.):
        """
        Spawns a thread to broadcast on a certain interval
        """
        _thread.start_new_thread(HostDatabase.cacheOnInterval,(self, cache_interval))