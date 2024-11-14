# Links

* [Data Compression The Complete Reference 3rd Ed - David Salomon](https://doc.lagout.org/Others/Information%20Theory/Compression/Data%20Compression%20The%20Complete%20Reference%203rd%20Ed%20-%20David%20Salomon.pdf)
* http://compression.ru/download/rev_univ.html
* https://www.researchgate.net/figure/Schematic-representation-of-an-S9-word-encoding-the-group-of-integers-98-112-117-and_fig1_325408300 S9 inegers pack

## Arithmetic, range, ANS

* https://go-compression.github.io/algorithms/arithmetic/ Arithmetic Coding - The Hitchhiker's Guide to Compression
* https://en.wikipedia.org/wiki/Range_coding
* https://habr.com/ru/companies/playrix/articles/441814/ Энтропийное кодирование rANS или как написать собственный архиватор


## BWT
* https://epdf.tips/the-burrows-wheeler-transform-data-compression-suffix-arrays-and-pattern-matchin.html
* https://compression.ru/arctest/descript/bwt-faq.htm#8


## Distance Coding

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

## Вероятностное сжатие
* http://compression.ru/download/articles/rev_univ/fomin_1998_compression_fundamentals.pdf - теория
* https://github.com/lmcilroy/lzp
* https://www.cs.auckland.ac.nz/~peter-f/FTPfiles/1997%20Sym%20Rank%20Compression.pdf see "Bloom’s LZP compressors"

## LZW
* [GIF decoder in SQL](https://explainextended.com/2018/12/31/happy-new-year-10/)
* https://planetcalc.com/9069/ LZW online text compression
* http://compression.ru/book/part2/part2__2.htm LZW см. про скорость поиска следующего символа в таблице по хешу!
* https://github.com/mikeleo03/LZW-Compressor_Backend/blob/main/src/algorithm/algorithm.js
* https://ru.wikipedia.org/wiki/Алгоритм_Лемпеля_—_Зива_—_Велча

## RLE
* https://habr.com/ru/companies/kts/articles/831440/
