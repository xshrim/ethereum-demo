import os, time, json, web3, timeit, asyncio, uuid, random, hashlib, string, sqlite3

from web3 import Web3
from threading import Thread
from solc import compile_source
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
    if passphrase is not None and passphrase != '':
        unlockAccount(w3, passphrase)
    return w3


# 从文件获取合约信息(address, abi)
def getContract(filepath):
    cinfo = None
    with open(filepath, 'r') as rf:
        cinfo = json.loads(rf.readline())
    return cinfo


# 解锁默认账号
def unlockAccount(w3, passphrase):
    # set pre-funded account as sender
    w3.eth.defaultAccount = w3.eth.accounts[0]
    w3.personal.unlockAccount(w3.eth.accounts[0], passphrase)


# 部署合约
def deploy(contract_source_code, w3):
    # 编译合约源码
    compiledSol = compile_source(contract_source_code)
    contractInterface = compiledSol['<stdin>:Test']

    # 生成合约对象
    Contract = w3.eth.contract(abi=contractInterface['abi'], bytecode=contractInterface['bin'])

    # with open('./test.json', 'w') as wf:
    #    wf.write(contractInterface['bin'])
    # print(contractInterface['bin'])
    # print(Contract.constructor().estimateGas(params))
    # 部署合约
    txhash = Contract.constructor().transact(params)

    # 等待合约部署交易完成
    txreceipt = w3.eth.waitForTransactionReceipt(txhash)
    print(txreceipt)
    if txreceipt['status'] != 1:
        return None

    # 将合约地址和abi进行json化保存到本地文件
    contractInfo = {'address': txreceipt.contractAddress, 'abi': contractInterface['abi']}
    with open('./test.json', 'w') as wf:
        wf.write(json.dumps(contractInfo))

    return contractInfo


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


def getReceipt(sn):
    txhash = contract.functions.getSTXByNum(sn).call()
    txreceipt = w3.eth.getTransactionReceipt(txhash)
    # receipt = contract.events.PayReceipt().processReceipt(tx_receipt)[0]['args']
    receipt = contract.events.PayReceipt().processReceipt(txreceipt)[0]
    print(receipt)
    return receipt


def getReceipts(payer="0x" + "0" * 40, payee="0x" + "0" * 40, pay=None):
    receipts = []
    sns = contract.functions.getSnSum().call()
    for i in range(0, sns):
        txhash = contract.functions.getSTXByIdx(i).call()
        txreceipt = w3.eth.getTransactionReceipt(txhash)
        receipts.append(contract.events.PayReceipt().processReceipt(txreceipt)[0])
    if pay is None:
        if payer != 0x00 and payer != "0x" + "0" * 40:
            receipts = [receipt for receipt in receipts if receipt['args']['payer'] == str(payer)]
        if payee != 0x00 and payee != "0x" + "0" * 40:
            receipts = [receipt for receipt in receipts if receipt['args']['payee'] == str(payee)]
    else:
        receipts = [
            receipt for receipt in receipts if receipt['args']['payer'] == str(pay) or receipt['args']['payee'] == str(pay)
        ]
    return receipts


'''
geth --identity=myeth --networkid=111 --nodiscover --maxpeers=10 --port=30303 --dev --dev.period=0 --gasprice=1000 --targetgaslimit=4712388000 --rpc --rpcapi=db,eth,net,web3,personal,miner,admin,debug --rpcaddr=0.0.0.0 --rpccorsdomain=* --rpcport=8545 --ws --wsapi=db,eth,net,web3,personal,miner,admin,debug --wsaddr=0.0.0.0 --wsorigins=* --wsport=8546 --datadir=/tmp console
'''

w3 = myProvider("ws://127.0.0.1:8546", "test")
params = {'from': w3.eth.coinbase, 'gas': 6000000}
if os.path.exists('./test.json'):
    contractInfo = getContract('./test.json')
else:
    estimate = w3.eth.getBlock('latest').gasLimit
    while True:
        with open('./Test.sol') as rf:
            contractSourceCode = rf.read()
        contractInfo = deploy(contractSourceCode, w3)
        if contractInfo is None:
            print('deploy failed: ' + str(estimate))
            estimate = w3.eth.getBlock('latest').gasLimit
            params = {'from': w3.eth.coinbase, 'gas': estimate}
        else:
            break
        # sys.exit(0)

contract = w3.eth.contract(
    address=contractInfo['address'],
    abi=contractInfo['abi'],
)

txreceipthash = contract.functions.setva(10, str("ok").encode('utf8')).transact(params)
txreceipt = w3.eth.waitForTransactionReceipt(w3.toHex(txreceipthash))
print(txreceipt)
print(str(w3.toHex(txreceipthash)))

txreceipthash = contract.functions.nsetva(11, str("fail").encode('utf8')).transact(params)
txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
print(txreceipt)

print(contract.functions.getva().call())

myfilter = contract.eventFilter('WatchDog', {'fromBlock': 0, 'toBlock': 'latest', 'filter': {'str': "ok".encode('utf8')}})
eventlist = myfilter.get_all_entries()
print(eventlist)

txreceipthash = contract.functions.setit().transact(params)
txreceipt = w3.eth.waitForTransactionReceipt(w3.toHex(txreceipthash))
print(txreceipt)

# event_filter = w3.eth.filter({'fromBlock': 1, 'toBlock': "latest", 'address': '0x0f84284d82dacB8ECF951c516e8EC52f8c3Bb10F'})
# event_filter = w3.eth.filter({"address": "0x0f84284d82dacB8ECF951c516e8EC52f8c3Bb10F"})
# print(event_filter.get_new_entries())
# print(w3.eth.getLogs({'fromBlock': 1, 'toBlock': "latest", 'address': '0x0f84284d82dacB8ECF951c516e8EC52f8c3Bb10F'}))

# filt = w3.eth.filter({'fromBlock': 1, 'toBlock': "latest", 'address': '0x0f84284d82dacB8ECF951c516e8EC52f8c3Bb10F'})
# logs = w3.eth.getFilterLogs(filt.filter_id)

# txreceipt = w3.eth.getTransactionReceipt("0x6eddca4b0a96d43917e448013e6f2bd8f2a4247e511366d4725f115d6e276d77")
# print(contract.events.WatchDog().processReceipt(txreceipt))
'''
hex_str = "0x{:064x}".format(10)
event_signature_hash = w3.sha3(text="WatchDog(address, string, uint64)").hex()
event_filter = w3.eth.filter({
    "address": '0x0f84284d82dacB8ECF951c516e8EC52f8c3Bb10F',
    "topics": [None, None, hex_str],
})

logs = w3.eth.getFilterLogs(event_filter.filter_id)
print(logs)
'''
# print(logs)
# txreceipthash = contract.functions.setHello("credit".encode('utf8')).transact(params)
# txreceipt = w3.eth.waitForTransactionReceipt(txreceipthash)
# print("credit".encode('utf8'))
# print(w3.toText(contract.functions.getHello().call()))

# block_filter = contract.events.PayReceipt.createFilter(fromBlock='latest')
# Thread(target=log_loop, args=(block_filter, 2), daemon=True).start()

# txhash = contract.functions.setGreeting('Hi').transact(params)
# print(w3.eth.waitForTransactionReceipt(txhash))

# addToken()
# print(getVersion().network)
# print(getAccounts())
# print(getTokenSum())
# tk = getToken(0, 0)
# print(tk.unitcode)

# print(contract.functions.getAddressCustomer(getAccounts()[8]).call())

# txhash = contract.functions.assignToken(addr, str("test"), hashs, addrs, ints).transact(params)
# txreceipt = w3.eth.waitForTransactionReceipt(txhash)
# print(txreceipt)

# for i in range(8):
#    print(getRToken(getAccounts()[i]))
# print(random.choice(getAccounts()))

# ["0x00" + "0" * 30, "0x01" + "0" * 30, "0xff" + randata([], "hash")[4:]]
# grantToken(getAccounts()[1], "0xff" + randata([], "hash")[4:])
# print(getAccounts()[0])
# enrollAddress("0xCEa677127C6b8885eF4fb7616E2875380BD6a97a", "2", "admin", "admin", 1, 0)
'''
txhash = contract.functions.logToken(0).transact(params)
txreceipt = w3.eth.waitForTransactionReceipt(txhash)
if txreceipt['status'] == 1:
    print("WatchDog", contract.events.WatchDog().processReceipt(txreceipt))
    # print("PayReceipt", contract.events.PayReceipt().processReceipt(txreceipt))
    # payreceipt = contract.events.PayReceipt().processReceipt(txreceipt)
'''
# input()
