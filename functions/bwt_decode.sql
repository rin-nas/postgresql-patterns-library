-- TODO
-- https://youtu.be/meKCBruvPZ0?t=1110
-- BWT decode develop
with recursive s as (
    select row_number() over (order by char) as pos,
           t.char,
           t.next_pos
    from regexp_split_to_table('ard$rcaaaabb', '') with ordinality as t(char, next_pos)
    where t.char != ''
    order by t.char
)
--select * from s; --test
, r as (
    select s.char, s.next_pos
    from s
    where s.char = '$'
    union all
    select s.char, s.next_pos
    from r
    inner join s on s.pos = r.next_pos and s.char != '$'
)
select array_to_string(array(
            select r.char
            from r
            offset 1
       ), '');
