pragma solidity ^0.4.23;


/*@ 文件描述
//@filename: RS.sol
//@author: 陈盼
//@date: 2018-07-30
//@project: 滚石
//@describe: 滚石资源权限管理智能合约（第二版）
*/


/*@ 滚石合约
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
        uint64 level;           // 用户级别(0: 地址不存在, 1: 平台管理员, 2: 企业管理员)
        uint64 timestamp;       // 用户创建时间
        uint64 status;          // 用户状态(0: 不存在, 1: 正常, 2：冻结, 6: 不可用)
    }

    /*@ 资源结构体
    */
    struct Item {
        bytes32 iid;            // 资源id
        bytes32 tid;            // 资源父id(0x00表示资源本身是原始资源)
        bytes32 sid;            // 资源未加密源文件id(0x00表示资源本身是未加密源文件)
        //bytes32 uperid;         // 资源上传者id
        bytes32 userid;         // 资源所有者id
        bytes32 itype;          // 资源类型
        //bytes32 cipher;         // 资源加密方式
        // bytes32 title;       // 资源名称
        bytes32 ihash;          // 资源额外信息hash
        bytes32 xhash;          // 资源文件hash
        // bytes32 info;        // 资源主要信息
        // string subids;       // 子资源集合
        uint64 level;           // 资源保密级别
        uint64 timestamp;       // 资源生成时间戳
        uint64 status;          // 资源状态(0: 不存在, 1: 正常, 2：冻结, 6: 不可用)
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
        // bytes32 phash;       // 权限hash
        bytes32 device;         // 授权查看设备
        uint64[3] ptype;        // 授权类型([是否可查看, 是否可下载, 是否可向下授权])
        uint64[2] ptimestamp;   // 授权时间戳([生成时间戳, 过期时间戳])
        uint64[2] ptime;        // 授权查看时间([总时间, 剩余时间])
        uint64[2] ptimes;       // 授权查看次数([总次数, 剩余次数])
        //uint64[2] pslice;        // 授权查看时间段([起始时间, 结束时间])
        uint64 status;          // 授权权限状态(0: 不存在, 1: 正常, 2：冻结, 6: 不可用)
    }

    /*@ 日志结构体
    */
    struct Log {
        bytes32 lid;             // 操作日志id
        bytes32 userid;         // 操作用户id
        bytes32 itemid;         // 操作资源id
        bytes32 permid;         // 操作使用的权限id
        // bytes32 lhash;       // 操作hash
        bytes32 action;         // 操作行为
        string desc;            // 操作描述
        uint64 duration;        // 操作时长
        uint64 timestamp;       // 操作时间戳
    }

    
    // uint networkid = 111;

    address public owner;

    uint64 usernum;
    mapping (uint64 => bytes32) uidxids;            // user index => user id
    mapping (bytes32 => address) uidaddrs;          // user id => user address
    mapping (address => bytes32) uaddrids;          // user address => user id
    mapping (bytes32 => User) users;                // user id => User


    uint64 itemnum;
    mapping (uint64 => bytes32) iidxids;            // item index => item id
    // mapping (bytes32 => bytes32) iiduids;           // item id => user id
    mapping (bytes32 => Item) items;                // item id => Item

    uint64 permnum;
    mapping (uint64 => bytes32) pidxids;            // perm index => perm id
    // mapping (bytes32 => bytes32[2]) piduiids;    // perm id => [userid, itemid]
    // mapping (bytes32 => bytes32) puiidids;       // keccak256([userid, itemid]) => perm id
    mapping (bytes32 => Perm) perms;                // perm id => Perm

    uint64 lognum;
    mapping (uint64 => bytes32) lidxids;            // log index => log id
    mapping (bytes32 => bytes32[2]) liduiids;       // log id => [userid, itemid]
    mapping (bytes32 => Log) logs;                  // log id => Log


    /*@ 测试事件
    //@param addr: address类型日志字段
    //@param themsg: bytes32类型日志字段
    //@param thimsg: string类型日志字段
    //@param res: uint类型日志字段
    */
    event WatchDog (address addr, bytes32 themsg, string thimsg, uint indexed res);

    /*@ 交易凭据日志
    //@param sn: 交易流水号/日志id
    //@param userid: 交易发起者id
    //@param itemid: 交易资源id
    //@param permid: 交易授权id
    //@param action: 交易动作/调用函数
    //@param details: 交易详细信息
    //@param sender: 交易发起者地址
    //@param duration: 交易时长
    //@param timestamp: 交易时间戳
    */
    event TXReceipt (bytes32 indexed sn, bytes32 indexed userid, bytes32 indexed itemid, bytes32 permid, bytes32 action, string details, address sender, uint64 duration, uint64 timestamp);
    //event TXReceipt (bytes32 indexed sn, address sender, bytes32 indexed userid, bytes32 indexed itemid, bytes32 permid, bytes32 rhash, bytes32 action, string details, uint64 duration, uint64 timestamp);


    constructor() public payable{
        owner = msg.sender;
        uidxids[usernum++] = "0";
        uidaddrs["0"] = msg.sender;
        uaddrids[msg.sender] = "0";
        users["0"] = User(msg.sender, "0", "0", "owner", 1, uint64(block.timestamp), 1);
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

    // 修饰器
    modifier onlyAdmin()
    {
        uint64[2] memory ls = getUserLSByAddr(msg.sender);
        require(ls[0] < 3 && ls[1] == 1, "sender level > 2 or status != 1");
        _;
    }

    // 修饰器
    modifier onlyValid()
    {
        uint64[2] memory ls = getUserLSByAddr(msg.sender);
        require(ls[1] == 1, "sender status != 1");
        _;
    }


    /*@ 将两个bytes32变量进行hash
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

    /*@ 判断用户是否是管理员By用户地址
    //@return 0: 是否是管理员
    */
    function isAdmin() internal view returns (bool) {
        uint64[2] memory ls = getUserLSByAddr(msg.sender);
        if (ls[0] == 1) {
            return true;
        } else {
            return false;
        }
    }

    /*@ 判断用户对其他用户的操作权限
    //@param sid: 操作者id
    //@param eid: 被操作者公司id
    //@return 0: 是否有操作权限
    */
    function ucheck(bytes32 sid, bytes32 eid) internal view returns (bool) {
        User memory sender = users[sid];
        if (sender.level > 3 || sender.status != 1) {
            return false;
        }
        if (eid != 0x00) {
            if (sender.eid != eid && sender.level != 1) {
                return false;
            }
        } else {
            if (sender.level != 1) {
                return false;
            }
        }
        return true;
    }

    /*@ 设置用户
    //@param addr: 用户地址
    //@param bts: bytes32类型字段[用户id, 用户公司id, 用户hash]
    //@param its: uint64类型字段[用户级别, 生成时间戳, 用户状态]
    //@return 0: 是否设置成功
    */
    function setUser(address addr, bytes32[3] bts, uint64[3] its) internal returns (bool) {
        if (uaddrids[addr] == 0x00) {
            uidxids[usernum++] = bts[0];
            uidaddrs[bts[0]] = addr;
            uaddrids[addr] = bts[0];
            users[bts[0]] = User(addr, bts[0], bts[1], bts[2], its[0], its[1], its[2]);
            return true;
        } else {
            return false;
        }
    }

    /*@ 添加用户
    //@param addr: 用户地址
    //@param bts: bytes32类型字段[用户id, 用户公司id, 用户hash, 交易流水号]
    //@param its: uint64类型字段[用户级别, 用户状态]
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function addUser(address addr, bytes32[4] bts, uint64[2] its, string details) public payable returns (bool) {
        if (ucheck(uaddrids[msg.sender], bts[1]) && setUser(addr, [bts[0], bts[1], bts[2]], [its[0], uint64(block.timestamp), its[1]])) {
            // addr.transfer(1000000000000000000000);
            addr.transfer(msg.sender.balance / 10000000000);
            emit TXReceipt(bts[3], bts[0], 0x00, 0x00, "addUser", details, msg.sender, 0, uint64(block.timestamp));
            // bytes32 lid = keccak256(block.difficulty,now);
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "addUser", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户状态
    //@param uid: 用户id
    //@param newstatus: 用户新的状态
    //@return 0: 是否设置成功
    */
    function setUserStatus(bytes32 uid, uint64 newstatus) internal returns (bool) {
        if (uid == 0x00) {
            revert("failed");
        } else {
            User storage user = users[uid];
            user.status = newstatus;
            return true;
        }
    }

    /*@ 设置用户状态By地址
    //@param addr: 用户地址
    //@param sn: 交易流水号
    //@param newstatus: 用户新的状态
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserStatusByAddr(address addr, bytes32 sn, uint64 newstatus, string details) public returns (bool) {
        User memory user = users[uaddrids[addr]];
        if (ucheck(uaddrids[msg.sender], user.eid) && setUserStatus(uaddrids[addr], newstatus)) {
            emit TXReceipt(sn, uaddrids[addr], 0x00, 0x00, "setUserStatusByAddr", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByAddr", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户状态By用户id
    //@param uid: 用户id
    //@param sn: 交易流水号
    //@param newstatus: 用户新的状态
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserStatusById(bytes32 uid, bytes32 sn, uint64 newstatus, string details) public returns (bool) {
        User memory user = users[uid];
        if (ucheck(uaddrids[msg.sender], user.eid) && setUserStatus(uid, newstatus)) {
            emit TXReceipt(sn, uid, 0x00, 0x00, "setUserStatusById", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusById", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户状态By索引
    //@param idx: 用户索引
    //@param sn: 交易流水号
    //@param newstatus: 用户新的状态
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserStatusByIdx(uint64 idx, bytes32 sn, uint64 newstatus, string details) public returns (bool) {
        User memory user = users[uidxids[idx]];
        if (ucheck(uaddrids[msg.sender], user.eid) && setUserStatus(uidxids[idx], newstatus)) {
            emit TXReceipt(sn, uidxids[idx], 0x00, 0x00, "setUserStatusByIdx", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByIdx", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户公司
    //@param uid: 用户id
    //@param neweid: 用户新的公司id
    //@return 0: 是否设置成功
    */
    function setUserEid(bytes32 uid, bytes32 neweid) internal returns (bool) {
        if (uid == 0x00) {
            revert("failed");
        } else {
            User storage user = users[uid];
            user.eid = neweid;
            return true;
        }
    }

    /*@ 设置用户公司By地址
    //@param addr: 用户地址
    //@param sn: 交易流水号
    //@param neweid: 用户新的公司id
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserEidByAddr(address addr, bytes32 sn, bytes32 neweid, string details) public returns (bool) {
        User memory user = users[uaddrids[addr]];
        if (ucheck(uaddrids[msg.sender], user.eid) && setUserEid(uaddrids[addr], neweid)) {
            emit TXReceipt(sn, uaddrids[addr], 0x00, 0x00, "setUserEidByAddr", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByAddr", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户公司By用户id
    //@param uid: 用户id
    //@param sn: 交易流水号
    //@param neweid: 用户新的公司
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserEidById(bytes32 uid, bytes32 sn, bytes32 neweid, string details) public returns (bool) {
        User memory user = users[uid];
        if (ucheck(uaddrids[msg.sender], user.eid) && setUserEid(uid, neweid)) {
            emit TXReceipt(sn, uid, 0x00, 0x00, "setUserEidById", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusById", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户公司By索引
    //@param idx: 用户索引
    //@param sn: 交易流水号
    //@param neweid: 用户新的公司id
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserEidByIdx(uint64 idx, bytes32 sn, bytes32 neweid, string details) public returns (bool) {
        User memory user = users[uidxids[idx]];
        if (ucheck(uaddrids[msg.sender], user.eid) && setUserEid(uidxids[idx], neweid)) {
            emit TXReceipt(sn, uidxids[idx], 0x00, 0x00, "setUserEidByIdx", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByIdx", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户级别
    //@param uid: 用户id
    //@param newelevel: 用户新的级别
    //@return 0: 是否设置成功
    */
    function setUserLevel(bytes32 uid, uint64 newlevel) internal returns (bool) {
        if (uid == 0x00) {
            revert("failed");
        } else {
            User storage user = users[uid];
            user.level = newlevel;
            return true;
        }
    }

    /*@ 设置用户级别By地址
    //@param addr: 用户地址
    //@param sn: 交易流水号
    //@param newlevel: 用户新的级别
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserLevelByAddr(address addr, bytes32 sn, uint64 newlevel, string details) public returns (bool) {
        User memory user = users[uaddrids[addr]];
        if (ucheck(uaddrids[msg.sender], user.eid) && setUserLevel(uaddrids[addr], newlevel)) {
            emit TXReceipt(sn, uaddrids[addr], 0x00, 0x00, "setUserLevelByAddr", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByAddr", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户级别By用户id
    //@param uid: 用户id
    //@param sn: 交易流水号
    //@param newlevel: 用户新的级别
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserLevelById(bytes32 uid, bytes32 sn, uint64 newlevel, string details) public returns (bool) {
        User memory user = users[uid];
        if (ucheck(uaddrids[msg.sender], user.eid) && setUserLevel(uid, newlevel)) {
            emit TXReceipt(sn, uid, 0x00, 0x00, "setUserLevelById", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusById", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户级别By索引
    //@param idx: 用户索引
    //@param sn: 交易流水号
    //@param newlevel: 用户新的级别
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setUserLevelByIdx(uint64 idx, bytes32 sn, uint64 newlevel, string details) public returns (bool) {
        User memory user = users[uidxids[idx]];
        if (ucheck(uaddrids[msg.sender], user.eid) && setUserLevel(uidxids[idx], newlevel)) {
            emit TXReceipt(sn, uidxids[idx], 0x00, 0x00, "setUserLevelByIdx", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserStatusByIdx", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置用户Hash
    //@param uid: 用户id
    //@param newhash: 用户新的hash
    //@return 0: 是否设置成功
    */
    function setUserHash(bytes32 uid, bytes32 newhash) internal returns (bool) {
        if (uid == 0x00) {
            revert("failed");
        } else {
            User storage user = users[uid];
            user.uhash = newhash;
            return true;
        }
    }

    /*@ 设置用户hash
    //@param sn: 交易流水号
    //@param newhash: 用户新的hash
    //@param details: 交易详细信息
    //@return 0: 是否设置成功
    */
    function setMyHash(bytes32 sn, bytes32 newhash, string details) public returns (bool) {
        if (setUserHash(uaddrids[msg.sender], newhash)) {
            emit TXReceipt(sn, uaddrids[msg.sender], 0x00, 0x00, "setMyHash", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], 0x00, 0x00], 0x00, "setUserHashByAddr", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 获取用户总数
    //@return 0: 用户总数
    */
    function getUserNum() public view returns (uint64) {
        return usernum;
    }

    /*@ 获取用户信息By用户id
    //@param uid: 用户id
    //@return 0: 用户地址
    //@return 1: 用户id
    //@return 2: 用户公司id
    //@return 3: 用户hash
    //@return 4: 用户级别
    //@return 5: 生成时间戳
    //@return 6: 用户状态
    */
    function getUserById(bytes32 uid) public view returns (address, bytes32, bytes32, bytes32, uint64, uint64, uint64) {
        if (uid == 0x00) {
            return (0x00, bytes32(0x00), 0x00, 0x00, uint64(0), 0, 0);
        } else {
            User memory user = users[uid];
            return (user.addr, user.uid, user.eid, user.uhash, user.level, user.timestamp, user.status);
        }
    }

    /*@ 获取用户信息By用户地址
    //@param addr: 用户地址
    //@return 0: 用户地址
    //@return 1: 用户id
    //@return 2: 用户公司id
    //@return 3: 用户hash
    //@return 4: 用户级别
    //@return 5: 生成时间戳
    //@return 6: 用户状态
    */
    function getUserByAddr(address addr) public view returns (address, bytes32, bytes32, bytes32, uint64, uint64, uint64) {
        return getUserById(uaddrids[addr]);
    }

    /*@ 获取用户信息By用户索引
    //@param idx: 用户索引
    //@return 0: 用户地址
    //@return 1: 用户id
    //@return 2: 用户公司id
    //@return 3: 用户hash
    //@return 4: 用户级别
    //@return 5: 生成时间戳
    //@return 6: 用户状态
    */
    function getUserByIdx(uint64 idx) public view returns (address, bytes32, bytes32, bytes32, uint64, uint64, uint64) {
        return getUserById(uidxids[idx]);
    }

    /*@ 获取用户等级状态 
    //@param uid: 用户id
    //@return 0: [用户等级, 用户状态]
    */
    function getUserLS(bytes32 uid) public view returns (uint64[2]) {
        if (uid == 0x00) {
            return ([uint64(0), 0]);
        } else {
            User memory user = users[uid];
            return [user.level, user.status];
        }
    }

    /*@ 获取用户等级状态By用户地址 
    //@param addr: 用户地址
    //@return 0: [用户等级, 用户状态]
    */
    function getUserLSByAddr(address addr) public view returns (uint64[2]) {
        return getUserLS(uaddrids[addr]);
    }
    

    /*@ 设置资源
    //@param ids: [资源id, 资源父id, 资源未加密源文件id, 资源所有者id]
    //@param itype: 资源类型
    //@param ihash: 资源额外信息hash
    //@param xhash: 资源文件hash
    //@param level: 资源安全级别
    //@param status: 资源状态
    //@param timestamp: 生成时间戳
    //@return 0: 是否设置成功
    */
    function setItem(bytes32[4] ids, bytes32 itype, bytes32 ihash, bytes32 xhash, uint64 level, uint64 timestamp, uint64 status) internal returns (bool) {
        iidxids[itemnum++] = ids[0];
        items[ids[0]] = Item(ids[0], ids[1], ids[2], ids[3], itype, ihash, xhash, level, timestamp, status);
        //iiduids[ids[0]] = ids[3];
        return true;
    }

    /*@ 添加资源
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param ids: [资源id, 资源父id, 资源未加密源文件id, 资源所有者id]
    //@param itype: 资源类型
    //@param ihash: 资源额外信息hash
    //@param xhash: 资源文件hash
    //@param level: 资源安全级别
    //@param status: 资源状态
    //@return 0: 是否设置成功
    */
    function addItem(bytes32 sn, string details, bytes32[4] ids, bytes32 itype, bytes32 ihash, bytes32 xhash, uint64 level, uint64 status) public onlyAdmin returns (bool) {
        bytes32 senderid = uaddrids[msg.sender];
        if (ids.length > 3) {
            senderid = ids[3];
        }
        if (setItem(ids, itype, ihash, xhash, level, uint64(block.timestamp), status)) {
            emit TXReceipt(sn, ids[3], ids[0], 0x00, "addItem", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, senderid, ids[0], 0x00], 0x00, "addItem", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 上传资源
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param ids: [资源id, 资源父id, 资源未加密源文件id]
    //@param itype: 资源类型
    //@param ihash: 资源额外信息hash
    //@param xhash: 资源文件hash
    //@param level: 资源安全级别
    //@param status: 资源状态
    //@return 0: 是否设置成功
    */
    function uplItem(bytes32 sn, string details, bytes32[3] ids, bytes32 itype, bytes32 ihash, bytes32 xhash, uint64 level, uint64 status) public onlyValid returns (bool) {
        bytes32 senderid = uaddrids[msg.sender];
        if (setItem([ids[0], ids[1], ids[2], senderid], itype, ihash, xhash, level, uint64(block.timestamp), status)) {
            emit TXReceipt(sn, senderid, ids[0], 0x00, "uplItem", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, senderid, 0x00, 0x00], 0x00, "uplItem", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置资源状态
    //@param itemid: 资源id
    //@param newstatus: 资源新的状态
    //@return 0: 是否设置成功
    */
    function setItemStatus(bytes32 itemid, uint64 newstatus) internal returns (bool) {
        if (itemid == 0x00) {
            revert("failed");
        } else {
            bytes32 senderid = uaddrids[msg.sender];
            User memory user = users[senderid];
            Item storage item = items[itemid];
            if (user.status == 0) {
                revert("failed");
            } else {
                if (user.level == 1 || item.userid == senderid) {
                    item.status = newstatus;
                    return true;
                } else {
                    revert("failed");
                }
            }
        }
    }

    /*@ 设置资源状态By资源id
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param id: 资源id
    //@param newstatus: 资源新的状态
    //@return 0: 是否设置成功
    */
    function setItemStatusById(bytes32 sn, string details, bytes32 id, uint64 newstatus) public onlyValid returns (bool) {
        if (setItemStatus(id, newstatus)) {
            emit TXReceipt(sn, 0x00, id, 0x00, "setItemStatusById", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], id, 0x00], 0x00, "setItemStatusById", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置资源状态By资源索引
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param idx: 资源索引
    //@param newstatus: 资源新的状态
    //@return 0: 是否设置成功
    */
    function setItemStatusByIdx(bytes32 sn, string details, uint64 idx, uint64 newstatus) public onlyValid returns (bool) {
        bytes32 id = iidxids[idx];
        if (setItemStatus(id, newstatus)) {
            emit TXReceipt(sn, 0x00, id, 0x00, "setItemStatusByIdx", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], id, 0x00], 0x00, "setItemStatusByIdx", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 获取资源总数
    //@return 0: 资源总数
    */
    function getItemNum() public view returns (uint64) {
        return itemnum;
    }

    /*@ 获取资源信息By资源id
    //@param id: 资源id
    //@return 0: [资源id, 资源父id, 资源未加密源文件id, 资源所有者id]
    //@return 1: 资源类型
    //@return 2: 资源额外信息hash
    //@return 3: 资源文件hash
    //@return 4: 资源安全级别
    //@return 5: 资源生成时间戳
    //@return 6: 资源状态
    */
    function getItemById(bytes32 id) public view returns (bytes32[4], bytes32, bytes32, bytes32, uint64, uint64, uint64) {
        if (id == 0x00) {
            return ([bytes32(0x00), 0x00, 0x00, 0x00], bytes32(0x00), 0x00, "", uint64(0), 0, 0);
        } else {
            Item memory item = items[id];
            return ([item.iid, item.tid, item.sid, item.userid], item.itype, item.ihash, item.xhash, item.level, item.timestamp, item.status);
        }
    }

    /*@ 获取资源信息By资源索引
    //@param idx: 资源索引
    //@return 0: [资源id, 资源父id, 资源未加密源文件id, 资源所有者id]
    //@return 1: 资源类型
    //@return 2: 资源额外信息hash
    //@return 3: 资源文件hash
    //@return 4: 资源安全级别
    //@return 5: 资源生成时间戳
    //@return 6: 资源状态
    */
    function getItemByIdx(uint64 idx) public view returns (bytes32[4], bytes32, bytes32, bytes32, uint64, uint64, uint64) {
        return getItemById(iidxids[idx]);
    }

    /*@ 获取资源等级状态
    //@param id: 资源id
    //@return 0: [资源安全级别, 资源状态]
    */
    function getItemLS(bytes32 id) public view returns (uint64[2]) {
        if (id == 0x00) {
            return ([uint64(0), 0]);
        } else {
            Item memory item = items[id];
            return [item.level, item.status];
        }
    }
    

    /*@ 设置权限
    //@param ids: [权限id, 父权限id, 授予用户id, 资源id]
    //@param device: 设备限制
    //@param ptype: [查看权限, 下载权限, 授予权限]
    //@param ptimestamp: [权限生成时间戳, 权限过期时间戳]
    //@param ptime: [权限总时间, 权限剩余时间]
    //@param ptimes: [权限可用次数, 权限剩余可用次数]
    //@param status: 权限状态
    //@return 0: 设置是否成功
    */
    function setPerm(bytes32[4] ids, bytes32 device, uint64[3] ptype, uint64[2] ptimestamp, uint64[2] ptime, uint64[2] ptimes, uint64 status) internal returns (bool) {
        // TODO user.level >= item.level
        bytes32 senderid = uaddrids[msg.sender];
        //Perm memory perm = perms[ids[1]];
        User memory user = users[ids[2]];
        Item memory item = items[ids[3]];
        if (item.userid == ids[2] || user.level == 1) {
            revert("failed");
        }
        if (verPerm([senderid, ids[3], ids[1]], device, ptype, ptimestamp[1], ptime[0], ptimes[0])) {
            pidxids[permnum++] = ids[0];
            perms[ids[0]] = Perm(ids[0], ids[1], senderid, ids[2], ids[3], device, [ptype[0], ptype[1], ptype[2]], [ptimestamp[0], ptimestamp[1]], [ptime[0], ptime[1]], [ptimes[0], ptimes[1]], status);
            // piduiids[ids[0]] = [ids[2], ids[3]];

            user = users[senderid];
            if (item.userid != senderid && user.level != 1) {
                if (ids[1] != 0x00 && setPermTimes(ids[1], ptimes[0])) {
                    return true;
                } else {
                    revert("failed");
                }
            } else {
                return true;
            }
        } else {
            revert("failed");
        }
    }


    /*@ 添加权限
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param ids: [权限id, 父权限id, 授予用户id, 资源id]
    //@param device: 设备限制
    //@param ptype: [查看权限, 下载权限, 授予权限]
    //@param ptimestamp: [权限生成时间戳, 权限过期时间戳]
    //@param ptime: [权限总时间, 权限剩余时间]
    //@param ptimes: [权限可用次数, 权限剩余可用次数]
    //@param status: 权限状态
    //@return 0: 设置是否成功
    */
    function addPerm(bytes32 sn, string details, bytes32[4] ids, bytes32 device, uint64[3] ptype, uint64[2] ptimestamp, uint64[2] ptime, uint64[2] ptimes, uint64 status) public onlyValid returns (bool) {
        if (setPerm(ids, device, ptype, ptimestamp, ptime, ptimes, status)) {
            // emit TXReceipt(sn, msg.sender, ids[1], ids[2], ids[0], 0x00, "addPerm", details, 0, ptimestamp[0]);
            emit TXReceipt(sn, ids[1], ids[2], ids[0], "addPerm", details, msg.sender, 0, uint64(block.timestamp));
            // emit WatchDog (block.coinbase, sn, details, status);
            //setLog([sn, uaddrids[msg.sender], ids[2], ids[1]], 0x00, "addPerm", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 追加权限
    //@param id: 权限id
    //@param device: 设备限制
    //@param ptype: [查看权限, 下载权限, 授予权限]
    //@param iptimestamp: 权限过期时间戳
    //@param iptime: 权限追加时间
    //@param iptimes: 权限追加次数
    //@return 0: 设置是否成功
    */
    /*
    function apdPerm(bytes32 id, bytes32 device, uint64[3] ptype, uint64 iptimestamp, uint64 iptime, uint64 iptimes) internal returns (bool) {
        if (id == 0x00) {
            revert("failed");
        } else {
            bytes32 senderid = uaddrids[msg.sender];
            Perm storage perm = perms[id];
            if (verPerm(senderid, perm.itemid, ptype, iptimestamp, iptime, iptimes)) {
                perm.sgerid = senderid;
                perm.device = device;
                perm.ptype = [ptype[0], ptype[1], ptype[2]];
                perm.ptimestamp = [perm.ptimestamp[0], iptimestamp];
                perm.ptime = [perm.ptime[0] + iptime, perm.ptime[1] + iptime];
                perm.ptimes = [perm.ptimes[0] + iptimes, perm.ptimes[1] + iptimes];
                perm.status = 1;

                User memory user = users[senderid];
                Item memory item = items[perm.itemid];
                if (item.userid != senderid && user.level != 1) {
                    if (setPermTimes(puiidids[concat(senderid, perm.itemid)], iptimes)) {
                        return true;
                    } else {
                        revert("failed");
                    }
                } else {
                    return true;
                }
            } else {
                revert("failed");
            }
        }
    }
    */

    /*@ 追加权限By权限id
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param id: 权限id
    //@param device: 设备限制
    //@param ptype: [查看权限, 下载权限, 授予权限]
    //@param iptimestamp: 权限过期时间戳
    //@param iptime: 权限追加时间
    //@param iptimes: 权限追加次数
    //@return 0: 设置是否成功
    */
    /*
    function apdPermById(bytes32 sn, string details, bytes32 id, bytes32 device, uint64[3] ptype, uint64 iptimestamp, uint64 iptime, uint64 iptimes) public onlyValid returns (bool) {
        if (apdPerm(id, device, ptype, iptimestamp, iptime, iptimes)) {
            emit TXReceipt(sn, msg.sender, piduiids[id][0], piduiids[id][1], id, "apdPermById", details, uint64(block.timestamp));
            setLog([sn, uaddrids[msg.sender], piduiids[id][1]], "adpPermById", 0x00, 0x00, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /*@ 追加权限By权限索引
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param idx: 权限索引
    //@param device: 设备限制
    //@param ptype: [查看权限, 下载权限, 授予权限]
    //@param iptimestamp: 权限过期时间戳
    //@param iptime: 权限追加时间
    //@param iptimes: 权限追加次数
    //@return 0: 设置是否成功
    */
    /*
    function apdPermById(bytes32 sn, string details, uint64 idx, bytes32 device, uint64[3] ptype, uint64 iptimestamp, uint64 iptime, uint64 iptimes) public onlyValid returns (bool) {
        if (apdPerm(pidxids[idx], device, ptype, iptimestamp, iptime, iptimes)) {
            emit TXReceipt(sn, msg.sender, piduiids[pidxids[idx]][0], piduiids[pidxids[idx]][1], pidxids[idx], "apdPermByIdx", details, uint64(block.timestamp));
            setLog([sn, uaddrids[msg.sender], piduiids[pidxids[idx]][1]], "adpPermByIdx", 0x00, 0x00, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /*@ 追加权限By权限用户和资源
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param ids: [用户id, 资源id]
    //@param device: 设备限制
    //@param ptype: [查看权限, 下载权限, 授予权限]
    //@param iptimestamp: 权限过期时间戳
    //@param iptime: 权限追加时间
    //@param iptimes: 权限追加次数
    //@return 0: 设置是否成功
    */
    /*
    function apdPermByUI(bytes32 sn, string details, bytes32[2] ids, bytes32 device, uint64[3] ptype, uint64 iptimestamp, uint64 iptime, uint64 iptimes) public onlyValid returns (bool) {
        bytes32 id = puiidids[concat(ids[0], ids[1])];
        if (apdPerm(id, device, ptype, iptimestamp, iptime, iptimes)) {
            emit TXReceipt(sn, msg.sender, ids[0], ids[1], id, "apdPermByUI", details, uint64(block.timestamp));
            setLog([sn, uaddrids[msg.sender], ids[1]], "adpPermByUI", 0x00, 0x00, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /*@ 设置权限时间次数
    //@param id: 权限id
    //@param utime: 消耗的时间
    //@return 0: 是否设置成功
    */
    function setPermTime(bytes32 id, uint64 utime) internal returns (bool) {
        if (id == 0x00) {
            revert("failed");
        } else {
            Perm storage perm = perms[id];
            bytes32 senderid = uaddrids[msg.sender];
            if (verPerm([senderid, perm.pid, perm.itemid], perm.device, [uint64(0), 0, 0], 0, 0, 0)) {
                uint64 prtime = perm.ptime[1];
                // uint64 prtimes = perm.ptimes[1];
                if (prtime == 0) {
                    return false;
                } else {
                    if (utime >= prtime) {
                        prtime = 0;
                    } else {
                        prtime -= utime;
                    }
                    /*
                    if (utime > 0) {
                        if (prtimes <= 1) {
                            prtimes = 0;
                        } else {
                            prtimes -= 1;
                        }
                    }
                    */
                    perm.ptime = [perm.ptime[0], prtime];
                    // perm.ptimes = [perm.ptimes[0], prtimes];
                    return true;
                }
            } else {
                revert("failed");
            }
        }
    }

    /*@ 设置权限次数
    //@param id: 权限id
    //@param utimes: 消耗的次数
    //@return 0: 是否设置成功
    */
    function setPermTimes(bytes32 id, uint64 utimes) internal returns (bool) {
        if (id == 0x00) {
            revert("failed");
        } else {
            Perm storage perm = perms[id];
            bytes32 senderid = uaddrids[msg.sender];
            if (verPerm([senderid, perm.pid, perm.itemid], perm.device, [uint64(0), 0, 0], 0, 0, 0)) {
                uint64 prtimes = perm.ptimes[1];
                if (prtimes == 0) {
                    return false;
                } else {
                    if (prtimes < utimes) {
                        prtimes = 0;
                    } else {
                        prtimes -= utimes;
                    }
                    perm.ptimes = [perm.ptimes[0], prtimes];
                    return true;
                }
            } else {
                revert("failed");
            }
        }
    }

    /*@ 设置权限时间次数By权限id
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param id: 权限id
    //@param utime: 消耗的时间
    //@return 0: 是否设置成功
    */
    function setPermTimeById(bytes32 sn, string details, bytes32 id, uint64 utime) public onlyValid returns (bool) {
        if (setPermTime(id, utime)) {
            Perm memory perm = perms[id];
            emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermTimeById", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermTimeById", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置权限时间次数By权限索引
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param idx: 权限索引
    //@param utime: 消耗的时间
    //@return 0: 是否设置成功
    */
    function setPermTimeByIdx(bytes32 sn, string details, uint64 idx, uint64 utime) public onlyValid returns (bool) {
        bytes32 id = pidxids[idx];
        if (setPermTime(id, utime)) {
            Perm memory perm = perms[id];
            emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermTimeByIdx", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermTimeByIdx", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置权限时间次数By权限用户和资源
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param ids: [用户id, 资源id]
    //@param utime: 消耗的时间
    //@return 0: 是否设置成功
    */
    /*
    function setPermTimeByUI(bytes32 sn, string details, bytes32[2] ids, uint64 utime) public onlyValid returns (bool) {
        bytes32 id = puiidids[concat(ids[0], ids[1])];
        if (setPermTime(id, utime)) {
            emit TXReceipt(sn, msg.sender, ids[0], ids[1], id, "setPermTimeByUI", details, uint64(block.timestamp));
            setLog([sn, uaddrids[msg.sender], ids[1]], "setPermTimeByUI", 0x00, 0x00, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /*@ 设置权限状态
    //@param id: 权限id
    //@param newstatus: 权限新的状态
    //@return 0: 是否设置成功
    */
    function setPermStatus(bytes32 id, uint64 newstatus) internal returns (bool) {
        if (id == 0x00) {
            revert("failed");
        } else {
            Perm storage perm = perms[id];
            bytes32 senderid = uaddrids[msg.sender];
            if (verPerm([senderid, perm.pid, perm.itemid], perm.device, [uint64(0), 0, 0], 0, 0, 0)) {
                perm.status = newstatus;
                return true;
            } else {
                revert("failed");
            }
        }
    }

    /*@ 设置权限状态By权限id
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param id: 权限id
    //@param newstatus: 权限新的状态
    //@return 0: 是否设置成功
    */
    function setPermStatusById(bytes32 sn, string details, bytes32 id, uint64 newstatus) public onlyValid returns (bool) {
        if (setPermStatus(id, newstatus)) {
            Perm memory perm = perms[id];
            emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermStatusById", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermStatusById", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置权限状态By权限索引
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param idx: 权限索引
    //@param newstatus: 权限新的状态
    //@return 0: 是否设置成功
    */
    function setPermStatusByIdx(bytes32 sn, string details, uint64 idx, uint64 newstatus) public onlyValid returns (bool) {
        bytes32 id = pidxids[idx];
        if (setPermStatus(id, newstatus)) {
            Perm memory perm = perms[id];
            emit TXReceipt(sn, perm.userid, perm.itemid, id, "setPermStatusByIdx", details, msg.sender, 0, uint64(block.timestamp));
            //setLog([sn, uaddrids[msg.sender], perm.itemid, id], 0x00, "setPermStatusByIdx", details, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 设置权限状态By权限用户和资源
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param ids: [用户id, 资源id]
    //@param newstatus: 权限新的状态
    //@return 0: 是否设置成功
    */
    /*
    function setPermStatusByUI(bytes32 sn, string details, bytes32[2] ids, uint64 newstatus) public onlyValid returns (bool) {
        bytes32 id = puiidids[concat(ids[0], ids[1])];
        if (setPermStatus(id, newstatus)) {
            emit TXReceipt(sn, msg.sender, piduiids[id][0], piduiids[id][1], id, "setPermStatusByUI", details, uint64(block.timestamp));
            setLog([sn, uaddrids[msg.sender], piduiids[id][1]], "setPermStatusByUI", 0x00, 0x00, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }
    */

    /*@ 验证用户对资源的权限
    //@param ids: [用户id, 资源id, 权限id]
    //@param ptype: [查看权限, 下载权限, 授权权限]
    //@param device: 授权设备
    //@param ptimestamp: 过期时间戳限制
    //@param ptime: 剩余时间限制
    //@param ptimes: 剩余次数限制
    //@return 0: 用户是否满足对资源的所有权限限制
    */
    function verPerm(bytes32[3] ids, bytes32 device, uint64[3] ptype, uint64 ptimestamp, uint64 ptime, uint64 ptimes) internal view returns (bool) {
        // TODO
        if (ids[0] == 0x00 || ids[1] == 0x00) {
            return false;
        } else {
            User memory user = users[ids[0]];
            Item memory item = items[ids[1]];
            Perm memory perm = perms[ids[2]];
            if (user.status != 1 || item.status != 1) {
                return false;
            } else {
                if (user.level == 1 || item.userid == user.uid) {
                    return true;
                } else {
                    if ( perm.pid == 0x00) {
                        return false;
                    } else {
                        if (perm.status != 1 || perm.userid != user.uid || perm.itemid != item.iid || perm.ptype[2] != 1) {
                            return false;
                        } else {
                            if (perm.device == device && perm.ptype[0] >= ptype[0] && perm.ptype[1] >= ptype[1] && perm.ptype[2] >= ptype[2] && perm.ptimestamp[1] >= ptimestamp && perm.ptimestamp[1] > 0 && perm.ptime[1] >= ptime && perm.ptime[1] > 0 && perm.ptimes[1] >= ptimes && perm.ptimes[1] > 0) {
                                return true;
                            } else {
                                return false;
                            }
                        }
                    }
                }
            }
        }
    }

    
    /*@ 获取权限总数
    //@return 0: 权限总数
    */
    function getPermNum() public view returns (uint64) {
        return permnum;
    }

    /*@ 获取权限信息By权限id
    //@param id: 权限id
    //@return 0: [权限id, 父权限id, 授予者id, 授予用户id, 资源id]
    //@return 1: 权限播放设备限制
    //@return 2: [查看权限, 下载权限, 授予权限]
    //@return 3: [权限生成时间戳, 权限过期时间戳]
    //@return 4: [权限总时间, 权限剩余时间]
    //@return 5: [权限可用次数, 权限剩余可用次数]
    //@return 6: 权限状态
    */
    function getPermById(bytes32 id) public view returns (bytes32[5], bytes32, uint64[3], uint64[2], uint64[2], uint64[2], uint64) {
        if (id == 0x00) {
            return ([bytes32(0x00), 0x00, 0x00, 0x00, 0x00], bytes32(0x00), [uint64(0), 0, 0], [uint64(0), 0], [uint64(0), 0], [uint64(0), 0], uint64(0));
        } else {
            Perm memory perm = perms[id];
            return ([perm.pid, perm.tid, perm.sgerid, perm.userid, perm.itemid], perm.device, [perm.ptype[0], perm.ptype[1], perm.ptype[2]], [perm.ptimestamp[0], perm.ptimestamp[1]], [perm.ptime[0], perm.ptime[1]], [perm.ptimes[0], perm.ptimes[1]], perm.status);
        }
    }

    /*@ 获取权限信息By权限索引
    //@param idx: 权限索引
    //@return 0: [权限id, 父权限id, 授予者id, 授予用户id, 资源id]
    //@return 1: 权限播放设备限制
    //@return 2: [查看权限, 下载权限, 授予权限]
    //@return 3: [权限生成时间戳, 权限过期时间戳]
    //@return 4: [权限总时间, 权限剩余时间]
    //@return 5: [权限可用次数, 权限剩余可用次数]
    //@return 6: 权限状态
    */
    function getPermByIdx(uint64 idx) public view returns (bytes32[5], bytes32, uint64[3], uint64[2], uint64[2], uint64[2], uint64) {
        return getPermById(pidxids[idx]);
    }

    /*@ 获取权限信息By权限用户和资源
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
    function getPermByUI(bytes32[2] ids) public view returns (bytes32[4], bytes32, uint64[3], uint64[2], uint64[2], uint64[2], uint64) {
        return getPermById(puiidids[concat(ids[0], ids[1])]);
    }
    */


    /*@ 获取用户对资源的权限(管理员用户, 资源所有者, 权限拥有者)
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
    function fetchPerm(bytes32 userid, bytes32 itemid) public view returns (uint64, bytes32[4], uint64[3], uint64[2], uint64[2], uint64[2], uint64) {
        if (userid == 0x00 || itemid == 0x00) {
            return (0, [bytes32(0x00), 0x00, 0x00, 0x00], [uint64(0), 0, 0], [uint64(0), 0], [uint64(0), 0], [uint64(0), 0], 0);
        } else {
            User memory user = users[userid];
            if (user.status == 0) {
                return (1, [bytes32(0x00), 0x00, 0x00, 0x00], [uint64(0), 0, 0], [uint64(0), 0], [uint64(0), 0], [uint64(0), 0], 0);
            } else {
                if (user.level == 1) {
                    return (2, [bytes32(0x00), 0x00, 0x00, 0x00], [uint64(0), 0, 0], [uint64(0), 0], [uint64(0), 0], [uint64(0), 0], 0);
                }
                Item memory item = items[itemid];
                if (item.userid == userid) {
                    return (3, [bytes32(0x00), 0x00, 0x00, 0x00], [uint64(0), 0, 0], [uint64(0), 0], [uint64(0), 0], [uint64(0), 0], 0);
                }
                bytes32 pid = puiidids[concat(userid, itemid)];
                if (pid == 0x00) {
                    return (4, [bytes32(0x00), 0x00, 0x00, 0x00], [uint64(0), 0, 0], [uint64(0), 0], [uint64(0), 0], [uint64(0), 0], 0);
                } else {
                    Perm memory perm = perms[pid];
                    return (5, [perm.id, perm.sgerid, perm.userid, perm.itemid], [perm.ptype[0], perm.ptype[1], perm.ptype[2]], [perm.ptimestamp[0], perm.ptimestamp[1]], [perm.ptime[0], perm.ptime[1]], [perm.ptimes[0], perm.ptimes[1]], perm.status);
                }
            }
        }
    }
    */
    

    /*@ 设置日志
    //@param ids: [日志id, 用户id, 资源id, 权限id]
    //@param action: 日志操作类型
    //@param desc: 日志描述
    //@param duration: 日志操作时长
    //@param timestamp: 日志生成时间戳
    //@return 0: 是否设置成功
    */
    function setLog(bytes32[4] ids, bytes32 action, string desc, uint64 duration, uint64 timestamp) internal returns (bool) {
        lidxids[lognum++] = ids[0];
        logs[ids[0]] = Log(ids[0], ids[1], ids[2], ids[3], action, desc, duration, timestamp);
        liduiids[ids[0]] = [ids[1], ids[2]];
        return true;
    }

    /*@ 添加日志
    //@param sn: 交易流水号
    //@param details: 交易详细信息
    //@param ids: [日志id, 用户id, 资源id, 权限id]
    //@param action: 日志操作类型
    //@param desc: 日志描述
    //@param duration: 日志操作时长
    //@param mode: 日志操作类型(0=只记日志不修改权限次数和时间, 1=记日志的同时修改权限次数和时间)
    //@return 0: 是否设置成功
    */
    function addLog(bytes32 sn, string details, bytes32[4] ids, bytes32 action, string desc, uint64 duration, uint64 mode) public onlyAdmin returns (bool) {
        if (setLog(ids, action, desc, duration, uint64(block.timestamp))) {
            if (mode != 0) {
                //bytes32 pid = puiidids[concat(ids[1], ids[2])];
                if (duration == 0) {
                    setPermTimes(ids[3], 1);
                } else {
                    setPermTime(ids[3], duration);
                }
            }
            emit TXReceipt(sn, ids[1], ids[2], ids[0], "addLog", details, msg.sender, 0, uint64(block.timestamp));
            return true;
        } else {
            revert("failed");
        }
    }

    /*@ 获取日志总数
    //@return 0: 日志总数
    */
    function getLogNum() public view returns (uint64) {
        return lognum;
    }

    /*@ 获取日志信息By日志id
    //@param id: 日志id
    //@return 0: [日志id, 用户id, 资源id, 权限id]
    //@return 1: 日志操作类型
    //@return 2: 日志描述
    //@return 3: 日志操作时长
    //@return 4: 日志生成时间戳
    */
    function getLogById(bytes32 id) public view returns (bytes32[4], bytes32, string, uint64, uint64) {
        if (id == 0x00) {
            return ([bytes32(0x00), 0x00, 0x00, 0x00], bytes32(0x00), "", uint64(0), 0);
        } else {
            Log memory log = logs[id];
            return ([log.lid, log.userid, log.itemid, log.permid], log.action, log.desc, log.duration, log.timestamp);
        }
    }

    /*@ 获取日志信息By日志索引
    //@param idx: 日志索引
    //@return 0: [日志id, 用户id, 资源id,权限id]
    //@return 1: 日志操作类型
    //@return 2: 日志描述
    //@return 3: 日志操作时长
    //@return 4: 日志生成时间戳
    */
    function getLogByIdx(uint64 idx) public view returns (bytes32[4], bytes32, string, uint64, uint64) {
        return getLogById(lidxids[idx]);
    }

    /*@ 合约自毁
    */
    function kill() public onlyOwner {
        selfdestruct(owner);
    }


}