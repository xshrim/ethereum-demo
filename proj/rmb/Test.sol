pragma solidity ^0.4.23;
// pragma experimental ABIEncoderV2;

/*
library C {
    function a() public view returns (address) {
        return address(this);
    }
}
*/

contract Test {
    uint64 va;

    event WatchDog (address indexed addr, bytes32 indexed str, uint64 indexed res);

    function getva() public view returns (uint64) {
        return va;
    }

    function setva(uint64 vb, bytes32 str) public returns (bool) {
        va = vb;
        emit WatchDog(msg.sender, str, va);
        return true;
    }
    
    function nsetva(uint64 vb, bytes32 str) public returns (bool) {
        emit WatchDog(msg.sender, str, vb);
        return true;
    }

    function setit() public returns (bool) {
        revert("hh");
    }

    function a() public view returns (address) {
        return address(this);
    }

    function b(bytes16 str) public pure returns (bytes16) {
        return str;
    }
}