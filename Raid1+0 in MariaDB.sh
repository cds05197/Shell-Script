#!/bin/bash
disk=($(lsblk | awk '{if($1 >= "sdb" && $1~/^sd/ )print $1}'))
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


if [ ! -e /usr/sbin/mdadm ]; then
	yum -y install mdadm
fi



if [ -e /dev/md10 ]; then
        umount /dev/md10
        mdadm -S /dev/md10
	for i in ${array[@]}
	do
	mdadm --zero-superblock $i
	done
	rm -rf /dev/md10
        mknod /dev/md10 b 9 10
        mdadm --create /dev/md10 --level=10 --raid-device=$cnt $array
        sed -i "/dev\/md10        \/var\/lib\/mysql          xfs     defaults        0 0/d" /etc/fstab
        mkfs.xfs /dev/md10
        mount /dev/md10 /var/lib/mysql
        mdadm --detail --scan > /etc/mdadm.conf
        echo "/dev/md10        /var/lib/mysql          xfs     defaults        0 0" >> /etc/fstab
else
        mknod /dev/md10 b 9 10
        mdadm --create /dev/md10 --level=10 --raid-device=$cnt $array
        mkfs.xfs /dev/md10
        mount /dev/md10 /var/lib/mysql
        mdadm --detail --scan > /etc/mdadm.conf
        echo "/dev/md10        /var/lib/mysql          xfs     defaults        0 0" >> /etc/fstab
fi