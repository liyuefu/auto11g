#!/bin/bash

U=`id -u`
R=`id root -u`
if [ $U  != $R ]; then
        echo "Please run with ROOT"
        exit 1;
else
        echo $USER
fi


make_RDBMS_software_installation() {

cp /stage/database/response/db_install.rsp /stage/db_install.rsp
source /stage/11g-setup.ini
cp /stage/database/response/db_install.rsp /stage/db_install.rsp

sed -i '/^#.*$/d' /stage/db_install.rsp
sed -i '/^$/d' /stage/db_install.rsp
sed -i "s#\(oracle.install.option=\)#\1INSTALL_DB_SWONLY#g" /stage/db_install.rsp
sed -i "s/\(ORACLE_HOSTNAME=\)/\1${HOST_NAME}/g" /stage/db_install.rsp
sed -i "s/\(UNIX_GROUP_NAME=\)/\1oinstall/g" /stage/db_install.rsp
sed -i "s#\(INVENTORY_LOCATION=\)#\1${ORA_INVENTORY}#g" /stage/db_install.rsp
sed -i "s#\(ORACLE_HOME=\)#\1${DB_HOME}#g" /stage/db_install.rsp
sed -i "s#\(ORACLE_BASE=\)#\1${DB_BASE}#g" /stage/db_install.rsp
sed -i "s/\(oracle.install.db.InstallEdition=\)/\1EE/g" /stage/db_install.rsp
sed -i "s/\(oracle.install.db.DBA_GROUP=\)/\1dba/g" /stage/db_install.rsp
sed -i "s/\(oracle.install.db.OPER_GROUP=\)/\1oper/g" /stage/db_install.rsp
sed -i "s/\(oracle.install.db.config.starterdb.type=\)/\1GENERAL_PURPOSE/g" /stage/db_install.rsp
sed -i "s#\(DECLINE_SECURITY_UPDATES=\)#\1TRUE#g" /stage/db_install.rsp

cat > /stage/db_install.sh <<EOF
cd /stage/database
#./runInstaller -ignorePrereq -waitforcompletion  -silent  -responsefile /stage/db_install.rsp
./runInstaller -ignorePrereq  -waitforcompletion -silent  -responseFile  /stage/db_install.rsp
EOF
chmod 755 /stage/db_install.sh
}
source /stage/11g-setup.ini
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Unzip RDBMS software"
echo "-----------------------------------------------------------------"
if [ -d /stage/database ]; then
    rm -rf /stage/database
fi
unzip -oq /stage/V17530-01_1of2.zip > /tmp/unzip_db.log
unzip -oq /stage/V17530-01_2of2.zip >> /tmp/unzip_db.log
rm -rf /stage/patch
chown -R oracle:oinstall /stage
rm -rf /u01/*
mkdir -p $DB_HOME
chown -R oracle:oinstall /u01
mkdir -p $DATA_PATH
chown -R oracle:oinstall $DATA_PATH

# install rdbms software 
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Install Oracle db"
echo "-----------------------------------------------------------------"
make_RDBMS_software_installation;
su - oracle -c "sh /stage/db_install.sh" 
sh ${ORA_INVENTORY}/orainstRoot.sh
sh ${DB_HOME}/root.sh
