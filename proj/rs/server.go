package main

import (
	"crypto/aes"
	"crypto/cipher"
	"fmt"
	"io"
	"net"
)

func main() {
	ln, err := net.Listen("tcp", "127.0.0.1:9080")

	if err != nil {
		panic(err)
	}

	key := []byte("example key 1234")

	fmt.Println("Started Listening")

	if err != nil {
		panic(err)
	}

	for {
		conn, err := ln.Accept()

		if err != nil {
			fmt.Errorf(
				"Error while handling request from",
				conn.RemoteAddr(),
				":",
				err,
			)
		}

		go func(conn net.Conn) {
			defer func() {
				fmt.Println(
					conn.RemoteAddr(),
					"Closed",
				)

				conn.Close()
			}()

			block, blockErr := aes.NewCipher(key)

			if blockErr != nil {
				fmt.Println("Error creating cipher:", blockErr)

				return
			}

			iv := make([]byte, 16)

			ivReadLen, ivReadErr := conn.Read(iv)

			if ivReadErr != nil {
				fmt.Println("Can't read IV:", ivReadErr)

				return
			}

			iv = iv[:ivReadLen]

			if len(iv) < aes.BlockSize {
				fmt.Println("Invalid IV length:", len(iv))

				return
			}

			fmt.Println("Received IV:", iv)

			stream := cipher.NewCFBDecrypter(block, iv)

			fmt.Println("Hello", conn.RemoteAddr())

			buf := make([]byte, 4096)

			for {
				rLen, rErr := conn.Read(buf)

				if rErr == nil {
					stream.XORKeyStream(buf[:rLen], buf[:rLen])

					fmt.Println("Data:", string(buf[:rLen]), rLen)

					continue
				}

				if rErr == io.EOF {
					stream.XORKeyStream(buf[:rLen], buf[:rLen])

					fmt.Println("Data:", string(buf[:rLen]), rLen, "EOF -")

					break
				}

				fmt.Errorf(
					"Error while reading from",
					conn.RemoteAddr(),
					":",
					rErr,
				)
				break
			}
		}(conn)
	}
}
