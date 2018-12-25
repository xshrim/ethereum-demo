pragma solidity ^0.4.23;
contract TestEvent {

    uint64 test;
    
    function setHi(uint64 sn) public returns(bool){
        test = sn;
        return true;
    }
    
    function getHi() public view returns (uint64) {
        if (test == 1) {
            return test;
        } else {
            revert("Fuck");
        }
    }
}