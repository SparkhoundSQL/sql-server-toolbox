
SELECT SUSER_NAME(principal_id) as endpoint_owner, *
from sys.endpoints
WHERE SUSER_NAME(principal_id) <> 'sa'
AND SUSER_NAME(principal_id) <> 'whatever\sqlservices'

--alter authorization on endpoint::[mirroring] to [whatver\sqlservices]