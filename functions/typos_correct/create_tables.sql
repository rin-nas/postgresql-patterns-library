/*
Выгрузка данных из БД:
psql postgresql://user@host:6001/db_name \
    --command='\copy (select id,pid,word,checked from public.wordforms order by word) to stdout csv' \
    > wordforms.csv
xz -zc9 --threads=8 wordforms.csv > wordforms.csv.xz
*/

CREATE EXTENSION IF NOT EXISTS fuzzymatch;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE public.wordforms (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pid integer DEFAULT 0 NOT NULL,
    word text NOT NULL check (length(word) between 1 and 100),
    checked boolean
);
--ALTER TABLE public.wordforms OWNER TO alexan;

COMMENT ON TABLE public.wordforms IS 'Слова русского языка со словоформами';
COMMENT ON COLUMN public.wordforms.id IS 'Идентификатор';
COMMENT ON COLUMN public.wordforms.pid IS 'Идентификатор леммы (начальной, словарной формы слова)';
COMMENT ON COLUMN public.wordforms.word IS 'Слово или словосочетание в нижнем регистре';
COMMENT ON COLUMN public.wordforms.checked IS 'Проверенное слово?';

\copy public.wordforms from program 'xzcat wordforms.csv.xz' with (format csv, header true);

-- создавать индексы после вставки данных быстрее, чем наоборот

CREATE INDEX idx_sphinx_wordforms_pid ON public.wordforms USING btree (pid);
CREATE UNIQUE INDEX idx_sphinx_wordforms_wildspeed_word_unique_lower ON public.wordforms USING btree (lower((word)) varchar_pattern_ops);
CREATE INDEX idx_sphinx_wordforms_word ON public.wordforms USING btree (word);

-- создавать внешние ключи после создания индексов быстрее, чем наоборот
ALTER TABLE ONLY public.wordforms ADD CONSTRAINT v3_sphinx_wordforms_fk1 FOREIGN KEY (pid) REFERENCES public.wordforms(id);

--CREATE INDEX /*CONCURRENTLY*/ IF NOT EXISTS custom_query_group_name_name_trigram_index ON public.custom_query_group_name USING GIN (lower(name) gin_trgm_ops);
CREATE INDEX /*CONCURRENTLY*/ IF NOT EXISTS sphinx_wordforms_word_trigram_index ON public.wordforms USING GIN (lower(word) gin_trgm_ops);

SELECT COUNT(*) FROM public.wordforms; -- 1,241,857 записей
