import core
from web3.auto import w3
from web3 import Web3
from web3.middleware import geth_poa_middleware

# 直接使用web3自动的自动连接功能
w3.middleware_stack.inject(geth_poa_middleware, layer=0)
num = w3.eth.blockNumber
tnum = 0
btlist = []
# 计算每个区块的交易数量
for i in range(0, num + 1):
    trans = w3.eth.getBlock(i).transactions
    btlist.append((i, len(trans)))
    for tran in trans:
        tnum += 1
        tranhash = Web3.toHex(tran)
        res = w3.eth.getTransactionReceipt(tranhash)
        print(str(i) + ':' + str(res))
        #info = w3.eth.getTransaction(trans)
        #pint(info)

# 调用合约内计数函数获取交易计数
contractInfo = core.getContract('./cinfo.json')
contract = w3.eth.contract(
    address=contractInfo['address'],
    abi=contractInfo['abi'],
)
print(contract.functions.getCount().call())

# 查看每个区块交易数
for bt in btlist:
    print(bt)
# 查看区块总数和总交易数
print(num, tnum)