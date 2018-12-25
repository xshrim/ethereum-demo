package main

import (
	"context"
	"crypto/ecdsa"
	"encoding/hex"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"math/big"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/common/hexutil"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common/compiler"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto/sha3"

	"./store"

	"github.com/ethereum/go-ethereum/accounts"
	"github.com/ethereum/go-ethereum/common"

	"github.com/ethereum/go-ethereum/accounts/keystore"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/rpc"
)

/*
geth --identity "myeth" --networkid 111 --nodiscover --maxpeers 10 --port "30303" --syncmode=full --gcmode=archive --gasprice=1 --dev --dev.period=0 --targetgaslimit=471238800  --rpc --rpcapi "db,eth,net,shh,web3,personal,miner,admin,debug,txpool" --rpcaddr 0.0.0.0 --rpcport "8545" --ws --wsaddr 0.0.0.0 --wsorigins=* --wsapi "db,eth,net,shh,web3,personal,miner,admin,debug" --wsport "8546" --extradata="myeth/127.0.0.1:8546" --datadir "/home/xshrim/lab/ethgo/eth" console

abigen --abi Store.abi --bin Store.bin --type Store --pkg store --out Store.go   (> Store.go)
abigen --sol Store.sol --pkg store --out Store.go                                (> Store.go)

solc --abi --bin Store.sol -o ./
abigen --bin=Store.bin --abi=Store.abi --type Store --pkg=store --out=Store.g   (> Store.go)

python3 tool.py -d -u ws://127.0.0.1:8546 -f Store.sol -o Store.json -a go                             # for golang
python3 tool.py -d -u ws://127.0.0.1:8546 -f Store.sol -o Store.json -a com.your.organisation.name     # for java

curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":6}' http://127.0.0.1:8545
*/

// 数据类型转换(将数字,字符串数字或者字符串转换为不以0x0开头的十六进制字符串)
func numToStr(value interface{}) (string, error) {
	var v string
	switch value.(type) {
	case int8:
		v = "0x" + hex.EncodeToString(big.NewInt(int64(value.(int8))).Bytes())
	case int:
		v = "0x" + hex.EncodeToString(big.NewInt(int64(value.(int))).Bytes())
	case int16:
		v = "0x" + hex.EncodeToString(big.NewInt(int64(value.(int16))).Bytes())
	case int32:
		v = "0x" + hex.EncodeToString(big.NewInt(int64(value.(int32))).Bytes())
	case int64:
		v = "0x" + hex.EncodeToString(big.NewInt(value.(int64)).Bytes())
	case *big.Int:
		v = "0x" + hex.EncodeToString(value.(*big.Int).Bytes())
	case string:
		if value.(string)[:2] != "0x" {
			if tmpv, bl := new(big.Int).SetString(value.(string), 10); bl {
				v = "0x" + hex.EncodeToString(tmpv.Bytes())
			} else {
				return "0x" + hex.EncodeToString([]byte(value.(string))), errors.New("string")
			}
			/*
				tmpv, err := strconv.ParseInt(value.(string), 10, 64)
				if err != nil {
					v = "0x" + hex.EncodeToString([]byte(value.(string)))
				} else {
					v = "0x" + hex.EncodeToString(big.NewInt(tmpv).Bytes())
				}
			*/
		}
	default:
		return "", errors.New("unsuitable arg type")
	}

	for v[:3] == "0x0" {
		v = strings.Replace(v, "0x0", "0x", -1)
	}
	return v, nil
}

func ethToWeiStr(v string) (string, error) {

	tmpv, err := strconv.ParseInt(v, 10, 64)
	if err != nil {
		return "", err
	}
	res := new(big.Int).Mul(big.NewInt(tmpv), big.NewInt(1000000000000000000))
	return res.String(), nil
}

func parseMethod(method string) []string {
	reg := regexp.MustCompile(`(?s)\((.*)\)`)
	args := reg.FindAllStringSubmatch(method, -1)[0][1]
	args = strings.Replace(args, " ", "", -1)
	return strings.Split(args, ",")
}

func generateData(method string, args ...interface{}) string {
	transferFnSignature := []byte(method)
	hash := sha3.NewKeccak256()
	hash.Write(transferFnSignature)
	methodID := hash.Sum(nil)[:4]

	argArr := parseMethod(method)
	fmt.Println(len(argArr))
	// fmt.Println(hexutil.Encode(methodID))

	/*
		paddedAddress := common.LeftPadBytes(common.HexToAddress(addr).Bytes(), 32)
		fmt.Println(hexutil.Encode(paddedAddress))

		amount := new(big.Int)
		amount.SetString(value, 10)
		paddedAmount := common.LeftPadBytes(amount.Bytes(), 32)
		fmt.Println(hexutil.Encode(paddedAmount))

		var data []byte
		data = append(data, methodID...)
		data = append(data, paddedAddress...)
		data = append(data, paddedAmount...)
	*/

	var data []byte

	data = append(data, methodID...)

	for _, arg := range args {
		var paddedArg []byte
		switch arg.(type) {
		case [32]byte:
			tmpv := arg.([32]byte)
			paddedArg = tmpv[:]
		case string:
			paddedArg = common.RightPadBytes([]byte(arg.(string)), 32)
		case []byte:
			paddedArg = arg.([]byte)
		}
		data = append(data, paddedArg...)
	}

	// return hex.EncodeToString(data)
	return hexutil.Encode(data)

}

// 编译合约
func compileContract(sourceFiles ...string) (map[string]*compiler.Contract, error) {
	res, err := compiler.CompileSolidity("", sourceFiles...) // use default compiler (env), support multiple solidity file (...string)
	if err != nil {
		return nil, err
	}
	for k, v := range res {
		fmt.Println(k)                                              // contractPath:contractName
		fmt.Println(v.Code)                                         // contract bytecode (for deploy)
		fmt.Println(v.Info.CompilerOptions, v.Info.CompilerVersion) // compiler info
		fmt.Println(v.Info.Source)                                  // contract source code
		fmt.Println(v.Info.AbiDefinition)                           // contract abi (for invoke)
	}
	return res, nil
}

// 获取rpc client
func getClientRpc(url string) (*rpc.Client, error) {
	return rpc.Dial(url)
}

// 获取ethclient
func getClientEth(url string) (*ethclient.Client, error) {
	return ethclient.Dial(url)
}

// 获取私钥
func getPrivateKey(path, addr, passwd string) string {

	// Method A
	/*
			file := "/home/xshrim/lab/ethgo/eth/keystore/UTC--2018-12-07T03-00-43.898785053Z--53df1f54169fcc6e9eac26cc1c55c075092e1972"
			password := "test"

			keyjson, err := ioutil.ReadFile(file)

			key, err := keystore.DecryptKey(keyjson, password)

			if err != nil {
				log.Fatal(err)
			}

			fmt.Println(key.PrivateKey.D.Bytes())
			fmt.Println(crypto.FromECDSA(key.PrivateKey))

		    hexPrivateKey := hex.EncodeToString(crypto.FromECDSA(key.PrivateKey))
	*/

	// Medthod B
	/*
			account := common.HexToAddress("53df1f54169fcc6e9eac26cc1c55c075092e1972")

			act := &accounts.Account{Address: account, URL: accounts.URL{Scheme: "", Path: ""}}

			ks := keystore.NewKeyStore("/home/xshrim/lab/ethgo/eth/keystore", keystore.StandardScryptN, keystore.StandardScryptP)
			js, err := ks.Export(*act, "test", "test")

			k, err := keystore.DecryptKey(js, "test")

			if err != nil {
				log.Fatal(err)
			}

		    hexPrivateKey := hex.EncodeToString(crypto.FromECDSA(k.PrivateKey))
	*/

	var hexPrivateKey string
	ks := keystore.NewKeyStore(path, keystore.StandardScryptN, keystore.StandardScryptP)
	for _, acc := range ks.Accounts() {
		if strings.ToLower(acc.Address.String()) == strings.ToLower(addr) {
			keyjson, err := ioutil.ReadFile(acc.URL.Path)
			key, err := keystore.DecryptKey(keyjson, passwd)
			if err != nil {
				return ""
			}
			hexPrivateKey = hex.EncodeToString(crypto.FromECDSA(key.PrivateKey))
			break
		}
	}

	return hexPrivateKey
	//common.HexToAddress()

}

// 通过rpc获取账号地址列表
func getAccountsRpc(client *rpc.Client) ([]string, error) {
	var accounts []string
	err := client.Call(&accounts, "eth_accounts")
	return accounts, err
}

// 通过ethclient获取账号地址列表
func getAccountsEth(client *ethclient.Client, path string) ([]accounts.Account, error) {
	ks := keystore.NewKeyStore(path, keystore.StandardScryptN, keystore.StandardScryptP)
	return ks.Accounts(), nil
}

// 通过rpc获取地址余额
func getBalanceRpc(client *rpc.Client, addr string) (*big.Int, error) {
	var res string
	err := client.Call(&res, "eth_getBalance", addr, "latest")
	if err != nil {
		return nil, err
	}

	/*
		if balance, ok := new(big.Int).SetString(res[2:], 16); ok {
			return balance, nil
		} else {
			return nil, errors.New("err")
		}
	*/

	balance, err := hexutil.DecodeBig(res)
	return balance, err

}

func getBalanceEth(client *ethclient.Client, addr string) (*big.Int, error) {
	account := common.HexToAddress(addr)
	balance, err := client.BalanceAt(context.Background(), account, nil)
	if err != nil {
		return nil, err
	}

	return balance, nil
}

// 通过ethclient获取合约实例
func getInstanceEth(client *ethclient.Client, caddr string) (*store.Store, error) {
	address := common.HexToAddress("0x8cF6FDdf1b1537762E6bE4e0eE77157Fb054E1Af") // contract address
	instance, err := store.NewStore(address, client)                             // new contract instance
	if err != nil {
		return nil, err
	}
	return instance, nil
}

// 通过ethclient调用合约方法
func getContractVersionEth(instance *store.Store, method string) (string, error) {
	var version string
	var err error
	switch method {
	case "pub": // version is a public variable
		version, err = instance.Version(nil)
		if err != nil {
			return "", err
		}
	case "func": // use function in store.go
		copts := &bind.CallOpts{Pending: false, From: common.HexToAddress("0x3df06e0818a07f195295f73fcfde7bc3c66b27c9"), Context: context.Background()}

		version, err = instance.GetVersion(copts) // CallOpts could be nil
		if err != nil {
			return "", err
		}
	case "raw": //use raw function in contract, like rpc
		copts := &bind.CallOpts{Pending: false, From: common.HexToAddress("0x3df06e0818a07f195295f73fcfde7bc3c66b27c9"), Context: context.Background()}
		storeraw := &store.StoreRaw{Contract: instance}
		err = storeraw.Call(copts, &version, "getVersion") // CallOpts could be nil
		if err != nil {
			return "", err
		}
	}
	return version, nil

}

// 通过RPC调用合约方法(to为合约地址, data为pack合约方法和参数后得到的十六进制字符串)
func callRpc(from, to, data string, client *rpc.Client) (string, error) {
	type T struct {
		From string
		To   string
		Data string
	}

	/*
		if data[:2] != "0x" {
			data = "0x" + data
		}

		for data[:3] == "0x0" {
			data = strings.Replace(data, "0x0", "0x", -1)
		}
	*/

	trans := T{From: from, To: to, Data: data}

	var ret string
	err := client.Call(&ret, "eth_call", trans, "latest")
	if err != nil {
		return "", err
	}

	res, err := hexutil.Decode(ret)

	return string(res), nil
}

// 通过BoundContract调用合约方法(BoundContract不依赖合约生成的go文件)
func callBC(bc *bind.BoundContract, from, method string, params ...interface{}) (string, error) {
	var res interface{}
	var ret string
	copts := &bind.CallOpts{Pending: false, From: common.HexToAddress(from), Context: context.Background()}
	err := bc.Call(copts, &res, method, params...)
	if err != nil {
		return "", err
	}
	switch res.(type) {
	case [32]byte:
		v := res.([32]byte)
		ret = string(v[:])
	case string:
		ret = res.(string)
	default:
		ret = ""
	}

	return ret, nil
}

// 获取通用合约实例
func getBoundContract(caddr string, abiStr string, client *ethclient.Client) (*bind.BoundContract, *abi.ABI, error) {
	address := common.HexToAddress(caddr)
	parsed, err := abi.JSON(strings.NewReader(abiStr))
	if err != nil {
		return nil, nil, err
	}
	return bind.NewBoundContract(address, parsed, client, client, client), &parsed, nil // return contract, abi
}

// 解锁区块链账号(需要使用管理api)
func unlockAccountRpc(addr, passwd string, duration int, client *rpc.Client) bool {

	var res bool
	err := client.Call(&res, "personal_unlockAccount", addr, passwd, duration) // duration 单位是秒, 为0表示永久解锁
	if err != nil {
		err = client.Call(&res, "personal_unlockAccount", addr, "", duration) // duration 单位是秒, 为0表示永久解锁
		if err != nil {
			return false
		}
	}
	return res
}

// 通过RPC API发送以太币
func transferRpc(from, to, value, passwd string, client *rpc.Client) (string, error) {
	var res string
	/* rpc调用的参数均是十六进制的string类型或者byte切片
	// types包中存在NewMessage函数和Message结构体, 可以直接使用, 但未来会被移除, 所以不推荐使用
	// sendTransaction的参数中, Gas, GasPrice, Value, Data, Nonce和To(交易为部署合约时)均是可选的, 不在参数结构体中定义时, 其值会自动计算, 如果在结构体中定义, 则初始化结构体时必须为参数指定合适的值(如Gas值), 否则交易失败
	// 发起交易前, from 账号必须是已经unlock的, dev模式下coinbase(即account[0])总是unlock的
		type T struct {
			From     string
			To       string
			Gas      string
			GasPrice string
			Value    string
			Data     []byte
			Nonce    string
		}
	*/
	type T struct {
		From  string
		To    string
		Value string
	}
	if !unlockAccountRpc(from, passwd, 60, client) {
		return "", errors.New("unlock accont faild")
	}
	value, err := numToStr(value)
	if err != nil {
		return "", err
	}

	// v := hexutil.EncodeUint64()
	// v := hexutil.EncodeBig()

	trans := T{From: from, To: to, Value: value}
	err = client.Call(&res, "eth_sendTransaction", trans)
	if err != nil {
		return "", err
	}
	return res, nil
	//types.NewTransaction()
	/*
		err := client.Call(&res, "eth_getBalance", addr, "latest")
		if err != nil {
			return nil, err
		}
		if balance, ok := new(big.Int).SetString(res[2:], 16); ok {
			return balance, nil
		} else {
			return nil, errors.New("err")
		}
	*/
}

// 直接使用RPC API中的管理API发送以太币(其实是将解锁账号和发送交易合二为一了)
func transferV2Rpc(from, to, value, passwd string, client *rpc.Client) (string, error) {
	var res string
	/* rpc调用的参数均是十六进制的string类型或者byte切片
	// types包中存在NewMessage函数和Message结构体, 可以直接使用, 但未来会被移除, 所以不推荐使用
	// sendTransaction的参数中, Gas, GasPrice, Value, Data, Nonce和To(交易为部署合约时)均是可选的, 不在参数结构体中定义时, 其值会自动计算, 如果在结构体中定义, 则初始化结构体时必须为参数指定合适的值(如Gas值), 否则交易失败
	// 发起交易前, from 账号必须是已经unlock的, dev模式下coinbase(即account[0])总是unlock的
		type T struct {
			From     string
			To       string
			Gas      string
			GasPrice string
			Value    string
			Data     []byte
			Nonce    string
		}
	*/
	type T struct {
		From  string
		To    string
		Value string
	}
	value, err := numToStr(value)
	if err != nil {
		return "", err
	}

	// v := hexutil.EncodeUint64()
	// v := hexutil.EncodeBig()

	trans := T{From: from, To: to, Value: value}
	err = client.Call(&res, "personal_sendTransaction", trans, passwd)
	if err != nil {
		return "", err
	}
	return res, nil
}

// 通过ethclient发送以太币(需要提供发送者私钥)
func transferEth(pkey, to, value string, client *ethclient.Client) (string, error) {
	privateKey, err := crypto.HexToECDSA(pkey)
	if err != nil {
		return "", errors.New("invalid private key")
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return "", errors.New("invalid public key")
	}

	fromAddr := crypto.PubkeyToAddress(*publicKeyECDSA)

	nonce, err := client.PendingNonceAt(context.Background(), fromAddr)
	if err != nil {
		return "", err
	}

	v, ok := new(big.Int).SetString(value, 10)
	if !ok {
		return "", errors.New("invalid value")
	}

	// v, err := hexutil.EncodeBig(value)

	gasLimit := uint64(210000)
	// gasPrice := big.NewInt(30000000000)
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		return "", err
	}

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		return "", err
	}
	fmt.Println(chainID)
	chainID = big.NewInt(1337)
	// chainID用于防止重放攻击, 该值关系到签名值, 错误的chainID将导致from的私钥无法完成验签
	// dev 模式下源码中已写死其chainID为1337, 通过client.NetworkID获取到的是NetworkID, NetorkID在命令行中通过--networkid指定

	toAddr := common.HexToAddress(to)

	tx := types.NewTransaction(nonce, toAddr, v, gasLimit, gasPrice, nil)

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		return "", err
	}

	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		return "", err
	}

	return signedTx.Hash().String(), nil

}

// 通过BoundContract发送以太币给合约
func transferBC(bc *bind.BoundContract, pkey, value string) (string, error) {
	privateKey, err := crypto.HexToECDSA(pkey)
	if err != nil {
		return "", errors.New("invalid private key")
	}

	v, ok := new(big.Int).SetString(value, 10)
	if !ok {
		return "", errors.New("invalid value")
	}

	topts := bind.NewKeyedTransactor(privateKey) // bind.NewTransactor(keyin, passphrase)

	// GasPrice, Nonce等参数由API自行计算(也可手动提供)
	topts.GasLimit = uint64(210000)
	topts.Value = v

	signedTx, err := bc.Transfer(topts)
	if err != nil {
		return "", err
	}

	return signedTx.Hash().String(), nil

}

// 通过RPC调用合约方法(to为合约地址, data为pack合约方法和参数后得到的十六进制字符串)
func transactRpc(from, to, passwd, value, data string, client *rpc.Client) (string, error) {
	type T struct {
		From  string
		To    string
		Value string
		Data  string
	}
	// 其他nonce,gasLimit,gasPrice等参数由API自行计算(也可手动提供):

	/*
		if data[:2] != "0x" {
			data = "0x" + data
		}

		for data[:3] == "0x0" {
			data = strings.Replace(data, "0x0", "0x", -1)
		}
	*/

	trans := T{From: from, To: to, Data: data}

	if value != "" {
		value, err := numToStr(value)
		if err != nil {
			return "", err
		}
		trans.Value = value
	}

	var res string
	err := client.Call(&res, "personal_sendTransaction", trans, passwd)
	if err != nil {
		return "", err
	}
	return res, nil
}

// 通过ethclient调用合约(to为合约地址, data为pack合约方法和参数后得到的十六进制字符串)
func transactEth(pkey, to, data string, client *ethclient.Client) (string, error) {
	privateKey, err := crypto.HexToECDSA(pkey)
	if err != nil {
		return "", errors.New("invalid private key")
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return "", errors.New("invalid public key")
	}

	fromAddr := crypto.PubkeyToAddress(*publicKeyECDSA)

	nonce, err := client.PendingNonceAt(context.Background(), fromAddr)
	if err != nil {
		return "", err
	}

	/*
		v, ok := new(big.Int).SetString(value, 10)
		if !ok {
			return "", errors.New("invalid value")
		}
		v, err := hexutil.EncodeBig(value)
	*/

	gasLimit := uint64(210000) // 此值不应过小, 否则交易失败
	// gasPrice := big.NewInt(30000000000)
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		return "", err
	}

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		return "", err
	}

	chainID = big.NewInt(1337)
	// chainID用于防止重放攻击, 该值关系到签名值, 错误的chainID将导致from的私钥无法完成验签
	// dev 模式下源码中已写死其chainID为1337, 通过client.NetworkID获取到的是NetworkID, NetorkID在命令行中通过--networkid指定

	toAddr := common.HexToAddress(to)

	d, err := hexutil.Decode(data)
	if err != nil {
		return "", err
	}

	tx := types.NewTransaction(nonce, toAddr, nil, gasLimit, gasPrice, d)

	// signedTx, err := types.SignTx(tx, types.HomesteadSigner{}, privateKey)

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		return "", err
	}

	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		return "", err
	}

	return signedTx.Hash().String(), nil

}

// 通过BoundContract调用合约方法
func transactBC(bc *bind.BoundContract, pkey, method string, args ...interface{}) (string, error) {
	privateKey, err := crypto.HexToECDSA(pkey)
	if err != nil {
		return "", errors.New("invalid private key")
	}

	/*
		v, ok := new(big.Int).SetString(value, 10)
		if !ok {
			return "", errors.New("invalid value")
		}
	*/

	topts := bind.NewKeyedTransactor(privateKey) // bind.NewTransactor(keyin, passphrase)

	// GasPrice, Nonce等参数由API自行计算(也可手动提供)
	topts.GasLimit = uint64(210000)
	// topts.Value = v

	signedTx, err := bc.Transact(topts, method, args...)
	if err != nil {
		return "", err
	}

	return signedTx.Hash().String(), nil

}

func main() {
	fmt.Println(parseMethod("setItem(bytes32,bytes32)"))
	log.Fatal("Exit")
	rclient, err := getClientRpc("ws://192.168.103.196:8546")
	if err != nil {
		log.Fatal(err)
	}

	raccounts, err := getAccountsRpc(rclient)
	if err != nil {
		log.Fatal(err)
	}
	balance, err := getBalanceRpc(rclient, raccounts[1])
	if err != nil {
		//log.Fatal(err)
	}
	fmt.Println(balance)

	/*
		d, err := numToStr(100000)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(d)
	*/
	ethv, err := ethToWeiStr("10") // from string Wei to string Eth
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(ethv)

	res, err := transferV2Rpc(raccounts[1], raccounts[2], "100000", "test", rclient)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(res)

	fmt.Println("===================================================")

	eclient, err := getClientEth("ws://192.168.103.196:8546")
	eaccounts, err := getAccountsEth(eclient, "/home/xshrim/lab/ethgo/eth/keystore")
	if err != nil {
		log.Fatal(err)
	}

	pkey := getPrivateKey("/home/xshrim/lab/ethgo/eth/keystore/", raccounts[0], "")
	if pkey == "" {
		log.Fatal("not found")
	}
	fmt.Println(pkey)

	txhash, err := transferEth(pkey, raccounts[1], "1000000", eclient)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(txhash)

	// fmt.Println(eaccounts)
	balance, err = getBalanceEth(eclient, eaccounts[1].Address.String())
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(balance)

	caddr := "0x8cF6FDdf1b1537762E6bE4e0eE77157Fb054E1Af"
	instance, err := getInstanceEth(eclient, caddr)
	if err != nil {
		log.Fatal(err)
	}

	version, err := getContractVersionEth(instance, "raw")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(version)

	// 可以直接通过合约地址, 合约abi以及ethclient连接区块链的client实例实现对区块链的访问(此三者即可得到BoundContract实例), 而无需使用abigen生成合约的go文件(事实上abigen生成的文件只是对合约所有功能的自动封装, 方便go代码直接调用, 但这不是必须的)
	// 合约abi可由compiler包根据合约源代码自动编译生成(需借助本地solidity编译器)
	caddr = "0x8cF6FDdf1b1537762E6bE4e0eE77157Fb054E1Af"

	StoreABI := "[{\"constant\":true,\"inputs\":[],\"name\":\"getVersion\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\"}],\"name\":\"items\",\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"method\",\"type\":\"string\"},{\"name\":\"arg\",\"type\":\"uint256\"}],\"name\":\"invoke\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"version\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"key\",\"type\":\"bytes32\"}],\"name\":\"getItem\",\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"key\",\"type\":\"bytes32\"},{\"name\":\"value\",\"type\":\"bytes32\"}],\"name\":\"setItem\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"name\":\"ver\",\"type\":\"string\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"name\":\"\",\"type\":\"string\"},{\"indexed\":false,\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"Log\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"name\":\"key\",\"type\":\"bytes32\"},{\"indexed\":false,\"name\":\"value\",\"type\":\"bytes32\"}],\"name\":\"ItemSet\",\"type\":\"event\"}]"

	boundContract, abicode, err := getBoundContract(caddr, StoreABI, eclient)
	if err != nil {
		log.Fatal(err)
	}

	/*
		abicode, err := abi.JSON(strings.NewReader(StoreABI))
		if err != nil {
			log.Fatal(err)
		}
	*/

	fmt.Println(abicode.Methods)

	txhash, err = transferBC(boundContract, pkey, "10000000")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(txhash)

	/*
		key := [32]byte{}
		value := [32]byte{}

		copy(key[:], []byte("go"))
		copy(value[:], []byte("lang"))

		data, err := abicode.Pack("setItem", key, value)
		if err != nil {
			log.Fatal("aa", err)
		}
		fmt.Println("0x" + hex.EncodeToString(data))
		fmt.Println(hexutil.Encode(data))
		d := hexutil.Encode(data)

		txhash, err = transactRpc(raccounts[1], caddr, "test", "", d, rclient)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(txhash)
	*/

	/* 生成十六进制字符串data的两种方法:
	// 方法1(手动生成):
	data := generateData("setItem(bytes32,bytes32)", "go", "lang")

	// 方法2(调用abi的Pack函数生成):
	key := [32]byte{}
	value := [32]byte{}

	copy(key[:], []byte("py"))
	copy(value[:], []byte("thon"))

	data2, err := abicode.Pack("setItem", key, value)
	if err != nil {
		log.Fatal(err)
	}
	dt := hexutil.Encode(data2)

	fmt.Println(data)
	fmt.Println(dt)
	*/

	data := generateData("setItem(bytes32,bytes32)", "node", "js")

	txhash, err = transactRpc(raccounts[1], caddr, "test", "", data, rclient)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(txhash)

	time.Sleep(2 * time.Second)
	ikey := [32]byte{}
	copy(ikey[:], []byte("node"))
	res, err = callBC(boundContract, raccounts[1], "getItem", ikey)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(res)

	data = generateData("setItem(bytes32,bytes32)", "linux", "shell")

	/*
		key := [32]byte{}
		value := [32]byte{}

		copy(key[:], []byte("ju"))
		copy(value[:], []byte("lia"))

		dt, err := abicode.Pack("setItem", key, value)
		if err != nil {
			log.Fatal(err)
		}
	*/

	res, err = transactEth(pkey, caddr, data, eclient)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(res)

	time.Sleep(2 * time.Second)
	calldata := generateData("getItem(bytes32)", "linux")

	res, err = callRpc(raccounts[1], caddr, calldata, rclient)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(res)

	ckey := [32]byte{}
	cvalue := [32]byte{}
	copy(ckey[:], []byte("redhat"))
	copy(cvalue[:], []byte("fedora"))
	txhash, err = transactBC(boundContract, pkey, "setItem", ckey, cvalue)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(txhash)

	time.Sleep(2 * time.Second)
	res, err = callBC(boundContract, raccounts[1], "getItem", ckey)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(res)
	// boundContract.Transact()
	// boundContract.Transfer()

	/*
		_, err = compileContract("./Store.sol") // compile solidity source file
		if err != nil {
			log.Fatal(err)
		}
	*/

	/*
		// get TransactOpts
		var pkey *ecdsa.PrivateKey
		bind.NewKeyedTransactor(pkey) // method 1: need private key

		f, err := os.Open("./Store.json")
		bind.NewTransactor(f, "aa") // method 2: need encrypted key file and passphrase
	*/

}
