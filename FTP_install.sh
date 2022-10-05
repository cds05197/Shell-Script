#!/bin/bash

yum -y remove vsftpd
yum -y install vsftpd

clear

echo ""
echo "======================================================"
echo "			start configure ftp		    "
echo "======================================================"
sleep 5

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/#anon_upload/anon_upload/g' /etc/vsftpd/vsftpd.conf
sed -i 's/#idle_session_timeout=600/idle_session_timeout=900/g' /etc/vsftpd/vsftpd.conf
sed -i 's/#data_connection_timeout=120/data_connection_timeout=180/g' /etc/vsftpd/vsftpd.conf
sed -i 's/#ftpd_banner=Welcome to blah FTP service./ftpd_banner=Welcome to My FTP service./g' /etc/vsftpd/vsftpd.conf
sed -i 's/#ascii_/ascii_/g' /etc/vsftpd/vsftpd.conf
sed -i 's/#chroot_/chroot_/g' /etc/vsftpd/vsftpd.conf
sed -e "105 i\\allow_writeable_chroot=YES" -i /etc/vsftpd/vsftpd.conf
sed -i 's/userlist_enable/userlist_deny/g' /etc/vsftpd/vsftpd.conf
sed -i "/max_clients/d" /etc/vsftpd/vsftpd.conf
sed -i "/pasv_/d" /etc/vsftpd/vsftpd.conf
echo "max_clients=20
pasv_enable=YES
pasv_min_port=2500
pasv_max_port=2550" >> /etc/vsftpd/vsftpd.conf

echo "vsftpd:ALL" > /etc/hosts.deny
echo "vsftpd:192.168.1.0/24" > /etc/hosts.allow
echo "root
itbank" > /etc/vsftpd/chroot_list
chmod 777 /var/ftp/pub


systemctl restart firewalld
firewall-cmd --permanent --add-service=ftp
firewall-cmd --permanent --add-port=2500-2550/tcp
firewall-cmd --reload
systemctl restart vsftpd

clear
echo ""
echo "======================================================"
echo "			complete configure ftp		    "
echo "======================================================"
sleep 5


