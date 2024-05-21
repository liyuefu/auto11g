#!/usr/bin/env bash
declare -r DIR="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
source $DIR/../src/lib/bsfl.sh
source $DIR/../src/lib/ext_bsfl.sh

declare -x LOG_ENABLED="yes"
declare -x DEBUG="yes"
declare -x TMPDIR="$DIR/../tmp"
declare -r TRUE=0
declare -r FALSE=1

dirname0=`dirname $0`
msg_info "dirname 0 is $dirname0"
msg_info "pwd is `pwd`"
msg_info "DIR is $DIR"
msg_info "TMPDIR is $TMPDIR"
#mkdir for temporary files used by oralib.
if [ ! -d $TMPDIR ]; then
  mkdir $TMPDIR
fi

####if not ends with / , output == ""
#### else  output != ""
check_path_ends_with_slash() {
  local parafile=$1

  #use sed to check if line end with / . / must be removed.
  slashline=$(sed -n '/\/$/p' $parafile)
#  echo $slashline
}

#### input a tmp file name $1, remove empty line and space, output text to a new text file $2.
get_one_row_data() {
  local tmpfile=$1
  newfile=$2
  if file_exists_and_not_empty $tmpfile; then
    grep -v ^$ $tmpfile |awk '{print $(NF)}' > $newfile
  else
    echo ""
  fi
}

#### from all the datafile, get the data path ,unique them and save to newfile.
#### there maybe multiple rows
get_multiple_row_data() {
  local tmpfile=$1
  newfile=$2
  if file_exists_and_not_empty $tmpfile; then
    sed 's/\(.*\)\/.*/\1/' $tmpfile | sed '/^$/d' |sort -r|uniq > $newfile
    #取最后一个\前的所有字符, 最后一个\后的字符舍弃.然后去掉空行, 排序, 去重, 保存到newfile.
#    cat $newfile
  else
    echo ""
  fi
}

# get diskgroup name from diskgroup filename. 
# input: +data/asp/datafile/system01.dbf. 
# output: +data
# $1 : tmpfile, contains diskgroup file name. 
# $2 : txt file to store disk group name.
# output : disk group name
get_diskgroup_name() {
  local tmpfile=$1
  newfile=$2
  awk -F'/' '{print $1}' $tmpfile | sort -r| uniq |grep -v ^$ > $newfile
  cat $newfile
}

#get oracle database info
#$1  ORACLE_HOME
#$2 model file name
#$3 sql file
get_dbinfo() {
  local ORACLE_HOME=$1
  local MODEL_FILE=$2
  local SQL_FILE=$3
  sed  "s#TMPPATH#$TMPDIR#g" $MODEL_FILE > $SQL_FILE
  #get database info and save to TMPDIR
  $ORACLE_HOME/bin/sqlplus -s / as sysdba @$SQL_FILE >/tmp/sqlplus.log 2>&1

  if grep "ORACLE" $TMPDIR/dbname.tmp; then
    return 1
  else
    format_dbinfo
    return 0
  fi
}
#
#convert information from dbinfo to formatted txt file.
#input : called by get_dbinfo. it create tmp files.
format_dbinfo(){
  get_one_row_data  $TMPDIR/dbname.tmp $TMPDIR/dbname.txt
  get_one_row_data  $TMPDIR/db_unique_name.tmp $TMPDIR/db_unique_name.txt
  get_one_row_data  $TMPDIR/cluster.tmp $TMPDIR/cluster.txt
  get_one_row_data  $TMPDIR/cluster_database_instances.tmp $TMPDIR/cluster_database_instances.txt
  get_one_row_data  $TMPDIR/domain.tmp $TMPDIR/domain.txt
  get_one_row_data  $TMPDIR/dbid.tmp $TMPDIR/dbid.txt
  get_one_row_data  $TMPDIR/version.tmp $TMPDIR/version.txt
  get_one_row_data  $TMPDIR/logsize.tmp $TMPDIR/logsize.txt
  get_multiple_row_data $TMPDIR/dbpath.tmp $TMPDIR/dbpath.txt
  get_multiple_row_data $TMPDIR/logpath.tmp $TMPDIR/logpath.txt
  cp $TMPDIR/logpath.txt $TMPDIR/addlogpath.txt

  cat $TMPDIR/banner.tmp |grep '^oracle database'| awk '{ print $3}' >$TMPDIR/dbver_major.txt
#  cat $TMPDIR/banner.tmp |grep '^oracle database'| awk '{ print $7}' >$TMPDIR/dbver_detail.txt
}
#check if current user is root
#$1 username
#return 0 , root user, 1 non-root user.
check_root() {
  local user=$1
  userid=`id $user -u`
  rootid=`id root -u`
  if [ $rootid  == $userid ]; then
    return 0
  else
    return 1
  fi
}

#check os distribute and version. 
get_os_major_version(){
  OSDIST=`cat /etc/redhat-release | awk '{ print $1 }'`
  if [ $OSDIST = 'CentOS' ]; then
    OSVER=`cat /etc/redhat-release  | awk '{ print $4 }' | awk -F. '{ print $1 }'`
  elif [ $OSDIST = 'Red' ]; then
    OSVER=`cat /etc/redhat-release  | awk '{ print $7 }' | awk -F. '{ print $1 }'`
  else
    OSVER="ERROR:NOSUPPORT"
  fi
  echo $OSVER
}
