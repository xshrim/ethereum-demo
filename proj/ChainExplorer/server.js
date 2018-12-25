//var app = require('http').createServer(handler);
var path = require('path')
var async = require('async');
var Web3 = require('web3');
var express = require("express");
var app = express();
var http = require('http').Server(app);
var io = require('socket.io').listen(http);
//var fs = require('fs');

var mio = null;
var peers = {};
var accounts = {};
var transactions = []
var web3 = null;
global.subTx = null;
global.subBlk = null;
//var provider = "ws://127.0.0.1:8546";

var chain = {
    'peerCount': 0,
    'addressCount': 0,
    'blockNumber': 0,
    'transactionCount': 0,
    'uncleCount': 0
}

var options = {
    dotfiles: 'ignore',
    etag: false,
    extensions: ['htm', 'html'],
    index: false,
    maxAge: '1d',
    redirect: false,
    setHeaders: function (res, path, stat) {
        res.set('x-timestamp', Date.now())
    }
}

function extend() {
    web3.eth.extend({
        property: 'txpool',
        methods: [{
            name: 'content',
            call: 'txpool_content'
        }, {
            name: 'inspect',
            call: 'txpool_inspect'
        }, {
            name: 'status',
            call: 'txpool_status'
        }]
    });
    //web3.eth.txpool.status().then(console.log).catch(console.error)
}

var initEnv = function () {
    //initPeer('127.0.0.1:8546');
    initPeer('172.16.201.191:8546');
    //links['127.0.0.1'] = createLink(provider);

    pickLink().then(res => {
        if (res != null) {
            calcBlock();
            calcAccount();
        }
    })

    // extend();
    //subcribeEvent();
    /*
    console.log(accounts.hasOwnProperty('asfjoods'));
    if (!accounts['0xiisdf']) {
        console.log('true');
    }
    */
}


var initPeer = async function (url) {
    if (url in peers && peers[url].ippt != null) {
        console.log(url + ' is exist!');
        return null;
    } else {
        peers[url] = {};
        var w3 = createLink("ws://" + url);
        var flag = await isConnected(w3);
        if (flag) {
            peers[url].ippt = url;
            peers[url].link = w3;
            async.series({
                one: done => {
                    w3.eth.getNodeInfo().then(res => {
                        peers[url].id = res.split('/')[1];
                        peers[url].cli = res;
                        done(null, res);
                    }).catch(err => {
                        console.log(err);
                        done(err, null);
                    });
                },
                two: done => {
                    w3.eth.getCoinbase().then(res => {
                        peers[url].coinbase = res;
                        done(null, res);
                    }).catch(err => {
                        console.log(err);
                        done(err, null);
                    });
                },
                three: done => {
                    w3.eth.net.getPeerCount().then(res => {
                        chain.peerCount = res + 1;
                        done(null, res);
                    }).catch(err => {
                        console.log(err);
                        done(err, null);
                    });
                },
                four: done => {
                    w3.eth.getAccounts().then(res => {
                        if (peers[url].accounts == null) {
                            peers[url].accounts = 0;
                        }
                        res.forEach(account => {
                            if (!accounts[account]) {
                                accounts[account] = url;
                                peers[url].accounts += 1;
                                console.log(account + ': ' + url);
                            }
                            //console.log(accounts.hasOwnProperty(account));
                        });
                        chain.addressCount += peers[url].accounts;
                        done(null, res);
                    }).catch(err => {
                        console.log(err);
                        done(err, null);
                    });
                }
            }, function (error, result) {
                if (error == null) {
                    chainInfo(mio, 'view_chainInfo');
                    return result;
                }
            });
        } else {
            peers[url].ippt = url;
            peers[url].id = null;
            peers[url].cli = null;
            peers[url].link = null;
            peers[url].coinbase = null;
            peers[url].accounts = 0;
            chainInfo(mio, 'view_chainInfo');
            return null;
        }
    }
}

var initServer = function () {
    //app.use(express.static('/static', options))
    app.use(express.static(path.join(__dirname, 'static'), options));
    //app.use("/", express.static(__dirname + "/static"));

    app.get('/', function (req, res) {
        res.sendFile(__dirname + '/index.html');
    });

    mio = io.of('/mio').on('connection', function (socket) { // 为特定的io接口指定命名空间和变量名
        //setTimeout(() => socket.disconnect(true), 500);
        console.log('a user connected');
        pickLink().then(res => {
            if (res != null) {
                peerStatus();
                chainInfo(socket, 'view_chainInfo');
                txpoolStatus();
                //recentBlocks(5);
                recentBTs(5);
            }
        });
        //console.log(peers);
        socket.emit('sample', {
            msg: 'Connected'
        });
        socket.on('msg', function (data) {
            console.log(data);
            socket.emit('msg', {
                msg: data.msg
            });
        });
        socket.on('broadcastmsg', function (data) {
            console.log(data);
            mio.emit('broadcastmsg', {
                msg: data.msg
            });
            socket.broadcast.emit('broadcastmsg', {
                msg: data.msg
            });
        });
        socket.on('getBlocks', function (data) {
            console.log(data);
            try {
                getBlocks(socket, 'get_blocks', data.start, data.end);
            } catch (err) {
                console.log(err);
            }

        });
        socket.on('getTransactions', function (data) {
            console.log(data);
            try {
                getTransactions(socket, 'get_transactions', data.txhashs);
            } catch (err) {
                console.log(err);
            }

        });
        socket.on('getBlock', function (data) {
            console.log(data);
            try {
                getBlock(socket, 'get_block', data.blkhash);
            } catch (err) {
                console.log(err);
            }
        });
        socket.on('getChainInfo', function (data) {
            // console.log(data);
            try {
                chainInfo(socket, 'get_chainInfo');
            } catch (err) {
                console.log(err);
            }
        });
        socket.on('createTransaction', function (data) {
            console.log(data);
            try {
                createTransaction(socket, 'create_transaction');
            } catch (err) {
                console.log(err);
            }
        });
        socket.on('addPeer', function (data) {
            console.log(data);
            try {
                initPeer(data.link);
            } catch (err) {
                console.log(err);
            }
        });
        socket.on('disconnect', function () {
            console.log('a user disconnected');
            mio.emit('a user disconnected');
        });
    });
}

/*
function isConnected(w3) {
    try {
        //console.log(w3.currentProvider.connection._readyState);
        //if (w3 && w3.currentProvider && w3.currentProvider.connected) {
        //if (w3 && w3.currentProvider && w3.currentProvider.connection._readyState == 0) {
        if (w3 && w3.currentProvider && w3.currentProvider.connection) {
            return true;
        } else {
            return false;
        }
    } catch (err) {
        console.log(err);
        return false;
    }
}
*/
var isConnected = function (w3) {
    return new Promise(function (resolve, reject) {
        if (w3 != null) {
            w3.eth.net.isListening().then((s) => {
                resolve(s);
            }).catch((e) => {
                resolve(false);
            });
        } else {
            resolve(false);
        }
    });
}

/*
function keepAlive() {
    try {
        web3.eth.net.isListening().then((s) => {
            console.log('We\'re still connected to the node');
        }).catch((e) => {
            var urls = [];
            for (var url in peers) {
                urls.push(url);
            }
            var idx = Math.random() * (peers.length - 1);
            web3 = createLink('ws://' + urls[idx]);
            peers[urls[idx]].link = web3;

            //console.log('Lost connection to the node, reconnecting');
            //web3.setProvider(your_provider_here);
        });
    } catch (err) {
        var urls = [];
        for (var url in peers) {
            urls.push(url);
        }
        var idx = Math.random() * (peers.length - 1);
        web3 = createLink('ws://' + urls[idx]);
        peers[urls[idx]].link = web3;
    }
}
*/

function sendMessage(chan, name, message) {
    chan.emit(name, {
        msg: message
    });
}

function createLink(provider) {
    return new Web3(provider || Web3.givenProvider);
}

var pickLink = async function () {
    var flag = await isConnected(web3);
    if (flag) {
        return web3;
    } else {
        for (var url in peers) {
            web3 = peers[url].link;
            flag = await isConnected(web3);
            if (flag) {
                break;
            } else {
                web3 = null;
            }
        }
        flag = await isConnected(web3);
        if (!flag) {
            for (var url in peers) {
                peers[url].link = createLink('ws://' + url)
                web3 = peers[url].link;
                flag = await isConnected(web3);
                if (flag) {
                    break;
                } else {
                    web3 = null;
                }
            }
        }
        //if (web3 != null && web3.currentProvider.connection._readyState == 0) {
        flag = await isConnected(web3);
        if (flag) {
            //web3.eth.clearSubscriptions();
            extend();
            subcribeEvent();
            return web3;
        } else {
            return null;
        }
    }

}
/*
web3.eth.net.isListening().then((s) => {
    console.log('We\'re still connected to the node');
}).catch((e) => {
    console.log('Lost connection to the node, reconnecting');
    web3.setProvider(your_provider_here);
})
*/
//return web3;

var getBlocks = async function (chan, name, start, end) {
    pickLink().then(res => {
        if (res != null) {
            web3.eth.getBlockNumber().then(number => {
                var arr = []
                chain.blockNumber = number;
                if (end == 'latest' || end > number) {
                    end = number;
                }
                if (start < 0) {
                    start = number + start;
                }
                if (start > end || start < 0) {
                    start == 0;
                }
                for (var i = end; i >= start; i--) {
                    arr.push(i);
                }
                async.map(arr, function (idx, callback) {
                    web3.eth.getBlock(idx).then(blk => {
                        blk.count = number;
                        // console.log(blk);
                        callback(null, blk)
                        //sendMessage(chan, name, blk);
                    }).catch(err => {
                        console.log(err);
                        callback(err, null);
                    });
                }, function (err, blks) {
                    if (err == null) {
                        // console.log(blks);
                        sendMessage(chan, name, blks);
                    } else {
                        console.log(err);
                    }
                });
                /*
                while (end >= start) {
                    web3.eth.getBlock(end--).then(blk => {
                        blk.count = number;
                        console.log(blk);
                        sendMessage(chan, name, blk);
                    }).catch(err => {
                        console.log(err);
                        pickLink();
                    });
                }
                */
            }).catch(err => {
                console.log(err);
            });
        }
    });

}

var getTransactions = async function (chan, name, arg) {
    pickLink().then(res => {
        if (res != null) {
            var txhashs = [];
            if (typeof (arg) == 'string') {
                var rg = arg.split('-');
                var start = parseInt(rg[0]);
                var end = parseInt(rg[1]);
                if (start >= end) {
                    [start, end] = [end, start];
                }
                if (start < 0) {
                    start = 0;
                }
                if (end >= transactions.length) {
                    end = transactions.length - 1;
                }
                txhashs = transactions.slice(start, end + 1);
            } else {
                txhashs = arg;
            }
            async.map(txhashs, function (txhash, callback) {
                web3.eth.getTransaction(txhash).then(tx => {
                    var transaction = tx;
                    transaction.peer = accounts[transaction.from];
                    web3.eth.getTransactionReceipt(tx.hash).then(receipt => {
                        transaction.status = receipt.status;
                        transaction.contractAddress = receipt.contractAddress;
                        // console.log(transaction);
                        callback(null, transaction);
                        //sendMessage(chan, name, transaction);
                    }).catch(err => {
                        console.log(err);
                        callback(err, null);
                    });
                }).catch(err => {
                    console.log(err);
                    callback(err, null);
                });
            }, function (err, txs) {
                if (err == null) {
                    // console.log(txs);
                    sendMessage(chan, name, txs);
                } else {
                    console.log(err);
                }
            });
        }
    });
}

var getPendingTransaction = async function (chan, name, txhash) {
    pickLink().then(res => {
        if (res != null) {
            var transaction = {};
            web3.eth.getTransaction(txhash).then(tx => {
                transaction.hash = tx.hash;
                transaction.from = tx.from;
                transaction.to = tx.to;
                transaction.nonce = tx.nonce;
                transaction.gas = tx.gas;
                transaction.gasPrice = tx.gasPrice;
                transaction.value = tx.value;
                transaction.r = tx.r;
                transaction.s = tx.s;
                transaction.v = tx.v;
                caccounts = [];
                if (!accounts[transaction.from]) {
                    caccounts.push(transaction.from);
                }
                /*
                if (!accounts[transaction.to]) {
                    caccounts.push(transaction.to);
                }
                */
                if (caccounts.length > 0) {
                    async.map(Object.keys(peers), function (url, callback) {
                        var w3 = peers[url].link;
                        w3.eth.getAccounts().then(res => {
                            res.forEach(acct => {
                                if (caccounts.includes(acct)) {
                                    accounts[acct] = url;
                                    peers[url].accounts += 1;
                                    chain.addressCount += 1;
                                    transaction.peer = url;
                                }
                                //console.log(accounts.hasOwnProperty(account));
                            });
                            callback(null, transaction);
                        }).catch(err => {
                            console.log(err);
                            callback(err, null);
                        });
                    }, function (err, txs) {
                        if (err == null) {
                            sendMessage(chan, name, transaction);
                        } else {
                            console.log(err);
                        }
                    });
                } else {
                    transaction.peer = accounts[transaction.from];
                    sendMessage(chan, name, transaction);
                    console.log(transaction);
                }
            }).catch(err => {
                console.log(err);
            });
        }
    });
}

var getBlock = async function (chan, name, blkhash) {
    pickLink().then(res => {
        if (res != null) {
            web3.eth.getBlock(blkhash).then(blk => {
                if (name == "view_block") {
                    chain.blockNumber++;
                    chain.transactionCount += blk.transactions.length;
                    chain.uncleCount += blk.uncles.length;
                    for (var idx in blk.transactions) {
                        transactions.push(blk.transactions[idx]);
                    }
                    txpoolStatus();
                    chainInfo(chan, "view_chainInfo");
                }
                var blktx = {}
                var ed = web3.utils.hexToString(blk.extraData.slice(0, 64)).split('\x00')[0];
                blk.signer = ed.split('/')[1];
                // console.log(blk);
                blktx.block = blk;
                //sendMessage(chan, name, blk);
                async.map(blk.transactions, function (item, callback) {
                    web3.eth.getTransaction(item).then(tx => {
                        var transaction = tx;
                        transaction.peer = accounts[transaction.from];
                        web3.eth.getTransactionReceipt(tx.hash).then(receipt => {
                            transaction.status = receipt.status;
                            transaction.contractAddress = receipt.contractAddress;
                            // console.log(transaction);
                            callback(null, transaction);
                            //sendMessage(chan, name, transaction);
                        }).catch(err => {
                            console.log(err);
                            callback(err, null);
                        });
                    }).catch(err => {
                        console.log(err);
                        callback(err, null);
                    });
                }, function (err, txs) {
                    if (err == null) {
                        blktx.txs = txs;
                        // console.log(blktx);
                        sendMessage(chan, name, blktx);
                    } else {
                        console.log(err);
                    }
                });
                /*
                for (var idx in blk.transactions) {
                    if (name == 'view_block') {
                        getTransaction(chan, 'view_transactions', blk.transactions[idx]);
                    } else {
                        getTransaction(chan, 'get_transactions', blk.transactions[idx]);
                    }
        
                }
                */
            }).catch(err => {
                console.log(err);
            });
        }
    });
}

var subcribeEvent = async function () {
    global.subTx = web3.eth.subscribe('pendingTransactions', function (error, result) {
            if (error)
                console.log(error);
            //else
            //    console.log(result);
        })
        .on("data", function (txhash) {
            getPendingTransaction(mio, 'view_pendingTransaction', txhash);
        });

    global.subBlk = web3.eth.subscribe('newBlockHeaders', function (error, result) {
            if (error)
                console.log(error);
            //else
            //    console.log(result);
        })
        .on("data", function (blockHeader) {
            peerStatus();
            getBlock(mio, 'view_block', blockHeader.hash);
        });
}

var calcAccount = async function () {
    console.log('Traversing accounts for each peer ...');
    var flag = false;
    chain.addressCount = 0;
    for (var url in peers) {
        var w3 = peers[url].link;
        flag = await isConnected(w3);
        if (!flag) {
            peers[url].link = createLink(url);
            w3 = peers[url].link;
        }
        flag = await isConnected(w3);
        if (flag) {
            if (peers[url].accounts == null) {
                peers[url].accounts = 0;
            }
            // peers[url].accounts = 0;
            w3.eth.getAccounts().then(res => {
                res.forEach(account => {
                    if (!accounts[account]) {
                        accounts[account] = url;
                        peers[url].accounts += 1;
                        console.log(account + ': ' + url);
                    }
                    //console.log(accounts.hasOwnProperty(account));
                });
                chain.addressCount += peers[url].accounts;
            }).catch(err => {
                console.log(err);
            });
        } else {
            console.log('fail');
        }
    }
}

var calcBlock = async function () {
    console.log('Traversing transactions for each block ...');
    web3.eth.getBlockNumber().then(number => {
        for (var i = chain.blockNumber + 1; i < number + 1; i++) {
            web3.eth.getBlock(i).then(blk => {
                chain.blockNumber++;
                chain.transactionCount += blk.transactions.length;
                chain.uncleCount += blk.uncles.length;
                for (var idx in blk.transactions) {
                    transactions.push(blk.transactions[idx]);
                }
                console.log('Block ' + blk.number + ': ' + blk.transactions.length + '/' + blk.uncles.length)
            }).catch(err => {
                console.log(err);
            });
        }
    }).catch(err => {
        console.log(err);
    });
}

var chainInfo = async function (chan, name) {
    var ipeers = {}
    for (var url in peers) {
        // console.log(peers[url]);
        ipeers[url] = {};
        ipeers[url].ippt = peers[url].ippt;
        ipeers[url].id = peers[url].id;
        ipeers[url].accounts = peers[url].accounts;
        ipeers[url].cli = peers[url].cli;
        ipeers[url].coinbase = peers[url].coinbase;
    }
    chain.peers = ipeers;
    chain.addressCount = Object.keys(accounts).length;
    chain.transactionCount = transactions.length;
    sendMessage(chan, name, chain);
}

var peerStatus = async function () {
    var flag = false;
    for (var url in peers) {
        (async function (url) {
            var w3 = peers[url].link;
            flag = await isConnected(w3);
            if (!flag) {
                peers[url].link = createLink('ws://' + url)
                w3 = peers[url].link;
            }
            flag = await isConnected(w3);
            if (flag) {
                w3.eth.isSyncing().then(res => {
                    var speer = url;
                    var sstatus = 'normal';
                    var sdesc = {};
                    if (res != false) {
                        sstatus = 'syncing';
                        sdesc = res;
                    }
                    console.log('peer ' + url + ' is ' + sstatus + '!');
                    sendMessage(mio, 'view_peerStatus', {
                        'peer': speer,
                        'status': sstatus,
                        'desc': sdesc
                    });
                }).catch(err => {
                    console.log(err);
                });
            } else {
                console.log('peer ' + url + ' is down!');
                sendMessage(mio, 'view_peerStatus', {
                    'peer': url,
                    'status': 'down',
                    'desc': {}
                });
            }
        })(url);
    }
}

var txpoolStatus = async function () {
    web3.eth.txpool.status().then(tp => {
        var txpool = {};
        txpool.pending = web3.utils.hexToNumber(tp.pending);
        txpool.queued = web3.utils.hexToNumber(tp.queued);
        sendMessage(mio, 'view_txpoolStatus', txpool);
    }).catch(err => {
        console.log(err);
    });
}

/*
function recentBlocks(num) {
    getBlocks(mio, 'view_blocks', 1 - num, 'latest');
}
*/

var recentBTs = async function (num) {
    web3.eth.getBlockNumber().then(number => {
        chain.blockNumber = number;
        var rg = 0;
        var arr = [];
        if (number < num) {
            rg = 0;
        } else {
            rg = number - num;
        }
        for (var i = number; i > rg; i--) {
            arr.push(i);
        }
        async.map(arr, function (idx, callback) {
            web3.eth.getBlock(idx).then(blk => {
                var ed = web3.utils.hexToString(blk.extraData.slice(0, 64)).split('\x00')[0];
                blk.signer = ed.split('/')[1];
                // console.log(blk);
                callback(null, blk)
                //sendMessage(chan, name, blk);
            }).catch(err => {
                console.log(err);
                callback(err, null);
            });
        }, function (err, blks) {
            if (err == null) {
                // console.log(blks);
                sendMessage(mio, 'view_blocks', blks)
                //console.log('========================================================================================');
                var txhashs = [];
                for (var t in blks) {
                    var txs = blks[t].transactions.reverse();
                    for (var k in txs) {
                        if (txhashs.length < num) {
                            txhashs.push(txs[k]);
                        } else {
                            break;
                        }
                    }
                    if (txhashs.length >= num) {
                        break;
                    }
                }
                getTransactions(mio, 'view_transactions', txhashs);
                //sendMessage(chan, name, blks);
            } else {
                console.log(err);
            }
        });
    }).catch(err => {
        console.log(err);
    });
}

var createTransaction = async function (chan, name) {
    pickLink().then(res => {
        if (res != null) {
            web3.eth.getAccounts().then(res => {
                var fr = res[0];
                var to = res[1];
                web3.eth.sendTransaction({
                        from: fr,
                        to: to,
                        value: '10000000'
                    })
                    .then(function (receipt) {
                        console.log(receipt);
                        sendMessage(chan, name, {
                            'receipt': receipt
                        });
                    });
            }).catch(err => {
                console.log(err);
            });
        }
    })
}

initEnv();
initServer();

//setInterval(calcAccount, 60000);

http.listen(8000, () => {
    console.log('listening on 0.0.0.0:8000');
});

process.on('uncaughtException', err => {
    //打印出错误
    console.log(err);
    //打印出错误的调用栈方便调试
    console.log(err.stack);
});
/*
app.listen(8080, '0.0.0.0');
//io.set('log level', 1); //将socket.io中的debug信息关闭  

function handler(req, res) {
    fs.readFile(__dirname + '/index.html', function (err, data) {
        if (err) {
            res.writeHead(500);
            return res.end('Error loading index.html');
        }
        res.writeHead(200, {
            'Content-Type': 'text/html'
        });
        res.end(data);
    });
}
*/

/*
io.sockets.on('connection', function (socket) {
    socket.emit('my response', {
        msg: 'Connected'
    });
    socket.on('my event', function (data) {
        socket.emit('my response', {
            msg: data
        });
    });
});
*/
