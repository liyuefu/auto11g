#!/bin/bash
source ~/.bash_profile

echo -e "[check transparent_huage_page...]\n"
cat /sys/kernel/mm/transparent_hugepage/enabled
if [ -f /sys/kernel/mm/redhat-transparent_huagepage/enabled ]; then
cat /sys/kernel/mm/redhat_transparent_hugepage/enabled
fi

echo -e "\n[check hugepage...]\n"

cat /proc/meminfo|grep HugePage

echo -e "\n[check oralce using huge_page...]\n"

export p=`sqlplus -S / as sysdba <<EOF
set heading off;
set termout off;
set echo off;
select trim(value) from v\\$diag_info where name='Diag Trace';
EOF
`
echo -e "\n"
 

grep -A 16 "Large Pages Information"   ${p}/alert_${ORACLE_SID}.log


echo -e "\n[check async...]\n"
sqlplus -s / as sysdba <<EOF
COL NAME FORMAT A50
SELECT NAME,ASYNCH_IO FROM V\$DATAFILE F,V\$IOSTAT_FILE I WHERE F.FILE#=I.FILE_NO AND FILETYPE_NAME='Data File';
EOF

echo -e "\n[check autotask...]\n"
sqlplus -s / as sysdba  <<EOF
select client_name, status from dba_autotask_client;
EOF

echo -e "\n[check oracle component...]\n"
sqlplus -s / as sysdba <<EOF
set linesize 120
col comp_id format a10;
col comp_name format a35;
col version format a15;
col status format a8;
col modified format a30;
select comp_id,replace(comp_name,' ','.') comp_name,version,status,replace(replace(modified,' ',':'),'-','/') modified from dba_registry;
select comments from registry\$history;
EOF
$ORACLE_HOME/OPatch/opatch lspatches
