#!/bin/bash
# author: abner
# description: it can batch telnet ip port for tcp protol, and need root user to run this script.
# param: ip port , ip must be a ipaddress inline of a text, and port must be a port inline of a text. 
# usage: ./batch_telnet_port ip port
# result: it  generates result files in dir of result, including telnet_alive.txt and telnet_die.txt
# there are some examples: ip, port, telnet_alive.txt and telnet_die.txt.
# ==== ip ====
# 172.16.199.203
# ==== port ===
# 22
# 25
# 443
# 80
# === telnet_alive.txt ====
# 172.16.199.203|22
# === telnet_die.txt ====
# 172.16.199.203|25
# 172.16.199.203|443
# 172.16.199.203|80


set -ex

function export_env() {

    BASEDIR=`dirname $0`
    BASEDIR=`cd $BASEDIR;pwd`
    result_dir=$BASEDIR/result
    [ ! -d $result_dir ] && mkdir -p $result_dir
    thread_num=30

}

function threads() {

    thread_num=$1
    rm -rf /tmp/tmp.fifo
    tmpfifo=/tmp/tmp.fifo
    mkfifo $tmpfifo
    exec 6<>${tmpfifo}
    rm -f $tmpfifo
    for ((i=1;i<=$thread_num;i++))
    do
       echo "">&6
    done

}

function telnet_ip_port() {

   ip=$1
   port=$2
   alive=`echo -e '\n' | telnet $ip $port | grep -i Connected | wc -l`
   if [  "$alive" -ge 1 ]; then
        echo "$ip|$port" >> $result_dir/telnet_alive.txt
   else
        echo "$ip|$port" >> $result_dir/telnet_die.txt
   fi

}

function read_port_process() {

    ip=$1
    telnet_port=$2
    while read port
    do
       read -u6
       { 
          echo "starts telnet $ip $port" 
          telnet_ip_port $ip $port >/dev/null 2>&1 
          echo "">&6
       }&
    done < $telnet_port 
    wait
    exec 6>&-
    echo "it is done, please cat $result_dir/telnet_alive.txt and cat $result_dir/telnet_die.txt"
    exit 0
}

function get_telnet_port() {

    telnet_ip=$1
    telnet_port=$2
    for ip in `cat $telnet_ip`
    do
       read_port_process $ip $telnet_port 
    done
}


function main() {
    which telnet 
    [ $? -ne 0 ] &&  echo "there is no telnet command,please install" && exit 1
    export_env
    threads  $thread_num
    get_telnet_port $1 $2 
}

[ $# -ne 2 ] && echo "usge: $0 ip port" || main  $1 $2
