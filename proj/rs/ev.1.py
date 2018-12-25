import os, sys, json, paramiko, threading, gevent
from gevent import monkey
monkey.patch_all()
from gevent.queue import Queue
from web3 import Web3
from web3.middleware import geth_poa_middleware
from pymongo import MongoClient
from retry import retry

nodes = {}
interval = 1
w3 = None
db = None
contract = None
blk_filter = None
tx_filter = None
'''
settings = {
    "host": '127.0.0.1',
    "port": 27017,
    "dbname": "test",
    "setname": "tc",
    "username": "tester",
    "passwd": "123",
}
'''

settings = {
    "host": '172.16.201.189',
    "port": 27017,
    "dbname": "rs",
    "setname": "user",
    "username": "test",
    "passwd": "test",
}
# mongo --port 27017 -u "test" -p "test" --authenticationDatabase "rs"
# mongod --shutdown --dbpath /root/data

pbs = Queue()  # 待写入区块
pts = Queue()  # 待写入交易
fts = Queue()  # 写入失败交易
pas = Queue()  # 待同步地址


class User:
    def __init__(self, addr, uid, eid, uhash, level, timestamp, status, mid, txhash):
        self.addr = addr
        self.uid = uid
        self.eid = eid
        self.uhash = uhash
        self.level = level
        self.timestamp = timestamp
        self.status = status
        self.mid = mid
        self.txhash = txhash

    def __str__(self):
        return str({
            "addr": self.addr,
            "uid": self.uid,
            "eid": self.eid,
            "uhash": self.uhash,
            "level": self.level,
            "timestamp": self.timestamp,
            "status": self.status,
            "mid": self.mid,
            "txhash": self.txhash
        })

    def show(self):
        return {
            "addr": self.addr,
            "uid": self.uid,
            "eid": self.eid,
            "uhash": self.uhash,
            "level": self.level,
            "timestamp": self.timestamp,
            "status": self.status,
            "mid": self.mid,
            "txhash": self.txhash
        }


class Item:
    def __init__(self, iid, tid, uperid, userid, xhash, shash, ihash, cipher, ikey, iopen, level, timestamp, status, mid, txhash):
        self.iid = iid
        self.tid = tid
        self.uperid = uperid
        self.userid = userid
        self.xhash = xhash
        self.shash = shash
        self.ihash = ihash
        self.cipher = cipher
        self.ikey = ikey
        self.iopen = iopen
        self.level = level
        self.timestamp = timestamp
        self.status = status
        self.mid = mid
        self.txhash = txhash

    def __str__(self):
        return str({
            "iid": self.iid,
            "tid": self.tid,
            "uperid": self.uperid,
            "userid": self.userid,
            "xhash": self.xhash,
            "shash": self.shash,
            "ihash": self.ihash,
            "cipher": self.cipher,
            "ikey": self.ikey,
            "iopen": self.iopen,
            "level": self.level,
            "timestamp": self.timestamp,
            "status": self.status,
            "mid": self.mid,
            "txhash": self.txhash
        })

    def show(self):
        return {
            "iid": self.iid,
            "tid": self.tid,
            "uperid": self.uperid,
            "userid": self.userid,
            "xhash": self.xhash,
            "shash": self.shash,
            "ihash": self.ihash,
            "cipher": self.cipher,
            "ikey": self.ikey,
            "iopen": self.iopen,
            "level": self.level,
            "timestamp": self.timestamp,
            "status": self.status,
            "mid": self.mid,
            "txhash": self.txhash
        }


class Perm:
    def __init__(self, pid, tid, sgerid, userid, itemid, phash, device, pmark, prvs, ptime, ptimes, pslice, ptimestamp, ptype,
                 status, mid, txhash):
        self.pid = pid
        self.tid = tid
        self.sgerid = sgerid
        self.userid = userid
        self.itemid = itemid
        self.phash = phash
        self.device = device
        self.pmark = pmark
        self.prvs = prvs
        self.ptime = ptime
        self.ptimes = ptimes
        self.pslice = pslice
        self.ptimestamp = ptimestamp
        self.ptype = ptype
        self.status = status
        self.mid = mid
        self.txhash = txhash

    def __str__(self):
        return str({
            "pid": self.pid,
            "tid": self.tid,
            "sgerid": self.sgerid,
            "userid": self.userid,
            "itemid": self.itemid,
            "phash": self.phash,
            "device": self.device,
            "pmark": self.pmark,
            "prvs": self.prvs,
            "ptime": self.ptime,
            "ptimes": self.ptimes,
            "pslice": self.pslice,
            "ptimestamp": self.ptimestamp,
            "ptype": self.ptype,
            "status": self.status,
            "mid": self.mid,
            "txhash": self.txhash
        })

    def show(self):
        return {
            "pid": self.pid,
            "tid": self.tid,
            "sgerid": self.sgerid,
            "userid": self.userid,
            "itemid": self.itemid,
            "phash": self.phash,
            "device": self.device,
            "pmark": self.pmark,
            "prvs": self.prvs,
            "ptime": self.ptime,
            "ptimes": self.ptimes,
            "pslice": self.pslice,
            "ptimestamp": self.ptimestamp,
            "ptype": self.ptype,
            "status": self.status,
            "mid": self.mid,
            "txhash": self.txhash
        }


class Log:
    def __init__(self, sn, userid, itemid, perms, operate, senderid, sender, duration, timestamp, details, mid, txhash):
        self.sn = sn
        self.userid = userid
        self.itemid = itemid
        self.perms = perms
        self.operate = operate
        self.senderid = senderid
        self.sender = sender
        self.duration = duration
        self.timestamp = timestamp
        self.details = details
        self.mid = mid
        self.txhash = txhash

    def __str__(self):
        return str({
            "sn": self.sn,
            "userid": self.userid,
            "itemid": self.itemid,
            "perms": self.perms,
            "operate": self.operate,
            "senderid": self.senderid,
            "sender": self.sender,
            "duration": self.duration,
            "timestamp": self.timestamp,
            "details": self.details,
            "mid": self.mid,
            "txhash": self.txhash
        })

    def show(self):
        return {
            "sn": self.sn,
            "userid": self.userid,
            "itemid": self.itemid,
            "perms": self.perms,
            "operate": self.operate,
            "senderid": self.senderid,
            "sender": self.sender,
            "duration": self.duration,
            "timestamp": self.timestamp,
            "details": self.details,
            "mid": self.mid,
            "txhash": self.txhash
        }


class MyMongoDB(object):
    def __init__(self, log=False, host=None, port=None, dbname=None, setname=None, username=None, passwd=None):
        if host is None:
            host = settings["host"]
        if port is None:
            port = settings["port"]
        if dbname is None:
            dbname = settings["dbname"]
        if setname is None:
            setname = settings["setname"]
        if username is None:
            username = settings["username"]
        if passwd is None:
            passwd = settings["passwd"]
        try:
            self.log = log
            self.client = MongoClient(host, port)
            self.db = self.client[dbname]
            self.db.authenticate(username, passwd)
            self.dbset = self.db[setname]
        except Exception as ex:
            print(str(ex))

    def display(self, msg):
        if self.log:
            print(msg)

    def insert(self, dic):
        self.display("insert...")
        return self.dbset.insert_many(dic)

    def update(self, dic, newdic):
        self.display("update...")
        return self.dbset.update_many(dic, newdic)

    def delete(self, dic):
        self.display("delete...")
        return self.dbset.delete_many(dic)

    def clear(self):
        self.display("clear...")
        return self.dbset.delete_many({})

    def dbfind(self, dic):
        self.display("find...")
        return self.dbset.find(dic)


# 连接mongo节点
def condb(host, port, replset, dbname, user="", passwd=""):
    db = None
    try:
        if replset is None or replset == "":
            client = MongoClient(host, port)
        else:
            client = MongoClient(host, port, replicaset=replset)
        gevent.sleep(1)
        if len(client.nodes) > 0:
            db = client.get_database(dbname)
            if user != "":
                db.authenticate(user, passwd)
        else:
            db = None
        # db = client['rs']
        # db.authenticate('tester', 'tester')
    except Exception as ex:
        print("condb:" + str(ex))
        db = None
        pass
    return db


# 连接区块链节点
def conbc(provider_url, passphrase="test"):
    # web3.py instance
    # w3 = Web3(Web3.EthereumTesterProvider())
    # PoA共识机制下api需要注入PoA中间件
    lnk = None
    try:
        if 'http' in provider_url:
            lnk = Web3(Web3.HTTPProvider(provider_url))
        else:
            lnk = Web3(Web3.WebsocketProvider(provider_url))
        if lnk.isConnected():
            lnk.middleware_stack.inject(geth_poa_middleware, layer=0)
            lnk.eth.defaultAccount = lnk.eth.coinbase
            if passphrase is not None and passphrase != '':
                lnk.personal.unlockAccount(lnk.eth.defaultAccount, passphrase)
            return lnk
    except Exception as ex:
        print("conbc:" + str(ex))
        pass
    return lnk


''' need beat
def conbc(passphrase="test"):
    global w3
    global blk_filter
    try:
        if w3 is None or w3.isConnected() == False:
            w3 = Web3([Web3.WebsocketProvider(node["url"]) for node in nodes])
            if w3.isConnected():
                w3.middleware_stack.inject(geth_poa_middleware, layer=0)
                w3.eth.defaultAccount = w3.eth.coinbase
                if passphrase is not None and passphrase != '':
                    w3.personal.unlockAccount(w3.eth.defaultAccount, passphrase)
                blk_filter = link.eth.filter('latest')
    except Exception as ex:
        print("conbc:" + str(ex))
        pass
'''


# 初始化区块链节点连接
def initNode(ip, user, passwd, url, path):
    nodes[ip] = {"ip": ip, "user": user, "passwd": passwd, "url": url, "link": conbc(url, ""), "path": path}


# 选择区块链连接节点
def pickNode():
    link = None
    curBlk = 0
    global blk_filter
    global tx_filter
    try:
        if w3 is not None and w3.isConnected():
            link = w3
            curBlk = link.eth.blockNumber
        else:
            print("switch node")
            for ip, node in nodes.items():
                if node["link"] is not None and node["link"].isConnected():
                    link = node["link"]
                    break
            if link is None or not link.isConnected():
                for ip, node in nodes.items():
                    lnk = conbc(node["url"])
                    if lnk is not None and lnk.isConnected():
                        node["link"] = lnk
                        link = lnk
                        break
            if link is not None and link.isConnected():
                curBlk = link.eth.blockNumber
                blk_filter = link.eth.filter('latest')
                # tx_filter = link.eth.filter('pending')
    except Exception as ex:
        print("pickNode:" + str(ex))
        link = None
    return (link, curBlk)


# 寻找地址所在节点及其keystore文件名
def addrSearch(addr, host_ip, remote_path, username, password):
    ssh_port = 22
    try:
        conn = paramiko.Transport((host_ip, ssh_port))
        conn.connect(username=username, password=password)
        ssh = paramiko.SSHClient()
        ssh._transport = conn
        stdin, stdout, stderr = ssh.exec_command('cd ' + remote_path + ';ls|grep ' + addr + '$')
        res = stdout.read().decode()
        conn.close()
        if res is not None and str(res).strip() != "":
            return str(res).replace('\n', '')
        else:
            return ""

    except Exception as ex:
        print(ex)
        return ""

# 将地址的keystore文件同步到指定节点
def addrCopy(itype, host_ip, remote_path, local_path, filename, username, password):
    ssh_port = 22
    try:
        conn = paramiko.Transport((host_ip, ssh_port))
        conn.connect(username=username, password=password)
        sftp = paramiko.SFTPClient.from_transport(conn)

        if not local_path:
            local_path = os.path.join('/tmp', remote_path)
        remote_file = os.path.join(remote_path, filename)
        local_file = os.path.join(local_path, filename)

        if itype == 'read':
            sftp.get(remote_file, local_file)

        if itype == "write":
            sftp.put(local_file, remote_file)

        conn.close()
        return True

    except Exception as ex:
        print(ex)
        return False


# 从文件获取合约信息(address, abi)
def getContract(filepath, contractName=""):
    cinfo = None
    contract = None
    try:
        if contractName is None or contractName == "":
            contractName = os.path.splitext(os.path.os.path.basename(filepath))[0]
        with open(filepath, 'r') as rf:
            cinfo = json.loads(rf.read())
        if cinfo is not None:
            contract = w3.eth.contract(
                address=cinfo[contractName]['address'],
                abi=cinfo[contractName]['abi'],
            )
    except Exception as ex:
        print("getContract:" + str(ex))
        contract = None
    return contract


# 根据id获取区块链上User信息
def getUser(userid, mid, txhash):
    try:
        if userid is None or userid == "":
            return None

        addr, uid, eid, uhash, level, timestamp, status = contract.functions.getUserById(userid.encode('utf-8')).call()

        addr = str(addr)
        uid = str(uid.decode('utf-8')).replace('\x00', '')
        eid = str(eid.decode('utf-8')).replace('\x00', '')
        uhash = str(uhash.decode('utf-8')).replace('\x00', '')
        level = int(level)
        timestamp = int(timestamp)
        status = int(status)

        user = User(addr, uid, eid, uhash, level, timestamp, status, mid, txhash)

        return user
    except Exception as ex:
        raise Exception("getUser:" + str(ex))
        return None


# 根据id获取区块链上Item信息
def getItem(itemid, mid, txhash):
    try:
        if itemid is None or itemid == "":
            return None

        (iid, tid, uperid, userid, xhash, shash, ihash, cipher, ikey), (iopen, level, timestamp, status) = contract.functions.getItemById(itemid.encode('utf-8')).call()

        iid = str(iid.decode('utf-8')).replace('\x00', '')
        tid = str(tid.decode('utf-8')).replace('\x00', '')
        uperid = str(uperid.decode('utf-8')).replace('\x00', '')
        userid = str(userid.decode('utf-8')).replace('\x00', '')
        xhash = str(xhash.decode('utf-8')).replace('\x00', '')
        shash = str(shash.decode('utf-8')).replace('\x00', '')
        ihash = str(ihash.decode('utf-8')).replace('\x00', '')
        cipher = str(cipher.decode('utf-8')).replace('\x00', '')
        ikey = str(ikey.decode('utf-8')).replace('\x00', '')
        iopen = int(iopen)
        level = int(level)
        timestamp = int(timestamp)
        status = int(status)

        item = Item(iid, tid, uperid, userid, xhash, shash, ihash, cipher, ikey, iopen, level, timestamp, status, mid, txhash)

        return item
    except Exception as ex:
        raise Exception("getItem:" + str(ex))
        return None


# 根据id获取区块链上Perm信息
def getPerm(permid, mid, txhash):
    try:
        if permid is None or permid == "":
            return None

        (pid, tid, sgerid, userid, itemid, phash, device, pmark), prvs, (ptime, ptimes, pslice, ptimestamp), (ptype, status)= contract.functions.getPermById(permid.encode('utf-8')).call()

        pid = str(pid.decode('utf-8')).replace('\x00', '')
        tid = str(tid.decode('utf-8')).replace('\x00', '')
        sgerid = str(sgerid.decode('utf-8')).replace('\x00', '')
        userid = str(userid.decode('utf-8')).replace('\x00', '')
        itemid = str(itemid.decode('utf-8')).replace('\x00', '')
        phash = str(phash.decode('utf-8')).replace('\x00', '')
        device = str(device.decode('utf-8')).replace('\x00', '')
        pmark = str(pmark.decode('utf-8')).replace('\x00', '')
        prvs = [int(x) for x in prvs]
        ptime = [int(x) for x in ptime]
        ptimes = [int(x) for x in ptimes]
        pslice = [int(x) for x in pslice]
        ptimestamp = [int(x) for x in ptimestamp]
        ptype = int(ptype)
        status = int(status)

        perm = Perm(pid, tid, sgerid, userid, itemid, phash, device, pmark, prvs, ptime, ptimes, pslice, ptimestamp, ptype, status, mid, txhash)

        return perm
    except Exception as ex:
        raise Exception("getPerm:" + str(ex))
        return None


# 根据合约和交易hash获取交易日志的详细信息
def fetchReceipt(txhash):
    txreceipt = w3.eth.getTransactionReceipt(txhash)
    if txreceipt['status'] == 1:
        mid = int(txreceipt['blockNumber']) * 100000 + int(txreceipt['transactionIndex'] * 100)
        return (contract.events.TXReceipt().processReceipt(txreceipt), mid)
    else:
        return (None, 0)


# 分析receipt信息
def parseReceipt(receipt, mid):
    try:
        if receipt is not None and len(receipt) > 0:
            txhash = str(Web3.toHex(receipt[0]['transactionHash']))
            args = receipt[0]['args']
            sn = str(args['sn'].decode('utf-8')).replace('\x00', '')
            userid = str(args['userid'].decode('utf-8')).replace('\x00', '')
            itemid = str(args['itemid'].decode('utf-8')).replace('\x00', '')
            operate = str(args['operate'].decode('utf-8')).replace('\x00', '')
            senderid = str(args['senderid'].decode('utf-8')).replace('\x00', '')
            sender = str(args['sender']).lower().replace('\x00', '')
            duration = int(args['duration'])
            timestamp = int(args['timestamp'])
            permids = str(args['permids'])
            details = eval(str(args['details']))

            if permids == "":
                perms = []
            else:
                perms = permids.split(",")
            if perms is not None and len(perms) > 0 and perms[-1] == "":
                perms = perms[:-1]
            
            mid = mid/100000.0
            log = Log(sn, userid, itemid, perms, operate, senderid, sender, duration, timestamp, details, mid, txhash)
            # print(log)

            if operate.startswith('addUser') or operate.startswith('setUser') or operate.startswith('setMyHash'):
                user = getUser(userid, mid, txhash)
                res = write({"user": [user.show()], "log": [log.show()]})
                print(res)
                ''''
                if operate.startswith('addUser'):
                    threading.Thread(target=addrThread, args=(user.addr.lower()[2:],)).start()
                    # pas.put_nowait(user.addr.lower()[2:])
                '''
            elif operate.startswith('addItem') or operate.startswith('uplItem') or operate.startswith('setItem') or operate.startswith('transItem'):
                item = getItem(itemid, mid, txhash)
                res = write({"item": [item.show()], "log": [log.show()]})
                print(res)
            elif operate.startswith('addPerm') or operate.startswith('setPerm'):
                perm = getPerm(perms[0], mid, txhash)
                pperm = getPerm(perm.tid, mid + 1/100000.0, txhash)
                if pperm is None:
                    res = write({"perm": [perm.show()], "log": [log.show()]})
                else:
                    res = write({"perm": [perm.show(), pperm.show()], "log": [log.show()]})
                print(res)
            else:
                jperms = []
                for i in range(len(perms)):
                    tp = getPerm(perms[i], mid + i/100000.0, txhash)
                    if tp is not None:
                        jperms.append(tp.show())
                res = write({"perm": jperms, "log": [log.show()]})
                print(res)


            '''
            if False and isinstance(details, dict):
                action = "" if "action" not in details.keys() else details['action']
                obj = "" if "object" not in details.keys() else details['object']
                key = "" if "key" not in details.keys() else details['key']
                att = "" if "att" not in details.keys() else details['att']
                note = "" if "note" not in details.keys() else details['note']
                old = "" if "old" not in details.keys() else details['old']
                new = "" if "new" not in details.keys() else details['new']

                print(new)

                if action.lower() == "add":
                    if obj.lower() == "user":
                        # user = createUser(new)
                        res = write({"user": [new], "log": log.show()})
                        print(res)
                    elif obj.lower() == "item":
                        item = createItem(new)
                    elif obj.lower() == "perm":
                        perm = createPerm(new)
                    else:
                        pass
                elif action.lower() == "upl" or action.lower() == "del":
                    pass
                else:
                    pass
        '''
    except Exception as ex:
        raise Exception("parseReceipt:" + str(ex))


# 交易同步到mongo数据库
def txsync(txhash):
    try:
        receipt, mid = fetchReceipt(txhash)
        parseReceipt(receipt, mid)
    except Exception as ex:
        print("txsync:" + str(ex))
        fts.put_nowait({"tx": txhash})


# 多线程方式同步地址
def addrThread(addr):
    for node, info in nodes.items():
        filename = addrSearch(addr, info['ip'], info['path'], info['user'], info['passwd'])
        print(filename)
        if filename != "" and addrCopy("read", info['ip'], info['path'], "/tmp", filename, info['user'], info['passwd']):
            for xnode, xinfo in nodes.items():
                if xnode != node:
                    print(addrCopy("write", xinfo['ip'], xinfo['path'], "/tmp", filename, xinfo['user'], xinfo['passwd']))
                else:
                    print(addrCopy("write", xinfo['ip'], xinfo['path'], "/tmp", filename, xinfo['user'], xinfo['passwd']))
            break


# 协程方式同步地址
def addrsync():
    while True:
        addr = pas.get()
        print("Addr:  " + addr)
        for i in range(3):
            try:
                for node, info in nodes.items():
                    filename = addrSearch(addr, info['ip'], info['path'], info['user'], info['passwd'])
                    print(filename)
                    if filename != "" and addrCopy("read", info['ip'], info['path'], "/tmp", filename, info['user'], info['passwd']):
                        for xnode, xinfo in nodes.items():
                            if xnode != node:
                                print(addrCopy("write", xinfo['ip'], xinfo['path'], "/tmp", filename, xinfo['user'], xinfo['passwd']))
                        break
                # gevent.sleep(interval)
            except Exception as ex:
                print("addrsync:" + str(ex))
                if i == 2:
                    # 写入失败队列
                    pas.put_nowait(addr)
                else:
                    continue


# mongo多文档事务写入
@retry(tries=2, delay=10)
def write(info):
    try:
        '''
        orders = client.db.orders
        inventory = client.db.inventory
        with client.start_session() as session:
        with session.start_transaction():
            orders.insert_one({"sku": "abc123", "qty": 100}, session=session)
            inventory.update_one({"sku": "abc123", "qty": {"$gte": 100}}, {"$inc": {"qty": -100}}, session=session)
        '''
        res = None
        with db.client.start_session() as session:
            # dbset = session.client.rsdb.latest
            with session.start_transaction():
                for key, values in info.items():
                    for value in values:
                        if key == "user":
                            res = db[key].update_one(
                                {"uid": value['uid']},
                                {"$set": {
                                    "addr": value['addr'],
                                    "uid": value['uid'],
                                    "eid": value['eid'],
                                    "uhash": value['uhash'],
                                    "level": value['level'],
                                    "timestamp": value['timestamp'],
                                    "status": value['status'],
                                    "mid": value['mid'],
                                    "txhash": value['txhash']
                                }},
                                upsert=True,
                                session=session
                            )
                        elif key == "item":
                            res = db[key].update_one(
                                {"iid": value['iid']},
                                {"$set": {
                                    "iid": value['iid'],
                                    "tid": value['tid'],
                                    "uperid": value['uperid'],
                                    "userid": value['userid'],
                                    "xhash": value['xhash'],
                                    "shash": value['shash'],
                                    "ihash": value['ihash'],
                                    "cipher": value['cipher'],
                                    "ikey": value['ikey'],
                                    "iopen": value['iopen'],
                                    "level": value['level'],
                                    "timestamp": value['timestamp'],
                                    "status": value['status'],
                                    "mid": value['mid'],
                                    "txhash": value['txhash']
                                }},
                                upsert=True,
                                session=session
                            )
                        elif key == "perm":
                            res = db[key].update_one(
                                {"pid": value['pid']},
                                {"$set": {
                                    "pid": value['pid'],
                                    "tid": value['tid'],
                                    "sgerid": value['sgerid'],
                                    "userid": value['userid'],
                                    "itemid": value['itemid'],
                                    "phash": value['phash'],
                                    "device": value['device'],
                                    "pmark": value['pmark'],
                                    "prvs": value['prvs'],
                                    "ptime": value['ptime'],
                                    "ptimes": value['ptimes'],
                                    "pslice": value['pslice'],
                                    "ptimestamp": value['ptimestamp'],
                                    "ptype": value['ptype'],
                                    "status": value['status'],
                                    "mid": value['mid'],
                                    "txhash": value['txhash']
                                }},
                                upsert=True,
                                session=session
                            )
                        elif key == "log":
                            res = db[key].update_one(
                                {"sn": value['sn']},
                                {"$set": {
                                    "sn": value['sn'],
                                    "userid": value['userid'],
                                    "itemid": value['itemid'],
                                    "perms": value['perms'],
                                    "operate": value['operate'],
                                    "senderid": value['senderid'],
                                    "sender": value['sender'],
                                    "duration": value['duration'],
                                    "timestamp": value['timestamp'],
                                    "details": value['details'],
                                    "mid": value['mid'],
                                    "txhash": value['txhash']
                                }},
                                upsert=True,
                                session=session
                            )
                # res = db["latest"].insert_many(
                #     [{
                #         "number": 40,
                #         "hash": "0x94b4bda694f7985dd849b9331148283d982c94e86c5e7eedac5f2b321a958668",
                #         "index": 0
                #     }],
                #     session=session)
                # session.commit_transaction()
        print(res.raw_result)
        if res is not None and res.raw_result['ok'] == 1.0:
            return True
        else:
            return False
    except Exception as ex:
        print("write:" + str(ex))
        return False


# 读取同步信息, 完成初始同步
def recover(curBlk):
    try:
        # curBlk = w3.eth.blockNumber
        # 未同步交易处理
        item = None
        for i in range(3):
            try:
                item = db['latest'].find_one()
                break
            except Exception:
                item = None
                gevent.sleep(10)
                continue

        while curBlk is not None and curBlk > 0 and item is not None and curBlk >= int(item["number"]):
            blk = w3.eth.getBlock(curBlk)
            for idx in range(len(blk["transactions"])):
                if curBlk == int(item["number"]):
                    if idx > int(item["index"]):
                        pts.put_nowait(Web3.toHex(blk["transactions"][idx]))
                else:
                    pts.put_nowait(Web3.toHex(blk["transactions"][idx]))
            curBlk -= 1
        # 失败交易记录
        pass
    except Exception as ex:
        print("recover:" + str(ex))
        pass


# 分析交易队列数据, 写入mongo缓存库
def handle():
    global w3
    while True:
        thash = pts.get()
        print("Tx:    " + thash)
        for i in range(3):
            try:
                txsync(thash)
                # TODO parse tx
                # gevent.sleep(interval)
                break
            except Exception as ex:
                print("handle:" + str(ex))
                if i == 2:
                    # 写入失败队列
                    fts.put_nowait({"tx": thash})
                else:
                    w3, _ = pickNode()
                    continue


# 区块队列数据写入交易队列
def extract():
    global w3
    while True:
        bhash = pbs.get()
        print("Block: " + bhash)
        for i in range(3):
            try:
                blk = w3.eth.getBlock(bhash)
                for thash in blk['transactions']:
                    pts.put_nowait(Web3.toHex(thash))
                # gevent.sleep(interval)
                break
            except Exception as ex:
                print("extract:" + str(ex))
                if i == 2:
                    # 写入失败队列
                    fts.put_nowait({"blk": bhash})
                else:
                    w3, _ = pickNode()
                    continue


# 监听区块链事件
def loop(event_type, event_filter):
    global w3
    while True:
        try:
            for event in event_filter.get_new_entries():
                print(event)
                if event_type == "blk":
                    pbs.put_nowait(Web3.toHex(event))
                # handler(event_type, event)
            gevent.sleep(interval)
        except Exception as ex:
            print("loop:" + str(ex))
            # sys.exit()
            w3, _ = pickNode()


# 区块链心跳
def beat():
    global w3
    while True:
        w3, _ = pickNode()
        gevent.sleep(5)


# gevent协程
def listen():
    gevent.joinall([
        gevent.spawn(beat),
        gevent.spawn(loop, "blk", blk_filter),
        # gevent.spawn(loop, "tx", tx_filter),
        gevent.spawn(extract),
        gevent.spawn(handle),
        gevent.spawn(addrsync)
    ])


def main():
    global w3
    global db
    global contract

    # db = condb("172.16.201.189", 27017, "", "rs", "test", "test")
    db = condb("172.16.201.189", 9927, "myrs", "rsdb")
    # write()

    initNode("172.16.201.191", "root", "szyz#233", "ws://172.16.201.191:8546", "/root/node1/keystore/")
    initNode("172.16.201.192", "root", "szyz#233", "ws://172.16.201.192:8546", "/root/node2/keystore/")
    initNode("172.16.201.193", "root", "szyz#233", "ws://172.16.201.193:8546", "/root/node3/keystore/")
    w3, curBlk = pickNode()

    contract = getContract('./RS.json')

    if contract is not None and w3 is not None and db is not None and w3.isConnected() and db.connect:
        # recover(curBlk)
        listen()
    else:
        print(w3.isConnected())
        print(db.connect)
        print(contract)


if __name__ == '__main__':
    main()

    #db = condb("172.16.201.189", 9927, "myrs", "rsdb")
    #initNode("172.16.201.191", "root", "szyz#233", "ws://172.16.201.191:8546", "/root/node1/keystore/")
    #initNode("172.16.201.192", "root", "szyz#233", "ws://172.16.201.192:8546", "/root/node2/keystore/")
    #initNode("172.16.201.193", "root", "szyz#233", "ws://172.16.201.193:8546", "/root/node3/keystore/")
    #w3, curBlk = pickNode()

    #initNode("127.0.0.1", "root", "root", "ws://127.0.0.1:8546", "/tmp/eth/keystore/")
    #w3, curBlk = pickNode()

    #contract = getContract('./RS.json')

    
    #txsync('0x8f53c03d33c7e6b15ba7ddd2d351ad9476c1b17e6486eeaf39f5cc8ae3d1007a')        # tx_addUser
    #txsync('0x820d2b116c6a92e943f9f25186dca70bc56e0b10223f99e5c3b489029c8d0488')        # tx_addPerm

    #txsync('0x4c22390c89030952c3c9e822cefb95db72f1d96a266ba7c244ed72bb211158bf')     # tx_addUser
    #txsync('0x5a6d700cb9dd4d7262bc353a371cf8509ebaa5e0746715f997349f5a2dc583e3')      # tx_addItem
    #txsync('0x958c824bda478ff74d7ad3c657b2083908b4ecfde1a50a2d41678b0376f02e27')      # tx_addPerm

    # db = condb("172.16.201.189", 27017, "", "rs", "test", "test")
    # print(db['item'].find_one())
    # if db.connect:
    #     print('OK')
# gevent.joinall([g1, g2, g3])
