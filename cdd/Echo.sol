pragma solidity ^0.4.22;


contract Echo {
    mapping(address => uint)public map;
    bytes32 public message;

    event WatchDog(bytes32 themsg, uint number);

    function Echo(uint _balance) public {
        map[msg.sender] = _balance;
    }

    function getBalance() public returns (uint) {
        return map[msg.sender];
    }

    function sendMessage(bytes32 _message) public {
        message = _message;
        emit WatchDog(_message, 1);
    }

    function getMessage() public returns (bytes32) {
        return message;
    }
}