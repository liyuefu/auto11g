version: 2021.08.11
version:2021.09.02 (yum install xorg-x11-utils)
ver: 2021.09.18. 去掉了rac部分，shmmax的设置完善。 打补丁时的错误可以忽略，参考：Go Doc ID 2265726.1
ver: 2021.10.01. 自动创建DATA_PATH目录，增加11g-06-check.sh,安装完成检查。config LISTENER in 04.sh.
ver: 2021.11.19  PSU OCT20 打补丁后建库不需要执行patchpost. 其他补丁144，168 需要执行响应的脚本，在03中执行
                 CentOS 7.8 需要安装yum install psmisc,所以加入了这个命令
ver. 2021.11.29. fix 检查redhat时用red, 不是redhat。检查cdrom 是否mount 成功，mount cdrom失败后退出
ver. 2022.04.11  fix /etc/sysconfig/selinux文件修改时加上sed -i,否则不能修改源文件/etc/selinux/config.
ver. 2022.07.13  fix  chown -R oracle:oinstall $DATA_PATH/..   . 如果DATA_PATH是/oradata,会把
整个/属主改为oracle:oinstall. 
ver. 2022.07.15  fix 生产环境设置grub禁用大页.生产环境用UETI启动启动.需要
                    检查: /boot/efi/EFI/redhat/grub.cfg文件.
ver. 2022.07.29  检查是否已经mount了/mnt,如果没有mount再尝试mount iso文件.
ver. 2022.08.19  检查SHMMAX部分没有转换数字,去掉.
ver. 2022.08.29  oracle增加环境变量NLS_LANG. export NLS_LANG=American_america.ZHS16GBK
ver. 2022.08.30  11g-02-db-soft.sh 创建安装数据库的rsp文件时,加上oper,用户组,HOST_NAME
ver. 2022.09.05. 重写sysctl.conf文件 改.而不是创建 /etc/sysctl.d/98-oraclekernel.conf
ver. 2022.09.07. 在11g-03-runasoracle-patch.sh设置oracle占内存75%. 字符集
                    CHARACTERSET = "ZHS16GBK" 
                    NATIONALCHARACTERSET = "AL16UTF16"
                    MEMORYPERCENTAGE = "75"
                    这里设置的优先于在lidao_11g.dbt的设置. 
ver. 2022.09.21. PATH变量如果把ORACLE_HOME/bin放前面,和上期的脚本冲突.导致backup.sh时找不到sqlplus.改为放后面.  
ver. 2022.12.31  增加dbora service. 自动启动关闭oracle
ver. 2023.01.12  grub增加了centos的支持.  grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg  
ver. 2023.02.02   06.sh  查看alert文件时目录从$diag_info读取.
ver. 2023.02.28  redo改为100M,1个文件.去掉hostname,hostip, grid密码,不检查补丁包(可以不打补丁安装),打补丁时再检查补丁包
ver. 2023.03.29. fix bug. dbora只在linux7 .
ver. 2023.05.04  fix bug 11g-01-user-env.sh, 创建/etc/profile.d/oracle-grid.sh $USER前加转义符\
ver. 2023.06.20. useradd , 增加oracle用户时, oinstall必须也放在-G后面,否则/etc/group没有Oracle.
                 参考: Databases alert log showing ORA-17503/ORA-01017 (Doc ID 2919585.1)

1. 半自动安装oracle11g 单机。
在linux6， linux 7.

2.需要建目录/stage,把oracle安装包，补丁包（ref: 安装准备文件清单.bmp)上传到/stage。
解压auto11g*.tar.gz(或者zip格式),设置shell执行权限
chmod +x *.sh

3. 按照编号
1）以root执行 11g-01-user-env.sh，设置环境变量，建用户
2）以root执行 11g-02-db-soft.sh,安装oracle软件
3) 03,04以oracle用户登录执行。分别完成打补丁，建库,建库后执行sql。 05不需要执行。如果安装不同的PSU，要看README
中：1.3.4 Patch Post-Installation Instructions for Databases Created or Upgraded after Installation of this PSU in the Oracle Home 部分的说明
4）sqlplus / as sysdba @parameter_setting.sql 优化oracle参数
5) 关闭数据库，重启服务器(禁用透明大页 生效)
cat   /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/redhat_transparent_hugepage/enabled

6）根据设置的oracle内存（sga_max_size=sga_target=1/2内存, pga_aggretage=1/3 sga_max_size)
执行howto_huge_page_calculate.sh
得到建议的值，修改
/etc/sysctl.d/98-oraclekernel.conf
加上建议的值，比如
Recommended setting: vm.nr_hugepages = 76827
加上
vm.nr_hugepages = 76827
这是150G的sga的值。

7)重启服务器
8)执行11g-06-check.sh
检查确认上面设置的内容




###############################################参考内容##############################################


启动数据库，看到如下信息：
************************ Large Pages Information *******************
Per process system memlock (soft) limit = UNLIMITED
 
Total Shared Global Region in Large Pages = 150 GB (100%)
 
Large Pages used by this instance: 76801 (150 GB)
Large Pages unused system wide = 26 (52 MB)
Large Pages configured system wide = 76827 (150 GB)
Large Page size = 2048 KB
********************************************************************
说明已经启用大页。

3. 定制安装数据库 ,只安装3个组件
set linesize 120
col comp_id format a10;
col comp_name format a35;
col version format a15;
col status format a8;
col modified format a30;
select comp_id,replace(comp_name,' ','.') comp_name,version,status,replace(replace(modified,' ',':'),'-','/') modified from dba_registry;


OWM        Oracle.Workspace.Manager            11.2.0.4.0      VALID    11/AUG/2021:11:05:14
CATALOG    Oracle.Database.Catalog.Views       11.2.0.4.0      VALID    11/AUG/2021:11:05:14
CATPROC    Oracle.Database.Packages.and.Types  11.2.0.4.0      VALID    11/AUG/2021:11:05:14


4. 查看补丁
[oracle@redhat6 ~]$ /u01/app/oracle/product/11.2.0/dbhome_1/OPatch/opatch lspatches
31537677;Database Patch Set Update : 11.2.0.4.201020 (31537677)


###############################################
根据 	Oracle Database (RDBMS) on Unix AIX,HP-UX,Linux,Mac OS X,Solaris,Tru64 Unix Operating Systems Installation and Configuration Requirements Quick Reference (8.0.5 to 11.2) (Doc ID 169706.1)

SHMALL is the total amount of shared memory, in pages, that the system can use at one time.


kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
fs.file-max = 6815744 512 x processes (for example 6815744 for 13312 processes_
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
kernel.shmall = physical RAM size / pagesize For most systems, this will be the value 2097152. See Note: 301830.1 for more information.
kernel.shmmax = RAM times 0.5 (or higher at customer's discretion - see Note:567506.1)
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
aio-max-nr=3145728 (as per Note 579108.1) 



##################################################
把补丁时错误可以忽略；
错误信息：
OPatch found the word "error" in the stderr of the make command.
Please look at this stderr. You can re-run this make command.
Stderr output:
chmod: changing permissions of '$ORACLE_HOME/bin/extjobO': Operation not permitted
make: [iextjob] Error 1 (ignored)

解决：可以忽略


Applying Proactive Bundle / PSU Patch fails with Error: "chmod: changing permissions of `$ORACLE_HOME/bin/extjobO': Operation not permitted" (Doc ID 2265726.1)
The Issue / Warning "chmod: changing permissions of '$ORACLE_HOME/bin/extjobO'': Operation not permitted" can be ignored safely.

This is also mentioned in Read Me of the Proactive Bundle Patches as mentioned below.

