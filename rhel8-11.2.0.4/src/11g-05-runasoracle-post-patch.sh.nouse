#!/bin/bash

U=`id -u`
O=`id oracle -u`
if [ $U  != $O ]; then
        echo "Please run with ORACLE."
        exit 1;
fi

#根据 PSU OCT20的说明，不需要执行这个
#执行打补丁的文件
#source /stage/11g-setup.ini
#source /home/oracle/.bash_profile

#cd $ORACLE_HOME/rdbms/admin
#cat > /stage/post_patch.sql <<EOF
#SHUTDOWN IMMEDIATE
#STARTUP
#@?/rdbms/admin/catbundle.sql psu apply
#@?/rdbms/admin/utlrp.sql
#QUIT
#EOF

#$ORACLE_HOME/bin/sqlplus / as sysdba @/stage/post_patch.sql



#install 14407401
#cd /stage/patch
#unzip /stage/p14407401_112040_Generic.zip
#cd 14407401
#$ORACLE_HOME/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -ph ./
#$ORACLE_HOME/OPatch/opatch apply
sqlplus / as sysdba <<EOF
@?/sqlpatch/14407401/postinstall.sql
exit
EOF

#install p16811897_112040_Generic.zip
#cd /stage/patch
#unzip /stage/p16811897_112040_Generic.zip
#cd 16811897
#$ORACLE_HOME/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -ph ./
#$ORACLE_HOME/OPatch/opatch apply
sqlplus / as sysdba <<EOF
@?/sqlpatch/16811897/postinstall.sql
exit
EOF

#install p18841764_112040_Linux-x86-64.zip
#PSU已经包括了，跳过

