--11g 单实例数据库安装后设置

--检查aio
COL NAME FORMAT A50
SELECT NAME,ASYNCH_IO FROM V$DATAFILE F,V$IOSTAT_FILE I
WHERE F.FILE#=I.FILE_NO
AND FILETYPE_NAME='Data File';
--启用aio
alter system set filesystemio_options=setall scope=spfile;

--禁用自动任务
alter profile default limit PASSWORD_LIFE_TIME unlimited;
begin
dbms_auto_task_admin.disable(client_name=>'sql tuning advisor',operation=>NULL,window_name=>NULL);
end;
/
begin
dbms_auto_task_admin.disable(client_name=>'auto space advisor',operation=>NULL,window_name=>NULL);
end;
/

begin
dbms_auto_task_admin.disable(client_name=>'auto optimizer stats collection',operation=>NULL,window_name=>NULL);
end;

/
select client_name, status from dba_autotask_client;



--其它
alter system set deferred_segment_creation=false scope=spfile sid='*';
alter system set audit_trail=none scope=spfile sid='*';
alter system set aq_tm_processes=10 scope=spfile sid='*';
alter system set open_cursors=3000 scope=spfile sid='*';
alter system set fast_start_mttr_target=900 scope=spfile sid='*';
alter system set db_flashback_retention_target=10800 scope=spfile sid='*';
alter system set undo_retention=10800 scope=spfile sid='*';
alter system set optimizer_capture_sql_plan_baselines=false scope=spfile sid='*';
alter profile default limit PASSWORD_LIFE_TIME unlimited;


--重启
shutdown immediate;
startup
--检查aio
COL NAME FORMAT A50
SELECT NAME,ASYNCH_IO FROM V$DATAFILE F,V$IOSTAT_FILE I
WHERE F.FILE#=I.FILE_NO
AND FILETYPE_NAME='Data File';

