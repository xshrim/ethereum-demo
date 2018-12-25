import sys, time, json, web3, timeit, asyncio
from web3 import Web3
from threading import Thread
from solc import compile_source
from web3.contract import ConciseContract
from web3.middleware import geth_poa_middleware


# 解锁默认账号
def unlockAccount(w3, passphrase):
    # set pre-funded account as sender
    w3.eth.defaultAccount = w3.eth.accounts[0]
    w3.personal.unlockAccount(w3.eth.accounts[0], passphrase)


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


def handle_event(event):
    print(event)
    # and whatever


async def log_loop(event_filter, poll_interval):
    while True:
        for event in event_filter.get_new_entries():
            handle_event(event)
        await asyncio.sleep(poll_interval)


w3 = myProvider("ws://127.0.0.1:8546", "test")
#with open('./Exchange.sol') as rf:
#    contractSourceCode = rf.read()
# contractInfo = deploy(contractSourceCode, w3)
contractInfo = getContract('./cinfo.json')
param = {'from': w3.eth.coinbase, 'gas': 4700000}
contract = w3.eth.contract(
    address=contractInfo['address'],
    abi=contractInfo['abi'],
)

block_filter = contract.events.WatchDog.createFilter(fromBlock='latest')  # 显示字符串
#block_filter = w3.eth.filter('latest')                                     # 显示字节码
tx_filter = w3.eth.filter('pending')
loop = asyncio.get_event_loop()
try:
    loop.run_until_complete(asyncio.gather(log_loop(block_filter, 2), log_loop(tx_filter, 2)))
finally:
    loop.close()
