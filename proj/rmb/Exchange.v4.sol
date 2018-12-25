pragma solidity ^0.4.23;

contract Exchange {
    struct Token {
        bytes16 idhash;         // Token唯一标识
        bytes16 parenthash;     // 父Token唯一标识, ""0x00": 没有父Token
        bytes16 origincode;     // Token分配码(最初授予Token的相关信息), "0x00: 分配而来, "0x00":  拆分而来,  还可以是一些信息的hash
        bytes16 statuscode;     // Token状态改变码, "0x00": 因分配而改变, "0x01": 因拆分而改变, "0x10": 因进入其他链而改变, "0x11": 不可用, 还可以是一些具体原因的hash(如交易合同)
        bytes16 typecode;       // Token类型码, "credit"表示额度, "tender"表示法币, 其他表示普通物品类
        bytes16 itemcode;       // Token物品码, Token对应的物品编码
        bytes16 unitcode;       // Token度量码, Token的度量单位
        address saddr;          // Token最初所属地址
        address caddr;          // Token当前所属地址
        uint64 snetwork;        // Token最初所属网络
        uint64 cnetwork;        // Token当前所属网络
        uint64 amount;          // Token份额(最小可拆分数)
        uint64 gtimestamp;      // Token生成时间
        uint64 ftimestamp;      // Token生效时间
        uint64 etimestamp;      // Token失效时间
        uint64 ctimestamp;      // Token最后一次流转时间
        uint64 stimestamp;      // Token最后一次状态改变时间
        uint64 status;          // Token当前状态, 0: normal, 1: external, 2: freezen, 6: invalid 
    }

    struct Item {
        string desc;
    }
    
    // uint networkid = 111;

    address public owner;

    uint64 tknum;
    mapping (uint64 => bytes16) tkidxs;              // token index => token id
    mapping (bytes16 => Token) tokens;             // token id => Token
    mapping (bytes16 => address) ledgers;          // token id => address
    mapping (bytes16 => bytes16) items;            // itemcode => token id
    mapping (address => bytes16[]) heldtokens;     // address => token id
    uint64 sncount;
    mapping (uint64 => string) sns;
    mapping (string => string) stxs;
    mapping (address => uint64[2]) counts;          // 持有Token数量(0:总数量, 1:有效状态的数量)
    /*
    mapping (address => uint) vbalances;            // 可用额度
    mapping (address => uint) ebalances;            // 外部额度
    mapping (address => uint) fbalances;            // 冻结额度
    */

    uint64 count;
    string greeting;
    bytes16 hello;
    
    /* 交易凭据日志
    //@param sender: 交易发起者地址
    //@param payer: 交易付款者地址
    //@param payee: 交易收款者地址
    //@param detail: 交易详细信息
    //@param timestamp: 交易时间戳
    */
    event WatchDog (string themsg, bytes16 thimsg, uint res);
    event PayReceipt (address sender, address indexed payer, address indexed payee, string detail, uint timestamp);


    constructor() public {
        owner = msg.sender;
        // tkids.push("0x00");
        // tokens["0x00"] = Token("0x00", "0x00", "0x00", "0x00", 0x00, 0x00, 0, 0, 0, 0, 0, 0, 0, 2);
    }

    // 修饰器
    modifier onlyOwner() {
        require (msg.sender == owner, "sender != owner");
        /*
        if (msg.sender != owner) {
            revert("sender != owner");
        }
        */
        _;
    }

    // 修饰器
    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }

    // 测试函数
    function setGreeting(string greet) public {
        greeting = greet;
        count++;
        emit WatchDog(greet, bytes16("0x00"), count);
    }

    function setHello(bytes16 hi) public {
        hello = hi;
    }

    function getHello() view public returns (bytes16) {
        if (hello == bytes16("credit")) {
            return hello;
        } else {
            return bytes16("Fail");
        }
    }

    function getGreet() view public returns (string) {
        return greeting;
    }

    function getCount() view public returns (uint64) {
        return count;
    }

    /* 判断指定id的token是否存在
    //@param tkid: Token的id
    //@return 1: Token是否存在
    */
    function isTokenExist(bytes16 tkid) public view returns (bool) {
        if (tokens[tkid].idhash == tkid) {
            return true;
        } else {
            return false;
        }
    }

    /* 判断指定item是否存在
    //@param itemcode: Token的id
    //@return 1: item的Token id
    */
    function isItemExist(bytes16 itemcode) public view returns (bytes16) {
        return items[itemcode];
    }


    /* 获取Token总计数(包括作废的和冻结的)
    //@return 1: Token总计数; 2: 可用Token总数
    */
    function getTokenSum(address addr) public view returns (uint64, uint64) {
        if (msg.sender == block.coinbase) {
            if (addr == address(0)) {
                return (tknum, 0);
            } else {
                return (counts[addr][0], counts[addr][1]);
            }
        } else {
            return (counts[msg.sender][0], counts[msg.sender][1]);
        }
    }

  
    /* 获取指定索引的Token
    //@param tkidx: Token的索引
    //@return 1: Token的idhash, parenthash, origincode, statuscode, typecode, itemcode, unitcode; 2: Token的saddr, caddr; 3: Token的snetwork, cnetwork, amount, gtimestamp, ftimestamp, etimestamp, ctimestamp, stimestamp, status
    */
    function getTokenByIdx(uint64 tkidx) public view returns (bytes16[7], address[2], uint64[9]) {
        if (tkidx < 0 || tkidx >= tknum) {
            return ([bytes16("0x00"), "0x00", "0x00", "0x00", "credit", "0x00", "yuan"], [address(0x00), 0x00], [uint64(0), 0, 0, 0, 0, 0, 0, 0, 2]);
        } else {
            Token storage tk = tokens[tkidxs[tkidx]];
            return ([tk.idhash, tk.parenthash, tk.origincode, tk.statuscode, tk.typecode, tk.itemcode, tk.unitcode], [tk.saddr, tk.caddr], [tk.snetwork, tk.cnetwork, tk.amount, tk.gtimestamp, tk.ftimestamp, tk.etimestamp, tk.ctimestamp, tk.stimestamp, tk.status]);
        }
    }


    /* 获取指定id的Token
    //@param tkid: Token的id
    //@return 1: Token的idhash, parenthash, origincode, statuscode, compactcode, itemcode, unitcode; 2: Token的saddr, caddr; 3: Token的snetwork, cnetwork, amount, gtimestamp, ftimestamp, etimestamp, ctimestamp, stimestamp, status
    */
    function getTokenById(bytes16 tkid) public view returns (bytes16[7], address[2], uint64[9]) {
        if (isTokenExist(tkid) == false) {
            return ([bytes16("0x00"), "0x00", "0x00", "0x00", "credit", "0x00", "yuan"], [address(0x00), 0x00], [uint64(0), 0, 0, 0, 0, 0, 0, 0, 2]);
        } else {
            Token storage tk = tokens[tkid];
            return ([tk.idhash, tk.parenthash, tk.origincode, tk.statuscode, tk.typecode, tk.itemcode, tk.unitcode], [tk.saddr, tk.caddr], [tk.snetwork, tk.cnetwork, tk.amount, tk.gtimestamp, tk.ftimestamp, tk.etimestamp, tk.ctimestamp, tk.stimestamp, tk.status]);
        }
    }

    /*
    function logToken(uint idx) public returns (bool) {
        Token storage tk = tokens[tkidxs[idx]];
        emit WatchDog("WatchDog", tk.origincode, tk.amount);
    }
    */
    
    
    /* 获取指定Token idx的当前持有者
    //@param tkidx: Token的idx
    //@return 1: Token所有者地址
    */
    function getTokenHolderByIdx(uint64 tkidx) public view returns (address) {
        return ledgers[tkidxs[tkidx]];
        
    }

    
    /* 获取指定Token id的当前持有者
    //@param tkid: Token的id
    //@return 1: Token所有者地址
    */
    function getTokenHolderById(bytes16 tkid) public view returns (address) {
        return ledgers[tkid];
        
    }
    
    /* 获取指定address持有过的Token总数 (仅作出错查询用, 不表示address的当前Token持有数)
    //@param addr: 要查询的地址
    //@return 1: 持有过的Token总数
    */
    function getHeldTokenSum(address addr) public view returns (uint64) {
        return uint64(heldtokens[addr].length);
    }

    /* 获取指定address持有过的token列表的指定索引对应的Token(仅作出错查询用)
    //@param addr: 要查询的地址
    //@param  idx: 持有token列表的索引
    //@return 1: Token的idhash, parenthash, origincode, statuscode, compactcode, itemcode, unitcode; 2: Token的saddr, caddr; 3: Token的snetwork, cnetwork, amount, gtimestamp, ftimestamp, etimestamp, ctimestamp, stimestamp, status
    */
    function getHeldTokenByIdx(address addr, uint64 tkidx) public view returns (bytes16[7], address[2], uint64[9]) {
        bytes16 tkid = heldtokens[addr][tkidx];
        if (ledgers[tkid] == addr) {                    // 不返回当前未持有的Token
            return getTokenById(tkid);
        } else {
            return ([bytes16("0x00"), "0x00", "0x00", "0x00", "credit", "0x00", "yuan"], [address(0x00), 0x00], [uint64(0), 0, 0, 0, 0, 0, 0, 0, 2]);
        }
    }

    /* 获取流水号数量
    //@return 1: 流水数量
    */
    function getSnSum() public view returns (uint64) {
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
    function getSTXByIdx(uint64 idx) public view returns (string) {
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
    //@param hashs: Token的id, parentid, origincode, statuscode, itemcode, unitcode
    //@param addrs: Token的saddr, caddr
    //@param ints: Token的snetwork, cnetwork, amount, gtimestamp, ftimestamp, etimestamp, ctimestamp, stimestamp, status
    //@return 1: 是否发行成功
    */
    function issueToken(address receiver, bytes16[7] hashs, address[2] addrs, uint64[9] ints) public returns (bool) {
        tkidxs[tknum++] = hashs[0];
        tokens[hashs[0]] = Token(hashs[0], hashs[1], hashs[2], hashs[3], hashs[4], hashs[5], hashs[6], addrs[0], addrs[1], ints[0], ints[1], ints[2], ints[3], ints[4], ints[5], ints[6], ints[7], ints[8]);
        ledgers[hashs[0]] = receiver;
        counts[receiver][0]++;
        heldtokens[receiver].push(hashs[0]);
        if (ints[8] == 0) {
            counts[receiver][1]++;
        }
        if (hashs[4] != bytes16("credit") && hashs[4] != bytes16("tender")) {
            if (isItemExist(hashs[5]) == bytes16(0x00)) {
                items[hashs[5]] = hashs[0];
            }
        }
        /*
        if (hashs[4] == bytes32("credit") || hashs[4] == bytes32("tender")) {
            if (ints[7] == 0) {
                vbalances[receiver] += ints[2] * ints[3];
            } else {
                if (ints[7] == 1) {
                    ebalances[receiver] += ints[2] * ints[3];
                } else {
                    if (ints[7] == 2) {
                        fbalances[receiver] += ints[2] * ints[3];
                    }
                }
            }
        }
        */
        return true;
    }


    /* 向指定地址分配Token
    //@param receiver: 接收Token地址
    //@param details: 交易信息
    //@param hashs: Token的id, parentid, origincode, statuscode, itemcode, unitcode
    //@param addrs: Token的saddr, caddr
    //@param ints: Token的snetwork, cnetwork, amount, gtimestamp, ftimestamp, etimestamp, ctimestamp, stimestamp, status
    //@return 1: 是否分配成功
    */
    function assignToken(address receiver, string details, bytes16[7] hashs, address[2] addrs, uint64[9] ints) public returns (bool) {
        if (msg.sender == block.coinbase && issueToken(receiver, hashs, addrs, ints)) {
            emit PayReceipt(block.coinbase, msg.sender, receiver, details, ints[3]);
            return true;
        } else {
            revert();
        }
    }


    /* 进行单方面交易
    //@param receiver: 收款方
    //@param details: 交易详细信息
    //@param tkids: 需要支付的Token的id列表
    //@param ctimestamp: Token流转时间戳
    //@return 1: Token流转是否成功
    */
    function transferToken(address receiver, string details, bytes16[] tkids, uint64 ctimestamp) public returns (bool) {
        bool flag = true;
        for (uint i = 0; i < tkids.length; i++) {
            flag = transMyToken(receiver, tkids[i], ctimestamp);
        }
        emit PayReceipt(msg.sender, msg.sender, receiver, details, ctimestamp);
        return flag;
    }
    

    /* 发起一笔完整的支付交易
    //@param receiver: 收款方
    //@param details: 交易详细信息
    //@param tkids: 需要将哪些付款方已有token给收款方
    //@param splittkid: 需要拆分付款方的哪些token
    //@param hashs: 拆分token后返还和支付的token idhash, origincode, unitcode等信息(二维数组,奇数返还, 偶数支付)
    //@params addrs: 拆分token后返还和支付的token saddr, caddr 信息(二维数组,奇数返还, 偶数支付)
    //@param ints: 拆分token后返还和支付的token snetwork, amount, gtimestamp, status等信息(二维数组,奇数返还, 偶数支付)
    //@return 1: 是否交易成功
    */
    function payToken(address receiver, string details, bytes16[] tkids, bytes16[] splittkids, bytes16[7][] hashs, address[2][] addrs, uint64[9][] ints) public returns (bool) {
        bool flag = true;
        if (msg.sender != 0x00 && msg.sender != block.coinbase) {
            for (uint i = 0; i < tkids.length; i++) {
                flag = transMyToken(receiver, tkids[i], ints[0][5]);
            }
            if (splittkids.length > 0) {
                flag = setMyTokenStatus(splittkids, "0x11", ints[0][6], 6);
                for (uint k = 0; k < hashs.length; k++) {
                    if (k % 2 == 0) {
                        flag = issueToken(msg.sender, [hashs[k][0], hashs[k][1], hashs[k][2], hashs[k][3], hashs[k][4], hashs[k][5], hashs[k][6]], [addrs[k][0], addrs[k][1]], [ints[k][0], ints[k][1], ints[k][2], ints[k][3], ints[k][4], ints[k][5], ints[k][6], ints[k][7], ints[k][8]]);
                    } else {
                        flag = issueToken(receiver, [hashs[k][0], hashs[k][1], hashs[k][2], hashs[k][3], hashs[k][4], hashs[k][5], hashs[k][6]], [addrs[k][0], addrs[k][1]], [ints[k][0], ints[k][1], ints[k][2], ints[k][3], ints[k][4], ints[k][5], ints[k][6], ints[k][7], ints[k][8]]);
                    }
                }
            }
            //emit PayReceipt(msg.sender, addrs, totkids, companys[a].balances[uint(splittkidx)], idhashs[0], idhashs[1], timestamps[1]);
            
            if (flag == false) {
                // emit WatchDog("F", tokens[tkids[0]].amount);
                revert();
            } else {
                emit PayReceipt(msg.sender, msg.sender, receiver, details, ints[0][5]);
            }
        }
    }
    
    /* 发起一笔完整的交易
    //@param parts: 交易双方(A and B)
    //@param details: 交易详细信息
    //@param atkids: A需要支付给B的Token列表
    //@param btkids: B需要支付给B的Token列表
    //@param asplittkid: A需要拆分的Token列表
    //@param bsplittkid: B需要拆分的Token列表
    //@param hashs: 拆分token后给A和给B的token idhash, origincode, unitcode等信息(二维数组,奇数给A, 偶数给B)
    //@params addrs: 拆分token后给A和给B的token saddr, caddr 信息(二维数组,奇数给A, 偶数给B)
    //@param ints: 拆分token后给A和给B的token snetwork, amount, gtimestamp, status等信息(二维数组,奇数给A, 偶数给B)
    //@return 1: 是否交易成功
    */
    function transactFull(address[] parts, string details, bytes16[] atkids, bytes16[] btkids, bytes16[] asplittkids, bytes16[] bsplittkids, bytes16[7][] hashs, address[2][] addrs, uint64[9][] ints) public returns (bool) {
        bool flag = true;
        if (msg.sender != 0x00 && msg.sender == block.coinbase) {
            for (uint i = 0; i < atkids.length; i++) {
                flag = transToken(parts[0], parts[1], atkids[i], ints[0][5]);
            }
            for (i = 0; i < btkids.length; i++) {
                flag = transToken(parts[1], parts[0], btkids[i], ints[0][5]);
            }
            if (asplittkids.length > 0 || bsplittkids.length > 0) {
                flag = setTokenStatus(asplittkids, "0x11", ints[0][6], 6);
                flag = setTokenStatus(bsplittkids, "0x11", ints[0][6], 6);
                for (i = 0; i < hashs.length; i++) {
                    if (i % 2 == 0) {
                        flag = issueToken(parts[0], [hashs[i][0], hashs[i][1], hashs[i][2], hashs[i][3], hashs[i][4], hashs[i][5], hashs[i][6]], [addrs[i][0], addrs[i][1]], [ints[i][0], ints[i][1], ints[i][2], ints[i][3], ints[i][4], ints[i][5], ints[i][6], ints[i][7], ints[i][8]]);
                    } else {
                        flag = issueToken(parts[1], [hashs[i][0], hashs[i][1], hashs[i][2], hashs[i][3], hashs[i][4], hashs[i][5], hashs[i][6]], [addrs[i][0], addrs[i][1]], [ints[i][0], ints[i][1], ints[i][2], ints[i][3], ints[i][4], ints[i][5], ints[i][6], ints[i][7], ints[i][8]]);
                    }
                }
            }
            //emit PayReceipt(msg.sender, addrs, totkids, companys[a].balances[uint(splittkidx)], idhashs[0], idhashs[1], timestamps[1]);
            
            if (flag == false) {
                // emit WatchDog("F", tokens[tkids[0]].amount);
                revert();
            } else {
                emit PayReceipt(msg.sender, parts[0], parts[1], details, ints[0][5]);
            }
        } else {
            revert();
        }
    }
    

    /* 设置本地址指定Token的状态
    //@param tkids: Token id
    //@param statuscode: 状态变更原因hash
    //@param  stimestamp: Token状态变化时间戳
    //@param status: Token需要改变的状态
    //@return 1: 是否设置成功
    */
    function setMyTokenStatus(bytes16[] tkids, bytes16 statuscode, uint64 stimestamp, uint64 status) public returns (bool) {
        for (uint i = 0; i < tkids.length; i++) {
            if (msg.sender == ledgers[tkids[i]]) {
                Token storage tk = tokens[tkids[i]];
                if (tk.status == 0) {
                    if (status != 0) {
                        counts[ledgers[tkids[i]]][1]--;
                    }
                } else {
                    if (status == 0) {
                        counts[ledgers[tkids[i]]][1]++;
                    }
                }
                /*
                if (tk.typecode == bytes32("credit") || tk.typecode == bytes32("tender")) {
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
                */
                tk.statuscode = statuscode;
                tk.stimestamp = stimestamp;
                tk.status = status;
                return true;
            } else {
                revert();
            }
        }
    }
    
    /* 设置指定Token的状态
    //@param tkid: Token id
    //@param statuscode: 状态变更原因hash
    //@param  stimestamp: Token状态变化时间戳
    //@param status: Token需要改变的状态
    //@return 1: 是否设置成功
    */
    function setTokenStatus(bytes16[] tkids, bytes16 statuscode, uint64 stimestamp, uint64 status) public returns (bool) {
        if (msg.sender == block.coinbase) {
            for (uint i = 0; i < tkids.length; i++) {
                Token storage tk = tokens[tkids[i]];
                if (tk.status == 0) {
                    if (status != 0) {
                        counts[ledgers[tkids[i]]][1]--;
                    }
                } else {
                    if (status == 0) {
                        counts[ledgers[tkids[i]]][1]++;
                    }
                }
                /*
                if (tk.typecode == bytes32("credit") || tk.typecode == bytes32("tender")) {
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
                */
                tk.statuscode = statuscode;
                tk.stimestamp = stimestamp;
                tk.status = status;
            }
            return true;
        } else {
            revert();
        }
    }


    /* 转移自身Token所有权
    //@param receiver: 收款方
    //@param tkid: 需要支付的Token的id
    //@param ctimestamp: Token流转时间戳
    //@return 1: Token流转是否成功
    */
    function transMyToken(address receiver, bytes16 tkid, uint64 ctimestamp) public returns (bool) {
        if (ledgers[tkid] == msg.sender) {
            Token storage tk = tokens[tkid];
            ledgers[tkid] = receiver;
            tk.caddr = receiver;
            tk.ctimestamp = ctimestamp;
            counts[msg.sender][0]--;
            counts[receiver][0]++;
            if (tk.status == 0) {
                counts[msg.sender][1]--;
                counts[receiver][1]++;
            }
            /*
            if (tk.typecode == bytes32("credit") || tk.typecode == bytes32("tender")) {
                vbalances[msg.sender] -= tk.amount;
                vbalances[receiver] += tk.amount;
            }
            */
            return true;
        } else {
            revert();
        }
    }
  
    /* 转移Token所有权
    //@param payer: 付款方
    //@param payee: 收款方
    //@param tkid: 需要支付的Token的id
    //@param ctimestamp: Token流转时间戳
    //@return 1: Token流转是否成功
    */
    function transToken(address payer, address payee, bytes16 tkid, uint64 ctimestamp) public returns (bool) {
        if (msg.sender == block.coinbase) {
            if (ledgers[tkid] == payer) {
                Token storage tk = tokens[tkid];
                ledgers[tkid] = payee;
                tk.caddr = payee;
                tk.ctimestamp = ctimestamp;
                counts[payer][0]--;
                counts[payee][0]++;
                if (tk.status == 0) {
                    counts[payer][1]--;
                    counts[payee][1]++;
                }
                /*
                if (tk.typecode == bytes32("credit") || tk.typecode == bytes32("tender")) {
                    vbalances[msg.sender] -= tk.amount;
                    vbalances[receiver] += tk.amount;
                }
                */
                return true;
            }
        } else {
            revert();
        }
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
    /*
    // callback function, 
    function () public payable {
        revert();
    }  
    */
    // TODO: Company删除
    // TODO: Token移除与合并
}