const Web3 = require('web3');

//var web3 = new Web3(Web3.givenProvider || "ws://localhost:7545");
var web3 = new Web3(Web3.givenProvider || "ws://localhost:8546");

const ownerAddress = "0x569529EF48fd6380065389cfa4D7B20B3D42f165";
const contractAbi = [{
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
    "name": "balances",
    "outputs": [{
        "name": "",
        "type": "uint256"
    }],
    "payable": false,
    "stateMutability": "view",
    "type": "function",
    "signature": "0x27e235e3"
}, {
    "constant": false,
    "inputs": [{
        "name": "musicId",
        "type": "string"
    }, {
        "name": "musicPrice",
        "type": "uint256"
    }, {
        "name": "expireTime",
        "type": "string"
    }],
    "name": "buy",
    "outputs": [{
        "name": "",
        "type": "string"
    }],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function",
    "signature": "0x3ece29ba"
}, {
    "constant": true,
    "inputs": [{
        "name": "index",
        "type": "uint256"
    }],
    "name": "getMusic",
    "outputs": [{
        "name": "",
        "type": "string"
    }, {
        "name": "",
        "type": "string"
    }],
    "payable": false,
    "stateMutability": "view",
    "type": "function",
    "signature": "0x4770ff8f"
}, {
    "constant": true,
    "inputs": [{
        "name": "",
        "type": "address"
    }, {
        "name": "",
        "type": "uint256"
    }, {
        "name": "",
        "type": "uint256"
    }],
    "name": "map",
    "outputs": [{
        "name": "",
        "type": "string"
    }],
    "payable": false,
    "stateMutability": "view",
    "type": "function",
    "signature": "0x530efeac"
}, {
    "constant": true,
    "inputs": [],
    "name": "owner",
    "outputs": [{
        "name": "",
        "type": "address"
    }],
    "payable": false,
    "stateMutability": "view",
    "type": "function",
    "signature": "0x8da5cb5b"
}, {
    "constant": true,
    "inputs": [],
    "name": "getMusicCount",
    "outputs": [{
        "name": "",
        "type": "uint256"
    }],
    "payable": false,
    "stateMutability": "view",
    "type": "function",
    "signature": "0xd888f3f4"
}, {
    "inputs": [{
        "name": "balance",
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
        "type": "string"
    }, {
        "indexed": false,
        "name": "number",
        "type": "uint256"
    }],
    "name": "WatchDog",
    "type": "event",
    "signature": "0x04a5afd7d4dbdb8be770ac0aa93c06221b09ade4b0ed79956523e37c5591b6b6"
}];

const contractAddress = "0x57056fC5D33088ca6813296Cb931821767e03004"; // <----- previous script output


var subscription = web3.eth.subscribe('logs', {
        address: '0x57056fC5D33088ca6813296Cb931821767e03004',
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


const myContract = new web3.eth.Contract(contractAbi, contractAddress);

myContract.events.WatchDog({
    fromBlock: 0,
    toBlock: 'latest'
}, (error, data) => {
    if (error)
        console.log("Error: " + error);
    else
        console.log("Log data: " + data["returnValues"]["themsg"]);
});

const options = {
    from: ownerAddress,
    gas: 4000000,
    gasPrice: '20000000000000',
};

// const message = web3.utils.asciiToHex('hola');

myContract.methods.buy("88", 1000, "2100-01-01")
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
        return myContract.methods.getBalance().call()
            .then((result) => {
                console.log(result);
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