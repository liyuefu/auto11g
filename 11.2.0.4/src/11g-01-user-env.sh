#!/usr/bin/env bash
# update: 2021-09-23. redhat7 , ls /mnt | wc = 17
#update: 2023-06-10. user add Oracle, -G must include oinstall.
#update: 2023.09.02 . limits.conf nproc change to 16384, same as profile.d/oracle.sh
#update: 2024.05.21. refactoring with functions.

source ../lib/oralib.sh
SETUP_FILE="11g-setup.ini"

#if file_exists_and_not_empty $SETUP_FILE tmpfile; then
# if [ ! -f ./SETUP_FILE ]; then
#     echo "no SETUP_FILE, create one from 11g-example.ini"
#     exit 1
# fi


# if [ -f ./SETUP_FILE ]; then
#     mv  ./SETUP_FILE  ./11g-old.ini
# fi
#
# mv ./setup.ini ./SETUP_FILE
#
setup_dbora()
{
  cat > /lib/systemd/system/dbora.service <<EOF
  [Unit]
  Description=Oracle Database Start/Stop Service
  After=syslog.target network.target local-fs.target remote-fs.target
   
  [Service]
  # systemd, by design does not honor PAM limits
  # See: https://bugzilla.redhat.com/show_bug.cgi?id=754285
  LimitNOFILE=65536
  LimitNPROC=16384
  LimitSTACK=32M
  LimitMEMLOCK=infinity
  LimitCORE=infinity
   
  Type=simple
  User=oracle
  Group=oinstall
  Restart=no
  ExecStartPre=/bin/rm -f  $DB_HOME/listener.log
  ExecStartPre=/bin/rm -f  $DB_HOME/startup.log
  ExecStart=$DB_HOME/bin/dbstart $DB_HOME
  RemainAfterExit=yes
  ExecStop=/bin/rm -rf  $DB_HOME/shutdown.log
  ExecStop=$DB_HOME/bin/dbshut $DB_HOOME
  TimeoutStopSec=5min
   
  [Install]
  WantedBy=multi-user.target
EOF

}

if file_exists_and_not_empty $SETUP_FILE; then
  msg_ok "$SETUP_FILE is ok."
else
  msg_error "$SETUP_FILE no exists, please check it. or copy from 11g-example.ini"
  exit -1
fi

check_root `whoami` && msg_ok "yes, run with root" || msg_error "Please run with root";exit 1

# U=`id -u`
# R=`id root -u`
# if [ $U  != $R ]; then
#         echo "Please run with ROOT"
#         exit 1;
# else
#         echo $USER
# fi

OSVER=$(get_os_major_version)
if [ $OSVER = 6 ] || [ $OSVER = 7 ]; then
  msg_ok "OS version is ok"
else
  msg_error "Only support Version 6,7. for RHEL8 please use another scripts."
  exit 1
fi
#check install package.
#check oracle package

if [ ! -f /stage/p13390677_112040_Linux-x86-64_1of7.zip ]; then
	echo "No p13390677_112040_Linux-x86-64_1of7.zip, exit";
	exit 1;
elif [ ! -f /stage/p13390677_112040_Linux-x86-64_2of7.zip ]; then
	echo "No p13390677_112040_Linux-x86-64_2of7.zip, exit";
	exit 1;
#elif [ ! -f /stage/p6880880_112000_Linux-x86-64.zip ];then
#	echo "No p6880880_112000_Linux-x86-64.zip,exit";
#	exit;
elif [ ! -f /stage/compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm ];then
	echo "No compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm, exit"
	exit;
fi


# setup host01

DIRECTORY=/mnt
if [ "`ls -A $DIRECTORY`" = "" ]; then
#如果发现/mnt没有内容，自动mount
  if [ ${ISO} == false ];then
    mount /dev/sr0 /mnt
  else
    mount -o loop /stage/${ISO}  /mnt
  fi
  if [ $? != "0" ]; then
#mount失败，退出      
    echo "please mount ISO on /mnt."
    exit
  fi
fi

if [ ! -d /etc/yum.repos.d/bak ]; then
  mkdir /etc/yum.repos.d/bak
fi
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak

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
xorg-x11-utils
EOF

fi

yum install -y `awk '{print $1}' /stage/pkg.lst`
#yum install -y psmisc
rpm -ivh /stage/compat-libstdc++-33*.rpm

dos2unix *.sh *.ini *.rsp *.txt

. /stage/SETUP_FILE

cat > /etc/profile.d/oracle.sh <<EOF
#Setting the appropriate ulimits for oracle 
if [ \$USER = "oracle" ]; then
  if [ \$SHELL = "/bin/ksh" ]; then
    ulimit -u 16384
    ulimit -n 65536
  else
    ulimit -u 16384 -n 65536
  fi
fi
EOF

cat > /etc/security/limits.d/99-oracle-limits.conf <<EOF
oracle soft nproc 16384
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
oracle hard stack 32768
oracle soft memlock -1
oracle hard memlock -1
EOF

# Recommended value for NOZEROCONF
#for RAC. 设置NOZEROCONF以确保路由169.254.0.0/16不会被添加到路由表中。
#cat  >> /etc/sysconfig/network <<EOF
#NOZEROCONF=yes
#EOF
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
        grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
        grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
    fi
else
#for linux6
    TRANSPARENT_HUGEPAGE=`grep "transparent_hugepage=never" /etc/grub.conf | wc | awk '{ print $1}'`
    if [  $TRANSPARENT_HUGEPAGE != "1" ]; then
        mv /etc/grub.conf /etc/grub.conf.def
        sed 's/\(.*\)quiet/\1quiet transparent_hugepage=never numa=off/' /etc/grub.conf.def > /etc/grub.conf
    fi

fi

echo "check shmmax now..."
cat /proc/sys/kernel/shmmax
echo "check shmall now..."
cat /proc/sys/kernel/shmall

cat >> /etc/hosts <<EOF
${HOST_IP}    ${HOST_NAME}
EOF

#####

#add kernel params

#cat > /etc/sysctl.d/98-oraclekernel.conf <<EOF
#fs.aio-max-nr = 1048576
#fs.file-max = 6815744
#kernel.sem = 250 32000 100 128
#kernel.shmmni = 4096
#net.ipv4.ip_local_port_range = 9000 65500
#net.core.rmem_default = 262144
#net.core.rmem_max = 4194304
#net.core.wmem_default = 262144
#net.core.wmem_max = 1048576
#vm.min_free_kbytes = 524288
#vm.nr_hugepages= xx
#EOF

cat > /etc/sysctl.conf<<EOF
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 18446744073692774399
kernel.shmmax = 18446744073692774399
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
#vm.min_free_kbytes = 524288
#vm.nr_hugepages= xx
EOF


/sbin/sysctl --system

id oracle
if [ $? -eq 0 ]; then
  echo "!!!!!!!!!!!!!ORACLE user exists now , if you continue, it will be recreated!!!!!!!!!!!!!!!!!!"
  read -p  "oracle will be deleted and created again, do you want to continue?[NO/YES]" recreate
  echo $recreate
  if [ "$recreate"x != "YES"x ];then
    exit 1;
  fi
fi

userdel -fr oracle
groupdel oinstall
groupdel oper
groupdel dba
groupadd -g 1101 oinstall
groupadd -g 1102 oper
groupadd -g 1103 dba

useradd oracle  -p $(echo "$ORACLE_PASSWORD"| openssl passwd -1 -stdin) -u 1101 -g 1101 -G 1101,1102,1103

export  ORA_SID=$DB_NAME

cat >> /home/oracle/.bash_profile <<EOF
export ORACLE_BASE=$DB_BASE
export ORACLE_HOME=$DB_HOME
export ORACLE_SID=${ORA_SID}
export PATH=$PATH:$DB_HOME/bin
export NLS_LANG=American_america.ZHS16GBK
export NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"
export LD_LIBRARY_PATH=$DB_HOME/lib
export PATH=$PATH:$DB_HOME/bin:$DB_HOME/OPatch

umask 022
EOF


cat >> /etc/pam.d/login <<EOF
session    required     pam_limits.so
EOF
#disable selinux
sed -i "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/selinux/config
setenforce 0



if [ $OSVER == 7 ]; then
    #这是linux7的设置
    #禁用时间同步time
    systemctl stop chronyd
    systemctl disable chronyd
    if [ -f /etc/chrony.conf ]; then
        mv /etc/chrony.conf /etc/chrony.conf.bak
    fi
    
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
    #create dbora service script
    setup_dbora
    

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

