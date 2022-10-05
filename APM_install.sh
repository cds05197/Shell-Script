!/bin/bash

yum -y remove httpd-*
yum -y install httpd-*

systemctl enable httpd
systemctl start httpd
systemctl restart firewalld
firewall-cmd --reload

echo "<?php
	phpinfo();
?>" > /var/www/html/t1.php

yum -y remove php
yum -y install php

systemctl restart httpd

yum -y remove mariadb-server
yum -y install mariadb-server

systemctl start mariadb
systemctl enable mariadb

expect -c "
spawn /usr/bin/mysql_secure_installation
expect \"password for root\"
send \"root\r\"
expect \"root password\"
send \"Y\r\"
expect \"New password\"
send \"root\r\"
expect \"Re-enter new password\"
send \"root\r\"
expect \"Reload privilege tables now?\"
send \"Y\r\"
expect \"Remove anonymous users\"
send \"Y\r\"
expect \"login remotely\"
send \"Y\r\"
expect \"access to it\"
send \"Y\r\"
expect \"tables now\"
send \"Y\r\"
exit 0
"
system restart mariadb

MYSQL_PWD='root' /usr/bin/mysql -u root<<EOF
show databases;
create database test;
use test;
create table demo(name char(2), age int);
insert into demo (name,age) values("Andy",23);
insert into demo (name,age) values("Hyun",28);
insert into demo (name,age) values("Down",22);
insert into demo (name,age) values("Dasun",26);
insert into demo (name,age) values("Sung",25);
select * from demo;
EOF

echo "<?php
	\$conn = mysqli_connect(\"localhost\",\"root\",\"root\",\"test\");
	\$sql = \"select name,age from demo\";
	\$result = mysqli_query(\$conn, \$sql);

	if (mysqli_num_rows(\$result) > 0) {
		while(\$row = mysqli_fetch_assoc(\$result)){
			echo \"name : \".\$row[\"name\"].\"age : \".\$row[\"age\"].\"<br>\";
		}
	}
	else{
		echo \"no data\" ;
	}		
?>" > /var/www/html/t2.php

yum -y remove php-mysql
yum -y install php-mysql

systemctl restart httpd



