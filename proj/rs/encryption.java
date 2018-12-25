import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.charset.Charset;

/**
 * Script: Encode.java Encode file or decode file. Java implementation and
 * upgrade Encoding: UTF-8 Version: 0.2 Java version: 1.8 Usage: java Encode
 * [encode | decode] filename [key]
 * 
 */
public class Encode {

    private static final String DEFAULT_KEY = "TESTKEY";
    private static final String DEFAULT_CHARSET = "UTF-8";
    private static final long SLEEP_TIME = 100;

    public boolean isEncode;
    public MappedByteBuffer mappedBuffer;

    private String filename;
    private String charset;
    private byte[] keyBytes;

    private EncodeThread[] workThreads;

    public Encode(boolean isEncode, String filename, String key) {
        this.isEncode = isEncode;
        this.filename = filename;
        this.charset = DEFAULT_CHARSET;
        this.keyBytes = key.getBytes(Charset.forName(charset));
    }

    public void run() {
        try {
            // read file
            RandomAccessFile raf = new RandomAccessFile(filename, "rw");
            FileChannel channel = raf.getChannel();
            long fileLength = channel.size();
            int bufferCount = (int) Math.ceil((double) fileLength / (double) Integer.MAX_VALUE);
            if (bufferCount == 0) {
                channel.close();
                raf.close();
                return;
            }
            int bufferIndex = 0;
            long preLength = 0;
            // repeat part
            long regionSize = Integer.MAX_VALUE;
            if (fileLength - preLength < Integer.MAX_VALUE) {
                regionSize = fileLength - preLength;
            }
            mappedBuffer = channel.map(FileChannel.MapMode.READ_WRITE, preLength, regionSize);
            preLength += regionSize;

            // create work threads
            int threadCount = keyBytes.length;

            System.out.println(
                    "File size: " + fileLength + ", buffer count: " + bufferCount + ", thread count: " + threadCount);
            long startTime = System.currentTimeMillis();
            System.out.println("Start time: " + startTime + "ms");
            System.out.println("Buffer " + bufferIndex + " start ...");

            workThreads = new EncodeThread[threadCount];
            for (int i = 0; i < threadCount; i++) {
                workThreads[i] = new EncodeThread(this, keyBytes[i], keyBytes.length, i);
                workThreads[i].start();
            }

            // loop
            while (true) {
                Thread.sleep(SLEEP_TIME);

                // wait until all threads completed
                boolean completed = true;
                for (int i = 0; i < workThreads.length; i++) {
                    if (!workThreads[i].isCompleted()) {
                        completed = false;
                        break;
                    }
                }
                if (!completed) {
                    continue;
                }

                // check if finished
                bufferIndex++;
                if (bufferIndex >= bufferCount) {
                    // stop threads
                    for (int i = 0; i < workThreads.length; i++) {
                        workThreads[i].flag = false;
                    }
                    break;
                }

                // repeat part
                regionSize = Integer.MAX_VALUE;
                if (fileLength - preLength < Integer.MAX_VALUE) {
                    regionSize = fileLength - preLength;
                }
                mappedBuffer = channel.map(FileChannel.MapMode.READ_WRITE, preLength, regionSize);
                preLength += regionSize;

                // restart threads
                System.out.println("Buffer " + bufferIndex + " start ...");
                for (int i = 0; i < workThreads.length; i++) {
                    workThreads[i].restart();
                }
            }

            // over loop
            while (true) {
                Thread.sleep(SLEEP_TIME);

                boolean isOver = true;
                for (int i = 0; i < workThreads.length; i++) {
                    if (workThreads[i].isAlive()) {
                        isOver = false;
                        break;
                    }
                }
                if (isOver) {
                    break;
                }
            }

            // close file relatives
            channel.close();
            raf.close();

            long endTime = System.currentTimeMillis();
            System.out.println("End time: " + endTime + "ms, use time: " + (endTime - startTime) + "ms");
            System.out.println("ok!");
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        String usage = "Usage: java -jar encode.jar [encode | decode] filename [key]";
        // parse args
        if (args.length < 2) {
            System.out.println("There must be two or more arguments!");
            System.out.println(usage);
            return;
        }
        if (!args[0].equals("encode") && !args[0].equals("decode")) {
            System.out.println("The first argument must be \"encode\" or \"decode\"");
            System.out.println(usage);
            return;
        }
        boolean isEncode = (args[0].equals("encode"));
        String filename = args[1];
        File file = new File(filename);
        if (!file.isFile()) {
            System.out.println("The file doesn't exist!");
            System.out.println(usage);
            return;
        }
        String key = DEFAULT_KEY;
        if (args.length > 2) {
            key = args[2];
        }

        // encode or decode
        new Encode(isEncode, filename, key).run();
    }

}

class EncodeThread extends Thread {

    private static final long SLEEP_TIME = 50;

    public boolean flag;

    private Encode encoder;
    private int key;
    private long dataIndex;
    private int interval;
    private int regionSize;
    private boolean completed;

    public EncodeThread(Encode encoder, byte key, int interval, int index) {
        this.encoder = encoder;
        this.key = key & 0xff;
        this.dataIndex = index;
        this.interval = interval;
        this.regionSize = encoder.mappedBuffer.limit();
        this.completed = false;
        this.flag = true;
    }

    public void restart() {
        this.dataIndex -= regionSize;
        regionSize = encoder.mappedBuffer.limit();
        completed = false;
    }

    public boolean isCompleted() {
        return completed;
    }

    @Override
    public void run() {
        try {
            if (encoder.isEncode) {
                encode();
            } else {
                decode();
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    private void encode() throws InterruptedException {
        while (flag) {
            // completed here ensure restart() synchronized
            if (completed) {
                Thread.sleep(SLEEP_TIME);
                continue;
            }
            if (dataIndex >= regionSize) {
                completed = true;
                System.out.println("Encode thread " + this.getName() + " is completed!");
                continue;
            }

            // do encode
            byte b = encoder.mappedBuffer.get((int) dataIndex);
            // added as unsigned byte
            b = (byte) (((b & 0xff) + key) % 256);
            encoder.mappedBuffer.put((int) dataIndex, b);
            dataIndex += interval;
        }
    }

    private void decode() throws InterruptedException {
        while (flag) {
            // completed here ensure restart() synchronized
            if (completed) {
                Thread.sleep(SLEEP_TIME);
                continue;
            }
            if (dataIndex >= regionSize) {
                completed = true;
                System.out.println("Encode thread " + this.getName() + " is completed!");
                continue;
            }

            // do decode
            byte b = encoder.mappedBuffer.get((int) dataIndex);
            // substracted as unsigned byte
            b = (byte) (((b & 0xff) + 256 - key) % 256);
            encoder.mappedBuffer.put((int) dataIndex, b);
            dataIndex += interval;
        }
    }

}