import os, sys, time, json, web3, timeit, asyncio, uuid, random, hashlib, string, sqlite3

from web3 import Web3
from threading import Thread
from solc import compile_source
from solc import link_code
from pymongo import MongoClient
from web3.contract import ConciseContract
from web3.middleware import geth_poa_middleware

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


# 从文件获取合约信息(address, abi)
def getContract(filepath, contractName=""):
    cinfo = None
    contract = None
    try:
        if contractName is None or contractName == "":
            contractName = os.path.splitext(os.path.os.path.basename(filepath))[0]
        with open(filepath, 'r') as rf:
            cinfo = json.loads(rf.readline())
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


def getAddr(uid):
    uaddr, uid, utype, uname, uhash, ulevel, utimestamp, ustatus = contract.functions.getUserById(uid).call()
    print(w3.toHex(uaddr))
    return str(w3.toHex(uaddr))


def getUser(idx):
    uaddr, uid, utype, uname, uhash, ulevel, utimestamp, ustatus = contract.functions.getUserByIdx(idx).call()
    # print(uid)
    print(w3.toHex(uid))
    return str(w3.toHex(uid))


def getItem(idx):
    ids, itype, title, ihash, path, level, timestamp, ustatus = contract.functions.getItemByIdx(idx).call()
    # print(uid)
    # print(w3.toHex(uid))
    print(w3.toHex(ids[0]), w3.toHex(ids[1]), w3.toText(title))
    return str(w3.toHex(ids[0]))


def getPerm(idx):
    ids, ptype, ptimestamp, ptime, ptimes, status = contract.functions.getPermByIdx(idx).call()
    print(w3.toHex(ids[0]), w3.toHex(ids[1]), w3.toHex(ids[2]), w3.toHex(ids[3]))
    return str(w3.toHex(ids[0]))


def queryEvent():
    # b'^a\x82L\x9a\xcbg\xfd\xa9\xc5\x00\x10\x184\xea\n\xf2x{\xa6\x06\xca3\x01\xce\xfd\xd2}\xf4a\x17\xff'
    # str(w3.sha3(text="uMYHF94C6"))
    # myfilter = contract.eventFilter('TXReceipt', {'fromBlock': 175, 'toBlock': 'latest', 'filter': {'payee': getAccounts()[1]}})
    myfilter = contract.eventFilter(
        'TXReceipt',
        {
            'fromBlock': 0,
            'toBlock': 'latest',
            #'filter': {
            #    'sn': "TJah0LveE".encode('utf8')
            #}
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


# addUser
def addUser(idx):
    addr = w3.eth.accounts[idx]
    uid = "0x" + str(uuid.uuid1().hex)
    itype = "user".encode('utf8')
    name = randata([], "str", 6).encode('utf8')
    ihash = "0x" + str(uuid.uuid1().hex)
    level = 2
    status = 1

    sn = "0x" + str(uuid.uuid1().hex)
    details = "addUser"

    params = {
        'from': w3.eth.coinbase,
        'gas': w3.eth.getBlock('latest').gasLimit,
        'value': int(w3.eth.getBalance(w3.eth.coinbase) / 10)
    }
    txreceipthash = contract.functions.addUser(sn, details, addr, uid, itype, name, ihash, level, status).transact(params)
    txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
    print(txreceipt)
    return uid


# addItem
def addItem():
    userid = getUser(1)
    itemid = "0x" + str(uuid.uuid1().hex)
    ids = [itemid, userid]
    itype = "video".encode('utf8')
    title = "sample video".encode('utf8')
    ihash = "0x" + str(uuid.uuid1().hex)
    path = "/root/sample.mp4".encode('utf8')
    level = 2
    status = 1

    sn = "0x" + str(uuid.uuid1().hex)
    details = "addItem"

    params = {
        'from': w3.eth.coinbase,
        'gas': w3.eth.getBlock('latest').gasLimit,
        'value': int(w3.eth.getBalance(w3.eth.coinbase) / 10)
    }
    txreceipthash = contract.functions.addItem(sn, details, ids, itype, title, ihash, path, level, status).transact(params)
    txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
    print(txreceipt)
    return itemid


# addPerm
def addPerm(userid, itemid, addr=None, passphrase="node1"):
    permid = "0x" + str(uuid.uuid1().hex)
    # userid = getUser(2)
    # itemid = getItem(0)
    ids = [permid, userid, itemid]
    device = 'windows'.encode('utf8')
    ptype = [0, 1, 1]
    ptimestamp = [1531357394956, 1531789394956]
    ptime = [10, 10]
    ptimes = [22, 22]
    status = 1

    sn = "0x" + str(uuid.uuid1().hex)
    details = "addPerm"
    if addr is None:
        addr = w3.eth.coinbase
    unlockAccount(addr, passphrase)
    params = {'from': addr, 'gas': w3.eth.getBlock('latest').gasLimit, 'value': int(w3.eth.getBalance(addr) / 10)}
    txreceipthash = contract.functions.addPerm(sn, details, ids, device, ptype, ptimestamp, ptime, ptimes,
                                               status).transact(params)
    txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
    print(txreceipt)
    return permid


'''
./geth --identity "myeth" --networkid 111 --nodiscover --maxpeers 10 --port "30303" --dev --dev.period=0 --targetgaslimit 80000000  --rpc --rpcapi "db,eth,net,web3,personal,miner,admin,debug" --rpcaddr 0.0.0.0 --rpcport "8545" --ws --wsaddr 0.0.0.0 --wsorigins=* --wsapi "db,eth,net,web3,personal,miner,admin,debug" --wsport "8546" --datadir "/tmp" console
'''

# rmongo = MyMongoDB(setname="record")
# tmongo = MyMongoDB(setname="token")

# 合约名
cname = "ControlContract"

w3 = myProvider("ws://127.0.0.1:8546", "test")
# w3 = myProvider("ws://127.0.0.1:8546", "test")
params = {
    'from': w3.eth.coinbase,
    'gas': w3.eth.getBlock('latest').gasLimit,
    'value': int(w3.eth.getBalance(w3.eth.coinbase) / 10)
}
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
'''
'''
txreceipthash = contract.functions.setid("420922198811274614".encode()).transact(params)
txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
print(txreceipt)
print(w3.toText(contract.functions.getid().call()))
'''
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
# params = {'from': w3.eth.coinbase, 'gas': w3.eth.getBlock('latest').gasLimit, 'value': int(w3.eth.getBalance(w3.eth.coinbase) / 10)}

params = {'from': w3.eth.coinbase, 'gas': 60000000}
'''
txreceipthash = contract.functions.setBalance(w3.eth.accounts[1], 100).transact(params)
txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
print(txreceipt)
print(contract.functions.getBalance(w3.eth.accounts[1]).call())
'''

print(contract.functions.addTen(w3.eth.accounts[1]).call())
txreceipthash = contract.functions.addIt(w3.eth.accounts[1]).transact(params)
txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
print(txreceipt)
print(contract.functions.addTen(w3.eth.accounts[1]).call())

# 0x881c69043cD24c153782010DdDF9f0eCd4f0dde5
