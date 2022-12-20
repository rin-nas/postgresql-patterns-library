-- Метафон на plpgsql, источник: https://habr.com/ru/post/341142/

create or replace function phoneme (in_lexeme text)
    returns text
    immutable
    language plpgsql
    set search_path = ''
as $$
declare
  res varchar(100) DEFAULT '';
begin
  res := lower(in_lexeme);
  res := regexp_replace(res,'[ъь]','','g');
  res := regexp_replace(res,'(йо|ио|йе|ие)','и','g');
  res := regexp_replace(res,'[оыя]','а','g');
  res := regexp_replace(res,'[еёэ]','и','g');
  res := regexp_replace(res,'ю','у','g');
  res := regexp_replace(res,'б([псткбвгджзфхцчшщ]|$)','п\1','g');
  res := regexp_replace(res,'з([псткбвгджзфхцчшщ]|$)','с\1','g');
  res := regexp_replace(res,'д([псткбвгджзфхцчшщ]|$)','т\1','g');
  res := regexp_replace(res,'в([псткбвгджзфхцчшщ]|$)','ф\1','g');
  res := regexp_replace(res,'г([псткбвгджзфхцчшщ]|$)','к\1','g');  
  res := regexp_replace(res,'дс','ц','g');
  res := regexp_replace(res,'тс','ц','g');
  res := regexp_replace(res,'(.)\1','\1','g');
  return res;
exception
  when others then raise exception '%', sqlerrm;
end;
$$;


create or replace function mquery(in_fullname text)
    returns text
    immutable
    language plpgsql
    set search_path = ''
as $$
declare
  res text;
begin
  res := metaphone(in_fullname);
  res := regexp_replace(res, '(б|п)', '(б|п)', 'g');
  res := regexp_replace(res, '(з|с)', '(з|с)', 'g');
  res := regexp_replace(res, '(д|т)', '(д|т)', 'g');
  res := regexp_replace(res, '(в|ф)', '(в|ф)', 'g');
  res := regexp_replace(res, '(г|к)', '(г|к)', 'g');
  res := regexp_replace(res, '\s', '%', 'g');
  return '%'||res||'%';
exception
  when others then raise exception '%', sqlerrm;
end;
$$;
