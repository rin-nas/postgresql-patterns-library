select
  md5(s5.content)
  --, s5.content, s1.content
from
  current_setting('hba_file') as cs(hba_file),
  pg_stat_file(cs.hba_file) as sf,
  pg_read_file(cs.hba_file) as s1(content),
  -- remove comments:
  regexp_replace(s1.content, '#[^\n]*\n', E'\n', 'g') as s2(content),
  -- remove redundant new lines and spaces around:
  regexp_replace(s2.content, '\s*\n\s*', E'\n', 'g') as s3(content),
  -- remove redundant spaces:
  regexp_replace(s3.content, ' +', ' ', 'g') as s4(content),
  concat_ws(
    E'\n',
    trim(s4.content, E' \n'),
    sf.modification::text,
    sf.change::text
  ) as s5(content);

-- https://www.zabbix.com/ru/integrations/postgresql#postgresql_agent2
GRANT EXECUTE ON FUNCTION pg_stat_file(text), pg_read_file(text) TO zbx_monitor;
