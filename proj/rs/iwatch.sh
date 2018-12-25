#! /bin/bash

# format
## %w 表示发生事件的目录
## %f 表示发生事件的文件
## %e 表示发生的事件
## %Xe 事件以“X"分隔
## %T 使用由--timefmt定义的时间格式

/usr/bin/inotifywait -mrq --format '%w%f' -e create,close_write,delete /home/xshrim/k8s  | while read line  
do
    if [ -f $line ];then
        echo $line
    else
        cd /home/xshrim/k8s/__pycache__ && echo $line
    fi

    if [ -f $line ];then
        rsync -az $line --delete rsync_backup@$backup_Server::nfsbackup --password-file=/etc/rsync.password       
    else
        cd $Path &&\
        rsync -az ./ --delete rsync_backup@$backup_Server::nfsbackup --password-file=/etc/rsync.password

done
