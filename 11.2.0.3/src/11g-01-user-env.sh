#!/bin/bash
U=`id -u`
R=`id root -u`
if [ $U  != $R ]; then
        echo "Please run with ROOT"
        exit 1;
else
        echo $USER
fi

#check os version
OSVER=`cat /etc/redhat-release  | awk '{ print $7 }' | awk -F. '{ print $1 }'`
if [ $OSVER != 6  -a $OSVER != 7 ] ; then
    echo "Only support Linux 6 and 7. Exit"
    exit 1;
fi 


. /stage/11g-setup.ini
# setup host01
mount /dev/sr0 /mnt
A=`ls -l  /mnt | wc | awk '{ print $1 }'`
if [ $A -lt 15  -a $OSVER == 7 ]; then
	echo "cdrom not mounted, please check it."
	exit 1;
elif [ $A -lt 27 -a $OSVER == 6 ]; then
	echo "cdrom not mounted, please check it."
	exit 1;
fi

cat > /etc/yum.repos.d/iso.repo <<EOF
[iso]
name=iso
baseurl=file:///mnt
enabled=1
gpgcheck=0
EOF


if [ $OSVER == "7" ]; then
#linux7
cat  > /stage/pkg.lst <<EOF
compat-libstdc++-33
binutils
compat-libcap1
gcc
gcc-c++
glibc
glibc-devel
ksh
libaio
libaio-devel
libgcc
libstdc++
libstdc++-devel
libXi
libXtst
make
sysstat
xdpyinfo
psmisc
expect
xorg-x11-xauth
EOF

else
#linux6
cat  > /stage/pkg.lst <<EOF
binutils 
compat-libstdc++-33 
elfutils-libelf 
elfutils-libelf-devel 
glibc 
glibc-common 
glibc-devel 
gcc 
gcc-c++ 
libaio-devel 
libaio 
libgcc 
libstdc++ 
libstdc++-devel 
make 
sysstat 
unixODBC 
unixODBC-devel 
pdksh 
ksh
psmisc
expect
xorg-x11-xauth
EOF

fi

yum install -y `awk '{print $1}' /stage/pkg.lst`
rpm -ivh /stage/compat-libstdc++-33*.rpm

cat > /etc/profile.d/oracle-grid.sh <<EOF
#Setting the appropriate ulimits for oracle and grid user
if [ \$USER = "oracle" ]; then
  if [ \$SHELL = "/bin/ksh" ]; then
    ulimit -u 16384
    ulimit -n 65536
  else
    ulimit -u 16384 -n 65536
  fi
fi
EOF

if  [ $INSTALL_RAC == 'true' ];then
    cat >> /etc/profile.d/oracle-grid.sh <<EOF
    if [ \$USER = "grid" ]; then
      if [ \$SHELL = "/bin/ksh" ]; then
        ulimit -u 16384
        ulimit -n 65536
      else
        ulimit -u 16384 -n 65536
      fi
    fi
EOF
fi

cat > /etc/security/limits.d/99-grid-oracle-limits.conf <<EOF
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
oracle hard stack 32768
oracle soft memlock -1
oracle hard memlock -1
EOF

if [ $INSTALL_RAC == 'true' ]; then
    cat >> /etc/security/limits.d/99-grid-oracle-limits.conf <<EOF
grid soft nproc 2047
grid hard nproc 16384
grid soft nofile 1024
grid hard nofile 65536
grid soft stack 10240
grid hard stack 32768
EOF
fi

# Recommended value for NOZEROCONF
cat  >> /etc/sysconfig/network <<EOF
NOZEROCONF=yes
EOF



#disable transparent_hugepage , numa

cat >> /etc/rc.local <<EOF
if test -f /sys/kernel/mm/redhat_transparent_hugepage/enabled; then
     echo never >  /sys/kernel/mm/redhat_transparent_hugepage/enabled
     echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag
fi
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
     echo never >  /sys/kernel/mm/transparent_hugepage/enabled
     echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
EOF
chmod +x /etc/rc.local

if [ $OSVER == "7" ];then 
#for linux7
TRANSPARENT_HUGEPAGE=`grep "transparent_hugepage=never" /etc/default/grub | wc | awk '{ print $1}'`
    if [  $TRANSPARENT_HUGEPAGE != "1" ]; then
        mv /etc/default/grub /etc/default/grub.def
        sed 's/\(.*\)quiet/\1quiet transparent_hugepage=never numa=off/' /etc/default/grub.def > /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
else
#for linux6
    TRANSPARENT_HUGEPAGE=`grep "transparent_hugepage=never" /etc/grub.conf | wc | awk '{ print $1}'`
    if [  $TRANSPARENT_HUGEPAGE != "1" ]; then
        mv /etc/grub.conf /etc/grub.conf.def
        sed 's/\(.*\)quiet/\1quiet transparent_hugepage=never numa=off/' /etc/grub.conf.def > /etc/grub.conf
    fi

fi

if [ $INSTALL_RAC == 'true' ]; then

cat >> /etc/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
# Public host info
${NODE1_PUBLIC_IP}    ${NODE1_HOSTNAME}
${NODE2_PUBLIC_IP}    ${NODE2_HOSTNAME}
# Private host info
${NODE1_PRIV_IP}     ${NODE1_PRIVNAME}
${NODE2_PRIV_IP}     ${NODE2_PRIVNAME}
# Virtual host info
${NODE1_VIP_IP}      ${NODE1_VIPNAME}
${NODE2_VIP_IP}      ${NODE2_VIPNAME}
# SCAN
${SCAN_IP1}      ${SCAN_NAME}
${SCAN_IP2}      ${SCAN_NAME}
${SCAN_IP3}      ${SCAN_NAME}
EOF
else
cat >> /etc/hosts <<EOF
${IP_ADDR}	`hostname` 
EOF

fi

#add kernel params
cat > /etc/sysctl.d/98-oraclekernel.conf <<EOF
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmmax = 68719476736
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF

/sbin/sysctl --system

userdel -fr oracle
userdel -fr grid
groupdel oinstall
groupdel oper
groupdel dba
groupdel asmadmin
groupdel asmoper
groupdel asmdba
groupdel backupdba
groupdel dgdba
groupdel kmdba
groupdel racdba
groupadd -g 1101 oinstall
groupadd -g 1102 oper
groupadd -g 1103 dba

if [ $INSTALL_RAC == 'true' ]; then
	echo "rac"
    groupadd -g 1104 asmadmin
    groupadd -g 1105 asmoper
    groupadd -g 1106 asmdba
    groupadd -g 1107 backupdba
    groupadd -g 1108 dgdba
    groupadd -g 1109 kmdba
    groupadd -g 1110 racdba
    useradd grid    -p $(echo "$GRID_PASSWORD" | openssl passwd -1 -stdin) -g 1101 -G 1102,1103,1104,1105,1106
    useradd oracle  -p $(echo "$ORACLE_PASSWORD"| openssl passwd -1 -stdin) -g 1101 -G 1102,1103,1104,1106,1107,1108,1109,1110
else
	echo " add user"
    useradd oracle  -p $(echo "$ORACLE_PASSWORD"| openssl passwd -1 -stdin) -g 1101 -G 1102,1103
fi
if [ $INSTALL_RAC == 'false' ]; then
    ORA_SID=$DB_NAME
else
    if [ `hostname` == ${NODE1_HOSTNAME} ] 
    then
        export  ORA_SID=${DB_NAME}1
        export GI_SID=+ASM1
    else
        export  ORA_SID=${DB_NAME}2
        export GI_SID=+ASM2
    fi

fi
if [ $INSTALL_RAC == 'true' ]; then
cat >> /home/grid/.bash_profile <<EOF
    export ORACLE_BASE=/u01/app/grid
    export ORACLE_HOME=/u01/app/11.2.0/grid
    export ORACLE_SID=${GI_SID}
    export PATH=\$PATH:\$ORACLE_HOME/bin
    
    umask 022
EOF
fi

cat >> /home/oracle/.bash_profile <<EOF
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/dbhome_1
export ORACLE_SID=${ORA_SID}
export PATH=\$PATH:\$ORACLE_HOME/bin
export NLS_LANG=American_america.ZHS16GBK
umask 022
EOF


cat >> /etc/pam.d/login <<EOF
session    required     pam_limits.so
EOF
#disable selinux
sed -i "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/sysconfig/selinux
setenforce 0


if [ $INSTALL_RAC == 'true' ]; then
	mkdir -p /u01/app/11.2.0/grid
	mkdir -p /u01/app/grid
	mkdir -p /u01/app/oracle/product/11.2.0/dbhome_1
	
	chown -R grid:oinstall /u01
	chown -R oracle:oinstall /u01/app/oracle
	
	mkdir -p /stage/patch
	chown grid:oinstall /stage
	
else
	mkdir -p /u01/app/oracle/product/11.2.0/dbhome_1
	chown -R oracle:oinstall /u01
	mkdir -p /u02/oradata
	chown -R oracle:oinstall /u02
fi


if [ $OSVER == 7 ]; then
    #这是linux7的设置
    #禁用时间同步time
    systemctl stop chronyd
    systemctl disable chronyd
    mv /etc/chrony.conf /etc/chrony.conf.bak
    
    #禁用防火墙
    systemctl stop firewalld
    systemctl disable firewalld
    
    #tuned
    systemctl stop tuned.service
    systemctl disable tuned.service
    
    #avahi
    systemctl stop avahi-dnsconfd
    systemctl stop avahi-daemon
    systemctl disable avahi-dnsconfd
    systemctl disable avahi-daemon
    
    #ref: 2380526.1
    systemctl stop NetworkManager.service
    systemctl disable NetworkManager.service
    

#for dbca . ref: Doc ID 2331884.1 
cat  >> /etc/systemd/system.conf <<EOF
DefaultTasksMax=infinity 
EOF
else
    # linux6
    
    #关闭ntpd
    service ntpd stop 
    chkconfig ntpd off
    #关闭防火墙
    service iptables stop
    chkconfig iptables off
    #禁用会启用透明大页的服务tuned
    service tuned stop
    chkconfig tuned off
    service ktune stop
    chkconfig ktune off

fi

#change format from dos to unix
rm pkg.lst

#执行完了要用oracle用户登录一下，再执行下一个脚本(mobaxterm)
