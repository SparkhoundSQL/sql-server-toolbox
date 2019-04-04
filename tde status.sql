
/* The value 3 represents an encrypted state on the database and transaction logs. */
SELECT d.name
, d.state_desc
--, encryption_state_desc --SQL 2019+ only
, encryption_state = CASE dek.encryption_state WHEN 0 THEN 'No database encryption key present, no encryption'
							WHEN 1 THEN 'Unencrypted'
							WHEN 2 THEN 'Encryption in progress'
							WHEN 3 THEN 'Encrypted'
							WHEN 4 THEN 'Key change in progress'
							WHEN 5 THEN 'Decryption in progress'
							WHEN 6 THEN 'Protection change in progress (The certificate or asymmetric key that is encrypting the database encryption key is being changed.)'
		END
, dek.percent_complete --	Percent complete of the database encryption state change. This will be 0 if there is no state change.
--, encryption_scan_state --SQL 2019+ only
--, encryption_scan_modify_date --SQL 2019+
, Cert_Name = c.name
, c.pvt_key_encryption_type_desc
, c.issuer_name 
, c.subject
, dek.modify_date
, c.pvt_key_last_backup_date
, dek.encryptor_type
, dek.key_algorithm
, dek.key_length
, c.start_date
, c.expiry_date 
--, *
FROM  sys.databases as d
left outer join sys.dm_database_encryption_keys as dek on dek.database_id = d.database_id
left outer join master.sys.certificates as c on c.thumbprint = dek.encryptor_thumbprint
where encryption_state is not null
GO
