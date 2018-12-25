import os, time, json, uuid, random, hashlib, string

from web3 import Web3
from solc import compile_source
from solc import link_code
from pymongo import MongoClient
# from web3.contract import ConciseContract
from web3.middleware import geth_poa_middleware

settings = {
    "host": '172.16.201.189',
    "port": 27017,
    "dbname": "rs",
    "setname": "user",
    "username": "test",
    "passwd": "test",
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

    def query(self, dic):
        self.display("find...")
        return self.dbset.find(dic)


class User:
    def __init__(self, addr, uid, eid, uhash, level, timestamp, status):
        self.addr = addr
        self.uid = uid
        self.eid = eid
        self.uhash = uhash
        self.level = level
        self.timestamp = timestamp
        self.status = status

    def __str__(self):
        return str({
            "address": self.addr,
            "uid": self.uid,
            "eid": self.eid,
            "uhash": self.uhash,
            "level": self.level,
            "timestamp": self.timestamp,
            "status": self.status
        })

    def show(self):
        return {
            "address": self.addr,
            "uid": self.uid,
            "eid": self.eid,
            "uhash": self.uhash,
            "level": self.level,
            "timestamp": self.timestamp,
            "status": self.status
        }


class Item:
    def __init__(self, iid, tid, uperid, userid, xhash, shash, ihash, cipher, ikey, iopen, level, timestamp, status):
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
            "status": self.status
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
            "status": self.status
        }


class Perm:
    def __init__(self, pid, tid, sgerid, userid, itemid, phash, device, pmark, prvs, ptime, ptimes, pslice, ptimestamp, ptype,
                 status):
        self.pid = pid
        self.tid = tid
        self.sgerid = sgerid
        self.userid = userid
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

    def __str__(self):
        return str({
            "pid": self.pid,
            "tid": self.tid,
            "sgerid": self.sgerid,
            "userid": self.userid,
            "phash": self.phash,
            "device": self.device,
            "pmark": self.pmark,
            "prvs": self.prvs,
            "ptime": self.ptime,
            "ptimes": self.ptimes,
            "pslice": self.pslice,
            "ptimestamp": self.ptimestamp,
            "ptype": self.ptype,
            "status": self.status
        })

    def show(self):
        return {
            "pid": self.pid,
            "tid": self.tid,
            "sgerid": self.sgerid,
            "userid": self.userid,
            "phash": self.phash,
            "device": self.device,
            "pmark": self.pmark,
            "prvs": self.prvs,
            "ptime": self.ptime,
            "ptimes": self.ptimes,
            "pslice": self.pslice,
            "ptimestamp": self.ptimestamp,
            "ptype": self.ptype,
            "status": self.status
        }


class Log:
    def __init__(self, sn, userid, itemid, permid, operate, senderid, sender, duration, timestamp, details):
        self.sn = sn
        self.userid = userid
        self.itemid = itemid
        self.permid = permid
        self.operate = operate
        self.senderid = senderid
        self.sender = sender
        self.duration = duration
        self.timestamp = timestamp
        self.details = details

    def __str__(self):
        return str({
            "sn": self.sn,
            "userid": self.userid,
            "itemid": self.itemid,
            "permid": self.permid,
            "operate": self.operate,
            "senderid": self.senderid,
            "sender": self.sender,
            "duration": self.duration,
            "timestamp": self.timestamp,
            "details": self.details
        })

    def show(self):
        return {
            "sn": self.sn,
            "userid": self.userid,
            "itemid": self.itemid,
            "permid": self.permid,
            "operate": self.operate,
            "senderid": self.senderid,
            "sender": self.sender,
            "duration": self.duration,
            "timestamp": self.timestamp,
            "details": self.details
        }


# 智能合约代码
contractSourceCode = '''
pragma solidity ^0.4.21;

contract Greeter {
    uint public count;
    string public greeting;

    function Greeter() public {
        count = 0;
        greeting = 'Hello';
    }

    function setGreeting(string _greeting) public {
        greeting = _greeting;
        count++;
    }

    function greet() view public returns (string) {
        return greeting;
    }

    function getCount() view public returns (uint) {
        return count;
    }
}
'''


def myProvider(provider_url, passphrase="test"):
    # web3.py instance
    # w3 = Web3(Web3.EthereumTesterProvider())
    # PoA共识机制下api需要注入PoA中间件
    if 'http' in provider_url:
        w3 = Web3(Web3.HTTPProvider(provider_url))
    else:
        w3 = Web3(Web3.WebsocketProvider(provider_url))
    w3.middleware_stack.inject(geth_poa_middleware, layer=0)
    w3.eth.defaultAccount = w3.eth.accounts[0]
    if passphrase is not None and passphrase != '':
        w3.personal.unlockAccount(w3.eth.defaultAccount, passphrase)
    return w3


# 解锁默认账号
def unlockAccount(addr, passphrase):
    # set pre-funded account as sender
    w3.personal.unlockAccount(addr, passphrase)


# 根据keystore文件和密码获取私钥, 公钥和地址, 并可以通过私钥和新密码生成新的keystore文件和地址. 区块链会自动感知
# geth提供geth --datadir <somepath> account update <address>的方式更新密码, 但不能在控制台这样操作
def updatePasswd():
    prikey = ""
    oldpasswd = "test"
    newpasswd = "node"
    with open('/tmp/keystore/UTC--2018-07-24T08-45-18.136630972Z--dcf9c96b3f9aa9818a1a2543bad39ae4b9fb9616') as keyfile:
        encrypted_key = keyfile.read()
        private_key = w3.eth.account.decrypt(encrypted_key, oldpasswd)
        prikey = private_key
        print(w3.toHex(private_key))
        acct = w3.eth.account.privateKeyToAccount(private_key)
        print(acct.address)
        print(acct._key_obj.public_key)
    # TODO 删除keystore文件
    print(w3.personal.importRawKey(prikey, newpasswd))  # 地址不会改变


# 根据合约和交易hash获取交易日志的详细信息
def parseReceipt(txhash):
    txreceipt = w3.eth.getTransactionReceipt(txhash)
    receipt = contract.events.TXReceipt().processReceipt(txreceipt)
    print(receipt)
    return receipt


# 直接解析交易凭条中的log的data字段(无需合约事件的配合, 即无需paraseReceipt函数方式)
# logs的data字段中, 只保存了没有indexed的字段, byte统一为bytes32, uint统一为uint256, string统一为string
# 解析到的数据需按实际情况进行转换, 如地址等十六进制数据使用toHex, 字符串编码的十六进制数据使用toText, int类型需要toHex后再转换为十进制
def parseLog(txhash):
    from eth_abi import decode_abi
    txreceipt = w3.eth.getTransactionReceipt(txhash)
    datas = decode_abi(
        ['bytes32', 'bytes32', 'bytes32', 'string', 'uint256', 'uint256'], w3.toBytes(hexstr=txreceipt.logs[0].data))
    print(w3.toHex(datas[0]))
    print(w3.toText(datas[1]))
    print(w3.toText(datas[2]))
    print(w3.toText(datas[3]))  # 实际是字符串类型
    print(int(w3.toHex(datas[4]), 16))
    print(int(w3.toHex(datas[5]), 16))


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
        print(ex)
        contract = None
    return contract


# 编译合约
def compiler(source, mode='file'):
    # 读取合约
    csc = ''
    contracts = []
    if mode != 'file':
        csc = source
    else:
        try:
            with open(source, 'r', encoding='utf-8') as rf:
                csc = rf.read()
        except Exception as ex:
            print('read file error: ' + str(ex))
    try:
        # 编译合约源码
        compiledSol = compile_source(csc)
        # contractId, contractInterface = compiledSol.popitem()
        for contractId, contractInterface in compiledSol.items():
            ctt = {}
            ast = contractInterface['ast']['children']
            for item in ast:
                if len(item['attributes'].keys()) > 2:
                    if str(contractId).split(':')[-1] == str(item['attributes']['name']):
                        # ctt['name'] = contractId
                        ctt['name'] = str(contractId).split(':')[-1]
                        ctt['type'] = item['attributes']['contractKind']
                        ctt['abi'] = contractInterface['abi']
                        ctt['bytecode'] = contractInterface['bin']
                        contracts.append(ctt)
    except Exception as ex:
        print('compile error: ' + str(ex))
    return contracts


# 部署合约
def deploy(w3, source, contractName="", mode='file'):
    contract = None
    subaddrs = {}
    contractInfo = {}

    try:
        if contractName is None or contractName == "":
            contractName = os.path.splitext(os.path.os.path.basename(source))[0]

        contracts = compiler(source, mode)

        for cont in contracts:
            if '__' not in cont['bytecode']:
                # 生成合约对象
                Contract = w3.eth.contract(abi=cont['abi'], bytecode=cont['bytecode'])
                # 部署合约
                txhash = Contract.constructor().transact(params)
                # 等待合约部署交易完成
                txreceipt = w3.eth.waitForTransactionReceipt(txhash)
                # print(txreceipt)
                if txreceipt['status'] == 1:
                    subaddrs[cont['name']] = txreceipt.contractAddress
                    contractInfo[cont['name']] = {
                        'name': cont['name'],
                        'address': txreceipt.contractAddress,
                        'abi': cont['abi'],
                        'bytecode': cont['bytecode']
                    }
                # print(tx_receipt)
        for cont in contracts:
            if '__' in cont['bytecode']:
                abi = cont['abi']
                bytecode = link_code(cont['bytecode'], subaddrs)
                # 生成合约对象
                Contract = w3.eth.contract(abi=abi, bytecode=bytecode)
                # 部署合约
                txhash = Contract.constructor().transact(params)
                # 等待合约部署交易完成
                txreceipt = w3.eth.waitForTransactionReceipt(txhash)
                # print(txreceipt)
                if txreceipt['status'] == 1:
                    subaddrs[cont['name']] = txreceipt.contractAddress
                    # 将合约地址和abi进行json化保存到本地文件
                    # print(bytecode)
                    contractInfo[cont['name']] = {
                        'name': cont['name'],
                        'address': txreceipt.contractAddress,
                        'abi': cont['abi'],
                        'bytecode': bytecode
                    }
        with open('./' + contractName + '.json', 'w', encoding='utf-8') as wf:
            wf.write(json.dumps(contractInfo))

        if os.path.exists('./' + contractName + '.json'):
            contract = getContract('./' + contractName + '.json')
    except Exception as ex:
        print('deploy error: ' + str(ex))

    return contract


def handle_event(event):
    print(event)
    # and whatever


def log_loop(event_filter, poll_interval):
    while True:
        for event in event_filter.get_new_entries():
            handle_event(event)
        time.sleep(poll_interval)


def getVersion():
    return w3.version


def getAccounts():
    return w3.eth.accounts


def getUserId(addr):
    _, uid, _, _, _, _, _ = contract.functions.getUserByAddr(addr).call()
    return uid.decode().split('\x00')[0]


def getUser(arg):
    if isinstance(arg, int):
        uaddr, uid, idcard, utype, uhash, ulevel, utimestamp, ustatus = contract.functions.getUserByIdx(arg).call()
    elif str(arg)[:2] == '0x':
        uaddr, uid, idcard, utype, uhash, ulevel, utimestamp, ustatus = contract.functions.getUserByAddr(arg).call()
    else:
        uaddr, uid, idcard, utype, uhash, ulevel, utimestamp, ustatus = contract.functions.getUserById(arg.encode()).call()
    # print(w3.toHex(uaddr), uid, utype, uhash, ulevel)
    user = User(uaddr,
                uid.decode().split('\x00')[0],
                idcard.decode().split('\x00')[0],
                utype.decode().split('\x00')[0],
                uhash.decode().split('\x00')[0], int(ulevel), int(utimestamp), int(ustatus))
    # print(w3.toText(uid))
    return user


def getItem(arg):
    if isinstance(arg, int):
        ids, itype, ihash, xhash, ilevel, itimestamp, istatus = contract.functions.getItemByIdx(arg).call()
    else:
        ids, itype, ihash, xhash, ilevel, itimestamp, istatus = contract.functions.getItemById(arg.encode()).call()
    item = Item(ids[0].decode().split('\x00')[0], ids[1].decode().split('\x00')[0], ids[2].decode().split('\x00')[0],
                ids[3].decode().split('\x00')[0],
                itype.decode().split('\x00')[0],
                ihash.decode().split('\x00')[0],
                xhash.decode().split('\x00')[0], int(ilevel), int(itimestamp), int(istatus))
    return item


def getPerm(idx):
    ids, device, ptype, ptimestamp, ptime, ptimes, status = contract.functions.getPermByIdx(idx).call()
    print(w3.toText(ids[0]), w3.toText(ids[1]), w3.toText(ids[2]), w3.toText(ids[3]))
    return str(w3.toText(ids[0]))


def queryEvent():
    # b'^a\x82L\x9a\xcbg\xfd\xa9\xc5\x00\x10\x184\xea\n\xf2x{\xa6\x06\xca3\x01\xce\xfd\xd2}\xf4a\x17\xff'
    # str(w3.sha3(text="uMYHF94C6"))
    # myfilter = contract.eventFilter('TXReceipt', {'fromBlock': 175, 'toBlock': 'latest', 'filter': {'payee': getAccounts()[1]}})
    myfilter = contract.eventFilter(
        'TXReceipt',
        {
            'fromBlock': 0,
            'toBlock': 'latest',
            'filter': {
                'sn': b'3cd2f5ddf47f4267998274c8fdb597fa'
                #    'sn': "TJah0LveE".encode('utf8')
            }
        })  # sn must be bytes32
    eventlist = myfilter.get_all_entries()
    print(eventlist)


def randata(data, mode="default", num=10):
    if mode == "str":
        data.append(''.join(random.sample(string.ascii_letters + string.digits, num)))
    if mode == "bytes":
        data.append(''.join(random.sample(string.ascii_letters + string.digits, num)).encode('utf8'))
    elif mode == "addr":
        data.append("0x" + str(hashlib.sha1(uuid.uuid1().bytes).hexdigest()))
    elif mode == "hash":
        # data.append("0x" + str(hashlib.sha256(uuid.uuid1().bytes).hexdigest()))
        data.append("0x" + str(uuid.uuid1().hex))
    elif mode == "small":
        data.append(random.randint(100, 999))
    elif mode == "large":
        data.append(random.randint(0, 9999999999))
    elif mode == "timestamp":
        data.append(int(time.time()) + random.randint(-1000000, 1000000))
    else:
        random.shuffle(data)
    return random.choice(data)
    # return random.sample(data, 1)[0]


def createUser(addr):
    # addr = w3.eth.accounts[idx]
    # uid = "0x" + str(uuid.uuid1().hex)
    # uid = str(hashlib.md5(uuid.uuid1().bytes).hexdigest())
    uid = str(uuid.uuid1().hex)
    eid = ''.join(random.sample(str(string.digits) + str(string.digits), 18))
    # name = randata([], "str", 6).encode('utf8')
    # uhash = "0x" + str(uuid.uuid1().hex)
    # uhash = str(hashlib.md5(uuid.uuid1().bytes).hexdigest())
    uhash = str(uuid.uuid1().hex)
    level = 2
    timestamp = int(time.time())
    status = 1
    return User(addr, uid, eid, uhash, level, timestamp, status)


def createItem(uid=""):
    # iid = str(hashlib.md5(uuid.uuid1().bytes).hexdigest())
    iid = str(uuid.uuid1().hex)
    tid = ""
    uperid = uid
    userid = uid
    # ihash = str(hashlib.md5(uuid.uuid1().bytes).hexdigest())
    xhash = str(uuid.uuid1().hex)
    # xhash = str(hashlib.md5(uuid.uuid1().bytes).hexdigest())
    shash = str(uuid.uuid1().hex)

    ihash = str(uuid.uuid1().hex)

    cipher = "aes-128-cfb"
    ikey = "abc"

    iopen = 0
    level = 2
    timestamp = int(time.time())
    status = 1
    return Item(iid, tid, uperid, userid, xhash, shash, ihash, cipher, ikey, iopen, level, timestamp, status)


def createLog(logstr):
    sn = w3.toText(logstr['sn'])
    sender = str(logstr['sender'])
    userid = w3.toText(logstr['userid'])
    itemid = w3.toText(logstr['itemid'])
    permid = w3.toText(logstr['permid'])
    action = w3.toText(logstr['action'])
    details = str(logstr['details'])
    duration = int(logstr['duration'])
    timestamp = int(logstr['timestamp'])
    return Log(sn, sender, userid, itemid, permid, action, details, duration, timestamp)


# addUser
def addUser(addr):
    # user = createUser(addr)
    # addr = Web3.toChecksumAddress(addr)
    uid = str(uuid.uuid1().hex)
    eid = str(uuid.uuid1().hex)
    uhash = str(uuid.uuid1().hex)
    level = 2
    # timestamp = int(time.time())
    status = 1

    bts = [uid.encode(), eid.encode(), uhash.encode()]

    its = [level, status]

    # sn = "0x" + str(uuid.uuid1().hex)
    # sn = str(hashlib.md5(uuid.uuid1().bytes).hexdigest())
    sn = str(uuid.uuid1().hex).encode()
    # details = str(user)
    details = "{'note': 'addTestUser'}"

    params = {'from': w3.eth.coinbase, 'gas': 60000000, 'value': int(w3.eth.getBalance(w3.eth.coinbase)/10)}
    # print(user)
    txreceipthash = contract.functions.addUser(str(addr), bts, its, sn, details).transact(params)
    txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
    print(txreceipt)
    if txreceipt['status'] == 1:
        return uid
    else:
        return None
    '''
    if txreceipt['status'] == 1:
        chainFlag = 1
        receipt = contract.events.TXReceipt().processReceipt(txreceipt)[0]
        logstr = receipt['args']
        user.timestamp = logstr['timestamp']
        log = createLog(logstr)
        if len(umongo.insert([user.show()]).inserted_ids) == 1:
            dbFlag = 1
            if len(lmongo.insert([log.show()]).inserted_ids) == 1:
                dbFlag = 2
        # user.timestamp = w3.eth.getBlock(txreceipt['blockNumber']).timestamp
        # print(getUser(user.uid))
    '''


# addItem
def addItem(addr=None, passphrase="test"):
    if addr is None:
        addr = w3.eth.coinbase
    # addr = Web3.toChecksumAddress(addr)
    unlockAccount(addr, passphrase)
    params = {'from': addr, 'gas': 60000000}
    uid = getUserId(addr)

    # item = createItem()
    iid = str(uuid.uuid1().hex)
    tid = ""
    # uperid = uid
    userid = uid
    # ihash = str(hashlib.md5(uuid.uuid1().bytes).hexdigest())
    xhash = str(uuid.uuid1().hex)
    # xhash = str(hashlib.md5(uuid.uuid1().bytes).hexdigest())
    shash = str(uuid.uuid1().hex)
    ihash = str(uuid.uuid1().hex)
    cipher = "aes-128-cfb"
    ikey = "abc"
    iopen = 0
    level = 2
    # timestamp = int(time.time())
    status = 1

    bts = [iid.encode(), tid.encode(),  userid.encode(), xhash.encode(), shash.encode(), ihash.encode(), cipher.encode(), ikey.encode()]

    its = [iopen, level, status]

    # sn = str(hashlib.md5(uuid.uuid1().bytes).hexdigest())
    sn = str(uuid.uuid1().hex).encode()
    details = "{'note': 'addTestItem'}"

    txreceipthash = contract.functions.uplItem(bts, its, sn, details).transact(params)
    txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
    print(txreceipt)
    if txreceipt['status'] == 1:
        # item.timestamp = w3.eth.getBlock(txreceipt['blockNumber']).timestamp
        # print(item)
        # print(getItem(item.iid))
        # print(contract.functions.getRes(item.iid.encode()).call())
        return iid
        pass
    else:
        return None


# addPerm
def addPerm(userid, itemid, permid="", pptime=-1, pptimes=-1, pptimestamp=-1, addr=None, passphrase="test"):
    if addr is None:
        addr = w3.eth.coinbase
    # addr = Web3.toChecksumAddress(addr)
    unlockAccount(addr, passphrase)
    params = {'from': addr, 'gas': w3.eth.getBlock('latest').gasLimit}

    pid = str(uuid.uuid1().hex)
    phash = str(uuid.uuid1().hex)
    device = "linux"
    pmark = "Hello"
    prvs = [1, 0, 1, 1]
    ptime = pptime
    ptimes = pptimes
    # ptime = 3600
    # ptimes = 5
    pslicea = -1
    psliceb = -1
    # ptimestamp = int(time.time())+3600
    ptimestamp = pptimestamp
    ptype = 0
    status = 1

    bts = [pid.encode(), permid.encode(), userid.encode(), itemid.encode(), phash.encode(), device.encode(), pmark.encode()]

    its = [ptime, ptimes, pslicea, psliceb, ptimestamp, ptype, status]

    sn = str(uuid.uuid1().hex).encode()
    details = "{'note': 'addTestPerm'}"

    txreceipthash = contract.functions.addPerm(bts, prvs, its, sn, details).transact(params)
    txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
    print(txreceipt)
    if txreceipt['status'] == 1:
        return pid
    else:
        return None


'''
./geth --identity "myeth" --networkid 111 --nodiscover --maxpeers 10 --port "30303" --syncmode=full --gcmode=archive --gasprice=1 --dev --dev.period=0 --targetgaslimit=471238800  --rpc --rpcapi "db,eth,net,web3,personal,miner,admin,debug,txpool" --rpcaddr 0.0.0.0 --rpcport "8545" --ws --wsaddr 0.0.0.0 --wsorigins=* --wsapi "db,eth,net,web3,personal,miner,admin,debug" --wsport "8546" --extradata="myeth/172.17.0.2:8546" --datadir "/tmp/geth/" console
'''

'''
umongo = MyMongoDB(setname="user")
imongo = MyMongoDB(setname="item")
pmongo = MyMongoDB(setname="perm")
lmongo = MyMongoDB(setname="log")
'''

# w3 = myProvider("ws://172.16.201.189:8646", "node1")
# w3.middleware_stack.inject(geth_poa_middleware, layer=0)
# w3 = myProvider("ws://127.0.0.1:8546", "test")
# w3 = myProvider("http://127.0.0.1:8545", "test")

# 合约名
cname = "RS"

w3 = myProvider("ws://127.0.0.1:8546", "test")
# w3 = myProvider("http://172.16.201.191:8545", "node1")
# print(w3.eth.getBalance(w3.eth.coinbase))
params = {'from': w3.eth.coinbase, 'gas': w3.eth.getBlock('latest').gasLimit, 'value': int(w3.eth.getBalance(w3.eth.coinbase)/10)}
if os.path.exists('./' + cname + '.json'):
    contract = getContract('./' + cname + '.json')
else:
    estimate = w3.eth.getBlock('latest').gasLimit
    while True:
        contract = deploy(w3, './' + cname + '.sol')
        if contract is None:
            print('deploy failed: ' + str(estimate))
            estimate = w3.eth.getBlock('latest').gasLimit
            params = {'from': w3.eth.coinbase, 'gas': estimate}
        else:
            break

# Addr
#addr1 = Web3.toChecksumAddress("0xc51e44f41e832b72ff215364971455964569dca4")
#addr2 = Web3.toChecksumAddress("0xef5f09d6a38c87bb51b2f65a75c5a16aefba7769")
#addr3 = Web3.toChecksumAddress("0xdf770c7e5d3fe418f5accaf7a98a5a435b0ec01a")
addr1 = Web3.toChecksumAddress(w3.eth.accounts[1])
addr2 = Web3.toChecksumAddress(w3.eth.accounts[2])
addr3 = Web3.toChecksumAddress(w3.eth.accounts[3])

print(addr1, addr2, addr3)

# addUser

uid1 = addUser(addr1)
print(contract.functions.getUserByAddr(addr1).call())   # 13d544d8c08611e8920228e347233abc
uid2 = addUser(addr2)
print(contract.functions.getUserByAddr(addr2).call())   # c8787240c08911e8942028e347233abc
uid3 = addUser(addr3)
print(contract.functions.getUserByAddr(addr3).call())
print(uid1, uid2, uid3)


# addItem

iid1 = addItem(addr1)
print(contract.functions.getItemById(iid1.encode()).call())
print(iid1)


# addPerm

pptime = 7200
pptimes = 20
pptimestamp = -1
pid1 = addPerm(uid2, iid1, "", pptime, pptimes, pptimestamp, addr1)
print(contract.functions.getPermById(pid1.encode()).call())
print(pid1)


pptime = 3600
pptimes = 10
pptimestamp = int(time.time()) + 1000
pid2 = addPerm(uid3, iid1, pid1, pptime, pptimes, pptimestamp, addr2)
print(contract.functions.getPermById(pid2.encode()).call())
print(pid2)


'''
# Users
print('User:' + "=" * 50)
for i in range(contract.functions.getUserNum().call()):
    print(contract.functions.getUserByIdx(i).call())

print('Item:' + "=" * 50)
for i in range(contract.functions.getItemNum().call()):
    print(contract.functions.getItemByIdx(i).call())

print('Perm:' + "=" * 50)
for i in range(contract.functions.getPermNum().call()):
    print(contract.functions.getPermByIdx(i).call())

'''

'''
user1 = contract.functions.getUserByIdx(1).call()[1].decode().replace('\x00', '')
user2 = contract.functions.getUserByIdx(2).call()[1].decode().replace('\x00', '')
item1 = contract.functions.getItemByIdx(0).call()[0][0].decode().replace('\x00', '')
perm1 = contract.functions.getPermByIdx(0).call()[0][0].decode().replace('\x00', '')
'''

#print(user2, item1, perm1)
#print(contract.functions.getUIPermNum([user2.encode(), item1.encode()]).call())
#print(contract.functions.bytes32ArrayToString(["abc".encode(), "def".encode()], ",".encode()).call())
params = {'from': w3.eth.coinbase, 'gas': w3.eth.getBlock('latest').gasLimit}
#print(contract.functions.getUIPerms([user2.encode(), item1.encode()]).call(params))

# 65ed947cc18111e8aa3f28e347233abc 66b26e78c18111e8aa3f28e347233abc 675d18e6c18111e8aa3f28e347233abc

'''
txreceipthash = contract.functions.addLog([user2.encode(), item1.encode(), "Play".encode()], [perm1.encode()], 10, str(uuid.uuid1().hex).encode(), "{'note': 'play'}").transact(params)
txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
receipt = contract.events.TXReceipt().processReceipt(txreceipt)
print(receipt)
'''

for i in range(contract.functions.getPermNum().call(params)):
    print(contract.functions.getPermByIdx(i).call(params))

'''
txreceipt = w3.eth.waitForTransactionReceipt("0x5dce3d361186b5a99b8df9884597ec6fd6ea7579a853db5ef19424db942794a5")
receipt = contract.events.TXReceipt().processReceipt(txreceipt)
print(receipt)
'''


#print(contract.functions.getUserById("caixiaofan004".encode()).call())
#print(contract.functions.getUserByAddr(addr1).call())
#print(contract.functions.getItemByIdx(0).call())
#print(contract.functions.getUIPermNum(["1a2f3816c06311e882d228e347233abc".encode(), "1bfc6c86c06311e882d228e347233abc".encode()]).call())
# print(contract.functions.getUIPermByIdx(["1a2f3816c06311e882d228e347233abc".encode(), "1bfc6c86c06311e882d228e347233abc".encode()], 0).call())

# print(contract.functions.bytes32ArrayToString(["cp".encode(), "cd9f0c87e42d434ca61ecb2486445c89".encode()], "".encode()).call())
'''
addUser(1)
addUser(2)
addUser(3)
addItem()
addPerm(getUser(2), getItem(0))

addPerm()
getUser(1)
getItem(0)
getPerm(0)
'''
'''
for i in range(contract.functions.getUserNum().call()):
    print(contract.functions.getUserByIdx(i).call())

for i in range(contract.functions.getItemNum().call()):
    print(contract.functions.getItemByIdx(i).call())

for i in range(contract.functions.getPermNum().call()):
    print(contract.functions.getPermByIdx(i).call())

for i in range(contract.functions.getLogNum().call()):
    print(contract.functions.getLogByIdx(i).call())
'''

# print(contract.functions.fetchPerm("cp".encode(), "cd9f0c87e42d434ca61ecb2486445c89".encode()).call())
'''
print(contract.functions.verPerm(
    "cp".encode(),
    "9358742f03754a40b9e5d273fb4e3a2f".encode(),
    2,
    153180317,
    10,
    10,
).call())
'''
# addUser(1)
# queryEvent()

# print(contract.functions.getItemByIdx(0).call())

# print(contract.functions.test(getUser(1), getItem(0)).call())

# print(contract.functions.testa(getUser(1), getItem(0)).call())

# _, a, _, _, _, _, _ = contract.functions.getPermById("a".encode()).call()
# print(w3.toText(a))
'''
for i in range(contract.functions.getUserNum().call()):
    print(contract.functions.getUserByIdx(i).call())
'''
'''
for addr in w3.eth.accounts[0:3]:
    print('unlock:' + str(addr))
    unlockAccount(addr, 'test')
    #Thread(target=unlockAccount, args=(addr, 'test')).start()
print(w3.eth.accounts[0])
'''
'''
for i in range(1100):
    addr = w3.personal.newAccount('test')
    print(addr)
    # unlockAccount(addr, 'test')

for addr in w3.eth.accounts[63:]:
    user = addUser(addr)
    print(user)
'''
'''
user = addUser(w3.eth.accounts[1])
if user is not None:
    for i in range(10):
        Thread(target=addItem, args=(user.uid, )).start()
'''
'''
for addr in w3.eth.accounts[1:100]:
    print('unlock: ' + str(addr))
    unlockAccount(addr, 'test')

print('#' * 40 + 'start'.center(20, ' ') + '#' * 40)
for addr in w3.eth.accounts[1:100]:
    Thread(target=addItem, args=(addr, 'test')).start()
'''
'''
start = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time()))
for i in range(contract.functions.getUserNum().call()):
    print(contract.functions.getUserByIdx(i).call())
end = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time()))
print(start)
print(end)
print(end - start)
'''
# print(addUser(w3.eth.accounts[6]))
# print(contract.functions.getUserByIdx(4).call())

# parseReceipt('0x96e567ca3e95581043fe420f4d180aafaab61a2db311caa04eeb33236f4b07fa')
# txreceipt = parseReceipt('0xff63112dbb0358f6c66b1bed31f8aef5ceb871cdb3a39d8d3156139dacfc252c')
# print(txreceipt[0]['args'])
