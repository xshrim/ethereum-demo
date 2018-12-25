pragma solidity ^0.4.23;

contract Exchange {
    struct Token {
        bytes32 idhash;         // Token唯一标识
        bytes32 parenthash;     // 父Token唯一标识, ""0x00": 没有父Token
        bytes32 origincode;     // 分配码(最初授予Token的相关信息), "0x00": 分配而来, "0x01": 拆分而来,  还可以是一些信息的hash
        bytes32 statuscode;     // Token状态改变码, "0x00": 因分配而改变, "0x01": 因拆分而改变, "0x10": 因进入其他链而改变, "0x11": 不可用, 还可以是一些具体原因的hash(如交易合同)
        bytes32 itemcode;       // 物品码, Token对应的物品编码, "0x00"表示额度
        address saddr;          // Token最初所属地址
        address caddr;          // Token当前所属地址
        uint snetwork;        // Token最初所属网络
        uint cnetwork;        // Token当前所属网络
        uint amount;            // Token份额(最小可拆分数)
        uint unit;              // Token度量单位, 0表示rmb 1分
        uint gtimestamp;        // Token生成时间
        uint ctimestamp;        // Token最后一次流转时间
        uint stimestamp;        // Token最后一次状态改变时间
        uint status;            // Token当前状态, 0: normal, 1: external, 2: freezen, 6: invalid 
    }

    
    uint networkid = 111;

    uint tknum;
    mapping (uint => bytes32) tkidxs;
    mapping (bytes32 => Token) tokens;              // tkid => Token
    mapping (bytes32 => address) ledgers;
    uint sncount;
    mapping (uint => string) sns;
    mapping (string => string) stxs;
    mapping (address => uint) vbalances;            // 可用额度
    mapping (address => uint) ebalances;            // 外部额度
    mapping (address => uint) fbalances;            // 冻结额度

    uint count;
    string greeting;
    
    /* 交易凭据日志
    //@param sender: 交易发起者地址
    //@param payer: 交易付款者地址
    //@param payee: 交易收款者地址
    //@param totkids: 支付给收款者的Token id列表
    //@param splittkid: 被拆分的Token id
    //@param topayertkid: 拆分Token后返还给付款者的Token id
    //@param topayeetkid: 拆分Token后支付给收款者的Token id列表
    //@param timestamp: 交易时间戳
    */
    event WatchDog (string themsg, uint res);
    event PayReceipt (address sender, address payer, address payee, string detail, uint timestamp);


    constructor() public {
        // tkids.push("0x00");
        // tokens["0x00"] = Token("0x00", "0x00", "0x00", "0x00", 0x00, 0x00, 0, 0, 0, 0, 0, 0, 0, 2);
    }

    // 测试函数
    function setGreeting(string greet) public {
        greeting = greet;
        count++;
        emit WatchDog(greet, count);
    }

    function getGreet() view public returns (string) {
        return greeting;
    }

    function getCount() view public returns (uint) {
        return count;
    }

    /* 判断指定id的token是否存在
    //@param tkid: Token的id
    //@return 1: Token是否存在
    */
    function isTokenExist(bytes32 tkid) public view returns (bool) {
        if (tokens[tkid].idhash == tkid) {
            return true;
        } else {
            return false;
        }
    }


    /* 获取Token总计数(包括作废的和冻结的)
    //@return 1: Token总计数
    */
    function gettknum() public view returns (uint) {
        return tknum;
    }
 
  
    /* 获取指定索引的Token
    //@param tkidx: Token的索引
    //@return 1: Token的idhash, parenthash, origincode, statuscode, itemcode; 2: Token的saddr, caddr; 3: Token的snetwork, cnetwork, amount, price, gtimestamp, ctimestamp, stimestamp, status
    */
    function getTokenByIdx(uint tkidx) public view returns (bytes32[5], address[2], uint[8]) {
        Token storage tk = tokens[tkidxs[tkidx]];
        return ([tk.idhash, tk.parenthash, tk.origincode, tk.statuscode, tk.itemcode], [tk.saddr, tk.caddr], [tk.snetwork, tk.cnetwork, tk.amount, tk.unit, tk.gtimestamp, tk.ctimestamp, tk.stimestamp, tk.status]);
    }


    /* 获取指定id的Token
    //@param tkid: Token的id
    //@return 1: Token的idhash, parenthash, origincode, statuscode, compactcode, itemcode; 2: Token的saddr, caddr; 3: Token的snetwork, cnetwork, amount, price, gtimestamp, ctimestamp, stimestamp, status
    */
    function getTokenById(bytes32 tkid) public view returns (bytes32[5], address[2], uint[8]) {
        if (isTokenExist(tkid) == false) {
            return ([bytes32("0x00"), "0x00", "0x00", "0x00", "0x00"], [address(0x00), 0x00], [uint(0), 0, 0, 0, 0, 0, 0, 2]);
        } else {
            Token storage tk = tokens[tkid];
            return ([tk.idhash, tk.parenthash, tk.origincode, tk.statuscode, tk.itemcode], [tk.saddr, tk.caddr], [tk.snetwork, tk.cnetwork, tk.amount, tk.unit, tk.gtimestamp, tk.ctimestamp, tk.stimestamp, tk.status]);
        }
    }
    
    
    /* 获取指定Token idx的当前持有者
    //@param tkidx: Token的idx
    //@return 1: Token所有者地址
    */
    function getTokenHolderByIdx(uint tkidx) public view returns (address) {
        return ledgers[tkidxs[tkidx]];
        
    }

    
    /* 获取指定Token id的当前持有者
    //@param tkid: Token的id
    //@return 1: Token所有者地址
    */
    function getTokenHolderById(bytes32 tkid) public view returns (address) {
        return ledgers[tkid];
        
    }
    

    /* 获取流水号数量
    //@return 1: 流水数量
    */
    function getsncount() public view returns (uint) {
        return sncount;
    }


    /* 根据交易流水号获取区块链上的交易号
    //@param rnum: 流水号
    //@return 1: 交易号
    */
    function getSTXByNum(string sn) public view returns (string) {
        return stxs[sn];
    }


    /* 根据流水索引号获取区块链上的交易号
    //@param idx: 流水索引号
    //@return 1: 交易号
    */
    function getSTXByIdx(uint idx) public view returns (string) {
        return stxs[sns[idx]];
    }


    /* 将交易流水号与区块链上的交易号相关联
    //@param rnum: 交易流水号
    //@param txhash: 交易hash
    //@return 1: 流水号
    */
    function setSTX(string sn, string txhash) public returns (string) {
        sns[sncount++] = sn;
        stxs[sn] = txhash;
        return sn;
    }

    
    /* 向地址发行Token
    //@param receiver: 接收Token的地址
    //@param hashs: Token的id, parentid, origincode, statuscode, itemcode
    //@param addrs: Token的saddr, caddr
    //@param networkids: Token的snetwork, cnetwork
    //@param aus: Token的amount, unit
    //@param timestamps: Token的gtimestamp, ctimestamp, stimestamp
    //@param status: Token的status
    //@return 1: 是否发行成功
    */
    function issueToken(address receiver, bytes32[5] hashs, address[2] addrs, uint[2] networkids, uint[2] aus, uint[3] timestamps, uint status) public returns (bool) {
        tkidxs[tknum++] = hashs[0];
        tokens[hashs[0]] = Token(hashs[0], hashs[1], hashs[2], hashs[3], hashs[4], addrs[0], addrs[1], networkids[0], networkids[1], aus[0], aus[1], timestamps[0], timestamps[1], timestamps[2], status);
        ledgers[hashs[0]] = receiver;
        if (hashs[4] == bytes32("0x00")) {
            if (status == 0) {
                vbalances[receiver] += aus[0] * aus[1];
            } else {
                if (status == 1) {
                    ebalances[receiver] += aus[0] * aus[1];
                } else {
                    if (status == 2) {
                        fbalances[receiver] += aus[0] * aus[1];
                    }
                }
            }
        }
        return true;
    }


    /* 向指定地址分配Token
    //@param receiver: 接收Token地址
    //@param details: 交易信息
    //@param hashs: Token的id, parentid, origincode, statuscode, itemcode
    //@param addrs: Token的saddr, caddr
    //@param networkids: Token的snetwork, cnetwork
    //@param aus: Token的amount, unit
    //@param timestamps: Token的gtimestamp, ctimestamp, stimestamp
    //@param status: 分配的Token的状态
    //@return 1: 是否分配成功
    */
    function assignToken(address receiver, string details, bytes32[5] hashs, address[2] addrs, uint[2] networkids, uint[2] aus, uint[3] timestamps, uint status) public returns (bool) {
        if (msg.sender == block.coinbase && issueToken(receiver, hashs, addrs, networkids, aus, timestamps, status)) {
            emit PayReceipt(block.coinbase, msg.sender, receiver, details, timestamps[0]);
            return true;
        } else {
            return false;
        }
    }
    
    
    /* 发起一笔完整的交易
    //@param receiver: 收款方
    //@param details: 交易详细信息
    //@param tkids: 需要将哪些付款方已有token给收款方
    //@param splittkid: 需要拆分付款方的哪个token
    //@param hashs: 拆分token后返还和支付的token id (0, 1) 和 itemcode (2, 3)
    //@params addrs: 拆分token后返还和支付的token saddr (0, 1) 和 caddr (2, 3)
    //@param aps: 拆分token后返还和支付的token amount (0, 1) 和 unit (2, 3)
    //@param timestamp: 拆分token后返还和支付的token timestamp
    //@return 1: 是否交易成功
    */
    function transactFull(address receiver, string details, bytes32[] tkids, bytes32 splittkid, bytes32[4] hashs, address[4] addrs, uint[4] aus, uint timestamp) public returns (bool) {
        if (msg.sender != 0x00 && msg.sender != block.coinbase) {
            for (uint i = 0; i < tkids.length; i++) {
                transToken(receiver, tkids[i], timestamp);
            }
            if (splittkid != "0x00") {
                setToken(splittkid, "0x11", timestamp, 6);
                issueToken(msg.sender, [hashs[0], splittkid, "0x01", "0x01", hashs[2]], [addrs[0], addrs[2]], [networkid, networkid], [aus[0], aus[2]], [timestamp, timestamp, timestamp], 0);
                issueToken(receiver, [hashs[1], splittkid, "0x01", "0x01", hashs[3]], [addrs[1], addrs[3]], [networkid, networkid], [aus[1], aus[3]], [timestamp, timestamp,timestamp], 0);
            }
            //emit PayReceipt(msg.sender, addrs, totkids, companys[a].balances[uint(splittkidx)], idhashs[0], idhashs[1], timestamps[1]);
            emit PayReceipt(msg.sender, msg.sender, receiver, details, timestamp);
            return true;
        } else {
            return false;
        }
        // TODO: emit event
    }
    
    
    /* 设置指定公司的指定索引的Token状态
    //@param tkid: Token id
    //@param  stimestamp: Token状态变化时间戳
    //@param status: Token需要改变的状态
    //@return 1: 是否设置成功
    */
    function setToken(bytes32 tkid, bytes32 statuscode, uint stimestamp, uint status) public returns (bool) {
        if (ledgers[tkid] == msg.sender) {
            Token storage tk = tokens[tkid];
            if (tk.itemcode == bytes32("0x00")) {
                if (tk.status == 0) {
                    if (status == 1) {
                        vbalances[msg.sender] -= tk.amount;
                        ebalances[msg.sender] += tk.amount;
                    } else {
                        if (status == 2) {
                            vbalances[msg.sender] -= tk.amount;
                            fbalances[msg.sender] -= tk.amount;
                        } else {
                            if (status == 6) {
                                vbalances[msg.sender] -= tk.amount;
                            }
                        }
                    }
                } else {
                    if (tk.status == 1) {
                        if (status == 0) {
                            ebalances[msg.sender] -= tk.amount;
                            vbalances[msg.sender] += tk.amount;
                        } else {
                            if (status == 2) {
                                ebalances[msg.sender] -= tk.amount;
                                fbalances[msg.sender] += tk.amount;
                            } else {
                                if (status == 6) {
                                    ebalances[msg.sender] -= tk.amount;
                                }
                            }
                        }
                    } else {
                        if (tk.status == 2) {
                            if (status == 0) {
                                fbalances[msg.sender] -= tk.amount;
                                vbalances[msg.sender] += tk.amount;
                            } else {
                                if (status == 1) {
                                    fbalances[msg.sender] -= tk.amount;
                                    ebalances[msg.sender] += tk.amount;
                                } else {
                                    if (status == 6) {
                                        fbalances[msg.sender] -= tk.amount;
                                    }
                                }
                            }
                        } else {
                            if (tk.status == 6) {
                                if (status == 0) {
                                    vbalances[msg.sender] += tk.amount;
                                } else {
                                    if (status == 1) {
                                        ebalances[msg.sender] += tk.amount;
                                    } else {
                                        if (status == 2) {
                                            fbalances[msg.sender] += tk.amount;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            tk.statuscode = statuscode;
            tk.stimestamp = stimestamp;
            tk.status = status;
            return true;
        }
    }

  
    /* 进行公司间交易
    //@param from: 付款方
    //@param to: 收款方
    //@param tkidx: 需要支付的Token在付款方额度中的索引
    //@param ctimestamp: Token流转时间戳
    //@return 1: Token流转是否成功
    */
    function transToken(address receiver, bytes32 tkid, uint ctimestamp) public returns (bool) {
        if (ledgers[tkid] == msg.sender) {
            Token storage tk = tokens[tkid];
            ledgers[tkid] = receiver;
            tk.caddr = receiver;
            tk.ctimestamp = ctimestamp;
            if (tk.itemcode == bytes32("0x00")) {
                vbalances[msg.sender] -= tk.amount;
                vbalances[receiver] += tk.amount;
            }
            return true;
        }
    }
    
    // TODO: Company删除
    // TODO: Token移除与合并
}