#!/bin/bash
#dbca 建库

U=`id -u`
O=`id oracle -u`
if [ $U  != $O ]; then
        echo "Please run with ORACLE."
        exit 1;
fi

DATA_PATH=""
source /stage/11g-setup.ini
cat > /stage/db_create.rsp<<EOF
[GENERAL]
RESPONSEFILE_VERSION = "11.2.0"
OPERATION_TYPE = "createDatabase"
[CREATEDATABASE]
GDBNAME = "${DB_NAME}"
SID = "${DB_NAME}"
TEMPLATENAME = "lidao_11g.dbt"
CHARACTERSET = "ZHS16GBK" 
NATIONALCHARACTERSET = "AL16UTF16"
MEMORYPERCENTAGE = "75"
EMCONFIGURATION = "NONE"
SYSPASSWORD = "${SYS_PASSWORD}"
SYSTEMPASSWORD = "${SYS_PASSWORD}"
DBSNMPPASSWORD = "${SYS_PASSWORD}"
SYSMANPASSWORD = "${SYS_PASSWORD}"
EOF

#不用快速恢复区
#sed -i '/initParam name="db_recovery_file_dest"/d'  $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
#sed -i '/initParam name="db_recovery_file_dest_size"/d'  $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
#不安装选件
#sed -i 's#option name="JSERVER" value="true"#option name="JSERVER" value="false"#g' $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
#sed -i 's#option name="SPATIAL" value="true"#option name="SPATIAL" value="false"#g' $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
#sed -i 's#option name="IMEDIA" value="true"#option name="IMEDIA" value="false"#g' $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
#sed -i 's#option name="XDB_PROTOCOLS" value="true"#option name="XDB_PROTOCOLS" value="false"#g' $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
#sed -i 's#option name="ORACLE_TEXT" value="true"#option name="ORACLE_TEXT" value="false"#g' $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
#sed -i 's#option name="EM_REPOSITORY" value="true"#option name="EM_REPOSITORY" value="false"#g' $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
#sed -i 's#option name="APEX" value="true"#option name="APEX" value="false"#g' $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
#sed -i 's#option name="OWB" value="true"#option name="OWB" value="false"#g' $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
#sed -i 's#option name="CWMLITE" value="true"#option name="CWMLITE" value="false"#g' $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
echo $DATA_PATH

cp /stage/lidao_11g.dbt $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
if [ ! -z $DATA_PATH ] ; then
#用户自定义了数据存放目录
	if [ -d $DATA_PATH ]; then
	    sed -i "s#{ORACLE_BASE}/oradata#${DATA_PATH}#g" $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
            sed -i "s#{ORACLE_BASE}/fast_recovery_area#${DATA_PATH}#g"  $ORACLE_HOME/assistants/dbca/templates/lidao_11g.dbt
     
	else
		echo "Please check $DATA_PATH, make sure it exists and owner is oracle:oinstall"
		exit 1;
	fi
fi

$ORACLE_HOME/bin/dbca -silent -force -responseFile  /stage/db_create.rsp

