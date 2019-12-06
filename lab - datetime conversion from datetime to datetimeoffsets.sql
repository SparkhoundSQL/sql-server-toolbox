use w
go

create table whateverdates
(id int not null IDENTITY(1,1) primary key 
, cdt datetime --we only assume this data is in CT, the only data we have initially.
, cdt_offset datetimeoffset(0)
, edt datetime 
, edt_offset  datetimeoffset(0)
)
GO
insert into dbo.whateverdates (cdt) values (getdate()) --now
insert into dbo.whateverdates (cdt) values ('10/28/2000 14:00') --historical data in DST
insert into dbo.whateverdates (cdt) values ('10/29/2000 14:00') --historical data after DST ended at 10/29/2000 at 1am
GO
update dbo.whateverdates
set cdt_offset = cdt AT TIME ZONE 'Central Standard Time' --assigns a time zone to datetime, which has no offset
GO
update dbo.whateverdates
set edt = cdt AT TIME ZONE 'Central Standard Time' AT TIME ZONE 'Eastern Standard Time' --asigns a time zone correctly (and historically), first to data without offset, then performing timezone math on data that has an offset
, edt_offset = cdt_offset AT TIME ZONE 'Eastern Standard Time' --asigns a time zone correctly (and historically) to data that has an offset
GO
select * from whateverdates
go

select * from sys.time_zone_info
drop table whateverdates