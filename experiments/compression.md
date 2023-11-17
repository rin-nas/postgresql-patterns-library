# Эксперимент по сжатию текстовых данных в БД PostgreSQL

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

### compress (Грека)
| | |
| :- | :- |
| **stat** | 166 -&gt; 62 bytes \(37%\) |
| **input** | Ехал Грека через реку. Видит Грека в реке рак. Сунул Грека руку в реку. Рак за руку Греку цап! |
| **v** | .тллу..аукевзваауап!уук     $  кзккРрхц  икррррррррче Вдааееееууеееуауа еГГГ Г    икккккррнСЕ   |
| **v** | {46,1090,1083,1083,1091,46,46,1072,1091,1082,1077,1074,1079,1074,1072,1072,1091,1072,1087,33,1091,1091,1082,32,32,32,32,32,36,32,32,1082,1079,1082,1082,1056,1088,1093,1094,32,32,1080,1082,1088,1088,1088,1088,1088,1088,1088,1088,1095,1077,32,1042,1076,1072,1072,1077,1077,1077,1077,1091,1091,1077,1077,1077,1091,1072,1091,1072,32,1077,1043,1043,1043,32,1043,32,32,32,32,1080,1082,1082,1082,1082,1082,1088,1088,1085,1057,1045,32,32} |
| **v** | {46,1090,1084,1,1091,4,1,1075,3,1085,1081,1079,1083,2,6,1,6,2,1089,43,4,1,8,43,1,1,1,1,46,2,1,3,9,2,1,1065,1090,1093,1094,7,1,1088,7,6,1,1,1,1,1,1,1,1095,16,6,1057,1088,17,1,5,1,1,1,15,1,2,1,1,2,3,2,2,6,4,1059,1,1,3,2,2,1,1,1,11,11,1,1,1,1,11,1,1092,1073,1063,7,1} |
| **v** | {46,1011,46,80,74,1,81,4,1,65,3,75,71,69,73,2,6,1,6,2,79,43,4,1,8,43,1,1,1,1,46,2,1,3,9,2,1,55,80,83,84,7,1,78,7,6,1,1,1,1,1,1,1,85,16,6,47,78,17,1,5,1,1,1,15,1,2,1,1,2,3,2,2,6,4,49,1,1,3,2,2,1,1,1,11,11,1,1,1,1,11,1,82,63,53,7,1} |
| **output** | 0xA99101D4E8B94F12EF48CD5324E1314DCF9B22E2778713FFA9BCE3780745A9615AF42D73FFFE2B27305A174F1FE8F7ECDB9DA2FCDBFCB2FFCBE4B08E56BC |

### decompress (Грека)
| | |
| :- | :- |
| **stat** | 62 -&gt; 166 bytes |
| **input** | 0xA99101D4E8B94F12EF48CD5324E1314DCF9B22E2778713FFA9BCE3780745A9615AF42D73FFFE2B27305A174F1FE8F7ECDB9DA2FCDBFCB2FFCBE4B08E56BC |
| **v** | {46,1011,46,80,74,1,81,4,1,65,3,75,71,69,73,2,6,1,6,2,79,43,4,1,8,43,1,1,1,1,46,2,1,3,9,2,1,55,80,83,84,7,1,78,7,6,1,1,1,1,1,1,1,85,16,6,47,78,17,1,5,1,1,1,15,1,2,1,1,2,3,2,2,6,4,49,1,1,3,2,2,1,1,1,11,11,1,1,1,1,11,1,82,63,53,7,1} |
| **v** | {46,1090,1084,1,1091,4,1,1075,3,1085,1081,1079,1083,2,6,1,6,2,1089,43,4,1,8,43,1,1,1,1,46,2,1,3,9,2,1,1065,1090,1093,1094,7,1,1088,7,6,1,1,1,1,1,1,1,1095,16,6,1057,1088,17,1,5,1,1,1,15,1,2,1,1,2,3,2,2,6,4,1059,1,1,3,2,2,1,1,1,11,11,1,1,1,1,11,1,1092,1073,1063,7,1} |
| **v** | {46,1090,1083,1083,1091,46,46,1072,1091,1082,1077,1074,1079,1074,1072,1072,1091,1072,1087,33,1091,1091,1082,32,32,32,32,32,36,32,32,1082,1079,1082,1082,1056,1088,1093,1094,32,32,1080,1082,1088,1088,1088,1088,1088,1088,1088,1088,1095,1077,32,1042,1076,1072,1072,1077,1077,1077,1077,1091,1091,1077,1077,1077,1091,1072,1091,1072,32,1077,1043,1043,1043,32,1043,32,32,32,32,1080,1082,1082,1082,1082,1082,1088,1088,1085,1057,1045,32,32} |
| **v** | .тллу..аукевзваауап!уук     $  кзккРрхц  икррррррррче Вдааееееууеееуауа еГГГ Г    икккккррнСЕ   |
| **output** | Ехал Грека через реку. Видит Грека в реке рак. Сунул Грека руку в реку. Рак за руку Греку цап! |


### compress (Lorem ipsum)

| | |
| :- | :- |
| **stat** | 445 -&gt; 271 bytes \(60%\) |
| **input** | Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. |
| **v** | ...mratttsea,ontademmtxogttdeepdumtrtrmetotedtststtiana,n,rr,dnitemn.tmtttram  $ neilpulll  cm  il  pctiudtti aaaceoxin srm   e  eiuaoiin iao     isrrrtrt assr v rthv drcsxdsd   mt t  of nuaeuscngrf pocdcnnn    cmstud ll urupnsllrlcel   laaleeuuoioooouloiuuieiau aa osm eioioigieieeai   oouuiue ddc mm rmddddvcnicclplbllLbbnil uime iueie i uoououeuooopo aoeptoeiiiiisn nei  ueeop uiiaeUiniusnaanneinaapiua cpaseaeqqrfqqDqn cslrsrdcltetri  a   eEe |
| **v** | {46,46,46,109,114,97,116,116,116,115,101,97,44,111,110,116,97,100,101,109,109,116,120,111,103,116,116,100,101,101,112,100,117,109,116,114,116,114,109,101,116,111,116,101,100,116,115,116,115,116,116,105,97,110,97,44,110,44,114,114,44,100,110,105,116,101,109,110,46,116,109,116,116,116,114,97,109,32,32,36,32,110,101,105,108,112,117,108,108,108,32,32,99,109,32,32,105,108,32,32,112,99,116,105,117,100,116,116,105,32,97,97,97,99,101,111,120,105,110,32,115,114,109,32,32,32,101,32,32,101,105,117,97,111,105,105,110,32,105,97,111,32,32,32,32,32,105,115,114,114,114,116,114,116,32,97,115,115,114,32,118,32,114,116,104,118,32,100,114,99,115,120,100,115,100,32,32,32,109,116,32,116,32,32,111,102,32,110,117,97,101,117,115,99,110,103,114,102,32,112,111,99,100,99,110,110,110,32,32,32,32,99,109,115,116,117,100,32,108,108,32,117,114,117,112,110,115,108,108,114,108,99,101,108,32,32,32,108,97,97,108,101,101,117,117,111,105,111,111,111,111,117,108,111,105,117,117,105,101,105,97,117,32,97,97,32,111,115,109,32,101,105,111,105,111,105,103,105,101,105,101,101,97,105,32,32,32,111,111,117,117,105,117,101,32,100,100,99,32,109,109,32,114,109,100,100,100,100,118,99,110,105,99,99,108,112,108,98,108,108,76,98,98,110,105,108,32,117,105,109,101,32,105,117,101,105,101,32,105,32,117,111,111,117,111,117,101,117,111,111,111,112,111,32,97,111,101,112,116,111,101,105,105,105,105,105,115,110,32,110,101,105,32,32,117,101,101,111,112,32,117,105,105,97,101,85,105,110,105,117,115,110,97,97,110,110,101,105,110,97,97,112,105,117,97,32,99,112,97,115,101,97,101,113,113,114,102,113,113,68,113,110,32,99,115,108,114,115,114,100,99,108,116,101,116,114,105,32,32,97,32,32,32,101,69,101} |
| **v** | {46,1,1,109,114,99,116,1,1,116,105,4,51,114,114,7,5,107,7,10,1,5,120,8,110,4,1,7,7,1,116,3,118,9,6,14,2,2,3,7,4,9,2,3,7,3,14,2,2,2,1,114,13,14,2,15,3,2,11,1,2,8,4,6,7,9,11,5,16,5,4,2,1,1,9,10,4,48,1,52,2,8,9,10,117,17,17,3,1,1,7,1,113,10,3,1,7,5,3,1,7,6,13,6,8,15,4,1,4,7,13,1,1,7,11,18,20,7,14,8,19,17,16,4,1,1,9,2,1,2,7,14,12,11,4,1,10,7,3,5,5,4,1,1,1,1,4,10,10,1,1,13,2,2,5,7,5,1,5,4,119,2,3,6,116,5,5,16,6,16,8,16,5,3,2,6,1,1,16,10,3,2,2,1,13,116,3,15,16,15,17,3,11,13,6,23,15,10,10,19,12,8,15,2,9,1,1,6,1,1,1,3,15,11,15,13,8,7,20,1,2,4,13,2,12,11,9,7,1,6,2,11,15,3,9,1,1,2,16,1,2,4,1,10,1,14,20,2,1,1,1,3,5,3,4,4,1,2,5,2,6,4,7,3,1,2,6,10,15,4,8,8,6,2,2,2,17,2,4,2,2,1,8,3,6,1,1,6,1,9,1,4,2,6,5,15,1,12,3,10,1,2,13,3,5,1,1,1,19,6,15,10,3,1,15,16,2,116,2,1,96,3,1,7,7,5,12,14,4,12,14,5,4,5,4,3,2,4,3,2,4,15,1,2,2,2,5,2,3,1,1,11,2,5,16,3,6,5,19,4,4,8,1,1,1,1,19,12,9,2,5,5,4,1,10,4,1,7,9,5,5,6,1,10,7,105,4,9,2,6,10,4,7,1,2,1,7,6,3,4,1,9,4,7,4,9,16,6,4,9,9,3,2,119,1,20,22,3,1,91,2,13,11,11,10,18,9,3,2,22,5,5,18,12,2,6,16,9,1,14,2,1,1,6,92,2} |
| **v** | {52,39,46,1,1,71,76,61,78,1,1,78,67,4,51,76,76,7,5,69,7,10,1,5,82,8,72,4,1,7,7,1,78,3,80,9,6,14,2,2,3,7,4,9,2,3,7,3,14,2,2,2,1,76,13,14,2,15,3,2,11,1,2,8,4,6,7,9,11,5,16,5,4,2,1,1,9,10,4,48,1,52,2,8,9,10,79,17,17,3,1,1,7,1,75,10,3,1,7,5,3,1,7,6,13,6,8,15,4,1,4,7,13,1,1,7,11,18,20,7,14,8,19,17,16,4,1,1,9,2,1,2,7,14,12,11,4,1,10,7,3,5,5,4,1,1,1,1,4,10,10,1,1,13,2,2,5,7,5,1,5,4,81,2,3,6,78,5,5,16,6,16,8,16,5,3,2,6,1,1,16,10,3,2,2,1,13,78,3,15,16,15,17,3,11,13,6,23,15,10,10,19,12,8,15,2,9,1,1,6,1,1,1,3,15,11,15,13,8,7,20,1,2,4,13,2,12,11,9,7,1,6,2,11,15,3,9,1,1,2,16,1,2,4,1,10,1,14,20,2,1,1,1,3,5,3,4,4,1,2,5,2,6,4,7,3,1,2,6,10,15,4,8,8,6,2,2,2,17,2,4,2,2,1,8,3,6,1,1,6,1,9,1,4,2,6,5,15,1,12,3,10,1,2,13,3,5,1,1,1,19,6,15,10,3,1,15,16,2,78,2,1,58,3,1,7,7,5,12,14,4,12,14,5,4,5,4,3,2,4,3,2,4,15,1,2,2,2,5,2,3,1,1,11,2,5,16,3,6,5,19,4,4,8,1,1,1,1,19,12,9,2,5,5,4,1,10,4,1,7,9,5,5,6,1,10,7,67,4,9,2,6,10,4,7,1,2,1,7,6,3,4,1,9,4,7,4,9,16,6,4,9,9,3,2,81,1,20,22,3,1,53,2,13,11,11,10,18,9,3,2,22,5,5,18,12,2,6,16,9,1,14,2,1,1,6,54,2} |
| **output** | 0x1588EA7E4981721A17E85D4774B02C0B58E135A78E4B0E93BD6BD0B3A2E39C36CD771B359C36DE058386D19B2F61DCD71963263B7F1A770BC56C38D322E9D33F5EA9A67AC67AE60E61A3BED60FD658B56B861CBA64EFE37B5C3ACBBD3598C77FF69A7E0DB1AC78EC4B67342C632732619319B9F934CDBC1A1668C9A3A665839A1A34D3975868DC7F3FCD1968C186B57BB06EB2E35F365A338FD93DDE9F0D5BFCC6777B1B9DACF734D1D861CDB74DDB78673F9F1F6E6347D669EC198FF9734699E8C9B42DE419EB58EB8775C31D8ECDD9BB47B6C6CFCB6326731CBBB0FFE5D71B18EF4EF5C631CF4D751DC6E69DAF7AE677C76BB8C9CEE38CD897AB833E56C1965A62E33706318BADCC9C7C37F355B0 |


### decompress (Lorem ipsum)

| | |
| :- | :- |
| **stat** | 271 -&gt; 445 bytes |
| **input** | 0x1588EA7E4981721A17E85D4774B02C0B58E135A78E4B0E93BD6BD0B3A2E39C36CD771B359C36DE058386D19B2F61DCD71963263B7F1A770BC56C38D322E9D33F5EA9A67AC67AE60E61A3BED60FD658B56B861CBA64EFE37B5C3ACBBD3598C77FF69A7E0DB1AC78EC4B67342C632732619319B9F934CDBC1A1668C9A3A665839A1A34D3975868DC7F3FCD1968C186B57BB06EB2E35F365A338FD93DDE9F0D5BFCC6777B1B9DACF734D1D861CDB74DDB78673F9F1F6E6347D669EC198FF9734699E8C9B42DE419EB58EB8775C31D8ECDD9BB47B6C6CFCB6326731CBBB0FFE5D71B18EF4EF5C631CF4D751DC6E69DAF7AE677C76BB8C9CEE38CD897AB833E56C1965A62E33706318BADCC9C7C37F355B0 |
| **v** | {52,39,46,1,1,71,76,61,78,1,1,78,67,4,51,76,76,7,5,69,7,10,1,5,82,8,72,4,1,7,7,1,78,3,80,9,6,14,2,2,3,7,4,9,2,3,7,3,14,2,2,2,1,76,13,14,2,15,3,2,11,1,2,8,4,6,7,9,11,5,16,5,4,2,1,1,9,10,4,48,1,52,2,8,9,10,79,17,17,3,1,1,7,1,75,10,3,1,7,5,3,1,7,6,13,6,8,15,4,1,4,7,13,1,1,7,11,18,20,7,14,8,19,17,16,4,1,1,9,2,1,2,7,14,12,11,4,1,10,7,3,5,5,4,1,1,1,1,4,10,10,1,1,13,2,2,5,7,5,1,5,4,81,2,3,6,78,5,5,16,6,16,8,16,5,3,2,6,1,1,16,10,3,2,2,1,13,78,3,15,16,15,17,3,11,13,6,23,15,10,10,19,12,8,15,2,9,1,1,6,1,1,1,3,15,11,15,13,8,7,20,1,2,4,13,2,12,11,9,7,1,6,2,11,15,3,9,1,1,2,16,1,2,4,1,10,1,14,20,2,1,1,1,3,5,3,4,4,1,2,5,2,6,4,7,3,1,2,6,10,15,4,8,8,6,2,2,2,17,2,4,2,2,1,8,3,6,1,1,6,1,9,1,4,2,6,5,15,1,12,3,10,1,2,13,3,5,1,1,1,19,6,15,10,3,1,15,16,2,78,2,1,58,3,1,7,7,5,12,14,4,12,14,5,4,5,4,3,2,4,3,2,4,15,1,2,2,2,5,2,3,1,1,11,2,5,16,3,6,5,19,4,4,8,1,1,1,1,19,12,9,2,5,5,4,1,10,4,1,7,9,5,5,6,1,10,7,67,4,9,2,6,10,4,7,1,2,1,7,6,3,4,1,9,4,7,4,9,16,6,4,9,9,3,2,81,1,20,22,3,1,53,2,13,11,11,10,18,9,3,2,22,5,5,18,12,2,6,16,9,1,14,2,1,1,6,54,2} |
| **v** | {46,1,1,109,114,99,116,1,1,116,105,4,51,114,114,7,5,107,7,10,1,5,120,8,110,4,1,7,7,1,116,3,118,9,6,14,2,2,3,7,4,9,2,3,7,3,14,2,2,2,1,114,13,14,2,15,3,2,11,1,2,8,4,6,7,9,11,5,16,5,4,2,1,1,9,10,4,48,1,52,2,8,9,10,117,17,17,3,1,1,7,1,113,10,3,1,7,5,3,1,7,6,13,6,8,15,4,1,4,7,13,1,1,7,11,18,20,7,14,8,19,17,16,4,1,1,9,2,1,2,7,14,12,11,4,1,10,7,3,5,5,4,1,1,1,1,4,10,10,1,1,13,2,2,5,7,5,1,5,4,119,2,3,6,116,5,5,16,6,16,8,16,5,3,2,6,1,1,16,10,3,2,2,1,13,116,3,15,16,15,17,3,11,13,6,23,15,10,10,19,12,8,15,2,9,1,1,6,1,1,1,3,15,11,15,13,8,7,20,1,2,4,13,2,12,11,9,7,1,6,2,11,15,3,9,1,1,2,16,1,2,4,1,10,1,14,20,2,1,1,1,3,5,3,4,4,1,2,5,2,6,4,7,3,1,2,6,10,15,4,8,8,6,2,2,2,17,2,4,2,2,1,8,3,6,1,1,6,1,9,1,4,2,6,5,15,1,12,3,10,1,2,13,3,5,1,1,1,19,6,15,10,3,1,15,16,2,116,2,1,96,3,1,7,7,5,12,14,4,12,14,5,4,5,4,3,2,4,3,2,4,15,1,2,2,2,5,2,3,1,1,11,2,5,16,3,6,5,19,4,4,8,1,1,1,1,19,12,9,2,5,5,4,1,10,4,1,7,9,5,5,6,1,10,7,105,4,9,2,6,10,4,7,1,2,1,7,6,3,4,1,9,4,7,4,9,16,6,4,9,9,3,2,119,1,20,22,3,1,91,2,13,11,11,10,18,9,3,2,22,5,5,18,12,2,6,16,9,1,14,2,1,1,6,92,2} |
| **v** | {46,46,46,109,114,97,116,116,116,115,101,97,44,111,110,116,97,100,101,109,109,116,120,111,103,116,116,100,101,101,112,100,117,109,116,114,116,114,109,101,116,111,116,101,100,116,115,116,115,116,116,105,97,110,97,44,110,44,114,114,44,100,110,105,116,101,109,110,46,116,109,116,116,116,114,97,109,32,32,36,32,110,101,105,108,112,117,108,108,108,32,32,99,109,32,32,105,108,32,32,112,99,116,105,117,100,116,116,105,32,97,97,97,99,101,111,120,105,110,32,115,114,109,32,32,32,101,32,32,101,105,117,97,111,105,105,110,32,105,97,111,32,32,32,32,32,105,115,114,114,114,116,114,116,32,97,115,115,114,32,118,32,114,116,104,118,32,100,114,99,115,120,100,115,100,32,32,32,109,116,32,116,32,32,111,102,32,110,117,97,101,117,115,99,110,103,114,102,32,112,111,99,100,99,110,110,110,32,32,32,32,99,109,115,116,117,100,32,108,108,32,117,114,117,112,110,115,108,108,114,108,99,101,108,32,32,32,108,97,97,108,101,101,117,117,111,105,111,111,111,111,117,108,111,105,117,117,105,101,105,97,117,32,97,97,32,111,115,109,32,101,105,111,105,111,105,103,105,101,105,101,101,97,105,32,32,32,111,111,117,117,105,117,101,32,100,100,99,32,109,109,32,114,109,100,100,100,100,118,99,110,105,99,99,108,112,108,98,108,108,76,98,98,110,105,108,32,117,105,109,101,32,105,117,101,105,101,32,105,32,117,111,111,117,111,117,101,117,111,111,111,112,111,32,97,111,101,112,116,111,101,105,105,105,105,105,115,110,32,110,101,105,32,32,117,101,101,111,112,32,117,105,105,97,101,85,105,110,105,117,115,110,97,97,110,110,101,105,110,97,97,112,105,117,97,32,99,112,97,115,101,97,101,113,113,114,102,113,113,68,113,110,32,99,115,108,114,115,114,100,99,108,116,101,116,114,105,32,32,97,32,32,32,101,69,101} |
| **v** | ...mratttsea,ontademmtxogttdeepdumtrtrmetotedtststtiana,n,rr,dnitemn.tmtttram  $ neilpulll  cm  il  pctiudtti aaaceoxin srm   e  eiuaoiin iao     isrrrtrt assr v rthv drcsxdsd   mt t  of nuaeuscngrf pocdcnnn    cmstud ll urupnsllrlcel   laaleeuuoioooouloiuuieiau aa osm eioioigieieeai   oouuiue ddc mm rmddddvcnicclplbllLbbnil uime iueie i uoououeuooopo aoeptoeiiiiisn nei  ueeop uiiaeUiniusnaanneinaapiua cpaseaeqqrfqqDqn cslrsrdcltetri  a   eEe |
| **output** | Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. |


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
