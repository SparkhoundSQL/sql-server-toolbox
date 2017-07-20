--same
Select CHECKSUM('sha2_512','Sparkhound')
Select CHECKSUM('sha2_512','AAAAAAAAAAAAAAAASparkhound')

--same 
Select BINARY_CHECKSUM('sha2_512','Sparkhound')
Select BINARY_CHECKSUM('sha2_512','AAAAAAAAAAAAAAAASparkhound')

--same
select CHECKSUM('aaaa')
select CHECKSUM('aaaaaaaaaaaaaaaaaaaa')

--not the same
select HASHBYTES('SHA2_512', N'aaaa')
select HASHBYTES('SHA2_512', N'aaaaaaaaaaaaaaaaaaaa')

--not the same
Select HASHBYTES('sha2_512','Sparkhound')
Select HASHBYTES('sha2_512','AAAAAAAAAAAAAAAASparkhound')

