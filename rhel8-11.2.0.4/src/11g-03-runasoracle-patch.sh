#!/bin/bash
#以oracle用户执行
#2022.08.19 unzip 不问要不要覆盖
U=`id -u`
O=`id oracle -u`
if [ $U  != $O ]; then
        echo "Please run with oracle"
        exit 1;
fi

if [ ! -f /stage/p6880880_112000_Linux-x86-64.zip ];then
        echo "No p6880880_112000_Linux-x86-64.zip,exit";
        exit;
elif [ ! -f /stage/p31537677_112040_Linux-x86-64.zip ];then
        echo "No p31537677_112040_Linux-x86-64.zip, exit"
        exit;
fi


source /home/oracle/.bash_profile

cd $ORACLE_HOME

mv OPatch `date +'%Y-%m-%d-%H-%M-%S'`.OPatch
unzip /stage/p6880880_112000_Linux-x86-64.zip  >/dev/null 2>&1

rm -rf /stage/patch/144
rm -rf  /stage/patch/168

mkdir -p /stage/patch/144
chown oracle:oinstall /stage/patch/144
cd /stage/patch/144;unzip /stage/p14407401_112040_Generic.zip >/dev/null 2>&1

#patch p144
cat > /tmp/p144.expect <<EOF
#!/usr/bin/expect -f
spawn $ORACLE_HOME/OPatch/opatch apply
set timeout 10
expect "Do you want to proceed? \[y|n\]"
send "y\r"
set timeout 60
expect eof
EOF
#执行expect文件
chmod +x /tmp/p144.expect
cd /stage/patch/144/14407401
/tmp/p144.expect

#patch p168

echo -e "${INFO}`date +%F' '%T`: Now patch /p16811897 .."

mkdir -p /stage/patch/168
chown oracle:oinstall /stage/patch/168
cd /stage/patch/168;unzip /stage/p16811897_112040_Generic.zip >/dev/null 2>&1
cat > /tmp/p168.expect <<EOF
#!/usr/bin/expect -f
spawn $ORACLE_HOME/OPatch/opatch apply
set timeout 10
expect "Do you want to proceed? \[y|n\]"
send "y\r"
set timeout 60
expect eof
EOF
chmod +x /tmp/p168.expect
cd /stage/patch/168/16811897
/tmp/p168.expect


cd /stage/patch
unzip /stage/p31537677_112040_*.zip >/dev/null 2>&1
#cd 31537677 
#$ORACLE_HOME/OPatch/opatch apply

#patch p31537677
cat > /tmp/p315.expect <<EOF
#!/usr/bin/expect -f
spawn $ORACLE_HOME/OPatch/opatch apply
set timeout 10
expect "Do you want to proceed? \[y|n\]"
send "y\r"
set timeout 10
expect "Is the local system ready for patching? \[y|n\]"
send "y\r"
set timeout 300
expect eof
EOF
#执行expect文件
chmod +x /tmp/p315.expect
cd /stage/patch/31537677
/tmp/p315.expect


