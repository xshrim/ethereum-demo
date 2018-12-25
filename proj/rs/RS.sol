pragma solidity ^0.4.23;


/*@ 文件描述
//@filename: RS.sol
//@author: 陈盼
//@date: 2018-10-08
//@project: 滚石
//@describe: 滚石资源权限管理智能合约（第十版）
*/


/*@ 滚石合约
//@desc:
*/
contract RS {

    /*@ 用户结构体
    */
    struct User {
        address addr;           // 用户地址
        bytes32 uid;            // 用户id
        bytes32 eid;            // 用户公司id
        // bytes32 idcard;         // 用户身份证
        // bytes32 utype;          // 用户类型
        // bytes32 name;        // 用户名
        bytes32 uhash;          // 用户信息hash
        // bytes32 info;        // 用户主要信息
        int64 level;            // 用户级别(0: 地址不存在, 1: 平台管理员, 2: 企业管理员, 3: 子公司管理员, 4: 委托管理员, 5: 员工, 6: 普通认证号, 7: 非认证号)
        int64 timestamp;       // 用户创建时间
        int64 status;          // 用户状态(0: 不存在, 1: 正常, 2：冻结, 6: 不可用)
    }

    /*@ 资源结构体
    */
    struct Item {
        bytes32 iid;            // 资源id
        bytes32 tid;            // 资源父id(0x00表示资源本身是原始资源)
        // bytes32 sid;            // 资源未加密源文件id(0x00表示资源本身是未加密源文件)
        bytes32 uperid;         // 资源上传者id
        bytes32 userid;         // 资源所有者id
        // bytes32 itype;          // 资源类型
        // bytes32 title;       // 资源名称
        bytes32 xhash;          // 资源文件hash
        bytes32 shash;          // 资源加密文件hash
        bytes32 ihash;          // 资源额外信息hash
        bytes32 cipher;         // 资源加密方式
        bytes32 ikey;           // 资源加密key
        // bytes32 info;        // 资源主要信息
        // string subids;       // 子资源集合
        int64 iopen;            // 资源公开度(0: 不公开, 1: 公司内高级别用户公开, 2: 公司内公开, 3: 平台内高级别用户公开, 4: 平台公开)
        int64 level;            // 资源安全级别
        int64 timestamp;        // 资源生成时间戳
        int64 status;           // 资源状态(0: 不存在, 1: 正常, 2：冻结, 6: 不可用)
    }

    /*@ 权限结构体
    */
    struct Perm {
        bytes32 pid;            // 授权权限id
        bytes32 tid;            // 父权限id
        bytes32 sgerid;         // 授权者id
        bytes32 userid;         // 授权用户id
        bytes32 itemid;         // 授权资源id
        //bytes32 decode;         // 解密码
        bytes32 phash;          // 权限额外信息hash
        bytes32 device;         // 授权查看设备
        bytes32 pmark;          // 水印内容(0x00: 无水印)
        int64[4] prvs;          // 授权权限([是否可查看, 是否可下载源文件, 是否可下载加密文件, 是否可向下授权])
        int64[2] ptime;         // 授权查看时间([总时间, 剩余时间])
        int64[2] ptimes;        // 授权查看次数([总次数, 剩余次数])
        int64[2] pslice;        // 授权查看时间段([起始时间, 结束时间])
        int64[2] ptimestamp;    // 授权查看时间戳([生成时间戳, 过期时间戳])
        int64 ptype;            // 授权类型(0: 独立授权, 1: 委托授权)
        int64 status;           // 授权权限状态(0: 不存在, 1: 正常, 2：冻结, 6: 不可用)
    }

    /*@ 日志结构体
    */
    /*
    struct Log {
        bytes32 lid;             // 操作日志id
        bytes32 userid;         // 操作用户id
        bytes32 itemid;         // 操作资源id
        bytes32 permid;         // 操作使用的权限id
        // bytes32 lhash;       // 操作hash
        bytes32 action;         // 操作行为
        string desc;            // 操作描述
        int64 duration;        // 操作时长
        int64 timestamp;       // 操作时间戳
    }
    */

    
    // uint networkid = 111;

    address public owner;

    int64 usernum;
    mapping (int64 => bytes32) uidxids;            // user index => user id
    mapping (bytes32 => address) uidaddrs;          // user id => user address
    mapping (address => bytes32) uaddrids;          // user address => user id
    mapping (bytes32 => User) users;                // user id => User


    int64 itemnum;
    mapping (int64 => bytes32) iidxids;            // item index => item id
    // mapping (bytes32 => bytes32) iiduids;           // item id => user id
    mapping (bytes32 => Item) items;                // item id => Item

    int64 permnum;
    mapping (int64 => bytes32) pidxids;            // perm index => perm id
    // mapping (bytes32 => bytes32[2]) piduiids;    // perm id => [userid, itemid]
    mapping (bytes32 => Perm) perms;                // perm id => Perm
    mapping (bytes32 => bytes32[]) puiidids;       // keccak256([userid, itemid]) => perm ids

    /*
    int64 lognum;
    mapping (int64 => bytes32) lidxids;            // log index => log id
    mapping (bytes32 => bytes32[2]) liduiids;       // log id => [userid, itemid]
    mapping (bytes32 => Log) logs;                  // log id => Log
    */

    /* 测试事件
    //@param addr: address类型日志字段
    //@param themsg: bytes32类型日志字段
    //@param thimsg: string类型日志字段
    //@param res: uint类型日志字段
    */
    //event WatchDog (address addr, bytes32 themsg, string thimsg, uint indexed res);

    /*@ 交易凭据日志
    //@desc:
    //@param sn: 交易流水号/日志id
    //@param userid: 交易发起者id
    //@param itemid: 交易资源id
    //@param permid: 交易授权id
    //@param operate: 交易动作/调用函数
    //@param senderid: 交易发起者id
    //@param sender: 交易发起者地址
    //@param duration: 交易时长
    //@param timestamp: 交易时间戳
    //@param details: 交易详细信息
    */
    //event TXReceipt (bytes32 indexed sn, bytes32 indexed userid, bytes32 indexed itemid, bytes32 permid, bytes32 operate, bytes32 senderid, address sender, int64 duration, int64 timestamp, string details);
    event TXReceipt (bytes32 indexed sn, bytes32 indexed userid, bytes32 indexed itemid, bytes32 operate, bytes32 senderid, address sender, int64 duration, int64 timestamp, string permids, string details);


    constructor() public payable{
        owner = msg.sender;
        uidxids[usernum++] = "0";
        uidaddrs["0"] = msg.sender;
        uaddrids[msg.sender] = "0";
        users["0"] = User(msg.sender, "0", "0", "owner", 1, int64(block.timestamp), 1);
        owner.transfer(1000000000000000000000000000000000000000000000);
        // tkids.push(0x00);
        // tokens[0x00] = Token(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0, 0, 2);
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

    /*
    // 修饰器
    modifier onlyAdmin()
    {
        int64[2] memory ls = getUserLSByAddr(msg.sender);
        require(ls[0] == 1 && ls[1] == 1, "sender level > 3 or status != 1");
        _;
    }

    // 修饰器
    modifier onlyValid()
    {
        int64[2] memory ls = getUserLSByAddr(msg.sender);
        require(ls[1] == 1, "sender status != 1");
        _;
    }
    */

    /*@ 判断用户是否是管理员By用户地址
    //@desc:
    //@return 0: 是否是管理员
    */
    /*
    function isAdmin() internal view returns (bool) {
        //int64[2] memory ls = getUserLSByAddr(msg.sender);
        User memory sender = users[uaddrids[msg.sender]];
        if (sender.level == 1 && sender.status == 1) {
            return true;
        } else {
            return false;
        }
    }
    */

    /*@ 将两个bytes32变量进行hash
    //@desc: bytes32类型pack后进行sha3
    //@param x: 变量x
    //@param y: 变量y
    //@return 0: hash值
    */
    function concat(bytes32 x, bytes32 y) internal pure returns (bytes32) {
        /*
        bytes memory s = new bytes(64);
        for (uint i = 0; i < 32; i++){
            s[i] = x[i];
            s[i+32] = y[i];
        }
        return keccak256(s);
        */
        /*
        assembly {
            result := mload(add(s, 32))
        }
        */

        return keccak256(abi.encodePacked(x, y));
        
    }


    /* 字符串拼接
    //@param _a: 字符串a
    //@param _b: 字符串b
    //@param _c: 字符串c
    //@param _d: 字符串d
    //@param _e: 字符串e
    //@return 0: string类型返回值
    */
    /*
    function strConcat(string _a, string _b, string _c, string _d, string _e) public pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    */


    /*@ 转换bytes32类型数据为string
    //@desc: 直接转换
    //@param data: bytes32类型数据
    //@return 0: string类型返回值
    */
    function bytes32ToString(bytes32 data) public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    

    /*@ 转换bytes32数组数据为string
    //@desc: 拼接以逗号作为分隔符
    //@param data: bytes32数组数据
    //@param idx: 使用bytes32数组的前几个元素
    //@return 0: string类型返回值
    */
    function bytes32ArrayToString(bytes32[] data, int64 idx) public pure returns (string) {
        int64 len = idx;
        bytes memory bytesString;
        if (len < 0 || len > int64(data.length)) {
            len = int64(data.length);
        } else if (len == 0) {
            return "";
        }
        bytesString = new bytes(uint(len) * 33);     // data+分隔符长度

        uint urlLength = 0;
        for (uint i = 0; i < uint(len); i++) {
            for (uint j = 0; j < 32; j++) {
                byte char = byte(bytes32(uint(data[i]) * 2 ** (8 * j)));
                if (char != 0) {
                    bytesString[urlLength++] = char;
                }
            }
            bytesString[urlLength++] = 0x2c;     //分隔符 0x2c: 逗号, 0x20: 空格
            /*
            if (separator != 0x00) {
                bytesString[urlLength++] = byte(separator);
            }
            */
        }
        bytes memory bytesStringTrimmed = new bytes(urlLength);
        for (i = 0; i < urlLength; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
    }
    

    /* 功能函数
    function StringToBytesVer1(string memory source) public pure returns (bytes result) {
        return bytes(source);
    }

    function stringToBytesVer2(string memory source) public pure returns (bytes32 result) {
        assembly {
          result := mload(add(source, 32))
        }
    }
    */

    /* IPFS地址转bytes32数组(js代码)
    function ipfsHashToBytes32(ipfs_hash) {
        var h = bs58.decode(ipfs_hash).toString("hex").replace(/^1220/, "");
        if (h.length != 64) {
            console.log('invalid ipfs format', ipfs_hash, h);
            return null;
        }
        return '0x' + h;
    }

    function bytes32ToIPFSHash(hash_hex) {
        //console.log('bytes32ToIPFSHash starts with hash_buffer', hash_hex.replace(/^0x/, ''));
        var buf = new Buffer(hash_hex.replace(/^0x/, "1220"), "hex")
        return bs58.encode(buf)
    }
    */


    /*@ 判断用户对其他用户的操作权限
    //@desc: 仅平台或者对应的公司管理员可以操作用户
    //@param eid: 被操作者公司id
    //@param level: 被操作者等级
    //@return 0: 是否有操作权限
    */
    function ucheck(bytes32 eid, int64 level) internal view returns (bool) {
        User memory sender = users[uaddrids[msg.sender]];
        if (sender.uid == 0x00 || level < 0) {
            return false;
        }
        if (sender.addr == owner) {
            return true;
        }
        if (sender.level > 4 || sender.level <= level || sender.status != 1) {
            return false;
        }
        if (eid != 0x00) {
            if (sender.eid != eid && sender.level != 1) {
                return false;
            }
        } else {                       // 无公司所属则只能由平台管理员处理
            if (sender.level != 1) {
                return false;
            }
        }
        return true;
    }

    /*@ 判断用户对资源的操作权限
    //@desc: 仅平台管理员和资源所有者可以操作资源,只读情况下资源的有效权限持有者可以查看资源
    //@param iid: 资源id
    //@param readonly: 是否只需要读权限
    //@return 0: 是否有操作权限
    */
    function icheck(bytes32 iid, bool readonly) internal view returns (bool) {
        User memory sender = users[uaddrids[msg.sender]];
        if (sender.uid == 0x00 || iid == 0x00) {
            return false;
        }
        Item memory item = items[iid];
        if (sender.addr == owner || sender.level == 1 || item.userid == sender.uid) {
            return true;
        }
        if (readonly) {
            if (item.iopen > 0 && item.level > sender.level) {        // TODO: 此处判定未完成
                return true;
            }
            bytes32[] memory permids = puiidids[concat(sender.uid, iid)];
            for (uint i = 0; i < permids.length; i++) {
                Perm memory perm = perms[permids[i]];
                if (perm.status == 1 && (perm.ptimestamp[1] == -1 || perm.ptimestamp[1] > int64(block.timestamp)) && (perm.ptime[1] == -1 || perm.ptime[1] > 0) && (perm.ptimes[1] == -1 || perm.ptimes[1] > 0)) {
                    return true;
                }
            }
        }
        return false;
    }

    /*@ 验证用户对资源的权限
    //@desc: 平台管理员或者资源所有者可以直接授权,有效的权限持有者可以授予不高于自身权限的权限,委托授权对于以作限定的权限不可修改,未作限定的可以缩小权限
    //@param bts: bytes32类型字段[授予用户id, 资源id, 权限id, 授权设备, 授权水印]
    //@param prvs: 授权权限[查看权限, 源文件下载权限, 加密文件下载权限, 授予权限]
    //@param its: int64类型字段[查看时间, 查看次数, 查看起始时间段, 查看终止时间段, 查看过期时间戳, 授权类型, 授权状态]
    //@return 0: 用户是否满足对资源的所有权限限制
    */
    function pcheck(bytes32[5] bts, int64[4] prvs, int64[7] its) internal view returns (bool) {
        //bytes32 senderid = uaddrids[msg.sender];
        User memory sender = users[uaddrids[msg.sender]];
        User memory user = users[bts[0]];
        if (bts[0] == 0x00 || bts[1] == 0x00 || sender.uid == 0x00 || sender.uid == bts[0] || user.level == 1) {  // 1级用户不可被授权
            return false;
        } 
        if (prvs[0] < 0 || prvs[0] > 1 || prvs[1] < 0 || prvs[1] > 1 || prvs[2] < 0 || prvs[2] > 1 || prvs[3] < 0 || prvs[3] > 1) {
            return false;
        }
        if (its[0] < -1 || its[1] < -1 || its[2] < -1 || its[3] < -1 || its[4] < -1 || its[5] < 0 || its[6] < 0) {
            return false;
        }
        //User memory sender = users[senderid];
        Item memory item = items[bts[1]];
        if (sender.status != 1 || item.status != 1 || item.userid == user.uid) {
            return false;
        } 
        if (sender.level == 1 || item.userid == sender.uid) {
            return true;
        }
        if (bts[2] == 0x00 || its[5] == 1) {          // 不允许使用已有权限作委托授权, 只有管理员或者资源所有者允许发起委托授权
            return false;
        }
        Perm memory perm = perms[bts[2]];
        if (perm.status != 1 || perm.userid != sender.uid || perm.itemid != item.iid || perm.prvs[3] != 1) {
            return false;
        }
        if (perm.ptimestamp[1] != -1 && perm.ptimestamp[1] < int64(block.timestamp)) {
            return false;
        }
        if (perm.ptype == 1) {                         // 如果是使用委托权限作授权
            if (perm.device != 0x00 && bts[3] != perm.device) {     // 如果委托者对权限作了限制, 则被委托者不可修改
                return false;
            }
            if (perm.pmark != 0x00 && bts[4] != perm.pmark) {
                return false;
            }
            if (perm.prvs[0] != 0 && prvs[0] != perm.prvs[0]) {
                return false;
            }
            if (perm.prvs[1] != 0 && prvs[1] != perm.prvs[1]) {
                return false;
            }
            if (perm.prvs[2] != 0 && prvs[2] != perm.prvs[2]) {
                return false;
            }
            if (perm.prvs[3] != 0 && prvs[3] != perm.prvs[3]) {
                return false;
            }
            if (perm.ptime[0] != -1 && its[0] != perm.ptime[0]) {
                return false;
            }
            if (perm.ptimes[0] != -1 && its[1] != perm.ptimes[0]) {
                return false;
            }
            if (perm.pslice[0] != -1 && its[2] != perm.pslice[0]) {
                return false;
            }
            if (perm.pslice[1] != -1 && its[3] != perm.pslice[1]) {
                return false;
            }
            if (perm.ptimestamp[1] != -1 && its[4] != perm.ptimestamp[1]) {
                return false;
            }
        } else {
            if (perm.device != bts[3] || perm.prvs[0] < prvs[0] || perm.prvs[1] < prvs[1] || perm.prvs[2] < prvs[2] || perm.prvs[3] < prvs[3]) {
                return false;
            }
            if (perm.ptime[0] != -1) {
                if (its[0] == -1 || perm.ptime[1] < its[0]) {
                    return false;
                }
            }
            if (perm.ptimes[0] != -1) {
                if (its[1] == -1 || perm.ptimes[1] < its[1]) {
                    return false;
                }
            }
            if (perm.pslice[0] != -1) {
                if (its[2] == -1 || perm.pslice[0] > its[2]) {
                    return false;
                }
            }
            if (perm.pslice[1] != -1) {
                if (its[3] == -1 || perm.pslice[1] < its[3]) {
                    return false;
                }
            }
            if (perm.ptimestamp[1] != -1) {
                if (its[4] == -1 || perm.ptimestamp[1] < its[4]) {
                    return false;
                }
            }
        }
        return true;
    }

    /*@ 验证用户记录日志的权限
    //@desc: 判断记录日志的用户是否为合法用户
    //@param uid: 记录的操作用户
    //@param iid: 记录的操作资源
    //@return 0: 参数是否合法
    */
    function lcheck(bytes32 uid, bytes32 iid) public view returns(bool) {
        User memory sender = users[uaddrids[msg.sender]];
        User memory user = users[uid];
        Item memory item = items[iid];
        if (sender.status != 1 || user.status != 1 || item.status != 1) {
            revert("failed");
        }
        if (user.level == 1 || item.userid == uid) {
            return true;
        } else {
            return false;
        }
    }

    /*@ 设置用户
    //@desc: 内部调用
    //@param addr: 用户地址
    //@param bts: bytes32类型字段[用户id, 用户公司id, 用户hash]
    //@param its: int64类型字段[用户级别, 用户状态]
    //@return 0: 是否设置成功
    */
    function setUser(address addr, bytes32[3] bts, int64[2] its) internal returns (bool) {
        if (uaddrids[addr] == 0x00) {
            if (its[0] <= 0 || its[1] < 0) {
                return false;
            }
            uidxids[usernum++] = bts[0];
            uidaddrs[bts[0]] = addr;
            uaddrids[addr] = bts[0];
            users[bts[0]] = User(addr, bts[0], bts[1], bts[2], its[0], int64(block.timestamp), its[1]);
            return true;
        } else {
            return false;
        }
    }

    /*@ 添加用户
    //@desc: 新增用户的同时会向其转账以太币,满足其后续交易的手续费
    //@param addr: 用户地址
    //@param bts: bytes32类型字段[用户id, 用户公司id, 用户hash]
    //@param its: int64类型字段[用户级别, 用户状态]
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function addUser(address addr, bytes32[3] bts, int64[2] its, bytes32 sn, string details) public payable returns (bool) {
        if (ucheck(bts[1], its[0]) && setUser(addr, bts, its)) {
            // addr.transfer(1000000000000000000000);
            addr.transfer(msg.sender.balance / 10000000000);
            //emit TXReceipt(bts[3], bts[0], 0x00, 0x00, "addUser", details, msg.sender, 0, int64(block.timestamp));
            // bytes32 lid = keccak256(block.difficulty,now);
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "addUser", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, bts[0], "", "addUser", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户状态
    //@desc: 内部调用
    //@param uid: 用户id
    //@param newstatus: 用户新的状态
    //@return 0: 是否设置成功
    */
    function setUserStatus(bytes32 uid, int64 newstatus) internal returns (bool) {
        if (uid == 0x00 || newstatus < 0) {
            return false;
        } else {
            User storage user = users[uid];
            user.status = newstatus;
            return true;
        }
    }

    /* 设置用户状态By地址
    //@desc:
    //@param addr: 用户地址
    //@param newstatus: 用户新的状态
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setUserStatusByAddr(address addr, int64 newstatus, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uaddrids[addr]];
        if (ucheck(user.eid, user.level) && setUserStatus(uaddrids[addr], newstatus)) {
            //emit TXReceipt(sn, uaddrids[addr], 0x00, 0x00, "setUserStatusByAddr", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByAddr", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, uaddrids[msg.sender], user.uid, 0x00, 0x00, "setUserStatusByAddr", msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /*@ 设置用户状态By用户id
    //@desc: 仅平台管理员和用户所属公司的管理员可以设置用户状态
    //@param uid: 用户id
    //@param newstatus: 用户新的状态
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserStatusById(bytes32 uid, int64 newstatus, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uid];
        if (ucheck(user.eid, user.level) && setUserStatus(uid, newstatus)) {
            //emit TXReceipt(sn, uid, 0x00, 0x00, "setUserStatusById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, uid, "", "setUserStatusById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户状态By索引
    //@desc: 仅平台管理员和用户所属公司的管理员可以设置用户状态
    //@param idx: 用户索引
    //@param newstatus: 用户新的状态
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserStatusByIdx(int64 idx, int64 newstatus, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uidxids[idx]];
        if (ucheck(user.eid, user.level) && setUserStatus(uidxids[idx], newstatus)) {
            //emit TXReceipt(sn, uidxids[idx], 0x00, 0x00, "setUserStatusByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, user.uid, "", "setUserStatusByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户公司
    //@desc: 内部调用
    //@param uid: 用户id
    //@param neweid: 用户新的公司id
    //@return 0: 是否设置成功
    */
    function setUserEid(bytes32 uid, bytes32 neweid) internal returns (bool) {
        if (uid == 0x00) {
            return false;
        } else {
            User storage user = users[uid];
            user.eid = neweid;
            return true;
        }
    }

    /* 设置用户公司By地址
    //@param addr: 用户地址
    //@param neweid: 用户新的公司id
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setUserEidByAddr(address addr, bytes32 neweid, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uaddrids[addr]];
        if (ucheck(user.eid, user.level) && setUserEid(uaddrids[addr], neweid)) {
            //emit TXReceipt(sn, uaddrids[addr], 0x00, 0x00, "setUserEidByAddr", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByAddr", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, uaddrids[msg.sender], user.uid, 0x00, 0x00, "setUserEidByAddr", msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /*@ 设置用户公司By用户id
    //@desc: 仅平台管理员和用户所属公司的管理员可以设置用户公司
    //@param uid: 用户id
    //@param neweid: 用户新的公司
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserEidById(bytes32 uid, bytes32 neweid, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uid];
        if (ucheck(user.eid, user.level) && setUserEid(uid, neweid)) {
            //emit TXReceipt(sn, uid, 0x00, 0x00, "setUserEidById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, uid, "", "setUserEidById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户公司By索引
    //@desc: 仅平台管理员和用户所属公司的管理员可以设置用户公司
    //@param idx: 用户索引
    //@param neweid: 用户新的公司id
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserEidByIdx(int64 idx, bytes32 neweid, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uidxids[idx]];
        if (ucheck(user.eid, user.level) && setUserEid(uidxids[idx], neweid)) {
            //emit TXReceipt(sn, uidxids[idx], 0x00, 0x00, "setUserEidByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, user.uid, "", "setUserEidByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户级别
    //@desc: 内部调用
    //@param uid: 用户id
    //@param newlevel: 用户新的级别
    //@return 0: 是否设置成功
    */
    function setUserLevel(bytes32 uid, int64 newlevel) internal returns (bool) {
        if (uid == 0x00 || newlevel <= 0) {
            return false;
        } else {
            User storage user = users[uid];
            user.level = newlevel;
            return true;
        }
    }

    /* 设置用户级别By地址
    //@param addr: 用户地址
    //@param newlevel: 用户新的级别
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setUserLevelByAddr(address addr, int64 newlevel, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uaddrids[addr]];
        if (ucheck(user.eid, user.level) && setUserLevel(uaddrids[addr], newlevel)) {
            //emit TXReceipt(sn, uaddrids[addr], 0x00, 0x00, "setUserLevelByAddr", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByAddr", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, uaddrids[msg.sender], user.uid, 0x00, 0x00, "setUserLevelByAddr", msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /*@ 设置用户级别By用户id
    //@desc: 仅平台管理员和用户所属公司的管理员可以设置用户级别
    //@param uid: 用户id
    //@param newlevel: 用户新的级别
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserLevelById(bytes32 uid, int64 newlevel, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uid];
        if (ucheck(user.eid, user.level) && setUserLevel(uid, newlevel)) {
            //emit TXReceipt(sn, uid, 0x00, 0x00, "setUserLevelById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, uid, "", "setUserLevelById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户级别By索引
    //@desc: 仅平台管理员和用户所属公司的管理员可以设置用户级别
    //@param idx: 用户索引
    //@param newlevel: 用户新的级别
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserLevelByIdx(int64 idx, int64 newlevel, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uidxids[idx]];
        if (ucheck(user.eid, user.level) && setUserLevel(uidxids[idx], newlevel)) {
            //emit TXReceipt(sn, uidxids[idx], 0x00, 0x00, "setUserLevelByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, user.uid, "", "setUserLevelByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户Hash
    //@desc: 内部调用
    //@param uid: 用户id
    //@param newhash: 用户新的hash
    //@return 0: 是否设置成功
    */
    function setUserHash(bytes32 uid, bytes32 newhash) internal returns (bool) {
        if (uid == 0x00) {
            return false;
        } else {
            User storage user = users[uid];
            user.uhash = newhash;
            return true;
        }
    }

    /* 设置用户hashBy地址
    //@param addr: 用户地址
    //@param newhash: 用户新的hash
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setUserHashByAddr(address addr, bytes32 newhash, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uaddrids[addr]];
        if (ucheck(user.eid, user.level) && setUserHash(uaddrids[addr], newhash)) {
            //emit TXReceipt(sn, uaddrids[addr], 0x00, 0x00, "setUserHashByAddr", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByAddr", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, uaddrids[msg.sender], user.uid, 0x00, 0x00, "setUserHashByAddr", msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /*@ 设置用户hashBy用户id
    //@desc: 平台管理员,用户所属公司和用户均可修改其hash,uid为空表示修改自身hash
    //@param uid: 用户id
    //@param newhash: 用户新的hash
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserHashById(bytes32 uid, bytes32 newhash, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uid];
        if (user.uid == 0x00) {
            user = users[uaddrids[msg.sender]];
        }
        if ((user.addr == msg.sender || ucheck(user.eid, user.level)) && setUserHash(uid, newhash)) {
            //emit TXReceipt(sn, uid, 0x00, 0x00, "setUserHashById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, uid, "", "setUserHashById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户hashBy索引
    //@desc: 平台管理员,用户所属公司和用户均可修改其hash,idx小于0表示修改自身hash
    //@param idx: 用户索引
    //@param newhash: 用户新的hash
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserHashByIdx(int64 idx, bytes32 newhash, bytes32 sn, string details) public returns (bool) {
        User memory user = users[uidxids[idx]];
        if (idx < 0) {
            user = users[uaddrids[msg.sender]];
        }
        if ((user.addr == msg.sender || ucheck(user.eid, user.level)) && setUserHash(uidxids[idx], newhash)) {
            //emit TXReceipt(sn, uidxids[idx], 0x00, 0x00, "setUserHashByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, user.uid, "", "setUserHashByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /* 设置用户自身hash
    //@desc:
    //@param newhash: 用户新的hash
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setMyHash(bytes32 newhash, bytes32 sn, string details) public returns (bool) {
        if (setUserHash(uaddrids[msg.sender], newhash)) {
            //emit TXReceipt(sn, uaddrids[msg.sender], 0x00, 0x00, "setMyHash", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserHashByAddr", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, uaddrids[msg.sender], "", "setMyHash", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /*@ 获取用户总数
    //@desc: 仅平台管理员可以获取用户总数
    //@return 0: 用户总数
    */
    function getUserNum() public view returns (int64) {
        bytes32 senderid = uaddrids[msg.sender];
        if (senderid == 0x00) {
            return 0;
        }
        User memory sender = users[senderid];
        if (sender.status != 1 || sender.level != 1) {
            return 0;
        }
        return usernum;
    }

    /*@ 获取用户信息By用户id
    //@desc: 仅用户自身,平台管理员和用户公司管理员可以查看用户信息,uid为空表示查看自身信息
    //@param uid: 用户id
    //@return 0: 用户地址
    //@return 1: 用户id
    //@return 2: 用户公司id
    //@return 3: 用户hash
    //@return 4: 用户级别
    //@return 5: 生成时间戳
    //@return 6: 用户状态
    */
    function getUserById(bytes32 uid) public view returns (address, bytes32, bytes32, bytes32, int64, int64, int64) {
        User memory user = users[uid];
        if (user.uid == 0x00) {
            user = users[uaddrids[msg.sender]];
        }
        if (user.addr == msg.sender || ucheck(user.eid, user.level)) {
            return (user.addr, user.uid, user.eid, user.uhash, user.level, user.timestamp, user.status);
        } else {
            return (0x00, bytes32(0x00), 0x00, 0x00, int64(0), 0, 0);
        }
    }

    /*@ 获取用户信息By用户地址
    //@desc: 仅用户自身,平台管理员和用户公司管理员可以查看用户信息,addr为空表示查看自身信息
    //@param addr: 用户地址
    //@return 0: 用户地址
    //@return 1: 用户id
    //@return 2: 用户公司id
    //@return 3: 用户hash
    //@return 4: 用户级别
    //@return 5: 生成时间戳
    //@return 6: 用户状态
    */
    function getUserByAddr(address addr) public view returns (address, bytes32, bytes32, bytes32, int64, int64, int64) {
        bytes32 uid = uaddrids[addr];
        if (addr == 0x00) {
            uid = uaddrids[msg.sender];
        }
        return getUserById(uid);
    }

    /*@ 获取用户信息By用户索引
    //@desc: 仅用户自身,平台管理员和用户公司管理员可以查看用户信息,idx小于0表示查看自身信息
    //@param idx: 用户索引
    //@return 0: 用户地址
    //@return 1: 用户id
    //@return 2: 用户公司id
    //@return 3: 用户hash
    //@return 4: 用户级别
    //@return 5: 生成时间戳
    //@return 6: 用户状态
    */
    function getUserByIdx(int64 idx) public view returns (address, bytes32, bytes32, bytes32, int64, int64, int64) {
        bytes32 uid = uidxids[idx];
        if (idx < 0) {
            uid = uaddrids[msg.sender];
        }
        return getUserById(uid);
    }

    /* 获取自身信息
    //@desc:
    //@return 0: 用户地址
    //@return 1: 用户id
    //@return 2: 用户公司id
    //@return 3: 用户hash
    //@return 4: 用户级别
    //@return 5: 生成时间戳
    //@return 6: 用户状态
    */
    /*
    function getMyInfo() public view returns (address, bytes32, bytes32, bytes32, int64, int64, int64) {
        User memory user = users[uaddrids[msg.sender]];
        if (user.uid == 0x00) {
            return (0x00, bytes32(0x00), 0x00, 0x00, int64(0), 0, 0);
        } else {
            return (user.addr, user.uid, user.eid, user.uhash, user.level, user.timestamp, user.status);
        }
    }
    */

    /* 获取用户等级状态 
    //@desc:
    //@param uid: 用户id
    //@return 0: [用户等级, 用户状态]
    */
    /*
    function getUserLS(bytes32 uid) public view returns (int64[2]) {
        if (uid == 0x00) {
            return ([int64(0), 0]);
        } else {
            User memory user = users[uid];
            return [user.level, user.status];
        }
    }
    */

    /* 获取用户等级状态By用户地址 
    //@desc:
    //@param addr: 用户地址
    //@return 0: [用户等级, 用户状态]
    */
    /*
    function getUserLSByAddr(address addr) public view returns (int64[2]) {
        if (uaddrids[addr] == 0x00) {
            return ([int64(0), 0]);
        } else {
            User memory user = users[uaddrids[addr]];
            return [user.level, user.status];
        }
    }
    */
    

    /*@ 设置资源
    //@desc: 内部调用
    //@param bts: bytes32类型字段[资源id, 资源父id, 上传者id, 所有者id, 文件hash, 加密文件hash, 额外信息hash, 加密方式, 加密key]
    //@param its: int64类型字段[资源公开度, 资源安全级别, 资源状态]
    //@return 0: 是否设置成功
    */
    function setItem(bytes32[9] bts, int64[3] its) internal returns (bool) {
        User memory user = users[bts[3]];
        if (its[0] < 0) {
            its[0] == 0;
        }
        if (its[1] <= 0) {
            its[1] = user.level;
        }
        if (user.level > its[1]) {
            its[1] = user.level;
        }
        if (its[2] < 0) {
            return false;
        }
        iidxids[itemnum++] = bts[0];
        items[bts[0]] = Item(bts[0], bts[1], bts[2], bts[3], bts[4], bts[5], bts[6], bts[7], bts[8], its[0], its[1], int64(block.timestamp), its[2]);
        //iiduids[ids[0]] = ids[3];
        return true;
    }

    /*@ 添加资源(管理员)
    //@desc: 仅平台管理员调用,可以指定资源的上传者
    //@param bts: bytes32类型字段[资源id, 资源父id, 上传者id, 所有者id, 文件hash, 加密文件hash, 额外信息hash, 加密方式, 加密key]
    //@param its: int64类型字段[资源公开度, 资源安全级别, 资源状态]
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function addItem(bytes32[9] bts, int64[3] its, bytes32 sn, string details) public returns (bool) {
        bytes32 senderid = uaddrids[msg.sender];
        if (senderid == 0x00) {
            revert("failed");
        }
        User memory sender = users[senderid];
        if (sender.status != 1 || sender.level != 1) {
            revert("failed");
        }
        bytes32 uperid = senderid;
        bytes32 userid = senderid;

        if (bts[2] != 0x00) {
            uperid = bts[2];
        }
        if (bts[3] != 0x00) {
            userid = bts[3];
        }
        if (setItem(bts, its)) {
            //emit TXReceipt(bts[9], senderid, bts[0], 0x00, "addItem", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, senderid, ids[0], 0x00], 0x00, "addItem", details, 0, int64(block.timestamp));
            //emit TXReceipt(bts[9], "addItem", msg.sender, [senderid, userid, bts[0], 0x00], 0, int64(block.timestamp), details);
            emit TXReceipt(sn, userid, bts[0], "addItem", senderid, msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 上传资源
    //@desc: 所有用户均可调用,资源上传者为自身,资源上传时可指定资源所有者
    //@param bts: bytes32类型字段[资源id, 资源父id, 所有者id, 文件hash, 加密文件hash, 额外信息hash, 加密方式, 加密key]
    //@param its: int64类型字段[资源公开度, 资源安全级别, 资源状态]
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function uplItem(bytes32[8] bts, int64[3] its, bytes32 sn, string details) public returns (bool) {
        bytes32 senderid = uaddrids[msg.sender];
        if (senderid == 0x00) {
            revert("failed");
        }
        User memory sender = users[senderid];
        if (sender.status != 1) {
            revert("failed");
        }
        bytes32 userid = senderid;
        if (bts[2] != 0x00) {
            userid = bts[2];
        }
        if (setItem([bts[0], bts[1], senderid, userid, bts[3], bts[4], bts[5], bts[6], bts[7]], its)) {
            //emit TXReceipt(bts[8], senderid, bts[0], 0x00, "uplItem", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, senderid, 0x00, 0x00], 0x00, "uplItem", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, userid, bts[0], "uplItem", senderid, msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 转移资源所有权
    //@desc: 仅资源所有者可以将资源所有权转移给其他用户
    //@param uid: 目标用户id
    //@param iid: 资源id
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function transItem(bytes32 uid, bytes32 iid, bytes32 sn, string details) public returns (bool) {
        bytes32 senderid = uaddrids[msg.sender];
        if (senderid == 0x00 || uid == 0x00 || iid == 0x00) {
            revert("failed");
        }
        User memory sender = users[senderid];
        User memory user = users[uid];
        if (sender.status != 1) {
            revert("failed");
        }
        Item storage item = items[iid];
        if (item.userid != senderid) {
            revert("failed");
        }
        item.userid = uid;
        if (item.level < user.level) {
            item.level = user.level;
        }
        //emit TXReceipt(sn, senderid, bts[0], 0x00, "transItem", details, msg.sender, 0, int64(block.timestamp));
        //setLog([sn, senderid, 0x00, 0x00], 0x00, "uplItem", details, 0, int64(block.timestamp));
        emit TXReceipt(sn, uid, iid, "transItem", senderid, msg.sender, 0, int64(block.timestamp), "", details);
        return true;
    }

    /*@ 设置资源额外信息hash
    //@desc: 内部调用
    //@param iid: 资源id
    //@param newihash: 资源新的额外信息hash
    //@return 0: 是否设置成功
    */
    function setItemIhash(bytes32 iid, bytes32 newihash) internal returns (bool) {
        Item storage item = items[iid];
        item.ihash = newihash;
        return true;
    }

    /*@ 设置资源额外信息hashBy资源id
    //@desc: 仅平台管理员和资源所有者可以修改资源额外信息hash
    //@param iid: 资源id
    //@param newihash: 资源新的额外信息hash
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setItemIhashById(bytes32 iid, bytes32 newihash, bytes32 sn, string details) public returns (bool) {
        if (icheck(iid, false) && setItemIhash(iid, newihash)) {
            Item memory item = items[iid];
            //emit TXReceipt(sn, 0x00, iid, 0x00, "setItemIhashById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], id, 0x00], 0x00, "setItemStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, item.userid, iid, "setItemIhashById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置资源额外信息hashBy资源索引
    //@desc: 仅平台管理员和资源所有者可以修改资源额外信息hash
    //@param idx: 资源索引
    //@param newihash: 资源新的额外信息hash
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setItemIhashByIdx(int64 idx, bytes32 newihash, bytes32 sn, string details) public returns (bool) {
        bytes32 iid = iidxids[idx];
        if (icheck(iid, false) && setItemIhash(iid, newihash)) {
            Item memory item = items[iid];
            //emit TXReceipt(sn, 0x00, iid, 0x00, "setItemIhashByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], id, 0x00], 0x00, "setItemStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, item.userid, iid, "setItemIhashByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置资源公开度和安全级别
    //@desc: 内部调用
    //@param iid: 资源id
    //@param newiopen: 资源新的公开度
    //@param newlevel: 资源新的安全级别
    //@return 0: 是否设置成功
    */
    function setItemOLevel(bytes32 iid, int64 newiopen, int64 newlevel) internal returns (bool) {
        if (newiopen < 0 || newlevel <= 0) {
            return false;
        }
        bytes32 senderid = uaddrids[msg.sender];
        User memory user = users[senderid];
        Item storage item = items[iid];
        if (newlevel < user.level) {
            return false;
        }
        item.level = newlevel;
        item.iopen = newiopen;
        return true;
    }

    /*@ 设置资源公开度和安全级别By资源id
    //@desc: 仅平台管理员和资源所有者可以修改资源公开度和安全级别
    //@param iid: 资源id
    //@param newiopen: 资源新的公开度
    //@param newlevel: 资源新的安全级别
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setItemOLevelById(bytes32 iid, int64 newiopen, int64 newlevel, bytes32 sn, string details) public returns (bool) {
        if (icheck(iid, false) && setItemOLevel(iid, newiopen, newlevel)) {
            Item memory item = items[iid];
            //emit TXReceipt(sn, 0x00, iid, 0x00, "setItemOLevelById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], id, 0x00], 0x00, "setItemStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, item.userid, iid, "setItemOLevelById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置资源安全级别By资源索引
    //@desc: 仅平台管理员和资源所有者可以修改资源公开度和安全级别
    //@param idx: 资源索引
    //@param newiopen: 资源新的公开度
    //@param newlevel: 资源新的安全级别
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setItemOLevelByIdx(int64 idx, int64 newiopen, int64 newlevel, bytes32 sn, string details) public returns (bool) {
        bytes32 iid = iidxids[idx];
        if (icheck(iid, false) && setItemOLevel(iid, newiopen, newlevel)) {
            Item memory item = items[iid];
            //emit TXReceipt(sn, 0x00, iid, 0x00, "setItemOLevelByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], id, 0x00], 0x00, "setItemStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, item.userid, iid, "setItemOLevelByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置资源状态
    //@desc: 内部调用
    //@param iid: 资源id
    //@param newstatus: 资源新的状态
    //@return 0: 是否设置成功
    */
    function setItemStatus(bytes32 iid, int64 newstatus) internal returns (bool) {
        if (newstatus < 0) {
            return false;
        }
        Item storage item = items[iid];
        item.status = newstatus;
        return true;
    }

    /*@ 设置资源状态By资源id
    //@desc: 仅平台管理员和资源所有者可以修改资源状态
    //@param iid: 资源id
    //@param newstatus: 资源新的状态
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setItemStatusById(bytes32 iid, int64 newstatus, bytes32 sn, string details) public returns (bool) {
        if (icheck(iid, false) && setItemStatus(iid, newstatus)) {
            Item memory item = items[iid];
            //emit TXReceipt(sn, 0x00, iid, 0x00, "setItemStatusById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], id, 0x00], 0x00, "setItemStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, item.userid, iid, "setItemStatusById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置资源状态By资源索引
    //@desc: 仅平台管理员和资源所有者可以修改资源状态
    //@param idx: 资源索引
    //@param newstatus: 资源新的状态
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setItemStatusByIdx(int64 idx, int64 newstatus, bytes32 sn, string details) public returns (bool) {
        bytes32 iid = iidxids[idx];
        if (icheck(iid, false) && setItemStatus(iid, newstatus)) {
            Item memory item = items[iid];
            //emit TXReceipt(sn, 0x00, iid, 0x00, "setItemStatusByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], id, 0x00], 0x00, "setItemStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, item.userid, iid, "setItemStatusByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), "", details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 获取资源总数
    //@desc: 仅平台管理员可以查看资源总数
    //@return 0: 资源总数
    */
    function getItemNum() public view returns (int64) {
        bytes32 senderid = uaddrids[msg.sender];
        if (senderid == 0x00) {
            return 0;
        }
        User memory sender = users[senderid];
        if (sender.status != 1 || sender.level != 1) {
            return 0;
        }
        return itemnum;
    }

    /*@ 获取资源信息By资源id
    //@desc: 平台管理员,资源所有者和资源权限持有者均可以查看资源信息
    //@param iid: 资源id
    //@return 0: bytes32类型字段[资源id, 资源父id, 上传者id, 所有者id, 文件hash, 加密文件hash, 额外信息hash, 加密方式, 加密key]
    //@return 1: int64类型字段[资源公开度, 资源安全级别, 资源生成时间戳, 资源状态]
    */
    function getItemById(bytes32 iid) public view returns (bytes32[9], int64[4]) {
        if (!icheck(iid, true)) {
            return ([bytes32(0x00), 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], [int64(0), 0, 0, 0]);
        } else {
            Item memory item = items[iid];
            return ([item.iid, item.tid, item.uperid, item.userid, item.xhash, item.shash, item.ihash, item.cipher, item.ikey], [item.iopen, item.level, item.timestamp, item.status]);
        }
    }

    /*@ 获取资源信息By资源索引
    //@desc: 平台管理员,资源所有者和资源权限持有者均可以查看资源信息
    //@param idx: 资源索引
    //@return 0: bytes32类型字段[资源id, 资源父id, 上传者id, 所有者id, 文件hash, 加密文件hash, 额外信息hash, 加密方式, 加密key]
    //@return 1: int64类型字段[资源公开度, 资源安全级别, 资源生成时间戳, 资源状态]
    */
    function getItemByIdx(int64 idx) public view returns (bytes32[9], int64[4]) {
        return getItemById(iidxids[idx]);
    }

    /* 获取资源公开度安全级别状态
    //@desc:
    //@param iid: 资源id
    //@return 0: int64类型字段[资源公开度, 资源安全级别, 资源状态]
    */
    /*
    function getItemOLS(bytes32 iid) public view returns (int64[3]) {
        if (!icheck(iid, true)) {
            return ([int64(0), 0, 0]);
        } else {
            Item memory item = items[iid];
            return [item.iopen, item.level, item.status];
        }
    }
    */
    

    /*@ 设置权限
    //@desc: 内部调用
    //@param bts: bytes32类型字段[权限id, 父权限id, 授予用户id, 授予资源id, 权限额外信息hash, 授权设备, 水印内容]
    //@param prvs: 授权权限[查看权限, 源文件下载权限, 加密文件下载权限, 授予权限]
    //@param its: int64类型字段[授权查看时间, 授权查看次数, 授权查看起始时间段, 授权查看终止时间段, 授权过期时间戳, 授权类型, 授权状态]
    //@return 0: 设置是否成功
    */
    function setPerm(bytes32[7] bts, int64[4] prvs, int64[7] its) internal returns (bool) {
        // TODO user.level >= item.level
        User memory sender = users[uaddrids[msg.sender]];
        //Perm memory perm = perms[ids[1]];
        //User memory user = users[bts[2]];
        Item memory item = items[bts[3]];
        pidxids[permnum++] = bts[0];
        perms[bts[0]] = Perm(bts[0], bts[1], sender.uid, bts[2], bts[3], bts[4], bts[5], bts[6], [prvs[0], prvs[1], prvs[2], prvs[3]], [its[0], its[0]], [its[1], its[1]], [its[2], its[3]], [int64(block.timestamp), its[4]], its[5], its[6]);
        bytes32[] storage permids = puiidids[concat(bts[2], bts[3])];
        permids.push(bts[0]);       // 将权限加入用户对资源的权限列表中
        // piduiids[ids[0]] = [ids[2], ids[3]];

        if (item.userid != sender.uid && sender.level != 1) {
            if (bts[1] == 0x00) {
                return false;
            }
            if (setPermTime(bts[1], its[0], 1) && setPermTimes(bts[1], its[1], 1)) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }


    /*@ 添加权限
    //@desc: 仅平台管理员,资源所有者和资源权限持有者可以对资源进行授权
    //@param bts: bytes32类型字段[权限id, 父权限id, 授予用户id, 资源id, 权限额外信息hash, 授权设备, 水印内容]
    //@param prvs: 授权权限[查看权限, 源文件下载权限, 加密文件下载权限, 授予权限]
    //@param its: int64类型字段[授权查看时间, 授权查看次数, 授权查看起始时间段, 授权查看终止时间段, 授权过期时间戳, 授权类型, 授权状态]
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 设置是否成功
    */
    function addPerm(bytes32[7] bts, int64[4] prvs, int64[7] its, bytes32 sn, string details) public returns (bool) {
        if (pcheck([bts[2], bts[3], bts[1], bts[5], bts[6]], prvs, its) && setPerm(bts, prvs, its)) {
            //emit TXReceipt(sn, ids[1], ids[2], ids[0], "addPerm", details, msg.sender, 0, int64(block.timestamp));
            // emit WatchDog (block.coinbase, sn, details, status);
            //setLog([sn, uaddrids[msg.sender], ids[2], ids[1]], 0x00, "addPerm", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, bts[2], bts[3], "addPerm", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), bytes32ToString(bts[0]), details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置权限时间
    //@desc: 内部调用
    //@param pid: 权限id
    //@param utime: 设定或者消耗的权限时间
    //@param smod: 设置模式(0=设定, 1=减去)
    //@return 0: 是否设置成功
    */
    function setPermTime(bytes32 pid, int64 utime, int64 smod) internal returns (bool) {
        if (pid == 0x00 || utime < -1 || smod < 0) {
            return false;
        }

        Perm storage perm = perms[pid];
        if (perm.ptype == 1) {                                     // 委托权限不可修改
            return true;
        }

        if (smod == 0) {                      // 设定剩余时间
            User memory sender = users[uaddrids[msg.sender]];
            if (sender.status != 1) {
                return false;
            }
            Item memory item = items[perm.itemid];
            if (sender.level == 1 || sender.uid == item.userid) {          //只有管理员和权限对应的资源持有者可以设定权限的值
                if (perm.ptime[0] == -1 || perm.ptime[0] < utime) {
                    perm.ptime = [utime, utime];
                } else {
                    perm.ptime = [perm.ptime[0], utime];
                }
                return true;
            } else {
                return false;
            }
        } else {                                 // 从剩余时间中减去
            if (utime < 0 && perm.ptime[0] != -1) {
                return false;
            }
            if (perm.ptime[0] == -1) {
                return true;
                // return setPermTimes(pid, 1, smod);
            } else {
                if (perm.ptime[1] == 0) {        // 无剩余时间则不可用于授权
                    return false;
                } else {
                    if (utime >= perm.ptime[1]) {
                        perm.ptime = [perm.ptime[0], 0];
                    } else {
                        perm.ptime = [perm.ptime[0], perm.ptime[1] - utime];
                    }
                    return true;
                    // return setPermTimes(pid, 1, smod);
                }
            }
        }
    }


    /* 设置权限时间By权限id
    //@param pid: 权限id
    //@param utime: 消耗的时间
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setPermTimeById(bytes32 pid, int64 utime, bytes32 sn, string details) public returns (bool) {
        Perm memory perm = perms[pid];
        if (pcheck([perm.itemid, pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermTime(pid, utime, 0)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermTimeById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermTimeById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, pid, "setPermTimeById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /* 设置权限时间By权限索引
    //@param idx: 权限索引
    //@param utime: 消耗的时间
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setPermTimeByIdx(int64 idx, int64 utime, bytes32 sn, string details) public returns (bool) {
        bytes32 pid = pidxids[idx];
        Perm memory perm = perms[pid];
        if (pcheck([perm.itemid, pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermTime(pid, utime, 0)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermTimeByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermTimeByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, pid, "setPermTimeByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */


    /*@ 设置权限次数
    //@desc: 内部调用
    //@param pid: 权限id
    //@param utimes: 权限次数
    //@param smod: 设置模式(0=设定, 1=减去)
    //@return 0: 是否设置成功
    */
    function setPermTimes(bytes32 pid, int64 utimes, int64 smod) internal returns (bool) {
        if (pid == 0x00 || utimes < -1 || smod < 0) {
            return false;
        }

        Perm storage perm = perms[pid];

        if (perm.ptype == 1) {                                     // 委托权限不可修改
            return true;
        }

        if (smod == 0) {                      // 设定剩余次数
            User memory sender = users[uaddrids[msg.sender]];
            if (sender.status != 1) {
                return false;
            }
            Item memory item = items[perm.itemid];
            if (sender.level == 1 || sender.uid == item.userid) {          //只有管理员和权限对应的资源持有者可以设定权限的值
                if (perm.ptimes[0] == -1 || perm.ptimes[0] < utimes) {
                    perm.ptimes = [utimes, utimes];
                } else {
                    perm.ptimes = [perm.ptimes[0], utimes];
                }
                return true;
            } else {
                return false;
            }
        } else {                                 // 从剩余次数中减去
            if (utimes < 0 && perm.ptimes[0] != -1) {
                return false;
            }
            if (perm.ptimes[0] == -1) {
                return true;
            } else {
                if (perm.ptimes[1] == 0) {              // 无剩余次数则不可用于授权
                    return false;
                } else {
                    if (utimes >= perm.ptimes[1]) {
                        perm.ptimes = [perm.ptimes[0], 0];
                    } else {
                        perm.ptimes = [perm.ptimes[0], perm.ptimes[1] - utimes];
                    }
                    return true;
                }
            }
        }
    }


    /* 设置权限次数By权限id
    //@param pid: 权限id
    //@param utimes: 消耗的次数
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setPermTimesById(bytes32 pid, int64 utimes, bytes32 sn, string details) public returns (bool) {
        Perm memory perm = perms[pid];
        if (pcheck([perm.itemid, pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermTimes(pid, utimes, 0)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermTimeById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermTimeById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, pid, "setPermTimesById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /* 设置权限次数By权限索引
    //@param idx: 权限索引
    //@param utimes: 消耗的次数
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setPermTimesByIdx(int64 idx, int64 utimes, bytes32 sn, string details) public returns (bool) {
        Perm memory perm = perms[pidxids[idx]];
        if (pcheck([perm.itemid, perm.pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermTimes(perm.pid, utimes, 0)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermTimeByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermTimeByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, perm.pid, "setPermTimesByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /* 设置权限时间次数By权限用户和资源
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param ids: [用户id, 资源id]
    //@param utime: 消耗的时间
    //@return 0: 是否设置成功
    */
    /*
    function setPermTimeByUI(bytes32 sn, string details, bytes32[2] ids, int64 utime) public onlyValid returns (bool) {
        bytes32 id = puiidids[concat(ids[0], ids[1])];
        if (setPermTime(id, utime)) {
            emit TXReceipt(sn, msg.sender, ids[0], ids[1], id, "setPermTimeByUI", details, int64(block.timestamp));
            setLog([sn, uaddrids[msg.sender], ids[1]], "setPermTimeByUI", 0x00, 0x00, 0, int64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /* 设置权限hash
    //@param pid: 权限id
    //@param newphash: 权限新的hash
    //@return 0: 是否设置成功
    */
    /*
    function setPermHash(bytes32 pid, bytes32 newphash) internal returns (bool) {
        if (pid == 0x00) {
            return false;
        } else {
            Perm storage perm = perms[pid];
            User memory sender = users[uaddrids[msg.sender]];
            if (sender.status != 1) {
                return false;
            }
            Item memory item = items[perm.itemid];
            if (sender.level == 1 || sender.uid == item.userid || sender.uid == perm.sgerid) {
                perm.phash = newphash;
            }
            return true;
        }
    }
    */

    /* 设置权限hashBy权限id
    //@param pid: 权限id
    //@param newphash: 权限新的hash
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setPermHashById(bytes32 pid, bytes32 newphash, bytes32 sn, string details) public returns (bool) {
        Perm memory perm = perms[pid];
        if (perm.pid != 0x00 && pcheck([perm.itemid, pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermHash(pid, newphash)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermStatusById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, pid, "setPermHashById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /* 设置权限hashBy权限索引
    //@param idx: 权限索引
    //@param newphash: 权限新的hash
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setPermHashByIdx(int64 idx, bytes32 newphash, bytes32 sn, string details) public returns (bool) {
        Perm memory perm = perms[pidxids[idx]];
        if (perm.pid != 0x00 && pcheck([perm.itemid, perm.pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermHash(perm.pid, newphash)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermStatusByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, perm.pid, "setPermHashByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /* 设置权限设备
    //@param pid: 权限id
    //@param newdevice: 权限新的设备
    //@return 0: 是否设置成功
    */
    /*
    function setPermDevice(bytes32 pid, bytes32 newdevice) internal returns (bool) {
        if (pid == 0x00) {
            return false;
        } else {
            Perm storage perm = perms[pid];
            User memory sender = users[uaddrids[msg.sender]];
            if (sender.status != 1) {
                return false;
            }
            Item memory item = items[perm.itemid];
            if (sender.level == 1 || sender.uid == item.userid || sender.uid == perm.sgerid) {
                perm.device = newdevice;
            }
            return true;
        }
    }
    */

    /* 设置权限设备By权限id
    //@param pid: 权限id
    //@param newdevice: 权限新的设备
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setPermDeviceById(bytes32 pid, bytes32 newdevice, bytes32 sn, string details) public returns (bool) {
        Perm memory perm = perms[pid];
        if (perm.pid != 0x00 && pcheck([perm.itemid, pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermDevice(pid, newdevice)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermStatusById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, pid, "setPermDeviceById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /* 设置权限设备By权限索引
    //@param idx: 权限索引
    //@param newdevice: 权限新的设备
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setPermDeviceByIdx(int64 idx, bytes32 newdevice, bytes32 sn, string details) public returns (bool) {
        Perm memory perm = perms[pidxids[idx]];
        if (perm.pid != 0x00 && pcheck([perm.itemid, perm.pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermDevice(perm.pid, newdevice)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermStatusByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, perm.pid, "setPermDeviceByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /* 设置权限水印
    //@param pid: 权限id
    //@param newpmark: 权限新的水印
    //@return 0: 是否设置成功
    */
    /*
    function setPermMark(bytes32 pid, bytes32 newpmark) internal returns (bool) {
        if (pid == 0x00) {
            return false;
        } else {
            Perm storage perm = perms[pid];
            User memory sender = users[uaddrids[msg.sender]];
            if (sender.status != 1) {
                return false;
            }
            Item memory item = items[perm.itemid];
            if (sender.level == 1 || sender.uid == item.userid || sender.uid == perm.sgerid) {
                perm.pmark = newpmark;
            }
            return true;
        }
    }
    */

    /* 设置权限水印By权限id
    //@param pid: 权限id
    //@param newpmark: 权限新的水印
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setPermMarkById(bytes32 pid, bytes32 newpmark, bytes32 sn, string details) public returns (bool) {
        Perm memory perm = perms[pid];
        if (perm.pid != 0x00 && pcheck([perm.itemid, pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermMark(pid, newpmark)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermStatusById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, pid, "setPermMarkById", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /* 设置权限水印By权限索引
    //@param idx: 权限索引
    //@param newpmark: 权限新的水印
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    /*
    function setPermMarkByIdx(int64 idx, bytes32 newpmark, bytes32 sn, string details) public returns (bool) {
        Perm memory perm = perms[pidxids[idx]];
        if (perm.pid != 0x00 && pcheck([perm.itemid, perm.pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermMark(perm.pid, newpmark)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermStatusByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, perm.pid, "setPermMarkByIdx", uaddrids[msg.sender], msg.sender, 0, int64(block.timestamp), details);
            return true;
        } else {
            revert("failed");
        }
    }
    */


    /*@ 设置权限状态
    //@desc: 内部调用
    //@param pid: 权限id
    //@param newstatus: 权限新的状态
    //@return 0: 是否设置成功
    */
    function setPermStatus(bytes32 pid, int64 newstatus) internal returns (bool) {
        if (pid == 0x00 || newstatus < 0) {
            return false;
        } else {
            Perm storage perm = perms[pid];
            User memory sender = users[uaddrids[msg.sender]];
            if (sender.status != 1) {
                return false;
            }
            Item memory item = items[perm.itemid];
            if (sender.level == 1 || sender.uid == item.userid || sender.uid == perm.sgerid) {
                perm.status = newstatus;
                return true;
            } else {
                return false;
            }
        }
    }

    /*@ 设置权限状态By权限id
    //@desc: 仅平台管理员,资源所有者和权限授予者可以修改权限状态
    //@param pid: 权限id
    //@param newstatus: 权限新的状态
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setPermStatusById(bytes32 pid, int64 newstatus, bytes32 sn, string details) public returns (bool) {
        User memory sender = users[uaddrids[msg.sender]];
        Perm memory perm = perms[pid];
        if (setPermStatus(perm.pid, newstatus)) {
        //if (perm.pid != 0x00 && pcheck([perm.itemid, pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermStatus(pid, newstatus)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermStatusById", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermStatusById", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, "setPermStatusById", sender.uid, msg.sender, 0, int64(block.timestamp), bytes32ToString(pid), details);
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置权限状态By权限索引
    //@desc: 仅平台管理员,资源所有者和权限授予者可以修改权限状态
    //@param idx: 权限索引
    //@param newstatus: 权限新的状态
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setPermStatusByIdx(int64 idx, int64 newstatus, bytes32 sn, string details) public returns (bool) {
        User memory sender = users[uaddrids[msg.sender]];
        Perm memory perm = perms[pidxids[idx]];
        if (setPermStatus(perm.pid, newstatus)) {
        //if (perm.pid != 0x00 && pcheck([perm.itemid, perm.pid, perm.device, perm.pmark], [int64(0), 0, 0, 0], [int64(0), 0, perm.pslice[0], perm.pslice[1], perm.ptimestamp[1], 0, 0]) && setPermStatus(perm.pid, newstatus)) {
            //emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermStatusByIdx", details, msg.sender, 0, int64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermStatusByIdx", details, 0, int64(block.timestamp));
            emit TXReceipt(sn, perm.userid, perm.itemid, "setPermStatusByIdx", sender.uid, msg.sender, 0, int64(block.timestamp), bytes32ToString(perm.pid), details);
            return true;
        } else {
            revert("failed");
        }
    }

    /* 设置权限状态By权限用户和资源
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param ids: [用户id, 资源id]
    //@param newstatus: 权限新的状态
    //@return 0: 是否设置成功
    */
    /*
    function setPermStatusByUI(bytes32 sn, string details, bytes32[2] ids, int64 newstatus) public onlyValid returns (bool) {
        bytes32 id = puiidids[concat(ids[0], ids[1])];
        if (setPermStatus(id, newstatus)) {
            emit TXReceipt(sn, msg.sender, piduiids[id][0], piduiids[id][1], id, "setPermStatusByUI", details, int64(block.timestamp));
            setLog([sn, uaddrids[msg.sender], piduiids[id][1]], "setPermStatusByUI", 0x00, 0x00, 0, int64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }
    */

    
    /*@ 获取权限总数
    //@desc: 仅平台管理员可以查看权限总数
    //@return 0: 权限总数
    */
    function getPermNum() public view returns (int64) {
        bytes32 senderid = uaddrids[msg.sender];
        if (senderid == 0x00) {
            return 0;
        }
        User memory sender = users[senderid];
        if (sender.status != 1 || sender.level != 1) {
            return 0;
        }
        return permnum;
    }

    /*@ 获取权限信息By权限id
    //@desc: 仅平台管理员,权限授予者和权限持有者可以查看权限信息
    //@param pid: 权限id
    //@return 0: bytes32类型字段[权限id, 父权限id, 授予者id, 授予用户id, 资源id, 权限额外信息hash, 授权设备, 水印内容]
    //@return 1: 授权权限[查看权限, 源文件下载权限, 加密文件下载权限, 授予权限]
    //@return 2: int64二维数组类型字段[授权查看时间, 授权查看次数, 授权查看时间段, 授权时间戳]
    //@return 3: int64类型字段[授权类型, 授权状态]
    */
    function getPermById(bytes32 pid) public view returns (bytes32[8], int64[4], int64[2][4], int64[2]) {
        User memory sender = users[uaddrids[msg.sender]];
        Perm memory perm = perms[pid];
        if (perm.pid != 0x00 && sender.status == 1 && (sender.level == 1 || perm.sgerid == sender.uid || perm.userid == sender.uid)) {
            return ([perm.pid, perm.tid, perm.sgerid, perm.userid, perm.itemid, perm.phash, perm.device, perm.pmark], [perm.prvs[0], perm.prvs[1], perm.prvs[2], perm.prvs[3]], [[perm.ptime[0], perm.ptime[1]], [perm.ptimes[0], perm.ptimes[1]], [perm.pslice[0], perm.pslice[1]], [perm.ptimestamp[0], perm.ptimestamp[1]]], [perm.ptype, perm.status]);
        } else {
            return ([bytes32(0x00), 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], [int64(0), 0, 0, 0], [[int64(0), 0], [int64(0), 0], [int64(0), 0], [int64(0), 0]], [int64(0), 0]);
        }
    }

    /*@ 获取权限信息By权限索引
    //@desc: 仅平台管理员,权限授予者和权限持有者可以查看权限信息
    //@param idx: 权限索引
    //@return 0: bytes32类型字段[权限id, 父权限id, 授予者id, 授予用户id, 资源id, 权限额外信息hash, 授权设备, 水印内容]
    //@return 1: 授权权限[查看权限, 源文件下载权限, 加密文件下载权限, 授予权限]
    //@return 2: int64二维数组类型字段[授权查看时间, 授权查看次数, 授权查看时间段, 授权时间戳]
    //@return 3: int64类型字段[授权类型, 授权状态]
    */
    function getPermByIdx(int64 idx) public view returns (bytes32[8], int64[4], int64[2][4], int64[2]) {
        return getPermById(pidxids[idx]);
    }


    /*@ 获取用户对指定资源的权限数量
    //@desc: 仅平台管理员和用户自身可以查看用户对指定资源的权限数量
    //@param ids: 用户和资源id[用户id, 资源id]
    //@return 0: 权限数量
    */
    function getUIPermNum(bytes32[] ids) public view returns (int64) {
        bytes32 userid;
        bytes32 itemid;
        User memory sender = users[uaddrids[msg.sender]];
        if (sender.uid == 0x00 || ids.length == 0) {
            return 0;
        }
        if (ids.length == 1) {
            userid = sender.uid;
            itemid = ids[0];
        } else {
            userid = ids[0];
            itemid = ids[1];
        }
        if (userid == 0x00 || itemid == 0x00) {
            return 0;
        }
        if (ids.length == 2 && sender.level != 1 && sender.uid != userid) {
            return 0;
        }
        bytes32[] memory permids = puiidids[concat(userid, itemid)];
        return int64(permids.length);
    }

    /*@ 获取用户对指定资源的权限
    //@desc: 仅平台管理员和用户自身可以查看用户对指定资源的权限
    //@param ids: 用户和资源id[用户id, 资源id]
    //@return 0: 权限ids
    */
    function getUIPerms(bytes32[] ids) public view returns (string) {
        bytes32 userid;
        bytes32 itemid;
        User memory sender = users[uaddrids[msg.sender]];
        if (sender.uid == 0x00 || ids.length == 0) {
            return "";
        }
        if (ids.length == 1) {
            userid = sender.uid;
            itemid = ids[0];
        } else {
            userid = ids[0];
            itemid = ids[1];
        }
        if (userid == 0x00 || itemid == 0x00) {
            return "";
        }
        if (ids.length == 2 && sender.level != 1 && sender.uid != userid) {
            return "";
        }
        bytes32[] memory permids = puiidids[concat(userid, itemid)];
        
        if (permids.length == 0) {
            return "";
        } else {
            return bytes32ArrayToString(permids, -1);
        }
        //return permids[idx];
    }

    /*
    function getUIPermByIdx(bytes32[] ids, int64 idx) public view returns (bytes32) {
        bytes32 userid;
        bytes32 itemid;
        User memory sender = users[uaddrids[msg.sender]];
        if (sender.uid == 0x00 || ids.length == 0 || idx < 0) {
            return 0x00;
        }
        if (ids.length == 1) {
            userid = sender.uid;
            itemid = ids[0];
        } else {
            userid = ids[0];
            itemid = ids[1];
        }
        if (userid == 0x00 || itemid == 0x00) {
            return 0x00;
        }
        if (ids.length == 2 && sender.level != 1 && sender.uid != userid) {
            return 0x00;
        }
        bytes32[] memory permids = puiidids[concat(userid, itemid)];
        return permids[uint(idx)];
    }
    */

    /* 获取权限信息By权限用户和资源
    //@param ids: [用户id, 资源id]
    //@return 0: [权限id, 授予者id, 授予用户id, 资源id]
    //@return 1: 权限播放设备限制
    //@return 2: [查看权限, 下载权限, 授予权限]
    //@return 3: [权限生成时间戳, 权限过期时间戳]
    //@return 4: [权限总时间, 权限剩余时间]
    //@return 5: [权限可用次数, 权限剩余可用次数]
    //@return 6: 权限状态
    */
    /*
    function getPermByUI(bytes32[2] ids) public view returns (bytes32[4], bytes32, int64[3], int64[2], int64[2], int64[2], int64) {
        return getPermById(puiidids[concat(ids[0], ids[1])]);
    }
    */


    /* 获取用户对资源的权限(管理员用户, 资源所有者, 权限拥有者)
    //@param userid: 用户id
    //@param itemid: 资源id
    //@return 0: 用户角色(0=参数不合法, 1=用户不可用, 2=管理员, 3=资源所有者, 4=无权限, 5=有权限)
    //@return 1: [权限id, 授予者id, 授予用户id, 资源id]
    //@return 2: [查看权限, 下载权限, 授予权限]
    //@return 3: [权限生成时间戳, 权限过期时间戳]
    //@return 4: [权限总时间, 权限剩余时间]
    //@return 5: [权限可用次数, 权限剩余可用次数]
    //@return 6: 权限状态
    */
    /*
    function fetchPerm(bytes32 userid, bytes32 itemid) public view returns (int64, bytes32[4], int64[3], int64[2], int64[2], int64[2], int64) {
        if (userid == 0x00 || itemid == 0x00) {
            return (0, [bytes32(0x00), 0x00, 0x00, 0x00], [int64(0), 0, 0], [int64(0), 0], [int64(0), 0], [int64(0), 0], 0);
        } else {
            User memory user = users[userid];
            if (user.status == 0) {
                return (1, [bytes32(0x00), 0x00, 0x00, 0x00], [int64(0), 0, 0], [int64(0), 0], [int64(0), 0], [int64(0), 0], 0);
            } else {
                if (user.level == 1) {
                    return (2, [bytes32(0x00), 0x00, 0x00, 0x00], [int64(0), 0, 0], [int64(0), 0], [int64(0), 0], [int64(0), 0], 0);
                }
                Item memory item = items[itemid];
                if (item.userid == userid) {
                    return (3, [bytes32(0x00), 0x00, 0x00, 0x00], [int64(0), 0, 0], [int64(0), 0], [int64(0), 0], [int64(0), 0], 0);
                }
                bytes32 pid = puiidids[concat(userid, itemid)];
                if (pid == 0x00) {
                    return (4, [bytes32(0x00), 0x00, 0x00, 0x00], [int64(0), 0, 0], [int64(0), 0], [int64(0), 0], [int64(0), 0], 0);
                } else {
                    Perm memory perm = perms[pid];
                    return (5, [perm.id, perm.sgerid, perm.userid, perm.itemid], [perm.ptype[0], perm.ptype[1], perm.ptype[2]], [perm.ptimestamp[0], perm.ptimestamp[1]], [perm.ptime[0], perm.ptime[1]], [perm.ptimes[0], perm.ptimes[1]], perm.status);
                }
            }
        }
    }
    */
    

    /* 设置日志
    //@param ids: [日志id, 用户id, 资源id, 权限id]
    //@param action: 日志操作类型
    //@param desc: 日志描述
    //@param duration: 日志操作时长
    //@param timestamp: 日志生成时间戳
    //@return 0: 是否设置成功
    */
    /*
    function setLog(bytes32[4] ids, bytes32 action, string desc, int64 duration, int64 timestamp) internal returns (bool) {
        lidxids[lognum++] = ids[0];
        logs[ids[0]] = Log(ids[0], ids[1], ids[2], ids[3], action, desc, duration, timestamp);
        liduiids[ids[0]] = [ids[1], ids[2]];
        return true;
    }
    */

  
    /*@ 添加日志
    //@desc: 仅平台管理员,资源所有者和权限持有者可以为资源添加日志,添加日志过程中会更新权限信息,pids第一个参数为空表示由区块链自行决定需要更新的权限
    //@param bts: bytes32类型数据[用户id, 资源id, 操作类型]
    //@param pids: 使用的权限列表
    //@param duration: 日志操作时长(-1=只作记录不修改权限, 0=只减次数不减时长)
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function addLog(bytes32[3] bts, bytes32[] pids, int64 duration, bytes32 sn, string details) public returns (bool) {
        uint i = 0;
        int64 remainder = duration;
        //User memory user = users[bts[0]];
        bytes32[] memory tpids = pids;
        //Item memory item = items[bts[1]];
        //if (duration == -1 || items[bts[1]].userid == bts[0] || isAdmin(bts[0])) {
        if (duration == -1 || lcheck(bts[0], bts[1])) {
            remainder = -1;
        } else {
            if (tpids.length == 0 || tpids[0] == 0x00) {
                tpids = puiidids[concat(bts[0], bts[1])];
            }
            for (i = 0; i < tpids.length; i++) {
                Perm memory perm = perms[tpids[i]];
                if (perm.status == 1 && perm.userid == bts[0] && perm.itemid == bts[1] && perm.ptype == 0 && (perm.ptimestamp[1] == -1 || perm.ptimestamp[1] > int64(block.timestamp)) && (perm.ptime[1] == -1 || perm.ptime[1] > 0) && (perm.ptimes[1] == -1 || perm.ptimes[1] > 0)) {
                    if (perm.ptime[1] == -1) {
                        if (setPermTimes(perm.pid, 1, 1)) {
                            remainder = 0;
                            break;
                        }
                    } else {
                        if (perm.ptime[1] >= remainder) {
                            if (setPermTimes(perm.pid, 1, 1) && setPermTime(perm.pid, remainder, 1)) {
                                remainder = 0;
                                break;
                            }
                        } else {
                            if (setPermTimes(perm.pid, 1, 1) && setPermTime(perm.pid, perm.ptime[1], 1)) {
                                remainder = remainder - perm.ptime[1];
                            }
                        }
                    } 
                }
            }
        }
        if (remainder == -1) {
            emit TXReceipt(sn, bts[0], bts[1], bts[2], uaddrids[msg.sender], msg.sender, duration, int64(block.timestamp), bytes32ArrayToString(tpids, int64(i)), details);
        } else {
            //emit TXReceipt(sn, bts[0], bts[1], "M", bts[2], uaddrids[msg.sender], msg.sender, duration, int64(block.timestamp), details);
            emit TXReceipt(sn, bts[0], bts[1], bts[2], uaddrids[msg.sender], msg.sender, duration, int64(block.timestamp), bytes32ArrayToString(tpids, int64(i + 1)), details);
        }
        return true;

        //emit TXReceipt(sn, ids[1], ids[2], ids[0], "addLog", details, msg.sender, duration, int64(block.timestamp));
        //emit TXReceipt(sn, uaddrids[msg.sender], ids[0], ids[1], ids[2], "addLog", msg.sender, duration, int64(block.timestamp), details);
    }
    
    

    /* 获取日志总数
    //@return 0: 日志总数
    */
    /*
    function getLogNum() public view returns (int64) {
        return lognum;
    }
    */

    /* 获取日志信息By日志id
    //@param id: 日志id
    //@return 0: [日志id, 用户id, 资源id, 权限id]
    //@return 1: 日志操作类型
    //@return 2: 日志描述
    //@return 3: 日志操作时长
    //@return 4: 日志生成时间戳
    */
    /*
    function getLogById(bytes32 id) public view returns (bytes32[4], bytes32, string, int64, int64) {
        if (id == 0x00) {
            return ([bytes32(0x00), 0x00, 0x00, 0x00], bytes32(0x00), "", int64(0), 0);
        } else {
            Log memory log = logs[id];
            return ([log.lid, log.userid, log.itemid, log.permid], log.action, log.desc, log.duration, log.timestamp);
        }
    }
    */

    /* 获取日志信息By日志索引
    //@param idx: 日志索引
    //@return 0: [日志id, 用户id, 资源id,权限id]
    //@return 1: 日志操作类型
    //@return 2: 日志描述
    //@return 3: 日志操作时长
    //@return 4: 日志生成时间戳
    */
    /*
    function getLogByIdx(int64 idx) public view returns (bytes32[4], bytes32, string, int64, int64) {
        return getLogById(lidxids[idx]);
    }
    */

    /*@ 合约自毁
    //@desc: 仅合约部署者可以销毁合约
    */
    function kill() public onlyOwner {
        selfdestruct(owner);
    }


}