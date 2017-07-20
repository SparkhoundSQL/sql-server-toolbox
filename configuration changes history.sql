--Based on the configuration changes history report in SSMS
exec sp_executesql @stmt=N'begin try
declare @enable int;
select @enable = convert(int,value_in_use) from sys.configurations where name = ''default trace enabled''
if @enable = 1 --default trace is enabled
begin
        declare @d1 datetime;
        declare @diff int;  
        declare @curr_tracefilename varchar(500); 
        declare @base_tracefilename varchar(500); 
        declare @indx int ;
        declare @temp_trace table (
                textdata nvarchar(MAX) collate database_default 
        ,       login_name sysname collate database_default
        ,       start_time datetime
        ,       event_class int
        );
        
        select @curr_tracefilename = path from sys.traces where is_default = 1 ; 
        
        set @curr_tracefilename = reverse(@curr_tracefilename)
        select @indx  = PATINDEX(''%\%'', @curr_tracefilename) 
        set @curr_tracefilename = reverse(@curr_tracefilename)
        set @base_tracefilename = LEFT( @curr_tracefilename,len(@curr_tracefilename) - @indx) + ''\log.trc'';
        
        insert into @temp_trace
        select TextData
        ,       LoginName
        ,       StartTime
        ,       EventClass 
        from ::fn_trace_gettable( @base_tracefilename, default ) 
        where ((EventClass = 22 and Error = 15457) or (EventClass = 116 and TextData like ''%TRACEO%(%''))
        
        select @d1 = min(start_time) from @temp_trace
        
        --set @diff= datediff(hh,@d1,getdate())
        --set @diff=@diff/24; 

        select --(row_number() over (order by start_time desc))%2 as l1
                @d1 as TraceStartDate
        ,       start_time as EventDate
		,       case event_class 
                        when 116 then ''Trace Flag '' + substring(textdata,patindex(''%(%'',textdata),len(textdata) - patindex(''%(%'',textdata) + 1) 
                        when 22 then substring(textdata,58,patindex(''%changed from%'',textdata)-60) 
                end as config_option
        ,       login_name
        ,       case event_class 
                        when 116 then ''--''
                        when 22 then substring(substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))
                                                                ,patindex(''%changed from%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata)))+13
                                                                ,patindex(''%to%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))) - patindex(''%from%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))) - 6) 
                end as old_value
        ,       case event_class 
                        when 116 then substring(textdata,patindex(''%TRACE%'',textdata)+5,patindex(''%(%'',textdata) - patindex(''%TRACE%'',textdata)-5)
                        when 22 then substring(substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))
                                                                ,patindex(''%to%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata)))+3
                                                                , patindex(''%. Run%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))) - patindex(''%to%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))) - 3) 
                end as new_value
        from @temp_trace 
        order by start_time desc
end else 
begin 
        select top 0  1  as l1, 1 as difference,1 as date , 1 as config_option,1 as start_time , 1 as login_name, 1 as old_value, 1 as new_value
end
end try 
begin catch
select  ERROR_NUMBER() as Error_Number
,       ERROR_SEVERITY() as date 
,       ERROR_STATE() as config_option
,       1 as start_time 
,       ERROR_MESSAGE() as login_name
,       1 as old_value, 1 as new_value
end catch',@params=N''