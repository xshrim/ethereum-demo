const fs = require('fs');
const Web3 = require('web3');

//var web3 = new Web3(Web3.givenProvider || "ws://localhost:7545");
var web3 = new Web3(Web3.givenProvider || "ws://localhost:8546");

var ownerAddress, contractName, contractAbi, contractAddress;

/*
ownerAddress = "0x909Ecfd1b6688eD6aa087cF89811C7ee7D4C1125";
contractAbi = [{
    "constant": true,
    "inputs": [],
    "name": "getBalance",
    "outputs": [{
        "name": "",
        "type": "uint256"
    }],
    "payable": false,
    "stateMutability": "view",
    "type": "function",
    "signature": "0x12065fe0"
}, {
    "constant": true,
    "inputs": [{
        "name": "",
        "type": "address"
    }],
    "name": "map",
    "outputs": [{
        "name": "",
        "type": "uint256"
    }],
    "payable": false,
    "stateMutability": "view",
    "type": "function",
    "signature": "0xb721ef6e"
}, {
    "constant": true,
    "inputs": [],
    "name": "getMessage",
    "outputs": [{
        "name": "",
        "type": "bytes32"
    }],
    "payable": false,
    "stateMutability": "view",
    "type": "function",
    "signature": "0xce6d41de"
}, {
    "constant": false,
    "inputs": [{
        "name": "_message",
        "type": "bytes32"
    }],
    "name": "sendMessage",
    "outputs": [],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function",
    "signature": "0xe12c9ca8"
}, {
    "constant": true,
    "inputs": [],
    "name": "message",
    "outputs": [{
        "name": "",
        "type": "bytes32"
    }],
    "payable": false,
    "stateMutability": "view",
    "type": "function",
    "signature": "0xe21f37ce"
}, {
    "inputs": [{
        "name": "_balance",
        "type": "uint256"
    }],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "constructor",
    "signature": "constructor"
}, {
    "anonymous": false,
    "inputs": [{
        "indexed": false,
        "name": "themsg",
        "type": "bytes32"
    }, {
        "indexed": false,
        "name": "number",
        "type": "uint256"
    }],
    "name": "WatchDog",
    "type": "event",
    "signature": "0x95743b47c851e0b3f1b63bb7dd8634b81106fd3b3695e546ff281a0635dbff75"
}];

contractAddress = "0x7C52e944BEE27953Aae1bFA766B99b27155E265E"; // <----- previous script output
*/

var result = JSON.parse(fs.readFileSync('./contractInfo.json'));
ownerAddress = result['ownerAddress'];
contractName = result['contractName'];
contractAbi = JSON.parse(result['contractAbi']);
contractAddress = result['contractAddress'];

console.log('Invoking ' + contractName + ' ...');

/*
var subscription = web3.eth.subscribe('logs', {
    address: '0x593B88d5926943E53938BEe81988E557fb7d576E',
}, function (error, result) {
    if (!error)
        console.log(result);
    else
        console.log(error);
})
.on("data", function (log) {
    console.log(log);
})
.on("changed", function (log) {});
*/

const myContract = new web3.eth.Contract(contractAbi, contractAddress);

myContract.events.WatchDog({
    fromBlock: 'latest',
    toBlock: 'latest'
}, (error, data) => {
    if (error)
        console.log("Error: " + error);
    else
        console.log("Log data: " + web3.utils.hexToAscii(data["returnValues"]["themsg"]));
});

const options = {
    from: ownerAddress,
    gas: 2000000,
    gasPrice: '22000000000',
};
/*
var get3rdAccount = async () => {
    const accounts = await web3.eth.getAccounts()
    return accounts[3]
}
console.log(get3rdAccount());
*/

//web3.eth.accounts.create(web3.utils.randomHex(32));
/*
account = web3.eth.accounts.create();
console.log(account);
web3.eth.getAccounts().then((accounts) => {
    console.log(accounts[3]);
    process.exit();
})
*/

if (true) {
    const message = web3.utils.asciiToHex('OK');

    myContract.methods.sendMessage(message)
        .send(options, (err, hash) => {
            if (err) {
                console.log(err);
            }
            console.log(`TxHash: ${hash}`);
        })
        .on('receipt', function (receipt) {
            // receipt example
            console.log('Receipt: ' + JSON.stringify(receipt));
        })
        .then((result) => {
            return myContract.methods.getMessage().call()
                .then((result) => {
                    console.log(web3.utils.hexToAscii(result));
                });
        }).then((res) => {
            // unsubscribes the subscription
            /*
            subscription.unsubscribe(function (error, success) {
                if (success)
                    console.log('Successfully unsubscribed!');
            });
            */
            process.exit();
        });
}