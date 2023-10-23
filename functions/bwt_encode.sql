-- TODO
-- https://www.geeksforgeeks.org/burrows-wheeler-data-transform-algorithm/
-- BWT encode develop
with recursive r (pos, suffix) as (
    select 1, 'abracadabra' || '$'
    union all
    select pos + 1, right(r.suffix, -1)
    from r
    where octet_length(r.suffix) > 1
)
--select * from r; --test
select array_to_string(array(
    select (select left(o.suffix, 1)
            from r as o
            where case when i.pos - 1 = 0 then length(i.suffix)
                       else i.pos - 1
                  end = o.pos
            limit 1
           )
    from r as i
    order by suffix
), '');
