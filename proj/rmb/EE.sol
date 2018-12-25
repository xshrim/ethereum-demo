pragma solidity ^0.4.23;

contract Exchange {
    struct Token {
        bytes16 idhash;
        bytes16 parenthash;
        bytes16 origincode;
        bytes16 statuscode;
        bytes16 typecode;
        bytes16 itemcode;
        bytes16 unitcode;
        address saddr;
        address caddr;
        uint64 snetwork;
        uint64 cnetwork;
        uint64 amount;
        uint64 gtimestamp;
        uint64 ftimestamp;
        uint64 etimestamp;
        uint64 ctimestamp;
        uint64 stimestamp;
        uint64 status;
    }

    struct Item {
        string desc;
    }

    address public owner;

    uint64 tknum;
    mapping (uint64 => bytes16) tkidxs;
    mapping (bytes16 => Token) tokens;
    mapping (bytes16 => address) ledgers;
    mapping (bytes16 => bytes16) items;
    mapping (address => bytes16[]) heldtokens;
    uint64 sncount;
    mapping (uint64 => string) sns;
    mapping (string => string) stxs;
    mapping (address => uint64[2]) counts;

    uint64 count;
    string greeting;
    bytes16 hello;

    event WatchDog (string themsg, bytes16 thimsg, uint res);
    event PayReceipt (address sender, address indexed payer, address indexed payee, string detail, uint timestamp);


    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require (msg.sender == owner, "sender != owner");
        /*
        if (msg.sender != owner) {
            revert("sender != owner");
        }
        */
        _;
    }

    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }

    /*
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
    */

    function isTokenExist(bytes16 tkid) public view returns (bool) {
        if (tokens[tkid].idhash == tkid) {
            return true;
        } else {
            return false;
        }
    }

    function isItemExist(bytes16 itemcode) public view returns (bytes16) {
        return items[itemcode];
    }

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

    function getTokenByIdx(uint64 tkidx) public view returns (bytes16[7], address[2], uint64[9]) {
        if (tkidx < 0 || tkidx >= tknum) {
            return ([bytes16("0x00"), "0x00", "0x00", "0x00", "credit", "0x00", "yuan"], [address(0x00), 0x00], [uint64(0), 0, 0, 0, 0, 0, 0, 0, 2]);
        } else {
            Token storage tk = tokens[tkidxs[tkidx]];
            return ([tk.idhash, tk.parenthash, tk.origincode, tk.statuscode, tk.typecode, tk.itemcode, tk.unitcode], [tk.saddr, tk.caddr], [tk.snetwork, tk.cnetwork, tk.amount, tk.gtimestamp, tk.ftimestamp, tk.etimestamp, tk.ctimestamp, tk.stimestamp, tk.status]);
        }
    }

    function getTokenById(bytes16 tkid) public view returns (bytes16[7], address[2], uint64[9]) {
        if (isTokenExist(tkid) == false) {
            return ([bytes16("0x00"), "0x00", "0x00", "0x00", "credit", "0x00", "yuan"], [address(0x00), 0x00], [uint64(0), 0, 0, 0, 0, 0, 0, 0, 2]);
        } else {
            Token storage tk = tokens[tkid];
            return ([tk.idhash, tk.parenthash, tk.origincode, tk.statuscode, tk.typecode, tk.itemcode, tk.unitcode], [tk.saddr, tk.caddr], [tk.snetwork, tk.cnetwork, tk.amount, tk.gtimestamp, tk.ftimestamp, tk.etimestamp, tk.ctimestamp, tk.stimestamp, tk.status]);
        }
    }

    function getTokenHolderByIdx(uint64 tkidx) public view returns (address) {
        return ledgers[tkidxs[tkidx]];
        
    }

    function getTokenHolderById(bytes16 tkid) public view returns (address) {
        return ledgers[tkid];
        
    }
    
    function getHeldTokenSum(address addr) public view returns (uint64) {
        return uint64(heldtokens[addr].length);
    }

    function getHeldTokenByIdx(address addr, uint64 tkidx) public view returns (bytes16[7], address[2], uint64[9]) {
        bytes16 tkid = heldtokens[addr][tkidx];
        if (ledgers[tkid] == addr) {
            return getTokenById(tkid);
        } else {
            return ([bytes16("0x00"), "0x00", "0x00", "0x00", "credit", "0x00", "yuan"], [address(0x00), 0x00], [uint64(0), 0, 0, 0, 0, 0, 0, 0, 2]);
        }
    }

    function getSnSum() public view returns (uint64) {
        return sncount;
    }

    function getSTXByNum(string sn) public view returns (string) {
        return stxs[sn];
    }

    function getSTXByIdx(uint64 idx) public view returns (string) {
        return stxs[sns[idx]];
    }

    function setSTX(string sn, string txhash) public returns (string) {
        sns[sncount++] = sn;
        stxs[sn] = txhash;
        return sn;
    }

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
        return true;
    }

    function assignToken(address receiver, string details, bytes16[7] hashs, address[2] addrs, uint64[9] ints) public returns (bool) {
        if (msg.sender == block.coinbase && issueToken(receiver, hashs, addrs, ints)) {
            emit PayReceipt(block.coinbase, msg.sender, receiver, details, ints[3]);
            return true;
        } else {
            revert();
        }
    }

    function transferToken(address receiver, string details, bytes16[] tkids, uint64 ctimestamp) public returns (bool) {
        bool flag = true;
        for (uint i = 0; i < tkids.length; i++) {
            flag = transMyToken(receiver, tkids[i], ctimestamp);
        }
        emit PayReceipt(msg.sender, msg.sender, receiver, details, ctimestamp);
        return flag;
    }
    
    /*
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
            
            if (flag == false) {
                revert();
            } else {
                emit PayReceipt(msg.sender, msg.sender, receiver, details, ints[0][5]);
            }
        }
    }
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
            
            if (flag == false) {
                revert();
            } else {
                emit PayReceipt(msg.sender, parts[0], parts[1], details, ints[0][5]);
            }
        } else {
            revert();
        }
    }
    
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
                tk.statuscode = statuscode;
                tk.stimestamp = stimestamp;
                tk.status = status;
                return true;
            } else {
                revert();
            }
        }
    }
    
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
                tk.statuscode = statuscode;
                tk.stimestamp = stimestamp;
                tk.status = status;
            }
            return true;
        } else {
            revert();
        }
    }

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
            return true;
        } else {
            revert();
        }
    }
  
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
                return true;
            }
        } else {
            revert();
        }
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }

}