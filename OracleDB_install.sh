#!/bin/bash

echo "Start Install Oracle Database"
sleep 1


yum -y localinstall oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm

sed -i "/net.ipv4.ip_local_port_range = 9000 65500/d" /etc/sysctl.conf
echo "fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576" >> /etc/sysctl.conf

/sbin/sysctl -p
sleep 1
clear

echo "oracle   soft   nofile    1024
oracle   hard   nofile    65536
oracle   soft   nproc    16384
oracle   hard   nproc    16384
oracle   soft   stack    10240
oracle   hard   stack    32768
oracle   hard   memlock    134217728
oracle   soft   memlock    134217728" >> /etc/security/limits.d/oracle-database-preinstall-19c.conf

useradd -g dba -G dba oracle

(echo oracle; echo oracle) | passwd oracle


systemctl stop firewalld
systemctl disable firewalld
 
systemctl stop bluetooth
systemctl disable bluetooth
 
systemctl stop chronyd
systemctl disable chronyd
mv /etc/chrony.conf /etc/chrony.conf.bak
 
systemctl stop ntpdate
systemctl disable ntpdate
 
systemctl stop avahi-daemon.socket
systemctl disable avahi-daemon.socket
 
systemctl stop avahi-daemon
systemctl disable avahi-daemon
 
systemctl stop libvirtd
systemctl disable libvirtd


yum -y localinstall oracle-database-ee-19c-1.0-1.x86_64.rpm

/etc/init.d/oracledb_ORCLCDB-19c configure

sed -i "/export PATH*/d" /home/oracle/.bash_profile

sudo -H -u oracle echo "export TMP=/tmp;
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export ORACLE_SID=ORCLCDB
export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bash_profile

. /home/oracle/.bash_profile

echo "Install Complete!!"
sleep 3

su oracle -c "sqlplus / as sysdba"

