var myDiagram;
var myModel;

// 通知消息
function noty(type, title, msg, img) {
    Lobibox.notify(type, {
        size: 'mini',
        title: '',
        icon: true,
        img: '',
        delay: 2000,
        delayIndicator: false,
        pauseDelayOnHover: true,
        sound: false,
        rounded: true,
        width: 500,
        //messageHeight: 30,
        position: "center bottom",
        onClickUrl: null,
        msg: msg
    });
}

// 
function popup(x, y, msg) {
    var a = new Array("富强", "民主", "文明", "和谐", "自由", "平等", "公正", "法治", "爱国", "敬业", "诚信", "友善");
    var $i = $("<span/>").text(a[msg]);

    // var x = e.pageX,y = e.pageY;
    console.log(x, y);
    $i.css({
        "z-index": 99999,
        //"top": y - 20,
        "top": y - 10,
        "left": x,
        "position": "absolute",
        "font-weight": "bold",
        "color": "#ff6651"
    });
    $("body").append($i);
    $i.animate({
        "top": y - 50,
        "opacity": 0
    }, 2000, function () {
        $i.remove();
    });
}

//
function convertKeyImage(src) {
    if (src == null || src == "") {
        return "refs/img/node.svg";
    } else {
        return src;
    }
}

//
function loop(node, interval) {
    var diagram = myDiagram;
    setTimeout(function () {
        var oldskips = diagram.skipsUndoManager;
        diagram.skipsUndoManager = true;
        diagram.links.each(function (link) {
            if (link.fromNode == node || link.toNode == node) {
                if (link.toNode == node) {
                    var model = diagram.model;
                    model.startTransaction("reconnect link");
                    model.setToKeyForLinkData(link, link.fromNode.key)
                    model.commitTransaction("reconnect link");
                }
                var shape = link.findObject("PIPE");
                var off = shape.strokeDashOffset - 2;
                shape.strokeDashOffset = (off <= 0) ? 20 : off;
            }
        });
        diagram.skipsUndoManager = oldskips;
        interval -= 1;
        if (interval > 0) {
            loop(node, interval);
        }
    }, 100);
}

//区块详情
function chainDetails(num) {
    $.ajax({
        type: "get",
        jsonpCallback: "callback",
        url: 'http://172.16.201.189:5000/rs/block/' + num,
        data: {},
        dataType: "jsonp",
        success: function (msg) {
            var item = "<p>" + "difficulty：<span>" + msg.block.difficulty + "</span></p>" +
                "<p>gasLimit：<span>" + msg.block.gasLimit + "</span></p>" +
                "<p>gasUsed：<span>" + msg.block.gasUsed + "</span></p>" +
                "<p>hash：<span>" + msg.block.hash + "</span></p>" +
                "<p>number：<span>" + msg.block.number + "</span></p>" +
                "<p>parentHash：<span>" + msg.block.parentHash + "</span></p>" +
                "<p>size：<span>" + msg.block.size + "</span></p>" +
                "<p>timestamp：<span>" + msg.block.timestamp + "</span></p>" +
                "<p>totalDifficulty：<span>" + msg.block.totalDifficulty + "</span></p>" +
                "<p>transactions：<span>" + msg.block.transactions + "</span></p>"
            $("#details").modal("show");
            $(".detail-list").empty().append(item);

        },
        error: function (msg) {
            alert("请求失败!")
        }
    });
}

//			交易详情
function tradeDetails(hash) {
    var hash = $(hash).text();
    $.ajax({
        type: "get",
        jsonpCallback: "callback",
        url: 'http://172.16.201.189:5000/rs/transaction/' + hash,
        data: {},
        dataType: "jsonp",
        success: function (msg) {
            var item = "<p>" + "blockHash：<span>" + msg.transaction.blockHash + "</span></p>" +
                "<p>" + "blockNumber：<span>" + msg.transaction.blockNumber + "</span></p>" +
                "<p>" + "from：<span>" + msg.transaction.from + "</span></p>" +
                "<p>" + "to：<span>" + msg.transaction.to + "</span></p>" +
                "<p>" + "gas：<span>" + msg.transaction.gas + "</span></p>" +
                "<p>" + "gasPrice：<span>" + msg.transaction.gasPrice + "</span></p>" +
                "<p>" + "hash：<span>" + msg.transaction.hash + "</span></p>" +
                "<p>" + "input：<span>" + msg.transaction.input + "</span></p>" +
                "<p>" + "nonce：<span>" + msg.transaction.nonce + "</span></p>"
            "<p>" + "transactionIndex：<span>" + msg.transaction.transactionIndex + "</span></p>"
            $("#details").modal("show");
            $(".detail-list").empty().append(item);

        },
        error: function (msg) {
            alert("请求失败!")
        }
    });
}

(function ($) {
    $.fn.numberAnimate = function (setting) {
        var defaults = {
            speed: 1000, //动画速度
            num: "", //初始化值
            iniAnimate: true, //是否要初始化动画效果
            symbol: '', //默认的分割符号，千，万，千万
            dot: 0 //保留几位小数点
        }
        //如果setting为空，就取default的值
        var setting = $.extend(defaults, setting);

        //如果对象有多个，提示出错
        if ($(this).length > 1) {
            alert("just only one obj!");
            return;
        }

        //如果未设置初始化值。提示出错
        if (setting.num == "") {
            alert("must set a num!");
            return;
        }
        var nHtml = '<div class="mt-number-animate-dom" data-num="{{num}}">\
            <span class="mt-number-animate-span">0</span>\
            <span class="mt-number-animate-span">1</span>\
            <span class="mt-number-animate-span">2</span>\
            <span class="mt-number-animate-span">3</span>\
            <span class="mt-number-animate-span">4</span>\
            <span class="mt-number-animate-span">5</span>\
            <span class="mt-number-animate-span">6</span>\
            <span class="mt-number-animate-span">7</span>\
            <span class="mt-number-animate-span">8</span>\
            <span class="mt-number-animate-span">9</span>\
            <span class="mt-number-animate-span">.</span>\
          </div>';

        //数字处理
        var numToArr = function (num) {
            num = parseFloat(num).toFixed(setting.dot);
            if (typeof (num) == 'number') {
                var arrStr = num.toString().split("");
            } else {
                var arrStr = num.split("");
            }
            return arrStr;
        }

        //设置DOM symbol:分割符号
        var setNumDom = function (arrStr) {
            var shtml = '<div class="mt-number-animate">';
            for (var i = 0, len = arrStr.length; i < len; i++) {
                if (i != 0 && (len - i) % 3 == 0 && setting.symbol != "" && arrStr[i] != ".") {
                    shtml += '<div class="mt-number-animate-dot">' + setting.symbol + '</div>' + nHtml.replace("{{num}}", arrStr[i]);
                } else {
                    shtml += nHtml.replace("{{num}}", arrStr[i]);
                }
            }
            shtml += '</div>';
            return shtml;
        }

        //执行动画
        var runAnimate = function ($parent) {
            $parent.find(".mt-number-animate-dom").each(function () {
                var num = $(this).attr("data-num");
                num = (num == "." ? 10 : num);
                var spanHei = $(this).height() / 11; //11为元素个数
                var thisTop = -num * spanHei + "px";
                if (thisTop != $(this).css("top")) {
                    if (setting.iniAnimate) {
                        //HTML5不支持
                        if (!window.applicationCache) {
                            $(this).animate({
                                top: thisTop
                            }, setting.speed);
                        } else {
                            $(this).css({
                                'transform': 'translateY(' + thisTop + ')',
                                '-ms-transform': 'translateY(' + thisTop + ')',
                                /* IE 9 */
                                '-moz-transform': 'translateY(' + thisTop + ')',
                                /* Firefox */
                                '-webkit-transform': 'translateY(' + thisTop + ')',
                                /* Safari 和 Chrome */
                                '-o-transform': 'translateY(' + thisTop + ')',
                                '-ms-transition': setting.speed / 1000 + 's',
                                '-moz-transition': setting.speed / 1000 + 's',
                                '-webkit-transition': setting.speed / 1000 + 's',
                                '-o-transition': setting.speed / 1000 + 's',
                                'transition': setting.speed / 1000 + 's'
                            });
                        }
                    } else {
                        setting.iniAnimate = true;
                        $(this).css({
                            top: thisTop
                        });
                    }
                }
            });
        }

        //初始化
        var init = function ($parent) {
            //初始化
            $parent.html(setNumDom(numToArr(setting.num)));
            runAnimate($parent);
        };

        //重置参数
        this.resetData = function (num) {
            var newArr = numToArr(num);
            var $dom = $(this).find(".mt-number-animate-dom");
            if ($dom.length < newArr.length) {
                $(this).html(setNumDom(numToArr(num)));
            } else {
                $dom.each(function (index, el) {
                    $(this).attr("data-num", newArr[index]);
                });
            }
            runAnimate($(this));
        }
        //init
        init($(this));
        return this;
    }
})(jQuery);

$(function () {
    var g = go.GraphObject.make;
    // Horizontal
    // Vertical
    var myNode = g(go.Node, "Vertical", {
            //background: "#66ccff",
            width: 100,
            height: 80,

            locationSpot: go.Spot.Center,
            /*
            tooltip: g(go.HTMLInfo, {
                show: "<span>aaa</span>",
            })
            */
        },
        //new go.Binding("location", "loc").makeTwoWay(),   //CircularLayout下自动布局, 指定位置不生效
        g(go.Picture, {
            //source: "",
            imageStretch: go.GraphObject.Fill,
            desiredSize: new go.Size(50, 50),
            margin: 4,
        }, new go.Binding("source", "src", convertKeyImage), {
            toolTip: // define a tooltip for each node
                g(go.Adornment, "Auto",
                    g(go.Shape, {
                        fill: "#FFFFCC"
                    }),
                    g(go.TextBlock, {
                            margin: 4
                        },
                        new go.Binding("text", "desc"))
                ) // end of Adornment
        }),
        /*
        g(go.Shape, "RoundedRectangle", {
            figure: "Club",
            width: 40,
            height: 50,
            margin: 4,
            fill: "red"
        }, new go.Binding("figure", "fig"), new go.Binding("fill", "fil")),
        */
        g(go.TextBlock, "Default Text", {
            margin: 5,
            stroke: "red",
            font: "bold 14px sans-serif"
        }, new go.Binding("text", "name")));


    var myLink = g(go.Link, {
            routing: go.Link.Normal,
            curve: go.Link.None,
            corner: 0,
            reshapable: true,
            relinkableFrom: true,
            relinkableTo: true,
            toShortLength: 5
        }, new go.Binding("points").makeTwoWay(),
        g(go.Shape, {
            isPanelMain: true,
            stroke: "purple",
            strokeWidth: 7
        }),
        g(go.Shape, {
            isPanelMain: true,
            stroke: "green",
            strokeWidth: 4
        }),
        g(go.Shape, {
            isPanelMain: true,
            stroke: "white",
            strokeWidth: 2,
            name: "PIPE",
            strokeDashArray: [10, 10]
        }),
        /*
        g(go.Shape, {
            toArrow: "Triangle", fill: "black", stroke: null
        }),
        g(go.Shape, {
            fromArrow: "Triangle", fill: "black", stroke: null
        })
        */
    );
    myModel = g(go.GraphLinksModel);

    myDiagram = g(go.Diagram, "chartNode", {
        //model: myModel,                     //model, nodeTemplate和linkTemplate也可以后续指定: myDiagram.model = myModel
        nodeTemplate: myNode,
        linkTemplate: myLink,
        initialContentAlignment: go.Spot.Center,
        allowZoom: false,
        allowMove: false,
        allowLink: false,
        allowResize: false,
        allowReshape: false,
        allowRotate: false,
        allowSelect: false,
        allowDragOut: false,
        allowDrop: false,
        isReadOnly: true,
        "undoManager.isEnabled": true,

        //"grid.visible": true,   // 是否显示网格
        "grid.gridCellSize": new go.Size(20, 20),
        "clickCreatingTool.archetypeNodeData": {
            text: "Node"
        },
        "panningTool.isEnabled": false,
        "toolManager.mouseWheelBehavior": go.ToolManager.WheelZoom,
        "toolManager.hoverDelay": 100,
        "toolManager.toolTipDuration": 5000,
        "commandHandler.copiesTree": false,
        "commandHandler.deletesTree": false,
        "draggingTool.dragsTree": false,
        "draggingTool.dragsLink": false,
        validCycle: go.Diagram.CycleNotDirected,
        layout: g(go.CircularLayout, {
            radius: 100,
            aspectRatio: 1
            //sorting: go.CircularLayout.Optimized
        })

        /*
        layout: g(go.TreeLayout, {
            angle: 90, sorting: go.TreeLayout.SortingAscending
        })
        */
    });

});

$(function () {
    var numRun1 = $(".numberRun1").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ","
    });
    var numRun2 = $(".numberRun2").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ","
    });
    var numRun3 = $(".numberRun3").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ","
    });
    var numRun4 = $(".numberRun4").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ","
    });
    var numRun5 = $(".numberRun5").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ","
    });
    var numRun6 = $(".numberRun6").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ","
    });
    var mio = io.connect('http://172.16.201.189:8000/mio');
    //		 	区块信息
    mio.on('view_chainInfo', function (data) {
        console.log(data);
        numRun1.resetData(data.msg.blockNumber);
        numRun2.resetData(data.msg.uncleCount);
        numRun3.resetData(data.msg.transactionCount);
        numRun4.resetData(data.msg.addressCount);
        var peers = data.msg.peers;
        var peers = Object.keys(data.msg.peers);
        nodeArray = [{
                key: "a",
                name: "节点A",
                src: "refs/img/server.png",
                desc: "I am A\n HHH",
                fig: "YinYang",
                fil: "blue"
            },
            {
                key: "b",
                name: "节点B",
                src: "refs/img/server.png",
                desc: "I am B",
                fig: "Peace",
                fil: "red"
            },
            {
                key: "c",
                name: "节点C",
                src: "refs/img/server.png",
                desc: "I am C",
                fig: "NotAllowd",
                fil: "gree"
            },
        ];

        //loop();

        //var data = myDiagram.model.nodeDataArray[0];
        //console.log(myModel.nodeDataArray)
        linkArray = [];

        for (var i = 0; i < nodeArray.length; i++) {
            for (var j = i + 1; j < nodeArray.length; j++) {
                linkArray.push({
                    from: nodeArray[i].key,
                    to: nodeArray[j].key
                });
            }
        };

        myModel.nodeDataArray = nodeArray;
        myModel.linkDataArray = linkArray;
        myDiagram.model = myModel;


    });

    //节点状态
    var checkValue = {}
    mio.on('view_peerStatus', function (val) {
        console.log(typeof (val))
        if (checkValue === val) {
            return false
        }
        checkValue = val
        nodePeer = val.msg.peer;
        nodeStatus = val.msg.status;

    });

    //		交易走势图
    mio.emit('getChainInfo', "");
    var linedata = [];
    var medium = 0;
    var difference = "";
    var array = [];
    mio.on('get_chainInfo', function (val) {
        var myDate = new Date();
        array.push(myDate.toLocaleString());
        difference = val.msg.transactionCount - medium;
        if (medium === 0) {
            difference = 0;
        }
        medium = val.msg.transactionCount;
        array.push(difference);
        linedata.push(array);
        var option = {
            title: {
                text: "交易走势图",
                textStyle: {
                    color: "#2d8cf0"
                }
            },
            tooltip: {
                trigger: "axis"
            },
            xAxis: {
                name: "时间",
                data: linedata.map(function (item) {
                    return item[0];
                }),
                axisLine: {
                    lineStyle: {
                        color: "#2d8cf0" //左边线的颜色
                    }
                }
            },
            yAxis: {
                name: "差值",
                minInterval: 1,
                boundaryGap: [0, 0.1],
                splitLine: {
                    show: true,
                    lineStyle: {
                        color: ["#2d8cf0"]
                    }
                },
                axisLine: {
                    lineStyle: {
                        color: "#2d8cf0" //左边线的颜色
                    }
                }
            },
            series: {
                name: "交易走势图",
                type: "line",
                data: linedata.map(function (item) {
                    return item[1];
                })
            }
        };

        var chart = echarts.init(document.getElementById("chartLine"));
        chart.setOption(option);
        window.onresize = function () {
            //重置容器高宽
            chart.resize();
        };
        array = [];
    });
    setInterval(function () {
        mio.emit('getChainInfo', "");
    }, 3000)

    //交易持状态		 
    mio.on('view_txpoolStatus', function (data) {
        numRun5.resetData(data.msg.pending);
        numRun6.resetData(data.msg.queued);
    });
    //五个块信息
    mio.on('view_blocks', function (data) {
        $(".chain_tbody").empty();
        if (data.msg.length == 0) {
            $(".chain_tbody").append("暂无区块产生")
        } else {
            for (var i = 0; i < data.msg.length; i++) {
                var tr = "<li class='clearfix'>" +
                    "<div class='block_box col-sm-4'>" +
                    "<p>block:" + data.msg[i].number + "</p>" +
                    "<p><em>区块大小:</em>" + data.msg[i].size + "</p>" +
                    "<p>" + new Date(data.msg[i].timestamp * 1000).toLocaleString() + "</p>" +
                    "</div>" +
                    "<div class='col-sm-8'>" +
                    "<p><em>交易数量:</em>" + data.msg[i].transactions.length + "</p>" +
                    "<p><em>打包节点:</em>" + data.msg[i].signer + "</p>" +
                    "<p><em>区块Hash:</em><span class='strong'>" + data.msg[i].hash + "</span></p>" +
                    "</div></li>"
                $(".chain_tbody").append(tr)
            }
        }
    });

    //五个交易信息
    mio.on('view_transactions', function (data) {
        $(".trade_tbody").empty();
        if (data.msg.length == 0) {
            $(".trade_tbody").append("暂无交易产生")
        } else {
            for (var i = 0; i < data.msg.length; i++) {
                var tr = "<div class='item_trade'>" +
                    "<p><em>交易节点:</em><span>" + data.msg[i].peer + "</span><em>交易Hash:</em><span>" + data.msg[i].hash + "</span></p>" +
                    "<p><em>发起者:</em><span>" + data.msg[i].from + "</span><em>受益者:</em><span>" + data.msg[i].to + "</span></p>" +
                    "<p><em>交易编号:</em><span>" + data.msg[i].transactionIndex + "</span><em>交易额:</em><span>" + data.msg[i].value + "</span></p>" +
                    "</div>"
                $(".trade_tbody").append(tr)
            }
        }
    })
    //产生块时增加一条
    mio.on('view_block', function (data) {
        console.log(data)
        var tr = "<li class='clearfix none'>" +
            "<div class='block_box col-sm-4'>" +
            "<p>block:" + data.msg.block.number + "</p>" +
            "<p><em>区块大小:</em>" + data.msg.block.size + "</p>" +
            "<p>" + new Date(data.msg.block.timestamp * 1000).toLocaleString() + "</p>" +
            "</div>" +
            "<div class='col-sm-8'>" +
            "<p><em>交易数量:</em>" + data.msg.block.transactions.length + "</p>" +
            "<p><em>打包节点:</em>" + data.msg.block.signer + "</p>" +
            "<p><em>区块Hash:</em><span class='strong'>" + data.msg.block.hash + "</span></p>" +
            "</div></li>"
        $(".chain_tbody").find("li:last-child").slideUp(500, function () {
            $(this).remove();
            $(".chain_tbody").prepend(tr)
            $(".chain_tbody").find("li:first-child").slideDown(500);
        })
        for (var i = 0; i < data.msg.txs.length; i++) {
            var trs = "<div class='item_trade none'>" +
                "<p><em>交易节点:</em><span>" + data.msg.txs[i].peer + "</span><em>交易Hash:</em><span>" + data.msg.txs[i].hash + "</span></p>" +
                "<p><em>发起者:</em><span>" + data.msg.txs[i].from + "</span><em>受益者:</em><span>" + data.msg.txs[i].to + "</span></p>" +
                "<p><em>交易编号:</em><span>" + data.msg.txs[i].transactionIndex + "</span><em>交易额:</em><span>" + data.msg.txs[i].value + "</span></p>" +
                "</div>"
            $(".trade_tbody").find(".item_trade:last-child").slideUp(500, function () {
                $(this).remove();
                $(".trade_tbody").prepend(trs)
                $(".trade_tbody").find(".item_trade:first-child").slideDown(500);
            })
        }
    });

});