#!/bin/bash
#shmmax : 0.5 x RAM
#shmmax: shmmax/4096
# update: 2021-09-23. redhat7 , ls /mnt | wc = 17



U=`id -u`
R=`id root -u`
if [ $U  != $R ]; then
        echo "Please run with ROOT"
        exit 1;
else
        echo $USER
fi

#check os version
OSDIST=`cat /etc/redhat-release | awk '{ print $1 }'`

if [ $OSDIST = 'CentOS' ]; then
  OSVER=`cat /etc/redhat-release  | awk '{ print $4 }' | awk -F. '{ print $1 }'`
elif [ $OSDIST = 'Red' ]; then
  OSVER=`cat /etc/redhat-release  | awk '{ print $7 }' | awk -F. '{ print $1 }'`
else
  echo "What Linux is This"
  exit 1
fi

if [ $OSVER != 6  -a $OSVER != 7 ] ; then
    echo "Only support Linux 6 and 7. Exit"
    exit 1;
fi 

#check install package.
#check oracle package

if [ ! -f /stage/V17530-01_1of2.zip ]; then
	echo "No V17530-01_1of2.zip , exit";
	exit 1;
elif [ ! -f /stage/V17530-01_2of2.zip ]; then
	echo "No V17530-01_1of2.zip  exit";
	exit 1;
fi


. /stage/11g-setup.ini
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

mkdir /etc/yum.repos.d/bak
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

#if  [ $INSTALL_RAC == 'true' ];then
#    cat >> /etc/profile.d/oracle-grid.sh <<EOF
#    if [ \$USER = "grid" ]; then
#      if [ \$SHELL = "/bin/ksh" ]; then
#        ulimit -u 16384
#        ulimit -n 65536
#      else
#        ulimit -u 16384 -n 65536
#      fi
#    fi
#EOF
#fi

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
        grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg 
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

cat > /etc/sysctl.d/98-oraclekernel.conf <<EOF
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF


/sbin/sysctl --system

userdel -fr oracle
groupdel oinstall
groupdel oper
groupdel dba
groupadd -g 1101 oinstall
groupadd -g 1102 oper
groupadd -g 1103 dba

useradd oracle  -p $(echo "$ORACLE_PASSWORD"| openssl passwd -1 -stdin) -u 1101 -g 1101 -G 1102,1103

export  ORA_SID=$DB_NAME

cat >> /home/oracle/.bash_profile <<EOF
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/dbhome_1
export ORACLE_SID=${ORA_SID}
export PATH=$PATH:\$ORACLE_HOME/bin
export NLS_LANG=American_america.ZHS16GBK
umask 022
EOF


cat >> /etc/pam.d/login <<EOF
session    required     pam_limits.so
EOF
#disable selinux
sed -i "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/selinux/config
setenforce 0


mkdir -p /u01/app/oracle/product/11.2.0/dbhome_1
chown -R oracle:oinstall /u01


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
