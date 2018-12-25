import cv2
import simplecrypt

out = cv2.VideoWriter('decryp-example.mp4', -1, 30, (1280, 720))

def decrypt_file(file_name, dec_file, key):
    with open(file_name, 'rb') as fo:
        ciphertext = fo.readlines(
        )  #gives me a list of all encrypted frames as it uses \n as a delimeter which we added after each encrypted text

        for i in ciphertext:
            dec = simplecrypt.decrypt(key, i)  #decrypting each frame
            frame = pickle.loads(dec)  #converting to numpy array
            out.write(frame)


decrypt_file('enc_vid.enc', 'example-decrypt.mp4', '30A9A5B20798A23C')
out.release()
