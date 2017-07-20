
--Look up deprecated counts, SQL 2008 and above
--http://msdn.microsoft.com/en-us/library/bb510662.aspx
--
SELECT object_name, instance_name, cntr_value

FROM sys.dm_os_performance_counters

WHERE object_name like '%Deprecated Features%'                    
                                                              