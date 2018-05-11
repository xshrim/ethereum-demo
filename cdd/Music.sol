pragma solidity ^0.4.22;


contract Music {

    address public owner;
    mapping (address => string[2][]) public map;
    mapping (address => uint) public balances;

    event WatchDog(string themsg, uint number);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(uint balance) public {
        owner = msg.sender;
        balances[owner] = balance;
    }
    
    function getBalance() public view returns (uint) {
        //return msg.sender.balance;
        return balances[msg.sender];
    }

    function buy(string memory musicId, uint musicPrice, string memory expireTime) public returns (string) {
        if (balances[msg.sender] < musicPrice) {
            emit WatchDog("-1", musicPrice);
            return "-1";
        } else {
            map[msg.sender].push([musicId, expireTime]);
            balances[msg.sender] -= musicPrice;

            emit WatchDog(musicId, musicPrice);
            return musicId;
        }
        /*
        if (balances[msg.sender] < musicPrice) {
            return "-1";
        } else {
            //msg.sender.balance -= msg.value;
            balances[msg.sender] -= musicPrice;
            //balances[owner] += musicPrice;
            map[msg.sender].push([musicId, expireTime]);
            return musicId;
        }
        */
    }

    function getMusicCount() public view returns (uint) {
        return map[msg.sender].length;
    }

    function getMusic(uint index) public view returns (string, string) {
        /*
        bytes[10] memory resid;
        bytes[10] memory resrt;
        */
        string[2][] storage data = map[msg.sender];
        /*
        for (uint i = 0; i < 10 && i < data.length; i++) {
            resid[i] = data[i][0];
            resrt[i] = data[i][1];
        }
        */
        //return data[0];
        return (data[index][0], data[index][1]);
    }

    function close() public onlyOwner {
        selfdestruct(owner);
    }

}
