import os, sys, time, json, getopt, asyncio
from web3 import Web3
from solc import link_code
# from solc import compile_files
from solc import compile_source
from web3.middleware import geth_poa_middleware


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
def unlockAccount(w3, addr, passphrase):
    # set pre-funded account as sender
    w3.personal.unlockAccount(addr, passphrase)


def javait(contract, output, java):
    if output == '' or not os.path.exists(output):
        output = "./"
    if os.path.isfile(output):
        output = os.path.dirname(output)
    abifile = os.path.join(output, contract['name'] + '.abi')
    binfile = os.path.join(output, contract['name'] + '.bin')
    with open(abifile, 'w', encoding='utf-8') as wf:
        wf.write(json.dumps(contract['abi']))
    with open(binfile, 'w', encoding='utf-8') as wf:
        wf.write(json.dumps(contract['bytecode']))
    cmd = "web3j solidity generate %s %s -o %s -p %s" % (binfile, abifile, output, java)
    os.system(cmd)
    os.remove(abifile)
    os.remove(binfile)


def compiler(source, output, java, mode='file'):
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
        if java != '':
            javait(contracts[-1], output, java)
        if output != '':
            with open(output, 'w', encoding='utf-8') as wf:
                wf.write(json.dumps({'contracts': contracts}))
    except Exception as ex:
        print('compile error: ' + str(ex))
    return contracts


# 部署合约
def deploy(w3, contracts, params, output, java):
    subaddrs = {}
    contractInfo = {}
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
    if java != '':
        javait(tuple(contractInfo.values())[-1], output, java)
    if output != '':
        with open(output, 'w', encoding='utf-8') as wf:
            wf.write(json.dumps(contractInfo))
    return contractInfo


def invoke(w3, fr, to, value):
    txhash = w3.eth.sendTransaction({'to': to, 'from': fr, 'value': value})
    txreceipt = w3.eth.waitForTransactionReceipt(txhash)
    if txreceipt['status'] == 1:
        return 'Succ'
    else:
        return 'Fail'


def monitor(w3):
    def handle_event(event, ftype):
        if ftype == 'block':
            print('block'.center(15, ' ').center(100, '-'))
            print(w3.eth.getBlock(event))
        if ftype == 'transaction':
            print('receipt'.center(15, ' ').center(100, '-'))
            print(w3.eth.waitForTransactionReceipt(event))
            print('transaction'.center(15, ' ').center(100, '-'))
            print(w3.eth.getTransaction(event))
        # and whatever

    async def log_loop(event_filter, ftype, poll_interval):
        while True:
            for event in event_filter.get_new_entries():
                handle_event(event, ftype)
            await asyncio.sleep(poll_interval)

    # block_filter = contract.events.WatchDog.createFilter(fromBlock='latest')  # 显示字符串
    block_filter = w3.eth.filter('latest')  # 显示字节码
    tx_filter = w3.eth.filter('pending')
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(asyncio.gather(log_loop(block_filter, 'block', 2), log_loop(tx_filter, 'transaction', 2)))
    finally:
        loop.close()


def query(w3, arg):
    try:
        if len(arg) > 2 and arg[:2] == '0x':
            blk = w3.eth.getBlock(arg)
        else:
            blk = w3.eth.getBlock(int(arg))
        return {'query': {'type': 'block', 'block': blk}}
    except Exception as ex:
        try:
            tx = w3.eth.getTransaction(str(arg))
            receipt = w3.eth.getTransactionReceipt(str(arg))
            return {'query': {'type': 'transaction', 'transaction': tx, 'receipt': receipt}}
        except Exception as ex:
            print('query failed: ' + str(ex))
            return {}


def info(w3):
    info = {}
    version = w3.version
    info['version'] = {'api': version.api, 'node': version.node, 'network': version.node, 'ethereum': version.ethereum}
    info['mining'] = w3.eth.mining
    info['syncing'] = w3.eth.syncing
    info['coinbase'] = w3.eth.coinbase
    info['accounts'] = w3.eth.accounts
    info['blocknumber'] = w3.eth.blockNumber
    info['txpool'] = w3.txpool.status
    info['nodeinfo'] = w3.admin.nodeInfo
    info['peers'] = w3.admin.peers
    info['datadir'] = w3.admin.datadir
    info['hashrate'] = w3.eth.hashrate
    info['gaslimit'] = w3.eth.getBlock('latest').gasLimit
    info['gasprice'] = w3.eth.gasPrice
    return info


def usage(mode):
    if mode == 'compile':
        print("Usage:%s -c/--compile -f/--fname <contract filename> [-o/--output <output file>] [-j/--java <java package>]" % sys.argv[0])
    elif mode == 'deploy':
        print(
            "Usage:%s -d/--deploy -u/--url <ethereum rpc> -f/--fname <contract filename> [-o/--output <output file>] [-j/--java <java package>] [-v/--value <value>]"
            % sys.argv[0])
    elif mode == 'invoke':
        print("Usage:%s -i/--invoke -u/--url <ethereum rpc> -t/--times <invoke times>" % sys.argv[0])
    elif mode == 'monitor':
        print("Usage:%s -m/--monitor -u/--url <ethereum rpc>" % sys.argv[0])
    elif mode == 'status':
        print("Usage:%s -s/--status -u/--url <ethereum rpc>" % sys.argv[0])
    elif mode == 'query':
        print("Usage:%s -q/--query -u/--url <ethereum rpc> -p/--param <query param>" % sys.argv[0])
    else:
        print("Format:%s [-c/--compile] [-d/--deploy] [-i/--invoke] [-m/--monitor] [-s/--status] [-q/--query] [-p/--param] [-o/--outpub] [-j/--java]..." % sys.argv[0])
        print('')
        print("Usage:%s -c/--compile -f/--fname <contract filename> [-o/--output <output file>] [-j/--java <java package>]" % sys.argv[0])
        print(
            "Usage:%s -d/--deploy -u/--url <ethereum rpc> -f/--fname <contract filename> [-o/--output <output file>] [-j/--java <java package>] [-v/--value <value>]"
            % sys.argv[0])
        print("Usage:%s -i/--invoke -u/--url <ethereum rpc> [-t/--times <invoke times>]" % sys.argv[0])
        print("Usage:%s -m/--monitor -u/--url <ethereum rpc>" % sys.argv[0])
        print("Usage:%s -s/--status -u/--url <ethereum rpc>" % sys.argv[0])
        print("Usage:%s -q/--query -u/--url <ethereum rpc> -p/--param <query param>" % sys.argv[0])


def show(info):
    if 'name' in info:
        print('name'.center(15, ' ').center(100, '*'))
        print(info['name'])
    if 'address' in info:
        print('address'.center(15, ' ').center(100, '*'))
        print(info['address'])
    if 'abi' in info:
        print('abi'.center(15, ' ').center(100, '*'))
        print(json.dumps(info['abi']))
    if 'bytecode' in info:
        print('bytecode'.center(15, ' ').center(100, '*'))
        print(info['bytecode'])

    if 'version' in info:
        print('version'.center(15, ' ').center(100, '*'))
        print(info['version'])
    if 'mining' in info:
        print('mining'.center(15, ' ').center(100, '*'))
        print(info['mining'])
    if 'syncing' in info:
        print('syncing'.center(15, ' ').center(100, '*'))
        print(info['syncing'])
    if 'coinbase' in info:
        print('coinbase'.center(15, ' ').center(100, '*'))
        print(info['coinbase'])
    if 'accounts' in info:
        print('accounts'.center(15, ' ').center(100, '*'))
        print(info['accounts'])
    if 'blocknumber' in info:
        print('blocknumber'.center(15, ' ').center(100, '*'))
        print(info['blocknumber'])
    if 'txpool' in info:
        print('txpool'.center(15, ' ').center(100, '*'))
        print(info['txpool'])
    if 'nodeinfo' in info:
        print('nodeinfo'.center(15, ' ').center(100, '*'))
        print(info['nodeinfo'])
    if 'peers' in info:
        print('peers'.center(15, ' ').center(100, '*'))
        print(info['peers'])
    if 'datadir' in info:
        print('datadir'.center(15, ' ').center(100, '*'))
        print(info['datadir'])
    if 'hashrate' in info:
        print('hashrate'.center(15, ' ').center(100, '*'))
        print(info['hashrate'])
    if 'gaslimit' in info:
        print('gaslimit'.center(15, ' ').center(100, '*'))
        print(info['gaslimit'])
    if 'gasprice' in info:
        print('gasprice'.center(15, ' ').center(100, '*'))
        print(info['gasprice'])
    if 'query' in info:
        print('query'.center(15, ' ').center(100, '*'))
        print(info['query'])


if "__main__" == __name__:
    action = ''
    fname = ''
    output = ''
    java = ''
    gas = 60000000
    url = ''
    value = 0
    times = 1
    param = ''
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hcdimsqt:f:o:g:j:p:u:v:", [
            "help", "compile", "deploy", "invoke", "monitor", "status", "query", "times=", "file=", "output=", "gas=", "java=",
            "param=", "url=", "value="
        ])

        #print("============ opts ==================")
        #print(opts)

        #print("============ args ==================")
        #print(args)

        # check all param
        for opt, arg in opts:
            if opt in ("-h", "--help"):
                usage('help')
                sys.exit(1)
            elif opt in ("-c", "--compile"):
                action = 'compile'
            elif opt in ("-d", "--deploy"):
                action = 'deploy'
            elif opt in ("-i", "--invoke"):
                action = 'invoke'
            elif opt in ("-m", "--monitor"):
                action = 'monitor'
            elif opt in ("-s", "--status"):
                action = 'status'
            elif opt in ("-q", "--query"):
                action = 'query'
            elif opt in ("-t", "--times"):
                times = int(arg)
            elif opt in ("-f", "--file"):
                fname = arg
            elif opt in ("-o", "--output"):
                output = arg
            elif opt in ("-g", "--gas"):
                gas = int(arg)
            elif opt in ("-j", "--java"):
                java = arg
            elif opt in ("-p", "--param"):
                param = arg
            elif opt in ("-u", "--url"):
                url = arg
            elif opt in ("-v", "--value"):
                value = int(arg)

            else:
                print("%s  ==> %s" % (opt, arg))

        print(action.center(12, ' ').center(120, '#'))

        if action == 'compile':
            if fname != '':
                try:
                    print('compiling ...'.ljust(25) + '<' + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    contracts = compiler(fname, output, java, 'file')
                    print('compile done ...'.ljust(25) + '<' + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) +
                          '>')
                    for contract in contracts:
                        show(contract)
                except Exception as ex:
                    print('compile failed: ' + str(ex))
                    sys.exit(1)
            else:
                usage('compile')
                sys.exit(1)
        if action == 'deploy':
            if fname != '' and url != '':
                try:
                    print('compiling ...'.ljust(25) + '<' + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    contracts = compiler(fname, '', '', 'file')
                    print('compile done ...'.ljust(25) + '<' + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) +
                          '>')
                    print('connecting to ethereum ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    w3 = myProvider(url)
                    print('connected,    excuting ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    params = {'from': w3.eth.coinbase, 'gas': gas}
                    if value > 0:
                        params['value'] = value
                    # params = {'from': w3.eth.coinbase, 'gas': 60000000, 'value': 5000000000000000000000}
                    print('deploying ...'.ljust(25) + '<' + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    contractInfo = deploy(w3, contracts, params, output, java)
                    if len(contractInfo) > 0:
                        print('deploy done ...'.ljust(25) + '<' +
                              time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    else:
                        print('deploy failed ...'.ljust(25) + '<' +
                              time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    for _, v in contractInfo.items():
                        show(v)
                except Exception as ex:
                    print('deploy failed: ' + str(ex))
                    sys.exit(1)
            else:
                usage('deploy')
                sys.exit(1)
        if action == 'invoke':
            if url != '':
                try:
                    print('connecting to ethereum ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    w3 = myProvider(url)
                    print('connected, excuting ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    fr = w3.eth.coinbase
                    to = w3.eth.accounts[1]
                    if value < 1000000:
                        value = 1000000
                    for i in range(times):
                        print('invoke ' + str(i + 1) + ': ' + invoke(w3, fr, to, value))
                        time.sleep(1)
                except Exception as ex:
                    print('invoke failed: ' + str(ex))
                    sys.exit(1)
            else:
                usage('invoke')
                sys.exit(1)
        if action == 'monitor':
            if url != '':
                try:
                    print('connecting to ethereum ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    w3 = myProvider(url)
                    print('connected, excuting ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    print('monitor start ...'.ljust(25) + '<' + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) +
                          '>')
                    monitor(w3)
                    print('monitor finished...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                except Exception as ex:
                    print('monitor failed: ' + str(ex))
                    sys.exit(1)
            else:
                usage('monitor')
                sys.exit(1)
        if action == 'status':
            if url != '':
                try:
                    print('connecting to ethereum ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    w3 = myProvider(url)
                    print('connected, excuting ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    print('collecting info ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    show(info(w3))
                    print(
                        'collect done...'.ljust(25) + '<' + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                except Exception as ex:
                    print('collect failed: ' + str(ex))
                    sys.exit(1)
            else:
                usage('status')
                sys.exit(1)
        if action == 'query':
            if url != '' and param != '':
                try:
                    print('connecting to ethereum ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    w3 = myProvider(url)
                    print('connected, excuting ...'.ljust(25) + '<' +
                          time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    print('querying ...'.ljust(25) + '<' + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) + '>')
                    show(query(w3, param))
                    print('query finished ...'.ljust(25) + '<' + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())) +
                          '>')
                    pass
                except Exception as ex:
                    print('query failed: ' + str(ex))
                    sys.exit(1)
            else:
                usage('query')
                sys.exit(1)
        print('#' * 120)
        # print(action, fname, url, times)

    except getopt.GetoptError:
        print("getopt error!")
        usage('error')
        sys.exit(1)
