package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"fmt"
	"io"
	"net"
)

func main() {
	key := []byte("example key 1234")

	conn, err := net.Dial("tcp", "127.0.0.1:9080")

	if err != nil {
		panic(err)
	}

	defer func() {
		fmt.Println("Bye")

		conn.Close()
	}()

	block, cipherErr := aes.NewCipher(key)

	if cipherErr != nil {
		fmt.Errorf("Can't create cipher:", cipherErr)

		return
	}

	iv := make([]byte, aes.BlockSize)

	if _, randReadErr := io.ReadFull(rand.Reader, iv); randReadErr != nil {
		fmt.Errorf("Can't build random iv", randReadErr)

		return
	}

	_, ivWriteErr := conn.Write(iv)

	if ivWriteErr != nil {
		fmt.Errorf("Can't send IV:", ivWriteErr)

		return
	} else {
		fmt.Println("IV Sent:", iv)
	}

	stream := cipher.NewCFBEncrypter(block, iv)

	data := [][]byte{
		[]byte("Test one"),
		[]byte("Hello crypto"),
		[]byte("Hello word"),
		[]byte("Hello excel"),
		[]byte("Hello powerpoint"),
	}

	for _, d := range data {
		encrypted := make([]byte, len(d))

		stream.XORKeyStream(encrypted, d)

		writeLen, writeErr := conn.Write(encrypted)

		if writeErr != nil {
			fmt.Errorf("Write failed:", writeErr)

			return
		}

		fmt.Println("Encrypted Data Written:", string(d), encrypted, writeLen)
	}
}
