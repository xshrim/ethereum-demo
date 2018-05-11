App = {
    web3Provider: null,
    contracts: {},

    init: function () {
        // Load pets.
        $.getJSON('../musics.json', function (data) {
            var musicsRow = $('#musicsRow');
            var musicTemplate = $('#musicTemplate');

            for (i = 0; i < data.length; i++) {
                musicTemplate.find('.panel-title').text(data[i].name);
                musicTemplate.find('img').attr('src', data[i].picture);
                musicTemplate.find('.audio').attr('src', data[i].media);
                musicTemplate.find('.audio').attr('path', data[i].media);
                musicTemplate.find('.audio').attr('style', "display:none");
                musicTemplate.find('.lyrics').text(data[i].lyrics);
                musicTemplate.find('.composer').text(data[i].composer);
                musicTemplate.find('.singer').text(data[i].singer);
                musicTemplate.find('.album').text(data[i].album);
                musicTemplate.find('.issue').text(data[i].issue);
                musicTemplate.find('.company').text(data[i].company);
                musicTemplate.find('.price').text(data[i].price);
                musicTemplate.find('.btn-do').attr('data-id', data[i].id);
                musicTemplate.find('.btn-do').attr('data-price', data[i].price);
                musicTemplate.find('.btn-do').attr('style', "display:block");

                musicsRow.append(musicTemplate.html());
            }
        });

        return App.initWeb3();
    },

    initWeb3: function () {
        /*
         * Replace me...
         */
        // Is there an injected web3 instance?
        /*
        if (typeof web3 !== 'undefined') {
            App.web3Provider = web3.currentProvider;
        } else {
            // If no injected web3 instance is detected, fall back to Ganache
            App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
        }
        */
        App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
        web3 = new Web3(App.web3Provider);

        //web3 = new Web3("ws://localhost:8546");

        return App.initContract();
    },

    initContract: function () {
        /*
         * Replace me...
         */
        // 加载Adoption.json，保存了Adoption的ABI（接口说明）信息及部署后的网络(地址)信息，它在编译合约的时候生成ABI，在部署的时候追加网络信息
        $.getJSON('Music.json', function (data) {
            // 用Adoption.json数据创建一个可交互的TruffleContract合约实例。
            var MusicArtifact = data;
            App.contracts.Music = TruffleContract(MusicArtifact);

            // Set the provider for our contract
            App.contracts.Music.setProvider(App.web3Provider);
            // Use our contract to retrieve and mark the adopted pets
            return App.markMusic();
        });
        return App.bindEvents();
    },

    bindEvents: function () {
        $(document).on('click', '.btn-do', App.handleMusic);
    },

    markMusic: function (musics, account) {
        /*
         * Replace me...
         */
        var musicInstance;
        App.contracts.Music.deployed().then(function (instance) {
            musicInstance = instance;
            // 调用合约的getAdopters(), 用call读取信息不用消耗gas
            return musicInstance.getMusicCount.call();
        }).then(function (num) {
            // console.log(num.toNumber());
            for (i = 0; i < num.toNumber(); i++) {
                musicInstance.getMusic.call(i).then(function (res) {
                    $('.panel-music').eq(parseInt(res[0])).find('audio').attr('style', "display:block");
                    $('.panel-music').eq(parseInt(res[0])).find('button').attr('style', "display:none");
                    return res[1];
                }).then((res) => {
                    console.log('ok');
                    /*
                    musicInstance.getBalance.call().then((balance) => {
                        // console.log(parseInt(balance.c[0]) / 1000.00);
                        console.log(balance.toNumber());
                    });
                    */
                });
                //$('.panel-music').eq(k).find('audio').attr('style', "display:block");
                //$('.panel-music').eq(k).find('button').attr('style', "display:none");
                // $('.panel-music').eq(i).find('button').text('Buy').attr('disabled', true);

                //$('.panel-music').eq(i).find('audio').attr('style', "display:none");
                //$('.panel-music').eq(i).find('button').attr('style', "display:block");
            }
        }).catch(function (err) {
            console.log(err.message);
        });
    },

    handleMusic: function (event) {
        event.preventDefault();

        var musicId = parseInt($(event.target).data('id'));
        var musicPrice = parseInt($(event.target).data('price'));
        /*
         * Replace me...
         */
        var musicInstance;

        // 获取用户账号
        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            var account = accounts[0];

            App.contracts.Music.deployed().then(function (instance) {
                musicInstance = instance;

                // 发送交易领养宠物
                // return adoptionInstance.adopt(petId);
                /*
                return musicInstance.buy(musicId.toString(), musicPrice, "2100-01-01", {
                    from: account,
                });
                */
                return musicInstance.buy(musicId.toString(), musicPrice, "2100-01-01", {
                        from: account,
                        gas: 200000,
                        gasPrice: '20000000000'
                    })
                    .then((result) => {
                        return App.markMusic();
                        /*
                        return musicInstance.getBalance.call()
                            .then((result) => {
                                console.log(result);
                                
                            });
                        */
                    });
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    }

};

$(function () {
    $(window).load(function () {
        App.init();
    });
});