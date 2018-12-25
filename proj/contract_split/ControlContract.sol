pragma solidity ^0.4.18;


contract DataContract {
    
    struct User {
        address addr;
        uint256 balance;
    }

    mapping (address => uint256) public balanceOf;
    mapping (address => User) public users;

    function setBalance(address addr,uint256 v) public {
        balanceOf[addr] = v;
    }
    
    function addBalance(address addr, uint256 v) public {
        balanceOf[addr] += v;
    }
    
    function subBalance(address addr, uint256 v) public {
        balanceOf[addr] -= v;
    }
    
    function getBalance(address addr) public view returns (uint256){
        return balanceOf[addr];
    }
    
    function setUser(address addr, uint256 v) public {
        users[addr] = User(addr, v);
    }
    
    function setUserBalance(address addr, uint256 v) public {
        User storage user = users[addr];
        user.balance = v;
    }
    
    function getUser(address addr) public view returns (address, uint256) {
        User memory user = users[addr];
        return (user.addr, user.balance);
    }
}

contract ControlContract {
    /*
    struct User {
        address addr;
        uint256 balance;
    }
    */

    DataContract dataContract;

    constructor(address dataContractAddr) public {
        dataContract = DataContract(dataContractAddr);
    }

    function getBalance(address addr) public view returns (uint256){
        return dataContract.balanceOf(addr);
    }
    
    function addBalance(address addr, uint256 v) public {
        dataContract.addBalance(addr, v);
    }
    
    function subBalance(address addr, uint256 v) public {
        dataContract.subBalance(addr, v);
    }
    
    function setUser(address addr, uint256 v) public {
        dataContract.setUser(addr, v);
    }
    
    function setUserBalance(address addr, uint256 v) public {
        dataContract.setUserBalance(addr, v);
    }
    
    function getUser(address addr) public view returns (address, uint256) {
        return dataContract.getUser(addr);
    }
    
    function fetchUser(address addr) public view returns (address, uint256) {
        address taddr;
        uint256 tbalance;
        
        (taddr, tbalance) = dataContract.users(addr);
        return (taddr, tbalance);
        
        return dataContract.users(addr);
        
    }
}
