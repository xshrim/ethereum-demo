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

function show(x, y, msg) {
    var color = "#ff6651";
    //var a = new Array("富强", "民主", "文明", "和谐", "自由", "平等", "公正", "法治", "爱国", "敬业", "诚信", "友善");
    var $i = $("<span/>").text(msg);

    // var x = e.pageX,y = e.pageY;
    if (msg == '区块') {
        x = x - 15;
        color = 'purple';
    } else if (msg == '交易') {
        x = x + 5;
        color = 'red';
    }
    $i.css({
        "z-index": 99999,
        //"top": y - 20,
        "top": y - 10,
        "left": x,
        "position": "absolute",
        "font-weight": "bold",
        "color": color
    });
    $("body").append($i);
    $i.animate({
        "top": y - 100,
        "opacity": 0
    }, 2000, function () {
        $i.remove();
    });
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
                if (thisTop != $(this).css("top") || thisTop == "0px") {
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
            if ($dom.length != newArr.length) {
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

    //判断是否为数组
    function isArray(v) {
        return v && typeof v.length == 'number' && typeof v.splice == 'function';
    }
    //创建元素
    function createEle(tagName) {
        return document.createElement(tagName);
    }
    //在body中添加子元素
    function appChild(eleName) {
        return document.body.appendChild(eleName);
    }
    //从body中移除子元素
    function remChild(eleName) {
        return document.body.removeChild(eleName);
    }
    //弹出窗口，标题（html形式）、html、宽度、高度、是否为模式对话框(true,false)、按钮（关闭按钮为默认，格式为['按钮1',fun1,'按钮2',fun2]数组形式，前面为按钮值，后面为按钮onclick事件）
    function showWindow(title, html, width, height, modal, buttons) {
        //避免窗体过小
        if (width < 300) {
            width = 300;
        }
        if (height < 200) {
            height = 200;
        }

        //声明mask的宽度和高度（也即整个屏幕的宽度和高度）
        var w, h;
        //可见区域宽度和高度
        var cw = document.body.clientWidth;
        var ch = document.body.clientHeight;
        //正文的宽度和高度
        var sw = document.body.scrollWidth;
        var sh = document.body.scrollHeight;
        //可见区域顶部距离body顶部和左边距离
        var st = document.body.scrollTop;
        var sl = document.body.scrollLeft;

        w = cw > sw ? cw : sw;
        h = ch > sh ? ch : sh;

        //避免窗体过大
        if (width > w) {
            width = w;
        }
        if (height > h) {
            height = h;
        }

        //如果modal为true，即模式对话框的话，就要创建一透明的掩膜
        if (modal) {
            var mask = createEle('div');
            mask.style.cssText = "position:absolute;left:0;top:0px;background:#fff;filter:Alpha(Opacity=30);opacity:0.5;z-index:100;width:" + w + "px;height:" + h + "px;";
            appChild(mask);
        }

        //这是主窗体
        var win = createEle('div');
        win.style.cssText = "position:absolute;left:" + (sl + cw / 2 - width / 2) + "px;top:" + (st + ch / 2 - height / 2) + "px;background:#f0f0f0;z-index:101;width:" + width + "px;height:" + height + "px;border:solid 2px #afccfe;";
        //标题栏
        var tBar = createEle('div');
        //afccfe,dce8ff,2b2f79
        tBar.style.cssText = "margin:0;width:" + width + "px;height:25px;background:url(top-bottom.png);cursor:move;";
        //标题栏中的文字部分
        var titleCon = createEle('div');
        titleCon.style.cssText = "float:left;margin:3px;";
        titleCon.innerHTML = title; //firefox不支持innerText，所以这里用innerHTML
        tBar.appendChild(titleCon);
        //标题栏中的“关闭按钮”
        var closeCon = createEle('div');
        closeCon.style.cssText = "float:right;width:20px;margin:3px;cursor:pointer;"; //cursor:hand在firefox中不可用
        closeCon.innerHTML = "×";
        tBar.appendChild(closeCon);
        win.appendChild(tBar);
        //窗体的内容部分，CSS中的overflow使得当内容大小超过此范围时，会出现滚动条
        var htmlCon = createEle('div');
        htmlCon.style.cssText = "text-align:center;width:" + width + "px;height:" + (height - 50) + "px;overflow:auto;";
        htmlCon.innerHTML = html;
        win.appendChild(htmlCon);
        //窗体底部的按钮部分
        var btnCon = createEle('div');
        btnCon.style.cssText = "width:" + width + "px;height:25px;text-height:20px;background:url(top-bottom.png);text-align:center;padding-top:3px;";

        //如果参数buttons为数组的话，就会创建自定义按钮
        if (isArray(buttons)) {
            var length = buttons.length;
            if (length > 0) {
                if (length % 2 == 0) {
                    for (var i = 0; i < length; i = i + 2) {
                        //按钮数组
                        var btn = createEle('button');
                        btn.innerHTML = buttons[i]; //firefox不支持value属性，所以这里用innerHTML
                        //                        btn.value = buttons[i];
                        btn.onclick = buttons[i + 1];
                        btnCon.appendChild(btn);
                        //用户填充按钮之间的空白
                        var nbsp = createEle('label');
                        nbsp.innerHTML = "&nbsp&nbsp";
                        btnCon.appendChild(nbsp);
                    }
                }
            }
        }
        //这是默认的关闭按钮
        var btn = createEle('button');
        //        btn.setAttribute("value","关闭");
        btn.innerHTML = "关闭";
        //        btn.value = '关闭';
        btnCon.appendChild(btn);
        win.appendChild(btnCon);
        appChild(win);

        /******************************************************以下为拖动窗体事件************************************************/
        //鼠标停留的X坐标
        var mouseX = 0;
        //鼠标停留的Y坐标
        var mouseY = 0;
        //窗体到body顶部的距离
        var toTop = 0;
        //窗体到body左边的距离
        var toLeft = 0;
        //判断窗体是否可以移动
        var moveable = false;

        //标题栏的按下鼠标事件
        tBar.onmousedown = function () {
            var eve = getEvent();
            moveable = true;
            mouseX = eve.clientX;
            mouseY = eve.clientY;
            toTop = parseInt(win.style.top);
            toLeft = parseInt(win.style.left);

            //移动鼠标事件

            tBar.onmousemove = function () {
                if (moveable) {
                    var eve = getEvent();
                    var x = toLeft + eve.clientX - mouseX;
                    var y = toTop + eve.clientY - mouseY;
                    if (x > 0 && (x + width < w) && y > 0 && (y + height < h)) {
                        win.style.left = x + "px";
                        win.style.top = y + "px";
                    }
                }
            } //放下鼠标事件，注意这里是document而不是tBar

            document.onmouseup = function () {
                moveable = false;
            }
        }

        //获取浏览器事件的方法，兼容ie和firefox
        function getEvent() {
            return window.event || arguments.callee.caller.arguments[0];
        }

        //顶部的标题栏和底部的按钮栏中的“关闭按钮”的关闭事件
        btn.onclick = closeCon.onclick = function () {
            remChild(win);
            if (mask) {
                remChild(mask);
            }
        }
    }

    function addCheckbox(name, value, id, click) {
        var str = "<input type='checkbox' name='" + name + "' value='" + value + "' id='" + id + "' onclick='" + (click == null ? '' : click) + "'/>&nbsp<label for='" + id + "'>" + value + "</label>";
        return str;
    }

    function show() {
        var str = "<div><div style='border:dotted 1px blue'><table cellspacing='2'>";
        str += "<tr><td colspan='7' style='text-align:center'>请选择所在地区：" + addCheckbox('all', '全（不）选', 'cities_all', 'selectAll(this,\"cities_cb\")') + "</td></tr>";
        str += "<tr><td>" + addCheckbox('cities_cb', '长沙市', 'cities_cb1') + "</td><td>" + addCheckbox('cities_cb', '株洲市', 'cities_cb2') + "</td><td>" + addCheckbox('cities_cb', '湘潭市', 'cities_cb3') + "</td><td>" + addCheckbox('cities_cb',
            '衡阳市', 'cities_cb4') + "</td><td>" + addCheckbox('cities_cb', '益阳市', 'cities_cb5') + "</td>";
        str += "<td>" + addCheckbox('cities_cb', '常德市', 'cities_cb6') + "</td><td>" + addCheckbox('cities_cb', '岳阳市', 'cities_cb7') + "</td></tr>";
        str += "<tr><td>" + addCheckbox('cities_cb', '邵阳市', 'cities_cb8') + "</td><td>" + addCheckbox('cities_cb', '郴州市', 'cities_cb9') + "</td><td>" + addCheckbox('cities_cb', '娄底市', 'cities_cb10') + "</td>";
        str += "<td>" + addCheckbox('cities_cb', '永州市', 'cities_cb11') + "</td><td>" + addCheckbox('cities_cb', '怀化市', 'cities_cb12') + "</td><td>" + addCheckbox('cities_cb', '张家界市', 'cities_cb13') + "</td><td>" + addCheckbox('cities_cb',
            '湘西自治州', 'cities_cb14') + "</td></tr>";
        str += "</table></div><br/><div style='border:dotted 1px blue'><table cellspacing='2'>";
        str += "<tr><td colspan='10' style='text-align:center'>请选择矿种：" + addCheckbox('all', '全（不）选', 'class_all', 'selectAll(this,\"class_cb\")') + "</td></tr>";
        str += "<tr><td>" + addCheckbox('class_cb', '铋', 'class_cb1') + "</td><td>" + addCheckbox('class_cb', '钒', 'class_cb2') + "</td><td>" + addCheckbox('class_cb', '金', 'class_cb3') + "</td><td>" + addCheckbox('class_cb', '煤',
            'class_cb4') + "</td><td>" + addCheckbox('class_cb', '锰', 'class_cb5') + "</td><td>" + addCheckbox('class_cb', '钼', 'class_cb6') + "</td><td>" + addCheckbox('class_cb', '铅', 'class_cb7') + "</td><td>" + addCheckbox('class_cb',
            '石膏', 'class_cb8') + "</td><td>" + addCheckbox('class_cb', '石煤', 'class_cb9') + "</td><td>" + addCheckbox('class_cb', '锑', 'class_cb10') + "</td></tr>";
        str += "<tr><td>" + addCheckbox('class_cb', '铁', 'class_cb11') + "</td><td>" + addCheckbox('class_cb', '铜', 'class_cb12') + "</td><td>" + addCheckbox('class_cb', '钨', 'class_cb13') + "</td><td>" + addCheckbox('class_cb', '锡',
            'class_cb14') + "</td><td>" + addCheckbox('class_cb', '锌', 'class_cb15') + "</td><td>" + addCheckbox('class_cb', '银', 'class_cb16') + "</td><td>" + addCheckbox('class_cb', '萤石', 'class_cb17') + "</td><td>" + addCheckbox(
            'class_cb', '铀', 'class_cb18') + "</td><td>" + addCheckbox('class_cb', '稀土氧化物', 'class_cb19') + "</td><td>" + addCheckbox('class_cb', '重晶石', 'class_cb20') + "</td></tr>";
        str += "<tr><td>" + addCheckbox('class_cb', '硼', 'class_cb21') + "</td><td>" + addCheckbox('class_cb', '磷', 'class_cb22') + "</td><td>" + addCheckbox('class_cb', '水泥灰岩', 'class_cb23') + "</td><td>" + addCheckbox('class_cb', '熔剂灰岩',
            'class_cb24') + "</td><td>" + addCheckbox('class_cb', '冶金白云岩', 'class_cb25') + "</td><td>" + addCheckbox('class_cb', '岩盐', 'class_cb26') + "</td><td>" + addCheckbox('class_cb', '芒硝', 'class_cb27') + "</td><td>" + addCheckbox(
            'class_cb', '钙芒硝', 'class_cb28') + "</td><td>" + addCheckbox('class_cb', '地下水', 'class_cb29') + "</td><td>" + addCheckbox('class_cb', '地下热水', 'class_cb30') + "</td></tr>";
        str += "</table></div></div>";

        showWindow('我的提示框', str, 850, 250, true, ['地区', fun1, '矿种', fun2]);
    }

    function selectAll(obj, oName) {
        var checkboxs = document.getElementsByName(oName);
        for (var i = 0; i < checkboxs.length; i++) {
            checkboxs[i].checked = obj.checked;
        }
    }

    function getStr(cbName) {
        var cbox = document.getElementsByName(cbName);
        var str = "";
        for (var i = 0; i < cbox.length; i++) {
            if (cbox[i].checked) {
                str += "," + cbox[i].value;
            }
        }
        str = str.substr(1);

        return str;
    }

    function fun1() {
        var str = getStr('cities_cb');
        alert('你选择的地区为：' + str);
    }

    function fun2() {
        var str = getStr('class_cb');
        alert('你选择的矿种为：' + str);
    }

    var originLeft;
    $("#toolPage").click(e => {
        if ($("#container").css("margin-left") == "400px") {
            //$("#container").css("float", "none");
            $("#container").animate({
                marginLeft: originLeft
            }, 500);
            //$("#container").css("margin-left", "");
            $("#control").modal('toggle')

        } else {
            originLeft = $("#container").offset().left + "px";
            $("#container").animate({
                marginLeft: "400px"
            }, 500);
            //$("#container").css("float", "left").animate({'left': 0}, 800);;
            //show();
            $('#control').modal({
                backdrop: false,
                keyboard: false,
            }).css({
                width: "360px",
                valign: "top",
                'margin-top': "40px",
                'margin-left': "15px"
            });
        }
    });

    $(".conTab li").click(function () {
        $(".conTab li").eq($(this).index()).addClass("active").siblings().removeClass("active");
        $(".tabCon div").hide().eq($(this).index()).show();
    });
});

$(function () {
    var positions = [
        [
            [0, 0]
        ],
        [
            [],
            []
        ],
        [
            [300, 300],
            [800, 300],
            [550, 100]
        ],
        [
            [],
            [],
            [],
            []
        ],
        [
            [],
            [],
            [],
            [],
            []
        ],
        [
            [],
            [],
            [],
            [],
            [],
            []
        ],
        [
            [],
            [],
            [],
            [],
            [],
            [],
            []
        ],
        [
            [],
            [],
            [],
            [],
            [],
            [],
            [],
            []
        ],
        [
            [],
            [],
            [],
            [],
            [],
            [],
            [],
            [],
            []
        ],
        [
            [],
            [],
            [],
            [],
            [],
            [],
            [],
            [],
            [],
            []
        ],
    ];
    var nodechart = echarts.init(document.getElementById("chartNode"), 'light');
    var linechart = echarts.init(document.getElementById("chartLine"), 'light');
    var nodeopts = {
        title: {
            text: "节点信息",
            textStyle: {
                color: "#2d8cf0"
            }
        },
        tooltip: {
            position: ['0%', '50%']
        },
        toolbox: {
            show: true,
            feature: {
                myAdd: {
                    show: true,
                    title: '添加节点',
                    //icon: 'image://http://echarts.baidu.com/images/favicon.png',
                    icon: 'path://M30.9,53.2C16.8,53.2,5.3,41.7,5.3,27.6S16.8,2,30.9,2C45,2,56.4,13.5,56.4,27.6S45,53.2,30.9,53.2z M30.9,3.5C17.6,3.5,6.8,14.4,6.8,27.6c0,13.3,10.8,24.1,24.101,24.1C44.2,51.7,55,40.9,55,27.6C54.9,14.4,44.1,3.5,30.9,3.5z M36.9,35.8c0,0.601-0.4,1-0.9,1h-1.3c-0.5,0-0.9-0.399-0.9-1V19.5c0-0.6,0.4-1,0.9-1H36c0.5,0,0.9,0.4,0.9,1V35.8z M27.8,35.8 c0,0.601-0.4,1-0.9,1h-1.3c-0.5,0-0.9-0.399-0.9-1V19.5c0-0.6,0.4-1,0.9-1H27c0.5,0,0.9,0.4,0.9,1L27.8,35.8L27.8,35.8z',
                    onclick: function () {
                        alert('myToolHandler1')
                    }
                }
            }
        },
        label: {
            show: true,
            position: 'bottom',
            distance: 5,
            fontSize: 10,
            fontWeight: 'bold'
        },
        animationDurationUpdate: 1500,
        animationEasingUpdate: "quinticInOut",
        coordinateSystem: "cartesian2d",
        series: [{
            type: "graph",
            layout: "none",
            symbolSize: 50,
            roam: false,
            //symbol: "rect",
            label: {
                normal: {
                    show: true
                }
            },
            //edgeSymbol: ["circle"],
            edgeSymbol: ["arrow", "arrow"],
            edgeSymbolSize: [4, 10],
            edgeLabel: {
                normal: {
                    textStyle: {
                        fontSize: 20
                    }
                }
            },
            /*
            itemStyle: {
                color: "#2d8cf0"
            },
            */
            data: [],
            /*
             data: [{
                 name: '172.16.201.191:8546',
                 x: 300,
                 y: 300
                 tooltip: "AAA<br>BBB",
                 
                 tooltip: {
                     formatter: function (peer, ticket, callback) {
                         return peer;
                     }
                 }
                 
             }, {
                 name: '172.16.201.192:8546',
                 x: 800,
                 y: 300
             }, {
                 name: '172.16.201.193:8546',
                 x: 550,
                 y: 100
             }],
             */
            links: [],
            /*
            links: [{
                source: '172.16.201.191:8546',
                target: '172.16.201.192:8546'
            }, {
                source: '172.16.201.191:8546',
                target: '172.16.201.193:8546'
            }, {
                source: '172.16.201.192:8546',
                target: '172.16.201.193:8546'
            }, {
                source: '172.16.201.192:8546',
                target: '172.16.201.191:8546'
            }, {
                source: '172.16.201.193:8546',
                target: '172.16.201.191:8546'
            }, {
                source: '172.16.201.193:8546',
                target: '172.16.201.192:8546'
            }],
            */
            lineStyle: {
                normal: {
                    opacity: 0.6,
                    curveness: 0,
                    width: 5,
                    //color: '#7CFC00',
                    color: '#2d8cf0',
                    type: 'dashed'
                }
            }
        }]
    };
    var lineopts = {
        title: {
            text: "交易走势图",
            textStyle: {
                color: "#2d8cf0"
            }
        },
        tooltip: {
            trigger: 'axis',
            axisPointer: {
                type: 'cross',
                label: {
                    backgroundColor: '#283b56'
                }
            }
        },
        legend: {
            data: ['交易数量', '区块数量']
        },
        toolbox: {
            show: true,
            feature: {
                dataView: {
                    readOnly: false
                },
                //restore: {},
                mySwitch: {
                    show: true,
                    title: '模式切换',
                    //icon: 'image://http://echarts.baidu.com/images/favicon.png',
                    icon: 'path://M432.45,595.444c0,2.177-4.661,6.82-11.305,6.82c-6.475,0-11.306-4.567-11.306-6.82s4.852-6.812,11.306-6.812C427.841,588.632,432.452,593.191,432.45,595.444L432.45,595.444z M421.155,589.876c-3.009,0-5.448,2.495-5.448,5.572s2.439,5.572,5.448,5.572c3.01,0,5.449-2.495,5.449-5.572C426.604,592.371,424.165,589.876,421.155,589.876L421.155,589.876z M421.146,591.891c-1.916,0-3.47,1.589-3.47,3.549c0,1.959,1.554,3.548,3.47,3.548s3.469-1.589,3.469-3.548C424.614,593.479,423.062,591.891,421.146,591.891L421.146,591.891zM421.146,591.891',
                    onclick: function () {
                        var tp = document.getElementById("chartLine").getAttribute('tp');
                        if (tp == null) {
                            tp = '定时模式';
                        } else if (tp == '定时模式') {
                            tp = '实时模式';
                        } else if (tp == '实时模式') {
                            tp = '样本模式';
                        } else if (tp == '样本模式') {
                            tp = '定时模式';
                        }
                        document.getElementById("chartLine").setAttribute('tp', tp);
                    }
                },
                saveAsImage: {}
            }
        },
        dataZoom: {
            show: false,
            start: 0,
            end: 100
        },
        xAxis: [{
                type: 'category',
                boundaryGap: true,
                data: (function () {
                    //var now = new Date();
                    var res = [];
                    var len = 10;
                    while (len--) {
                        res.unshift(new Date().toLocaleTimeString('chinese', {
                            hour12: false
                        }).replace(/^\D*/, ''));
                        //now = new Date(now - 2000);
                    }
                    return res;
                })()
            },
            {
                type: 'category',
                boundaryGap: true,
                data: (function () {
                    //var now = new Date();
                    var res = [];
                    var len = 10;
                    while (len--) {
                        res.unshift(new Date().toLocaleDateString('chinese', {
                            hour12: false
                        }));
                        //now = new Date(now - 2000);
                    }
                    /*
                    while (len--) {
                        res.push(10 - len - 1);
                    }
                    */
                    return res;
                })()
            }
        ],
        yAxis: [{
                type: 'value',
                scale: true,
                name: '区块量',
                minInterval: 1,
                boundaryGap: [0, 0.1],
                /*
                max: 30,
                min: 0,
                boundaryGap: [0.2, 0.2]
                */
            },
            {
                type: 'value',
                scale: true,
                name: '交易量',
                minInterval: 1,
                boundaryGap: [0, 0.1],
                /*
                max: 1200,
                min: 0,
                boundaryGap: [0.2, 0.2]
                */
            }
        ],
        series: [{
                name: '交易数量',
                type: 'bar',
                xAxisIndex: 1,
                yAxisIndex: 1,
                data: (function () {
                    var res = [];
                    var len = 10;
                    while (len--) {
                        res.push(Math.round(Math.random() * 1000));
                    }
                    return res;
                })()
            },
            {
                name: '区块数量',
                type: 'line',
                itemStyle: {
                    normal: {
                        color: "#c23531",
                        lineStyle: {
                            color: "#c23531"
                        }
                    }
                },
                data: (function () {
                    var res = [];
                    var len = 0;
                    while (len < 10) {
                        res.push((Math.random() * 10 + 5).toFixed(1) - 0);
                        len++;
                    }
                    return res;
                })()
            }
        ]
    }
    document.getElementById("chartLine").setAttribute('tp', '定时模式');

    window.onresize = function () {
        //重置容器高宽
        nodechart.resize();
        linechart.resize();
    };

    var numRun1 = $(".numberRun1").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ""
    });
    var numRun2 = $(".numberRun2").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ""
    });
    var numRun3 = $(".numberRun3").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ""
    });
    var numRun4 = $(".numberRun4").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ""
    });
    var numRun5 = $(".numberRun5").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ""
    });
    var numRun6 = $(".numberRun6").numberAnimate({
        num: '0',
        speed: 1000,
        symbol: ""
    });
    var mio = io.connect('http://172.16.201.189:8000/mio');
    //		 	区块信息

    mio.on('view_chainInfo', function (data) {
        //console.log(data.msg);
        numRun1.resetData(data.msg.blockNumber);
        numRun2.resetData(data.msg.uncleCount);
        numRun3.resetData(data.msg.transactionCount);
        numRun4.resetData(data.msg.addressCount);
        var peers = data.msg.peers;
        var keys = Object.keys(peers);
        var nodes = [];
        var links = [];
        keys.forEach(i => {
            //console.log(keys.length);
            nodes.push({
                name: peers[i].ippt,
                symbol: "image://./refs/img/server.png",
                //x: 0 + 100 * keys.indexOf(i),
                //y: 0 + 100 * keys.indexOf(i),
                x: positions[keys.length - 1][keys.indexOf(i)][0],
                y: positions[keys.length - 1][keys.indexOf(i)][1],
                itemStyle: {
                    color: "#2d8cf0"
                    //color: 'red'
                },
                label: {
                    color: "#2d8cf0"
                },
                tooltip: "ID:" + peers[i].id + "<br>" + "IPPT:" + peers[i].ippt + "<br>" + "client:" + peers[i].cli + "<br>" + "coinbase:" + peers[i].coinbase + "<br>" + "accounts:" + peers[i].accounts
            })
        });

        for (var i = 0; i < keys.length; i++) {
            for (var j = i + 1; j < keys.length; j++) {
                links.push({
                    source: keys[i],
                    target: keys[j]
                });
                links.push({
                    source: keys[j],
                    target: keys[i]
                });
            }
        };

        nodeopts.series[0].data = nodes;
        nodeopts.series[0].links = links;

        nodechart.setOption(nodeopts);
        //console.log(nodeopts.series[0].data);

        /*
        window.onresize = function () {
            //重置容器高宽
            nodechart.resize();
        };
        */
    });

    //节点状态
    mio.on('view_peerStatus', function (data) {
        for (var i in nodeopts.series[0].data) {
            if (nodeopts.series[0].data[i].name === data.msg.peer) {
                if (data.msg.status === "normal") {
                    nodeopts.series[0].data[i].itemStyle = {
                        color: "#2d8cf0"
                    };
                    nodeopts.series[0].data[i].label = {
                        color: "#2d8cf0"
                    };
                } else if (data.msg.status === "syncing") {
                    nodeopts.series[0].data[i].itemStyle = {
                        color: "#fbb900"
                    };
                    nodeopts.series[0].data[i].label = {
                        color: "#fbb900"
                    };
                } else {
                    //console.log(node);
                    nodeopts.series[0].data[i].itemStyle = {
                        color: "red"
                    };
                    nodeopts.series[0].data[i].label = {
                        color: "red"
                    };
                }
            }
        }
        nodechart.setOption(nodeopts);
        /*
        window.onresize = function () {
            //重置容器高宽
            nodechart.resize();
        };
        */
    });

    //		交易走势图
    mio.emit('getChainInfo', "");
    var cbn = -1;
    var ctn = -1;

    mio.on('get_chainInfo', function (data) {
        if (cbn === -1 && ctn === -1) {
            cbn = data.msg.blockNumber;
            ctn = data.msg.transactionCount;
        }
        /*
        var lineopts = {
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
        */
        var date = new Date();
        var tp = document.getElementById("chartLine").getAttribute('tp');
        //console.log(tp);
        //console.log(date.toLocaleTimeString());

        var data0 = lineopts.series[0].data;
        var data1 = lineopts.series[1].data;
        data0.shift();
        data1.shift();
        if (tp == '定时模式' || tp == null) {
            data0.push(data.msg.transactionCount - ctn);
            data1.push(data.msg.blockNumber - cbn);
        } else if (tp == '样本模式' || tp == '实时模式') {
            data0.push(Math.round(Math.random() * 1000));
            data1.push((Math.random() * 10 + 5).toFixed(1) - 0);
        }

        //data0.push(Math.round(Math.random() * 1000));


        //data1.push((Math.random() * 10 + 5).toFixed(1) - 0);

        lineopts.xAxis[0].data.shift();
        lineopts.xAxis[0].data.push(date.toLocaleTimeString('chinese', {
            hour12: false
        }).replace(/^\D*/, ''));
        lineopts.xAxis[1].data.shift();
        lineopts.xAxis[1].data.push(date.toLocaleDateString('chinese', {
            hour12: false
        }));
        //lineopts.xAxis[1].data.push(app.count++);

        linechart.setOption(lineopts);
        /*
        window.onresize = function () {
            //重置容器高宽
            chart.resize();
        };
        */
        cbn = data.msg.blockNumber;
        ctn = data.msg.transactionCount;
    });
    setInterval(function () {
        mio.emit('getChainInfo', "");
    }, 2000);


    //五个块信息
    mio.on('view_blocks', function (data) {
        $(".chain_tbody").empty();
        if (data.msg.length == 0) {
            $(".chain_tbody").append("暂无区块产生");
        } else {
            //$(".chain_tbody").append("<li></li>");
            for (var i = data.msg.length - 1; i >= 0; i--) {
                (function (i) {
                    var blk = "<li class='clearfix'>" +
                        "<div class='block_box col-sm-4'>" +
                        "<p>block:" + data.msg[i].number + "</p>" +
                        "<p><em>区块大小:</em>" + data.msg[i].size + "</p>" +
                        "<p>" + new Date(data.msg[i].timestamp * 1000).toLocaleString('chinese', {
                            hour12: false
                        }) + "</p>" +
                        "</div>" +
                        "<div class='col-sm-8'>" +
                        "<p><em>交易数量:</em>" + data.msg[i].transactions.length + "</p>" +
                        "<p><em>打包节点:</em>" + data.msg[i].signer + "</p>" +
                        "<p><em>区块Hash:</em><span class='strong'>" + data.msg[i].hash + "</span></p>" +
                        "</div></li>";
                    if ($('.chain_tbody').children('li').length == 0) {
                        $(".chain_tbody").append(blk);
                    } else {
                        $('.chain_tbody').magicMove({
                                easing: 'ease',
                                duration: 300
                            },
                            function () {
                                $(this).prepend(blk);
                            }
                        );
                    }
                })(i);
            }
        }
    });

    //五个交易信息
    mio.on('view_transactions', function (data) {
        $(".trade_tbody").empty();
        if (data.msg.length == 0) {
            $(".trade_tbody").append("暂无交易产生")
        } else {
            for (var i = data.msg.length - 1; i >= 0; i--) {
                (function (i) {
                    var sdiv = "";
                    var dclass = "item_trade";
                    if (data.msg[i].status) {
                        dclass += ' trade_succ';
                    } else {
                        dclass += ' trade_fail'
                    }
                    if (data.msg[i].contractAddress == null) {
                        sdiv = "";
                    } else {
                        dclass += ' zsign';
                        sdiv = "<div class='sign ok' style='height:" + 60 + "px;width:" + 60 + "px;top:" + 10 + "px;left:" + 220 + "px'><img src='" + "./refs/img/signet.png" + "' draggable='false'/></div>";
                    }
                    var tx = "<li class='clearfix none'>" +
                        "<div class='" + dclass + "'>" +
                        "<p><em>交易节点:</em><span>" + data.msg[i].peer + "</span><em>交易Hash:</em><span>" + data.msg[i].hash + "</span></p>" +
                        "<p><em>发起者:</em><span>" + data.msg[i].from + "</span><em>受益者:</em><span>" + data.msg[i].to + "</span></p>" +
                        "<p><em>块序号:</em><span>" + data.msg[i].blockNumber + "/" + data.msg[i].transactionIndex + "/" + data.msg[i].nonce + "</span><em>交易额:</em><span>" + data.msg[i].value + "</span></p>" + sdiv +
                        "</div></li>";
                    if ($('.trade_tbody').children('li').length == 0) {
                        $(".trade_tbody").append(tx);
                    } else {
                        $('.trade_tbody').magicMove({
                                easing: 'ease',
                                duration: 300
                            },
                            function () {
                                $(this).prepend(tx);
                            }
                        );
                    }
                })(i);
            }
        }
    });

    //交易池状态		 
    mio.on('view_txpoolStatus', function (data) {
        /*
        numRun5 = $(".numberRun5").numberAnimate({
            num: '0',
            speed: 1000,
            symbol: ","
        });
        numRun6 = $(".numberRun6").numberAnimate({
            num: '0',
            speed: 1000,
            symbol: ","
        });
        */
        numRun5.resetData(data.msg.pending);
        numRun6.resetData(data.msg.queued);
    });

    //新增交易		 
    mio.on('view_pendingTransaction', function (data) {
        numRun5.resetData(1);
        nodeopts.series[0].data.forEach(node => {
            if (node.name == data.msg.peer) {
                var pos = nodechart.convertToPixel({
                    seriesIndex: 0
                }, [node.x, node.y]);
                var top = $("#chartNode").offset().top;
                var left = $("#chartNode").offset().left;
                //console.log("canvas:", left, top);
                show(pos[0] + left, pos[1] + top, "交易");
            }
        });
    });

    //产生块时增加一条
    mio.on('view_block', function (data) {
        //console.log(data)
        nodeopts.series[0].data.forEach(node => {
            if (node.name == data.msg.block.signer) {
                var pos = nodechart.convertToPixel({
                    seriesIndex: 0
                }, [node.x, node.y]);
                var top = $("#chartNode").offset().top;
                var left = $("#chartNode").offset().left;
                //console.log("canvas:", left, top);
                show(pos[0] + left, pos[1] + top, "区块");
            }
        });
        //console.log(data.msg.block)

        var blk = "<li class='clearfix none'>" +
            "<div class='block_box col-sm-4'>" +
            "<p>block:" + data.msg.block.number + "</p>" +
            "<p><em>区块大小:</em>" + data.msg.block.size + "</p>" +
            "<p>" + new Date(data.msg.block.timestamp * 1000).toLocaleString('chinese', {
                hour12: false
            }) + "</p>" +
            "</div>" +
            "<div class='col-sm-8'>" +
            "<p><em>交易数量:</em>" + data.msg.block.transactions.length + "</p>" +
            "<p><em>打包节点:</em>" + data.msg.block.signer + "</p>" +
            "<p><em>区块Hash:</em><span class='strong'>" + data.msg.block.hash + "</span></p>" +
            "</div></li>";
        $('.chain_tbody').magicMove({
                easing: 'ease',
                duration: 500
            },
            function () {
                if ($(this).children('li').length == 5) {
                    $(this).find('li:last').remove();
                }
                if ($(this).children('li').length == 0) {
                    $(this).append(blk);
                } else {
                    $(this).prepend(blk);
                    /*
                    if ($(this).children('li').length == 0) {
                        $(this).prepend(tr);
                    } else {
                        $(this).find('li:first').before(tr);
                    }
                    //$(this).find('li:first').before($el);
                    */
                }
            }
        );
        /*
        $(".chain_tbody").find("li:last-child").slideUp(500, function () {
            $(this).remove();
            $(".chain_tbody").prepend(tr)
            $(".chain_tbody").find("li:first-child").slideDown(500);
        })
        */
        for (var i = data.msg.txs.length - 1; i >= 0; i--) {
            (function (i) {
                //console.log(data.msg.txs[i]);
                var sdiv = "";
                var dclass = "item_trade";
                if (data.msg.txs[i].status) {
                    dclass += ' trade_succ';
                } else {
                    dclass += ' trade_fail'
                }
                if (data.msg.txs[i].contractAddress == null) {
                    sdiv = "";
                } else {
                    dclass += ' zsign';
                    sdiv = "<div class='sign ok' style='height:" + 60 + "px;width:" + 60 + "px;top:" + 10 + "px;left:" + 220 + "px'><img src='" + "./refs/img/signet.png" + "' draggable='false'/></div>";
                }

                var tx = "<li class='clearfix none'>" +
                    "<div class='" + dclass + "'>" +
                    "<p><em>交易节点:</em><span>" + data.msg.txs[i].peer + "</span><em>交易Hash:</em><span>" + data.msg.txs[i].hash + "</span></p>" +
                    "<p><em>发起者:</em><span>" + data.msg.txs[i].from + "</span><em>受益者:</em><span>" + data.msg.txs[i].to + "</span></p>" +
                    "<p><em>块序号:</em><span>" + data.msg.txs[i].blockNumber + "/" + data.msg.txs[i].transactionIndex + "/" + data.msg.txs[i].nonce + "</span><em>交易额:</em><span>" + data.msg.txs[i].value + "</span></p>" + sdiv +
                    "</div></li>";
                $('.trade_tbody').magicMove({
                        easing: 'ease',
                        duration: 500
                    },
                    function () {
                        if ($(this).children('li').length == 5) {
                            $(this).find('li:last').remove();
                        }
                        if ($(this).children('li').length == 0) {
                            $(this).append(tx);
                        } else {
                            $(this).prepend(tx);
                            /*
                            if ($(this).children('li').length == 0) {
                                $(this).prepend(trs);
                            } else {
                                $(this).find('li:first').before(trs);
                            }
                            //$(this).find('li:first').before($el);
                            */
                        }
                        /*
                        $(".trade_tbody").find('.item_trade').zSign({
                            img: './refs/img/signet.gif',
                            signit: true,
                            offsetx: 100
                        });
                        */
                    }
                );

                /*
                $(".trade_tbody").find(".item_trade:last-child").slideUp(500, function () {
                    $(this).remove();
                    $(".trade_tbody").prepend(trs)
                    $(".trade_tbody").find(".item_trade:first-child").slideDown(500);
                })
                */
            })(i);
        }
    });



    /*
    $("body").click(function () {
        $("body").zSign({
            img: './refs/img/prize.png',
            signit: false,
            offsetx: 200,
            offsety: 10
        });
        console.log('aaa')

    })
    */

});