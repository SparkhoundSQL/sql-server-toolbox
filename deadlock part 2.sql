USE w
go
BEGIN TRAN t2
UPDATE dbo.lock WITH (TABLOCK) SET col1 = 3
UPDATE dbo.dead WITH (TABLOCK) SET col1 = 3
commit tran t2