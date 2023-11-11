# Эксперимент по сжатию текстовых данных в БД

## Flow

* Compression flow: `INPUT -> BWT -> MTF -> FIB -> OUTPUT`
* Decompression flow: in reverse order


## Queries

```sql
with compress as (
    select concat(octet_length(p0.input), ' -> ', octet_length(p5.output), ' bytes',
                  ' (', octet_length(p5.output) * 100 / octet_length(p0.input), '%)') as stat,
           p0.input,
           p1.v, p2.v, p3.v, p4.v,
           p5.output
    from
        --coalesce('Съешь [же] ещё этих мягких французских булок да выпей чаю.') as p0(input) --https://ru.wikipedia.org/wiki/Панграмма
        --coalesce('Юлия, съешь же ещё этих мягких французских булок из Йошкар-Олы, да выпей алтайского чаю.') as p0(input)
        --coalesce('いろはにほへと ちりぬるを わかよたれそ つねならむ うゐのおくやま けふこえて あさきゆめみし ゑひもせす') as p0(input) --https://ru.wikipedia.org/wiki/Панграмма
        coalesce('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.') as p0(input)
        --coalesce('Sed ut perspiciatis, unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt, explicabo. Nemo enim ipsam voluptatem, quia voluptas sit, aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos, qui ratione voluptatem sequi nesciunt, neque porro quisquam est, qui dolorem ipsum, quia dolor sit, amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt, ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit, qui in ea voluptate velit esse, quam nihil molestiae consequatur, vel illum, qui dolorem eum fugiat, quo voluptas nulla pariatur? At vero eos et accusamus et iusto odio dignissimos ducimus, qui blanditiis praesentium voluptatum deleniti atque corrupti, quos dolores et quas molestias excepturi sint, obcaecati cupiditate non provident, similique sunt in culpa, qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio, cumque nihil impedit, quo minus id, quod maxime placeat, facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet, ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.') as p0(input)
        --coalesce('Старик рыбачил один на своей лодке в Гольфстриме. Вот уже восемьдесят четыре дня он ходил в море и не поймал ни одной рыбы. Первые сорок дней с ним был мальчик. Но день за днем не приносил улова, и родители сказали мальчику, что старик теперь уже явно salao, то есть «самый что ни на есть невезучий», и велели ходить в море на другой лодке, которая действительно привезла три хорошие рыбы в первую же неделю. Мальчику тяжело было смотреть, как старик каждый день возвращается ни с чем, и он выходил на берег, чтобы помочь ему отнести домой снасти или багор, гарпун и обернутый вокруг мачты парус. Парус был весь в заплатах из мешковины и, свернутый, напоминал знамя наголову разбитого полка. Старик был худ и изможден, затылок его прорезали глубокие морщины, а щеки были покрыты коричневыми пятнами неопасного кожного рака, который вызывают солнечные лучи, отраженные гладью тропического моря. Пятна спускались по щекам до самой шеи, на руках виднелись глубокие шрамы, прорезанные бечевой, когда он вытаскивал крупную рыбу. Однако свежих шрамов не было. Они были стары, как трещины в давно уже безводной пустыне. Все у него было старое, кроме глаз, а глаза были цветом похожи на море, веселые глаза человека, который не сдается.') as p0(input)
        --coalesce('TOBEORNOTTOBEORTOBEORNOT') as p0(input)
        --coalesce('missisippi') as p0(input)
        --coalesce('абракадабра') as p0(input)
        --coalesce('Ехал Грека через реку. Видит Грека в реке рак. Сунул Грека руку в реку. Рак за руку Греку цап!') as p0(input)
      , public.bwt_encode(p0.input, '$') as p1(v)
      , public.string_to_codepoints(p1.v) as p2(v)
      , public.mtf_encode(p2.v) as p3(v) -- смысл MTF - присваивать более короткие коды более частым символам
      , public.codepoints_gap_decrease(p3.v) as p4(v)
      , public.fib_pack(p4.v) as p5(output)
)
, decompress as (
    select concat(octet_length(p0.output), ' -> ', octet_length(p5.output), ' bytes') as stat,
           p0.output as input,
           p1.v, p2.v, p3.v, p4.v,
           p5.output as output
    from compress as p0
       , public.fib_unpack(p0.output) as p1(v)
       , public.codepoints_gap_increase(p1.v) as p2(v)
       , public.mtf_decode(p2.v) as p3(v)
       , public.string_from_codepoints(p3.v) as p4(v)
       , public.bwt_decode(p4.v, '$') as p5(output)
)
select * from compress
--select * from decompress
;

```

## Links

* [Data Compression The Complete Reference 3rd Ed - David Salomon](https://doc.lagout.org/Others/Information%20Theory/Compression/Data%20Compression%20The%20Complete%20Reference%203rd%20Ed%20-%20David%20Salomon.pdf)
* http://compression.ru/download/rev_univ.html
* https://www.researchgate.net/figure/Schematic-representation-of-an-S9-word-encoding-the-group-of-integers-98-112-117-and_fig1_325408300 S9 inegers pack

### Arithmetic, range, ANS

* https://go-compression.github.io/algorithms/arithmetic/ Arithmetic Coding - The Hitchhiker's Guide to Compression
* https://en.wikipedia.org/wiki/Range_coding
* https://habr.com/ru/companies/playrix/articles/441814/ Энтропийное кодирование rANS или как написать собственный архиватор


### BWT
* https://epdf.tips/the-burrows-wheeler-transform-data-compression-suffix-arrays-and-pattern-matchin.html
* https://compression.ru/arctest/descript/bwt-faq.htm#8


### Distance Coding

```
Procedure Distance Coding
(1) Write the first character in s;
(2) For each other character σ ∈ Σ, write the distance to the first σ in s, or 1 if σ does not occur (notice no distance is 1, because we do
not reconsider the first character in s);
(3) For each maximal run of a character σ , write the distance from the ending position of that run to the starting position of the next run
of σ ’s, or 1 if there are no more σ ’s (again, no distance is 1);
(4) Encode the length ` of the last run in s.
```

* https://www.sciencedirect.com/science/article/pii/S030439751000229X?ref=pdf_download&fr=RR-2&rr=81d3a310e82f160a
* file:///home/r.mukhtarov/Downloads/document.pdf (3.6 Distance coding)
* https://docs.rs/compress/0.2.1/compress/bwt/dc/index.html

### Вероятностное сжатие
* http://compression.ru/download/articles/rev_univ/fomin_1998_compression_fundamentals.pdf - теория
* https://github.com/lmcilroy/lzp
* https://www.cs.auckland.ac.nz/~peter-f/FTPfiles/1997%20Sym%20Rank%20Compression.pdf see "Bloom’s LZP compressors"

### LZW
* https://planetcalc.com/9069/ LZW online text compression 
* http://compression.ru/book/part2/part2__2.htm LZW см. про скорость поиска следующего символа в таблице по хешу!  
* https://github.com/mikeleo03/LZW-Compressor_Backend/blob/main/src/algorithm/algorithm.js
* https://ru.wikipedia.org/wiki/Алгоритм_Лемпеля_—_Зива_—_Велча
