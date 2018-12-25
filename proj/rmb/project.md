# 项目备忘

## 开发测试环境

|  主机名  |       用途       |    IP地址    | 账号口令  | 防火墙 |              开放端口              | 备注 |
|:--------:|:----------------:|:------------:|:---------:|:------:|:----------------------------------:|:----:|
|   chp    |  陈盼开发测试机  | 192.168.0.90 | root/root |  关闭  |               22/ssh               |      |
|   zhlg   | 赵立刚开发测试机 | 192.168.0.91 | root/root |  关闭  |               22/ssh               |      |
|   cxf    | 蔡小凡开发测试机 | 192.168.0.92 | root/root |  关闭  |               22/ssh               |      |
| ethnodea |   区块链节点A    | 192.168.0.93 | root/root |  关闭  | 22/ssh, 8545/rpc-http, 8546/rpc-ws |      |
| ethnodeb |   区块链节点B    | 192.168.0.94 | root/root |  关闭  | 22/ssh, 8545/rpc-http, 8546/rpc-ws |      |
| ethnodec |   区块链节点C    | 192.168.0.95 | root/root |  关闭  | 22/ssh, 8545/rpc-http, 8546/rpc-ws |      |
|  mongoa  | 缓存数据库节点A  | 192.168.0.98 | root/root |  关闭  |        22/ssh, 27017/mongod        |      |

## 区块链

### 合约

合约地址和abi在cinfo.json文件中, 合约源码为Exchange.sol

### API

相关调用接口在智能合约功能接口说明书中

### 数据

从第290块以后的数据为当前合约存储的数据

### 其他

demo.py为使用web3.py进行合约相关功能调用的demo程序, Token.png和Record.png为Token和Record的字段, Architecture.png为逻辑架构图

## MongoDB

### 账号

root账号: root / root
管理账号: admin/admin
测试账号: rmber/rmber

### 数据库

数据库名: rmb (rmber账号拥有读写权)
集合名: token(存储Token信息), record(存储交易记录)

启动数据库服务:
mongod --auth --bind_ip_all --port 27017 --fork --dbpath /data --logpath /root/mongod.log

登录数据库后台:
mongo --port 27017 -u "rmber" -p "rmber" --authenticationDatabase "rmb"

关闭后台服务:
> use admin
> db.shutdownServer()
