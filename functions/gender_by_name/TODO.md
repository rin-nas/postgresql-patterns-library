# Исправить ошибки

```sql
select gender_by_name(e'Исаков\nЭлмурод\nБобамиродивич'); --female
select gender_by_name(e'Фабрика\nПластелинавая'); --female
select gender_by_name(e'Elick\nMr.Ellis'); --female
select gender_by_name(e'Россия\nпросто'); --female
select gender_by_name(e'Gorkovenko\nAlexander'); --unknown
select gender_by_name(e'Kutsemakhin\nMichael'); --unknown
select gender_by_name(e'Нематов\nУмат'); --female
```

# Неопределяется пол

```sql
select gender_by_name(fio)
from unnest(string_to_array('Мерине Сафарян,Маэму Шавкатжон,Симба Анселму,Этаба Эстелль,Григорян Лаэрт', ',')) as u(fio)
where trim(fio) != '';
```

Скорее всего нужно пополнить словарь новыми именами.
