pragma solidity ^0.4.23;

/*@ 测试合约
*/
contract Test {
    bytes32 testid;

    function setid(bytes32 id) public returns (bool) {
        testid = id;
    }

    function checkid() public view returns (bool) {
        if (testid ==  0x00) {
            return true;
        } else {
            return false;
        }
    }

    function getid() public view returns (bytes32) {
        return testid;
    }
}