create or replace function public.slugify(str text)
returns text
language plpgsql
as $$
declare
_out text;
begin
_out := translate(
trim(both ' ' from lower(str)),
'абвгдеёзийклмнопрстуфыэ',
'abvgdeeziyklmnoprstufye'
);
_out := replace(_out, 'ж', 'zh');
_out := replace(_out, 'х', 'kh');
_out := replace(_out, 'ц', 'ts');
_out := replace(_out, 'ч', 'ch');
_out := replace(_out, 'ш', 'sh');
_out := replace(_out, 'щ', 'sch');
_out := replace(_out, 'ь', '');
_out := replace(_out, 'ъ', '');
_out := replace(_out, 'ю', 'yu');
_out := replace(_out, 'я', 'ya');
_out := regexp_replace(_out, '[^a-z0-9]+', '-', 'g');
return _out;
end
$$;
