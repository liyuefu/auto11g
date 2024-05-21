#!/bin/bash
#shmmax : 0.5 x RAM
#shmmax: shmmax/4096
# update: 2021-09-23. redhat7 , ls /mnt | wc = 17

if [ ! -f ./setup.ini ]; then
  echo "no setup.ini, create one from 11g-example.ini"
  exit 1
fi

if [ -f ./11g-setup.ini ]; then
  mv ./11g-setup.ini ./11g-setup-old.ini
fi

cp -f ./setup.ini ./11g-setup.ini

setup_dbora() {
  cat >/lib/systemd/system/dbora.service <<EOF
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

U=$(id -u)
R=$(id root -u)
if [ $U != $R ]; then
  echo "Please run with ROOT"
  exit 1
else
  echo $USER
fi

#check os version
OSDIST=$(cat /etc/redhat-release | awk '{ print $1 }')
echo $OSDIST

if [ $OSDIST = 'CentOS' ]; then
  OSVER=$(cat /etc/redhat-release | awk '{ print $4 }' | awk -F. '{ print $1 }')
elif [ $OSDIST = 'Red' ]; then
  OSVER=$(cat /etc/redhat-release | awk '{ print $(NF-1) }' | awk -F. '{ print $1 }')
else
  grep 'release 8' /etc/redhat-release >/dev/null && OSVER='8'
  echo "This is $OSDIST $OSVER"
fi


#check install package.
#check oracle package

if [ ! -f /stage/p13390677_112040_Linux-x86-64_1of7.zip ]; then
  echo "No p13390677_112040_Linux-x86-64_1of7.zip, exit"
  exit 1
elif [ ! -f /stage/p13390677_112040_Linux-x86-64_2of7.zip ]; then
  echo "No p13390677_112040_Linux-x86-64_2of7.zip, exit"
  exit 1
# elif [ ! -f /stage/p6880880_112000_Linux-x86-64.zip ]; then
#   echo "No p6880880_112000_Linux-x86-64.zip,exit"
#   exit
# elif [ ! -f /stage/compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm ]; then
#   echo "No compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm, exit"
#   exit
fi

# setup host01

DIRECTORY=/mnt
if [ "$(ls -A $DIRECTORY)" = "" ]; then
  #如果发现/mnt没有内容，自动mount
  if [ ${ISO} == false ]; then
    mount /dev/sr0 /mnt
  else
    mount -o loop /stage/${ISO} /mnt
  fi
  if [ $? != "0" ]; then
    #mount失败，退出
    echo "please mount ISO on /mnt."
    exit
  fi
fi

mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak

if [ $OSVER != "8" ]; then
  cat >/etc/yum.repos.d/iso.repo <<EOF
[iso]
name=iso
baseurl=file:///mnt
enabled=1
gpgcheck=0
EOF
else
  cat >/etc/yum.repos.d/iso.repo <<EOF
[dvd-BaseOS]
name=DVD for RHEL - BaseOS
baseurl=file:///mnt/BaseOS
enabled=1
gpgcheck=0

[dvd-AppStream]
name=DVD for RHEL - AppStream
baseurl=file:///mnt/AppStream
enabled=1
gpgcheck=0
EOF
fi

if [ $OSVER == "7" ]; then
  #linux7
  cat >/stage/pkg.lst <<EOF
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

elif [ $OSVER == "6" ]; then
  #linux6
  cat >/stage/pkg.lst <<EOF
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
elif [ -f /etc/redhat-release ]; then
  if uname -a | grep 'x86_64' >/dev/null; then
    grep -E '(release 6|release 7|release 8)' /etc/redhat-release >/dev/null
    if [ $? -eq 0 ]; then
      bit32=i686
      grep 'release 8' /etc/redhat-release >/dev/null && DNFOPT='--setopt=strict=0'
    else
      bit32=i386
    fi
    yum -y $DNFOPT install tar bzip2 gzip install bc nscd perl-TermReadKey unzip zip parted openssh-clients bind-utils wget nfs-utils smartmontools \
      binutils.x86_64 compat-db.x86_64 compat-libcap1.x86_64 compat-libstdc++-296.${bit32} compat-libstdc++-33.x86_64 compat-libstdc++-33.${bit32} \
      elfutils-libelf-devel.x86_64 gcc.x86_64 gcc-c++.x86_64 glibc.x86_64 glibc.${bit32} glibc-devel.x86_64 glibc-devel.${bit32} ksh.x86_64 libaio.x86_64 net-tools.x86_64 \
      libaio-devel.x86_64 libaio.${bit32} libaio-devel.${bit32} libgcc.${bit32} libgcc.x86_64 libgnome.x86_64 libgnomeui.x86_64 libstdc++.x86_64 libstdc++-devel.x86_64 \
      libstdc++.${bit32} libstdc++-devel.${bit32} libXp.${bit32} libXt.${bit32} libXtst.x86_64 libXtst.${bit32} make.x86_64 pdksh.x86_64 psmisc.x86_64 sysstat.x86_64 unixODBC.x86_64 \
      unixODBC-devel.x86_64 unixODBC.${bit32} unixODBC-devel.${bit32} xorg-x11-utils.x86_64 libnsl.x86_64 libnsl expect
  else
    yum -y install bc nscd perl-TermReadKey unzip zip parted openssh-clients bind-utils wget nfs-utils smartmontools binutils compat-db compat-libcap1 compat-libstdc++-296 \
      compat-libstdc++-33 elfutils-libelf-devel gcc gcc-c++ glibc glibc-devel ksh libaio net-tools libaio-devel libgcc libgnome libgnomeui libstdc++ libstdc++-devel \
      libXp libXt libXtst make pdksh sysstat unixODBC unixODBC-devel xorg-x11-utils
  fi
#elif [ -f /etc/SuSE-release ]; then
#    if uname -a | grep 'x86_64' >/dev/null; then
#        zypper -n in -l --no-recommends binutils gcc gcc48 glibc glibc-32bit glibc-devel glibc-devel-32bit \
#            mksh libaio1 libaio-devel libcap1 libstdc++48-devel libstdc++48-devel-32bit libstdc++6 libstdc++6-32bit \
#            libstdc++-devel libstdc++-devel-32bit libgcc_s1 libgcc_s1-32bit make sysstat xorg-x11-driver-video \
#            xorg-x11-server xorg-x11-essentials xorg-x11-Xvnc xorg-x11-fonts-core xorg-x11 xorg-x11-server-extra xorg-x11-libs xorg-x11-fonts
#    fi
fi

#yum install -y psmisc
rpm -ivh /stage/compat-libstdc++-33*.rpm
#remove new libaio
yum remove -y libaio
#install rhel7.9 libaio
yum install -y libaio*

ln -s /lib64/libnsl.so.1 /lib64/libnsl.so 2>/dev/null

dos2unix *.sh *.ini *.rsp *.txt

. /stage/11g-setup.ini

cat >/etc/profile.d/oracle-grid.sh <<EOF
#Setting the appropriate ulimits for oracle and grid user
if [ $USER = "oracle" ]; then
  if [ $SHELL = "/bin/ksh" ]; then
    ulimit -u 16384
    ulimit -n 65536
  else
    ulimit -u 16384 -n 65536
  fi
fi
EOF

#if  [ $INSTALL_RAC == 'true' ];then
#    cat >> /etc/profile.d/oracle-grid.sh <<EOF
#    if [ $USER = "grid" ]; then
#      if [ $SHELL = "/bin/ksh" ]; then
#        ulimit -u 16384
#        ulimit -n 65536
#      else
#        ulimit -u 16384 -n 65536
#      fi
#    fi
#EOF
#fi

cat >>/etc/security/limits.conf <<EOF
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
cat >>/etc/sysconfig/network <<EOF
NOZEROCONF=yes
EOF

#disable transparent_hugepage , numa

cat >>/etc/rc.local <<EOF
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

if [ $OSVER == "7" ]; then
  #for linux7
  TRANSPARENT_HUGEPAGE=$(grep "transparent_hugepage=never" /etc/default/grub | wc | awk '{ print $1}')
  if [ $TRANSPARENT_HUGEPAGE != "1" ]; then
    mv /etc/default/grub /etc/default/grub.def
    sed 's/\(.*\)quiet/\1quiet transparent_hugepage=never numa=off/' /etc/default/grub.def >/etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg
    grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
    grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
  fi
else
  #for linux6
  TRANSPARENT_HUGEPAGE=$(grep "transparent_hugepage=never" /etc/grub.conf | wc | awk '{ print $1}')
  if [ $TRANSPARENT_HUGEPAGE != "1" ]; then
    mv /etc/grub.conf /etc/grub.conf.def
    sed 's/\(.*\)quiet/\1quiet transparent_hugepage=never numa=off/' /etc/grub.conf.def >/etc/grub.conf
  fi

fi

echo "check shmmax now..."
cat /proc/sys/kernel/shmmax
echo "check shmall now..."
cat /proc/sys/kernel/shmall

cat >>/etc/hosts <<EOF
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
#EOF

cat >/etc/sysctl.conf <<EOF
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
EOF

/sbin/sysctl --system

id oracle
if [ $? -eq 0 ]; then
  echo "!!!!!!!!!!!!!ORACLE user exists now , if you continue, it will be recreated!!!!!!!!!!!!!!!!!!"
  read -p "oracle will be deleted and created again, do you want to continue?[NO/YES]" recreate
  if [ $recreate != "YES" ]; then
    exit 1
  fi
fi

userdel -fr oracle 2> /dev/null
groupdel oinstall 2> /dev/null
groupdel oper 2> /dev/null
groupdel dba 2> /dev/null
groupadd -g 1101 oinstall 
groupadd -g 1102 oper
groupadd -g 1103 dba

useradd oracle -p $(echo "$ORACLE_PASSWORD" | openssl passwd -1 -stdin) -u 1101 -g 1101 -G 1102,1103

export ORA_SID=$DB_NAME

cat >>/home/oracle/.bash_profile <<EOF
export ORACLE_BASE=$DB_BASE
export ORACLE_HOME=$DB_HOME
export ORACLE_SID=${ORA_SID}
export PATH=$PATH:$DB_HOME/bin
export NLS_LANG=American_america.ZHS16GBK
umask 022
EOF

cat >>/etc/pam.d/login <<EOF
session    required     pam_limits.so
EOF
#disable selinux
sed -i "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/selinux/config
setenforce 0

if [ $OSVER == 6 ]; then
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
else
 #这是linux7/8的设置
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

  #for dbca . ref: Doc ID 2331884.1
  cat >>/etc/systemd/system.conf <<EOF
DefaultTasksMax=infinity 
EOF

fi

#change format from dos to unix
#rm pkg.lst

#create dbora service script
setup_dbora
