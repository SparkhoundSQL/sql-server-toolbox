--http://blogs.msdn.com/b/dpless/archive/2010/12/01/leveraging-sys-dm-io-virtual-file-stats.aspx?Redirected=true

select d.name, mf.physical_name
, SizeMb = size_on_disk_bytes /1024./1024. 
--, mf.size*8./1024. --same
, io_stall_read_s = fs.io_stall_read_ms /1000.
, io_stall_write_s = fs.io_stall_write_ms /1000.
, io_stall_s = fs.io_stall / 1000.
from sys.dm_io_virtual_file_stats (null,null) fs
inner join sys.master_files mf on fs.file_id = mf.file_id
inner join sys.databases d on d.database_id = mf.database_id  and fs.database_id = d.database_id

order by io_stall desc