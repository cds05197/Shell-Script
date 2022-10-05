#!/bin/bash
disk=($(lsblk | awk '{if($1 >= "sdc" && $1~/^sd/ )print $1}'))
cnt=0

for i in ${disk[@]}
do
echo $i
array+=" /dev/$i""1"
cnt=`expr $cnt + 1`
done

for i in ${disk[@]}
do
fdisk /dev/$i << EOF
d
q
EOF
done

for i in ${disk[@]}
do
fdisk /dev/$i << EOF
n
p
1


t
fd
p
w
EOF
done



if [ -e /dev/md5 ]; then
        umount /dev/md5
	rm -rf /NFS_Storage
        mdadm -S /dev/md5
        mdadm --zero-superblock /dev/sdc1
        mdadm --zero-superblock /dev/sdd1
        mdadm --zero-superblock /dev/sde1
	rm -rf /dev/md5
        mknod /dev/md5 b 9 5
        mdadm --create /dev/md5 --level=5 --raid-device=$cnt $array
        sed -i "/dev\/md5        \/NFS_Storage          xfs     defaults        0 0/d" /etc/fstab
        mkfs.xfs /dev/md5
        mkdir /NFS_Storage
        mount /dev/md5 /NFS_Storage
        mdadm --detail --scan > /etc/mdadm.conf
        echo "/dev/md5        /NFS_Storage          xfs     defaults        0 0" >> /etc/fstab
else
        mknod /dev/md5 b 9 5
        mdadm --create /dev/md5 --level=5 --raid-device=$cnt $array
        mkfs.xfs /dev/md5
        mkdir /NFS_Storage
        mount /dev/md5 /NFS_Storage
        mdadm --detail --scan > /etc/mdadm.conf
        echo "/dev/md5        /raid5          xfs     defaults        0 0" >> /etc/fstab
fi

chmod 777 /NFS_Storage 
yum -y remove nfs-utils
yum -y remove rpcbind
yum -y install nfs-utils
yum -y install rpcbind

firewall-cmd --permanent --remove-service=nfs
firewall-cmd --permanent --remove-port=111/tcp
firewall-cmd --permanent --remove-port=111/udp
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-port=111/tcp
firewall-cmd --permanent --add-port=111/udp

echo "/NFS_Storage 192.168.1.0/24(rw,root_squash,no_all_squash,async,no_wdelay)" > /etc/exports

systemctl restart nfs-server
systemctl restart rpcbind

exportfs -ra
