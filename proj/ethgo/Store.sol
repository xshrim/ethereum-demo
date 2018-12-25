pragma solidity >0.4.25 <0.6.0;

contract Store {
    event Log(string, uint);
    event ItemSet(bytes32 key, bytes32 value);

    string public version;
    mapping (bytes32 => bytes32) public items;

    constructor(string memory ver) public {
        version = ver;
    }

    function getVersion() public view returns (string memory) {
        return version;
    }

    function setItem(bytes32 key, bytes32 value) external {
        items[key] = value;
        emit ItemSet(key, value);
    }

    function getItem(bytes32 key) public view returns (bytes32) {
        return items[key];
    }

    function invoke(string memory method, uint arg) public returns (string memory) {
        if (keccak256(abi.encodePacked(method)) == keccak256("multiply")) {
            bytes32 res = bytes32(multiply(arg));
            bytes memory bres = new bytes(res.length);
            for (uint i = 0; i < res.length; i++) {
                bres[i] = res[i];
            }
            emit Log("OK", 1);
            return string(bres);
        }
    }

    function multiply(uint a) internal pure returns (uint d) {
        return a * 7;
    }

}