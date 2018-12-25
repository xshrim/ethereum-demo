import os, sys, time, json, web3, timeit, asyncio, uuid, random, hashlib, sqlite3

from web3 import Web3
from threading import Thread
from solc import compile_source
from solc import compile_files
from solc import link_code
from web3.contract import ConciseContract
from web3.middleware import geth_poa_middleware

# 智能合约代码
csc = '''
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
def deploy(csc, w3):
    # 编译合约源码
    compiledSol = compile_source(csc)
    # contractId, contractInterface = compiledSol.popitem()
    contracts = []
    subaddrs = {}
    contractInfo = {}
    for contractId, contractInterface in compiledSol.items():
        ctt = {}
        ast = contractInterface['ast']['children']
        for item in ast:
            if len(item['attributes'].keys()) > 2:
                if str(contractId).split(':')[-1] == str(item['attributes']['name']):
                    ctt['name'] = contractId
                    ctt['type'] = item['attributes']['contractKind']
                    ctt['abi'] = contractInterface['abi']
                    ctt['bytecode'] = contractInterface['bin']
                    contracts.append(ctt)

    # contractInterface = compiledSol['<stdin>:' + cname]
    for cont in contracts:
        if '__' not in cont['bytecode']:
            # 生成合约对象
            Contract = w3.eth.contract(abi=cont['abi'], bytecode=cont['bytecode'])
            # 部署合约
            txhash = Contract.constructor().transact(params)
            # 等待合约部署交易完成
            txreceipt = w3.eth.waitForTransactionReceipt(txhash)
            subaddrs[cont['name']] = txreceipt.contractAddress
            contractInfo[cont['name']] = {'id': cont['name'], 'address': txreceipt.contractAddress, 'abi': cont['abi']}
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
            subaddrs[cont['name']] = txreceipt.contractAddress
            # 将合约地址和abi进行json化保存到本地文件
            print(bytecode)
            contractInfo[cont['name']] = {'id': cont['name'], 'address': txreceipt.contractAddress, 'abi': cont['abi']}
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


w3 = myProvider("ws://127.0.0.1:8546", "test")
params = {'from': w3.eth.coinbase, 'gas': 4700000}
if os.path.exists('./test.json'):
    contractInfo = getContract('./test.json')
else:
    with open('./Test.sol') as rf:
        csc = rf.read()
    contractInfo = deploy(csc, w3)

cti = contractInfo['<stdin>:A']
contract = w3.eth.contract(
    address=cti['address'],
    abi=cti['abi'],
)

print(contract.functions.a().call())
print(contract.functions.b("好的哈哈".encode('utf8')).call())
