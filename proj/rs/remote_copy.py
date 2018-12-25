#coding=utf-8
import paramiko, os


def remote_search(addr, host_ip, remote_path, username, password):
    ssh_port = 22
    try:
        conn = paramiko.Transport((host_ip, ssh_port))
        conn.connect(username=username, password=password)
        ssh = paramiko.SSHClient()
        ssh._transport = conn
        stdin, stdout, stderr = ssh.exec_command('cd ' + remote_path + ';ls|grep ' + addr + '$')
        res = stdout.read().decode()
        conn.close()
        if res is not None and str(res).strip() != "":
            return str(res).replace('\n', '')
        else:
            return ""

    except Exception as ex:
        print(ex)
        return False


def remote_scp(itype, host_ip, remote_path, local_path, filename, username, password):
    ssh_port = 22
    try:
        conn = paramiko.Transport((host_ip, ssh_port))
        conn.connect(username=username, password=password)
        sftp = paramiko.SFTPClient.from_transport(conn)

        if not local_path:
            local_path = os.path.join('/tmp', remote_path)
        remote_file = os.path.join(remote_path, filename)
        local_file = os.path.join(local_path, filename)

        if itype == 'read':
            sftp.get(remote_file, local_file)

        if itype == "write":
            sftp.put(local_file, remote_file)

        conn.close()
        return True

    except Exception as ex:
        print(ex)
        return False


filename = remote_search("3c50f7a74f56c3090457fb0b67f3bd4943feef81", "127.0.0.1", "/home/xshrim/lab/ethlab/ethbase/keystore",
                         "root", "root")
print(filename)
if filename != "":
    res = remote_scp("read", "127.0.0.1", "/home/xshrim/lab/ethlab/ethbase/keystore", "/tmp", filename, "root", "root")
    print(res)
