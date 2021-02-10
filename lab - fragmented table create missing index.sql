--Use to generate Missing Index Suggestions, together with the 3 "lab - fragmented table... .sql" scripts.
select fragtext from fragmented_table_nsi where fragtext2 = 'bbb'
select fragtext from fragmented_table_int where fragtext2 = 'bbb'
select fragtext from fragmented_table where fragtext2 = 'bbb'