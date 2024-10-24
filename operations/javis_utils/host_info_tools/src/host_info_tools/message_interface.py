"""
Author: Josh Spisak <jspisak@andrew.cmu.edu>
Date: 8/26/2021
Description: a quick, lightweight network protocol
"""
import sys
import math
import json
import time
import ifcfg
import socket
import _thread

out_stream = sys.stderr

MESSAGE_DELIM = "!{!}!"

class Message():
    HANDSHAKE = 0
    LIST_RQST = 1
    HOST_LIST = 2

    # Used to request a host ID
    HOST_ID_RQST = 5
    HOST_ID = 6

    # Used to get host info
    HOST_PARAMS_RQST = 7
    HOST_PARAMS = 8
    HOST_PARAMS_SET_RQST = 9
    HOST_PARAMS_SET = 10

    # Interface to reload host info
    RELOAD_PARAMS_RQST = 11
    INVALIDATE_PARAMS_CACHE = 12

    # Get a remote hosts current time
    HOST_TIME_RQST = 13
    HOST_TIME = 14


def deserialize_message(data):
    buffer_after = bytes("", 'utf-8')
    cur_msg_data = None
    dd = data.decode('utf-8')
    if MESSAGE_DELIM in dd:
        parts = dd.split(MESSAGE_DELIM)
        cur_msg_data = parts[0]
        if len(parts) > 2 or len(parts[1]) > 0:
            for i in range(1, len(parts)):
                if len(parts[i]) == 0:
                    continue
                buffer_after +=  bytes(parts[i] + MESSAGE_DELIM, 'utf-8')
    else:
        return None, None, data

    msg = json.loads(cur_msg_data)
    return msg["type"], msg["payload"], buffer_after

def serialize_message(type, payload):
    header = {
        "type": type,
        "payload": payload
    }
    return bytes(json.dumps(header) + MESSAGE_DELIM, 'utf-8')

def create_handshake(ip):
    return serialize_message(Message.HANDSHAKE,
    {
        "ip": ip
    })

def create_listing_request():
    return serialize_message(Message.LIST_RQST, {})

def create_host_list(host_list):
    return serialize_message(Message.HOST_LIST, host_list)

def create_host_id_rqst():
    return serialize_message(Message.HOST_ID_RQST, {})

def create_host_id(host_name):
    return serialize_message(Message.HOST_ID, host_name)

def create_host_params_rqst(param_name = None):
    return serialize_message(Message.HOST_PARAMS_RQST, {"param_name": param_name})

def create_host_params(info):
    return serialize_message(Message.HOST_PARAMS, info)

def create_host_params_set_rqst(param_name, param_value):
    return serialize_message(Message.HOST_PARAMS_SET_RQST, {"param_name": param_name, "param_value": param_value})

def create_host_params_set(success, value, message):
    return serialize_message(Message.HOST_PARAMS_SET, {"success": success, "value": value, "message": message})

def create_reload_params_rqst():
    return serialize_message(Message.RELOAD_PARAMS_RQST, {})

def create_invalidate_params_cache():
    return serialize_message(Message.INVALIDATE_PARAMS_CACHE, {})

def create_host_time_rqst():
    return serialize_message(Message.HOST_TIME_RQST, {})

def create_host_time(current_time = None):
    if current_time is None:
        current_time = time.time()
    return serialize_message(Message.HOST_TIME, {"current_time": current_time})

class MessageBuffer():
    def __init__(self, sock, timeout = 0.1, receive_buffer_size = 1024, msg_queue_size = 1, multicast = False):
        self.sock = sock
        self.buffer = bytes('', "utf-8")
        self.multicast_buffers = {}
        self.receive_buffer_size = receive_buffer_size
        self.timeout = timeout
        self.messages = {}
        self.msg_queue_size = msg_queue_size
        self.multicast = multicast

        self.message_callbacks = {}
    
    def receiveData(self):
        self.sock.settimeout(self.timeout)
        try:
            if self.multicast:
                buffer, source_ip = self.sock.recvfrom(self.receive_buffer_size)
                if len(buffer) == 0:
                    raise Exception("Disconnected")
                if source_ip not in self.multicast_buffers:
                    self.multicast_buffers[source_ip] = bytes('', "utf-8")
                self.multicast_buffers[source_ip] += buffer
            else:
                self.buffer += self.sock.recv(self.receive_buffer_size)
                if len(self.buffer) == 0:
                    raise Exception("Disconnected")
        except socket.timeout:
            pass

    def processBuffer(self, buffer, buffer_source = None):
        msg_type, payload, buffer = deserialize_message(buffer)
        if msg_type is not None:
            if msg_type in self.message_callbacks:
                if buffer_source is not None:
                    self.message_callbacks[msg_type](msg_type, payload, buffer_source)
                else:
                    self.message_callbacks[msg_type](msg_type, payload)
            if len(self.message_callbacks) <= 0:
                if msg_type not in self.messages:
                    self.messages[msg_type] = []
                if len(self.messages[msg_type]) < self.msg_queue_size:
                    self.messages[msg_type].append(payload)
        return buffer

    def process(self):
        self.receiveData()
        if self.multicast:
            for source_ip in self.multicast_buffers.keys():
                self.multicast_buffers[source_ip] = self.processBuffer(self.multicast_buffers[source_ip], source_ip)
        else:
            self.buffer = self.processBuffer(self.buffer)

    def getMessage(self, msg_type):
        if msg_type in self.messages:
            if len(self.messages[msg_type]) > 0:
                msg = self.messages[msg_type].pop(0)
                if len(self.messages[msg_type]) == 0:
                    self.messages.pop(msg_type)
                return msg
        return None

    def waitForMessage(self, msg_type, timeout = 1.0):
        start = time.time()
        while math.fabs(time.time() - start) < timeout:
            self.process()
            res = self.getMessage(msg_type)
            if res is not None:
                return res
        return None
    
    def setMessageCallback(self, msg_type, callback):
        if callback is None:
            self.message_callbacks.pop(msg_type)
        self.message_callbacks[msg_type] = callback


class Server():
    @staticmethod
    def get_iface_from_ip(ipaddr):
        interfaces = ifcfg.interfaces()
        local = None
        for iface in interfaces:
            if interfaces[iface]["inet"] == "127.0.0.1":
                local = iface
            if interfaces[iface]["inet"] == ipaddr:
                return iface
        if ipaddr == "127.0.1.1" and local is not None:
            return local
        raise Exception("Unable to identify interface.")

    @staticmethod
    def server_connection_handler(sock, client_address, host_database):
        myaddr = sock.getsockname()[0]
        iface = Server.get_iface_from_ip(myaddr)
        print("INFO: Server connected to %s over %s"%(client_address[0], iface), file=out_stream)
        sock.send(create_handshake(client_address))

        handshake = False
        def handshake_handler(msg_type, payload):
            handshake = True
        def list_rqst_handler(msg_type, payload):
            new_msg = host_database.getHostListings()
            sock.send(create_host_list(new_msg))
        def host_params_rqst_hander(msg_type, payload):
            params = host_database.getLocalParams(payload["param_name"])
            sock.send(create_host_params(params))
        def host_params_set_rqst_handler(msg_type, payload):
            try:
                host_database.setLocalParam(payload["param_name"], payload["param_value"])
                sock.send(create_host_params_set(True, payload["param_value"], "Successfully set param [%s]"%(payload["param_name"])))
            except Exception as err:
                sock.send(create_host_params_set(False, None, "Error: %s"%(str(err))))
        def request_param_reload_handler(msg_type, payload):
            host_database.local_host.reloadConstParams()
        def invalidate_cache_handler(msg_type, payload):
            host_database.invalidateParamsCache()
        def time_request_handler(msg_type, payload):
            sock.send(create_host_time())

        message_queue = MessageBuffer(sock, timeout = 10.0)
        message_queue.setMessageCallback(Message.HANDSHAKE, handshake_handler)
        message_queue.setMessageCallback(Message.LIST_RQST, list_rqst_handler)
        message_queue.setMessageCallback(Message.HOST_PARAMS_RQST, host_params_rqst_hander)
        message_queue.setMessageCallback(Message.HOST_PARAMS_SET_RQST, host_params_set_rqst_handler)
        message_queue.setMessageCallback(Message.RELOAD_PARAMS_RQST, request_param_reload_handler)
        message_queue.setMessageCallback(Message.INVALIDATE_PARAMS_CACHE, invalidate_cache_handler)
        message_queue.setMessageCallback(Message.HOST_TIME_RQST, time_request_handler)
        while True:
            try:
                message_queue.process()
            except Exception as err:
                print("WARN: Disconnected from %s: %s"%(client_address[0], str(err)), file=out_stream)
                break

    def __init__(self, host_address, host_port, host_database):
        self.host_address = host_address
        self.host_port = host_port
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind((host_address, host_port))
        self.host_database = host_database


    def listen(self, placeholder = "placeholder"):
        print("INFO: HIS listening on  %s:%d"%(self.host_address, self.host_port), file=out_stream)
        self.server_socket.listen(5)

        while True:
            connection, client_address = self.server_socket.accept()
            _thread.start_new_thread(Server.server_connection_handler,(connection, client_address, self.host_database))

    def spawn_listen_thread(self):
        """
        Spawns a thread to broadcast on a certain interval
        """
        _thread.start_new_thread(Server.listen,(self, None))

class Client():
    def __init__(self, address, port):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        self.sock.connect((address, port))
        self.sock.send(create_handshake(address))

        self.message_queue = MessageBuffer(self.sock)
        msg = self.message_queue.waitForMessage(Message.HANDSHAKE, timeout = 0.1)
        if msg is None:
            raise Exception("Did not receive heartbeat :(")

    def close(self):
        self.sock.close()

    def getHostList(self):
        tries = 3
        while tries > 0:
            self.sock.send(create_listing_request())
            resp = self.message_queue.waitForMessage(Message.HOST_LIST, 0.1)
            if resp is not None:
                return resp
            tries -= 1
        raise Exception("Disconnected or something :(")

    def getParams(self, param_name = None):
        tries = 3
        while tries > 0:
            self.sock.send(create_host_params_rqst(param_name))
            resp = self.message_queue.waitForMessage(Message.HOST_PARAMS, 0.1)
            if resp is not None:
                return resp
            tries -= 1
        raise Exception("Disconnected or something :(")

    def setParam(self, name, value):
        tries = 3
        while tries > 0:
            self.sock.send(create_host_params_set_rqst(name, value))
            resp = self.message_queue.waitForMessage(Message.HOST_PARAMS_SET, 0.1)
            if resp is not None:
                return resp
            tries -= 1
        raise Exception("Disconnected or something :(")

    def requestParamsReload(self):
        self.sock.send(create_reload_params_rqst())

    def invalidateParamsCache(self):
        self.sock.send(create_invalidate_params_cache())

    def getHostTime(self):
        tries = 3
        while tries > 0:
            self.sock.send(create_host_time_rqst())
            resp = self.message_queue.waitForMessage(Message.HOST_TIME, 0.1)
            if resp is not None:
                return resp["current_time"]
            tries -= 1
        raise Exception("Disconnected or something :(")
