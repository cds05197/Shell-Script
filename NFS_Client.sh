#!/bin/bash

if [ -e /NFS ]; then
	umount /NFS
	sed -i "/NFS_Storage/d" /etc/fstab
	rm -rf /NFS
	yum -y remove nfs-utils
else
	yum -y remove nfs-utils
fi

yum -y install nfs-utils


mkdir /NFS
mount -t nfs 192.168.1.100:/NFS_Storage /NFS
sed -i "/NFS_Storage/d" /etc/fstab
echo "192.168.1.100:/NFS_Storage	/NFS		nfs	defaults	0 0" >> etc/fstab

systemctl start firewalld
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-port=111/tcp
firewall-cmd --permanent --add-port=111/udp
firewall-cmd --reload
systemctl restart nfs

clear
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo "NFS System Sucess!!"
sleep 3

