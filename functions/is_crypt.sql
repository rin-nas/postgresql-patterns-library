-- https://man7.org/linux/man-pages/man3/crypt.3.html
-- https://en.bitcoinwiki.org/wiki/Bcrypt
-- https://www.php.net/manual/ru/function.crypt.php
create or replace function is_crypt(str text)
    returns boolean
    stable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
as
$$
select regexp_match(
            str,
            --$id$salt$encrypted
            --$id$rounds=yyy$salt$encrypted
            $regexp$
            ^
                \$
                \d[a-z]?  #algorithm id
                \$
                (?:rounds=\d+ #rounds
                   \$
                )?
                [A-Za-z\d./]{2,} #salt/rounds
                \$
                [A-Za-z\d./]{22,86} #encrypted
            $
            $regexp$, 'x') is not null;
$$;

comment on function is_crypt(text) is 'Проверяет, что переданная строка является результатом Linux функции crypt';

--TEST

DO $$
BEGIN
    --positive
    ASSERT is_crypt('$1$rasmusle$rISCgZzpwk3UhDidwXvin0'); --MD5
    ASSERT is_crypt('$2y$07$usesomesillystringfore2uDLvp1Ii2e./U9C8sBjqp8I90dH6hi'); --Blowfish
    ASSERT is_crypt('$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'); --Blowfish
    ASSERT is_crypt('$5$rounds=5000$usesomesillystri$KqJWpanXZHKq2BOB43TSaYhEWsQ1Lr5QNyPCDH/Tp.6'); --SHA-256
    ASSERT is_crypt('$6$rounds=5000$usesomesillystri$D4IrlXatmP7rx3P3InaxBeoomnAihCKRVQP22JZ6EY47Wc6BkroIuUUBOov1i.S5KPgErtP/EN5mcO.ChWQW21'); --SHA-512

    --negative
    ASSERT NOT is_crypt('$2a$10$N');

END $$;
