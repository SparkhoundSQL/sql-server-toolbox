

declare @replacement varchar(30)
--The second and third arguments must contain an equal number of characters.
--So unlike replace, you can't replace ' ' with ''
--The characters can be in any order.


select @replacement = 'abcdef'
select @replacement
, [T] = TRANSLATE(@replacement, 'abcdef', '123456')
, [R] = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@replacement,'a', '1'),'b', '2'),'c', '3'),'d', '4'),'e', '5'),'f', '6')

select @replacement = '@@data"$%'
select @replacement
, [T] = TRANSLATE (@replacement, '/"_@$%', '_____!')
, [R] = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@replacement,'/', '_'),'"', '_'), '@', '_'), '$', '_'), '%', '!');

select @replacement = '(OlympicsAreGreat)'
select @replacement
, [T] = TRANSLATE (@replacement, 'Olympic()','DadJoke[!')
, [R] = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@replacement,'O', 'D'),'l', 'a'), 'y', 'd'), 'm', 'J'), 'p', 'o'),'i', 'k'),'c', 'e'), '(', '['), ')', '!')

