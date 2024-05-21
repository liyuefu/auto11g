ver. 2023.10.26  增加支持RHEL8.

上传auto11g_full_20230228.tar.gz 到/stage.  
上传auto11g-rhel8-20231026-1315.zip 到/stage
解压auto11g_full_20230228.tar.gz

解压auto11g-rhel8-20231026-1315.zip (不使用auto11g_product_)
cp 11g-setup.ini setup.ini,根据数据库名字,安装目录,数据目录修改setup.ini
挂载iso mount  /dev/sr0 /mnt
然后以root执行01, 02, 
oracle执行04.

报错:
Oracle Database/Client 11.2.0.4 on RHEL/OL 8.x : OUI fails to launch with Errors "There was an error trying to initialize the HPI library.........Could not create the Java virtual machine" (Doc ID 2889673.1)
是因为没有安装libnsl-2.28-189.5.0.1.el8_6.x86_64                                   <<<<<<<<<<<<<<

