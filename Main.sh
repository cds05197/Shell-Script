#!/bin/bash
# 스크립트 실행 사용자가 root인지 체크합니다.
ME=$(whoami)
if [ "$ME" != "root" ]; then
   echo "해당 스크립트는 \"root\" 유저만 실행이 가능합니다."
   exit
fi

# 현재 경로의 ip.txt파일이 있는지 체크합니다.
if [ ! -e ./ip.txt ]; then
   echo "현재 경로의 ip.txt 파일을 생성해주세요."
   echo "다음과 같은 양식으로 작성해주세요"
   echo "\"Host_Name\" \"Host_IP\" \"root_password\""
   exit
fi
 
# ip.txt 파일을 awk로 필요한 부분만 각각 배열에 담는 과정
host_arr=$(cat ./ip.txt | awk '{print $1}')
host_arr=($host_arr)
ip_arr=$(cat ./ip.txt | awk '{print $2}')
ip_arr=($ip_arr)
pass_arr=$(cat ./ip.txt | awk '{print $3}')
pass_arr=($pass_arr)

# ip.txt 정합성 체크 
function IP_Check() {
clear
echo "ip.txt 파일의 내용을 검증합니다..."
sleep 1

if [ "$ip_arr" == "" ]; then
   clear
   echo "다음과 같은 양식으로 작성해주세요"
   echo "\"Host_Name\" \"Host_IP\" \"root_password\""
   exit
elif [ "$pass_arr" == "" ]; then
   echo "다음과 같은 양식으로 작성해주세요"
   echo "\"Host_Name\" \"Host_IP\" \"root_password\""
   exit
fi

# ip, hosts_name, root_password의 수가 각각 동일한지 검사
if  [ ${#ip_arr[@]} != ${#host_arr[@]} ] || [ ${#ip_arr[@]} != ${#pass_arr[@]} ]; then
   echo "ip와 호스트이름,  root 패스워드를 하나씩  수에 맞춰 입력해주세요"
   exit
fi

#IP가 0-255사이에 숫자인지, .으로 구분된 4개의 영역으로 구성되어 있는지
#검사 하는 구간

for i in ${ip_arr[@]}
do
        ip=$(echo $i | sed 's/\./ /g')
        ip=($ip)
        if [ ${#ip[@]} != 4 ]; then
                echo ""
                echo "ip.txt에 입력된 IP가 형식에 맞지 않습니다!"
                echo "IPv4 형식에 맞게 입력해주세요"
                echo "EX) 192.168.1.120"
                echo ""
                exit
        fi

        for ip in ${ip[@]}
        do
                re='^[0-9]+$'
                if ! [[ "$ip" =~ $re ]]; then
                echo "IP는 0-255 사이에 정수로 입력되어야합니다."
                echo "확인 후 ip.txt 파일을 수정해주세요"
                exit
                elif ! [ $ip -ge 0 ] || ! [ $ip -le 255 ]; then
                echo "IP는 0-255 사이에 정수로 입력되어야합니다."
                echo "확인 후 ip.txt 파일을 수정해주세요"
                exit
                fi
        done
done

# root 패스워드 검증에 필요한 sshpass 설치 여부
if [ ! -e /usr/bin/sshpass ]; then
   clear
   echo "sshpass가 설치되어있지 않습니다."
   echo "sshpass 설치를 시작합니다."
   sleep 1
   yum -y install sshpass
   clear
   echo "sshpass 설치를 완료했습니다."
   sleep 1
   clear
   echo "ip.txt 검증을 재개합니다."
   sleep 1
fi


#root 패스워드 유효성 검사
#
for ((i=1 ; i <= ${#ip_arr[@]} ; i++));
do
idx=`expr $i - 1`
sshpass -p ${pass_arr[$idx]} ssh -T -o StrictHostKeyChecking=no root@${ip_arr[$idx]} "echo pass-Check" > /dev/null 

# ssh -T -o StrictHostKeyChecking=no  어쩌구는 ssh 최초 접속 시 yes/no 물어보는거 방지

if [ $? -ne 0 ]; then
        echo "Host IP에 root 계정 패스워드가 일치하지 않습니다"
        echo "확인 후 ip.txt를 수정해주세요"
        exit
fi
done

clear
echo "ip.txt 파일의 검증이 완료되었습니다."
sleep 1

}


# Ansible 및 필요 패키지 설치 여부 확인
#
function Ansible_install() {
clear
echo "Ansible 관련 패키지 설치 여부를 확인합니다."
sleep 1
if [ ! -e /etc/yum.repos.d/CentOS-SIG-ansible-29.repo ]; then
   clear
   echo "centos-release-ansible-29가 설치되어 있지 않습니다."
   echo "설치를 시작합니다."
   sleep 1
   clear
   yum -y install centos-release-ansible-29
   clear
   echo "설치를 완료했습니다."
   sleep 1
   clear
fi
if [ ! -e /usr/bin/ansible ]; then
   clear
   echo "Ansible이 설치되어 있지 않습니다."
   echo "설치를 시작합니다."
   sleep 1
   clear
   yum -y install ansible
   clear
   echo "설치를 완료했습니다."
   sleep 1
   clear
fi

clear
echo "Ansible 관련 패키지가 정상적으로 설치되어 있습니다."
sleep 1

}

# 원격지 SSH .ssh 디렉터리 생성 및 키 인증 방식 활성화
function SSH_Config() {
clear
echo "원격지 호스트의 SSH 설정 및 .ssh 디렉터리를 생성합니다."
sleep 1

for ((i=1 ; i <= ${#ip_arr[@]} ; i++));
do
idx=`expr $i - 1`
sshpass -p ${pass_arr[$idx]} ssh root@${ip_arr[$idx]} "sed -i 's/#PubkeyAuthentication/PubkeyAuthentication/g' /etc/ssh/sshd_config"
sshpass -p ${pass_arr[$idx]} ssh root@${ip_arr[$idx]} "mkdir /root/.ssh" 2> /dev/null
sshpass -p ${pass_arr[$idx]} ssh root@${ip_arr[$idx]} "chmod 700 /root/.ssh"
sshpass -p ${pass_arr[$idx]} ssh root@${ip_arr[$idx]} "rm -rf /root/.ssh/*" 2> /dev/null
done
clear
echo "SSH 설정 및 .ssh 디렉터리 생성이 완료되었습니다."
sleep 1
}

# expect 사용해서 key 자동 생성 및 배포
function SSH_Keygen() {
clear
echo "SSH키 생성 및 원격지 배포를 실행합니다."
sleep 1

ID_RSA=/root/.ssh/id_rsa.pub
if [ ! -e /usr/bin/expect ]; then
   clear
   echo "expect 모듈이 설치되어있지 않습니다."
   echo "설치를 진행합니다."
   sleep 1
   clear
        yum -y install expect
   clear
   echo "설치를 완료했습니다."
   sleep 1
   clear
   echo "SSH키 생성 및 원격지 배포를 실행합니다."
   sleep 1
fi

# expect로 키 생성 자동화
if [ ! -f $ID_RSA ]; then
clear
expect -c "spawn ssh-keygen" \
                   -c "expect -re \":\"" \
                   -c "send \"\r\"" \
                   -c "expect -re \":\"" \
                   -c "send \"\r\"" \
                   -c "expect -re \":\"" \
                   -c "send \"\r\"" \
                   -c "puts \" \n * ssh-keygen success!!#3 *\"" \
                   -c "interact"
fi
chmod 600 ~/.ssh/*
for ((i=1 ; i <= ${#ip_arr[@]} ; i++));
do
idx=`expr $i - 1`
sshpass -p ${pass_arr[$idx]} scp ~/.ssh/id_rsa.pub root@${ip_arr[$idx]}:~/.ssh/authorized_keys
done

clear
echo "SSH 키 생성 및 원격지 배포를 완료했습니다."
sleep 1
clear
}

# Make Inventory
# ip.txt 정보를 가지고 Inventory 생성

function MakeInventory() {
clear
echo "ansible inventory를 생성합니다."
sleep 1

echo "[server]" > /root/.ansible/inventory

for ((i=1 ; i <= ${#ip_arr[@]} ; i++));
do
idx=`expr $i - 1`
echo "${host_arr[$idx]}   ansible_host=${ip_arr[$idx]}" >> /root/.ansible/inventory
done

echo "
[server:vars]
ansible_connection=ssh
ansible_user=root" >> /root/.ansible/inventory

clear
echo "ansible inventory 생성이 완료되었습니다."
sleep 1
}

# Make Monitoring.sh
# 메인 쉘 파일 생성 구문 만들어서 /root/Ansible/ansi_shell 디렉터리에 저장

function Make_Monitoring.sh() {

mkdir -p /root/Ansible/ansi_shell 2> /dev/null

clear
echo "Monitoring.sh 스크립트 파일을 생성합니다."
sleep 1

cat << EOF > /root/Ansible/ansi_shell/monitoring.sh
#!/bin/bash


# unset any variable which system may be using
unset os version kernelrelease architecture internalip externalip nameserver
echo "======================================="

# Check Internet Connection
ping -c 1 google.com &> /dev/null
if [ \$? -eq 0 ];
then
   echo -e "Internet:  Connected"
else
   echo -e "Internet:  Disconnected"
fi
echo ""
# System Uptime
uptime=\$(uptime | cut -d ',' -f 1-2)
echo -e "System Uptime :"  \$uptime
echo ""
# Check OS Type
os=\$(uname -o)
echo -e "Operating System Type :"  \$os
echo ""
# Check OS Release Version and NAME
version=\$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d '"' -f 2)
echo -e "OS Version :"  \$version 
echo ""
# Check Kernel Release
kernelrelease=\$(uname -r)
echo -e "Kernel Release :"  \$kernelrelease
echo ""
# Check Architecture
architecture=\$(uname -m)
echo -e "Architecture :"  \$architecture
echo ""
# Check hostname
echo -e "Hostname :"  \$HOSTNAME
echo ""
# Check Internal IP
internalip=\$(hostname -I)
echo -e "Internal IP :"  \$internalip
echo ""
# Check External IP
externalip=\$(dig +short myip.opendns.com @resolver1.opendns.com)
echo -e "External IP :  "\$externalip
echo ""
# Check DNS
nameservers=\$(cat /etc/resolv.conf | sed '1 d' | awk '{print \$2}')
echo -e "Name Servers :"  \$nameservers 
echo ""
# Check Logged In Users
echo -e "Logged In users : " 
who
echo ""
# Check RAM and SWAP Usages
echo -e "Memory Usages :"  
Memtotal=\$(free | grep ^Mem | awk '{print \$2}')
Memused=\$(free | grep ^Mem | awk '{print \$3}')
Memfree=\$(free | grep ^Mem | awk '{print \$4}')
Memcache=\$(free | grep ^Mem | awk '{print \$6}')
MemPercent=\$((100*Memfree/Memtotal))
echo -e "Total Memory : \${Memtotal}MB"
echo -e "Used  Memory : \${Memused}MB"
echo -e "Cache Memory : \${Memcache}MB"
echo -e "Free  Memory : \${MemPercent}%"
echo ""
echo -e "Swap Usages :"  
Swaptotal=\$(free | grep ^Swap | awk '{print \$2}')
Swapused=\$(free | grep ^Swap | awk '{print \$3}')
Swapfree=\$(free | grep ^Swap | awk '{print \$4}')
SwapPercent=\$((100*Swapfree/Swaptotal))
echo -e "Total Swap : \${Swaptotal}MB"
echo -e "Used  Swap : \${Swapused}MB"
echo -e "Free  Swap : \${SwapPercent}%"
echo ""
# Check Disk Usages
echo -e "Disk Usages :"
df -h | grep -E 'Filesystem|/dev/sda*' 
echo ""
# Check CPU Usages
used=\$(mpstat | tail -1 | awk '{print 100-\$11}')
free=\$(mpstat | tail -1 | awk '{print \$11}')
usr=\$(mpstat | tail -1 | awk '{print \$2}')
nice=\$(mpstat | tail -1 | awk '{print \$3}')
sys=\$(mpstat | tail -1 | awk '{print \$4}')
iowait=\$(mpstat | tail -1 | awk '{print \$5}')
irq=\$(mpstat | tail -1 | awk '{print \$6}')
soft=\$(mpstat | tail -1 | awk '{print \$7}')
steal=\$(mpstat | tail -1 | awk '{print \$8}')
echo -e "CPU Usages :" 
echo "Free      Used     Usr      Nice     Sys      Iowait   Irq      Soft     Steal"
echo -e "\$free%    \$used%    \$usr%    \$nice%    \$sys%    \$iowait%    \$irq%    \$soft%    \$steal%"
echo ""

# Check Load Average
_1minloadaverage=\$(uptime | cut -d ':' -f 5 | awk '{print \$1}' | tr -d ',')
_5minloadaverage=\$(uptime | cut -d ':' -f 5 | awk '{print \$2}' | tr -d ',')
_15minloadaverage=\$(uptime | cut -d ':' -f 5 | awk '{print \$3}')
echo -e "Load Average :" 
echo -e "1min load average : \$_1minloadaverage"
echo -e "5min load average : \$_5minloadaverage"
echo -e "15min load average : \$_15minloadaverage"
echo ""
# Check Firewall List
fwinterfaces=\$(firewall-cmd --list-all | sed -n '4p' | cut -d ':' -f 2)
fwservices=\$(firewall-cmd --list-all | sed -n '6p' | cut -d ':' -f 2)
fwports=\$(firewall-cmd --list-all | sed -n '7p' | cut -d ':' -f 2)
echo -e "Firewall List :" 
echo -e "interfaces :\$fwinterfaces"
echo -e "services :\$fwservices"
echo -e "ports :\$fwports"
echo ""

# Check Active Service and Port_Number
echo -e "Listen Ports :" 
netstat -antp | grep LISTEN | awk '{print \$1"\tPID/Service : "\$7 "  \tAllow_IP:Active_Port: " \$4}' 
echo ""
EOF

chmod 700 /root/Ansible/ansi_shell/monitoring.sh 

clear
echo "Monitoring.sh 파일 생성이 완료되었습니다."
sleep 1
}


# ansible ad-hoc 명령어를 통해 원격지에 monitoring.sh 배포 후
# 실행하여 결과 값을 /root/Ansible/result에 저장해주는 스크립트 생성
  
function Make_Manager() {

# manager.sh의 결과물들을 저장할 디렉터리 생성
if [ ! -e /root/Ansible/result ]; then
   mkdir -p /root/Ansible/result 
fi

clear
echo "manager.sh 스크립트 파일을 생성합니다."
sleep 1

cat <<EOF > /root/Ansible/ansi_shell/manager.sh
#!/bin/bash
cat /root/ip.txt | awk '{print \$1}' > /root/Ansible/hosts.txt
# ip.txt는 root 패스워드가 기재되어 있어서  최초 실행시에만 사용후 삭제 권장
# 이후에는 crontab 실행시에는 hosts.txt 참조해서 실행 

host_arr=\$(cat /root/Ansible/hosts.txt)
host_arr=(\$host_arr)
DATE=\`date +%y_%m_%d\`


ansible all -m file -a "dest=/root/ansi_shell state=directory" -i /root/.ansible/inventory
ansible all -m file -a "dest=/root/ansi_shell mode=700" -i /root/.ansible/inventory
ansible all -m yum -a "name=sysstat state=present" -i /root/.ansible/inventory
ansible all -m yum -a "name=bind-utils state=present" -i /root/.ansible/inventory
ansible all -m copy -a "src=/root/Ansible/ansi_shell/monitoring.sh dest=/root/ansi_shell/monitoring.sh" -i ~/.ansible/inventory
ansible all -m file -a "dest=/root/ansi_shell/monitoring.sh mode=700" -i /root/.ansible/inventory
for i in \${host_arr[@]}
do
ansible \$i -a "sh /root/ansi_shell/monitoring.sh" -i ~/.ansible/inventory | awk '{if (NR != 1 && NR != 2) print}' > /root/Ansible/result/\${DATE}_\$i.info
done
EOF

clear
echo "manager.sh 스크립트 파일 생성이 완료되었습니다."
sleep 1

}

# 생성한 manager.sh 파일 실행 
function Run_Manager() {

clear
echo "manager.sh 파일을 최초 실행 합니다."
sleep 1
clear

cd /root/Ansible/ansi_shell
chmod +x manager.sh
./manager.sh
clear
echo "manager.sh 파일을 성공적으로 실행하였습니다."
sleep 2
clear

cd /root
}

# Crontab 파일 생성
function Config_Crontab() {
clear
echo "Crontab 설정을 시작합니다..."
sleep 1
sed -i "/^#/d" /etc/crontab # 주석문 삭제
sed -i "/manager.sh/d" /etc/crontab # 중복 실행 시 대비하여 구문 삭제
echo "0 0 * * * root /root/Ansible/ansi_shell/manager.sh 2> /root/Ansible/error.log\n" >> /etc/crontab # 구문 추가

clear
echo "Crontab 설정을 완료했습니다."
sleep 1
}

### 실제 함수 실행 부분
IP_Check
Ansible_install
SSH_Config
SSH_Keygen
MakeInventory
Make_Monitoring.sh
Make_Manager
Run_Manager
Config_Crontab
###

clear
echo "" > /root/Ansible/readme
echo "=======================================================================" >> /root/Ansible/readme
echo "                                                                       " >> /root/Ansible/readme
echo "                      모든 작업이 완료되었습니다                       " >> /root/Ansible/readme
echo "     보안을 위해 root 패스워드가 적힌 ip.txt 파일을 삭제하여주세요     " >> /root/Ansible/readme
echo "      Monitoring 결과물은 /root/Ansible/result에서 확인 가능합니다     " >> /root/Ansible/readme
echo "    Shell Script 파일은 /root/Ansible/ansi_shell에서 확인 가능합니다   " >> /root/Ansible/readme
echo "      Crontab 설정으로 매일 자정 자동으로 manager.sh를 실행합니다      " >> /root/Ansible/readme
echo "    Crontab 에러 발생시 /root/Ansible/error.log에서 확인이 가능합니다  " >> /root/Ansible/readme
echo "                                                                       " >> /root/Ansible/readme
echo "=======================================================================" >> /root/Ansible/readme
echo "" >> /root/Ansible/readme

cat /root/Ansible/readme
sleep 1


