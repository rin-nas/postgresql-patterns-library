/*
Выгрузка из БД:
psql postgresql://user@host:6001/db_name \
    --command='\copy (select id,pid,word,checked from sphinx_wordforms order by word) to stdout csv' > sphinx_wordforms.csv
xz -zc9 --threads=8 sphinx_wordforms.csv > sphinx_wordforms.csv.xz
*/

CREATE EXTENSION IF NOT EXISTS fuzzymatch;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE public.sphinx_wordforms (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pid integer DEFAULT 0 NOT NULL,
    word text NOT NULL check (length(word) between 1 and 100),
    checked boolean
);
--ALTER TABLE public.sphinx_wordforms OWNER TO alexan;

COMMENT ON TABLE public.sphinx_wordforms IS 'Слова русского языка со словоформами';
COMMENT ON COLUMN public.sphinx_wordforms.id IS 'Идентификатор';
COMMENT ON COLUMN public.sphinx_wordforms.pid IS 'Идентификатор леммы (начальной, словарной формы слова)';
COMMENT ON COLUMN public.sphinx_wordforms.word IS 'Слово или словосочетание в нижнем регистре';
COMMENT ON COLUMN public.sphinx_wordforms.checked IS 'Проверенное слово?';

\copy public.sphinx_wordforms from program 'xzcat sphinx_wordforms.csv.xz' with (format csv, header true);

-- создавать индексы после вставки данных быстрее, чем наоборот

CREATE INDEX idx_sphinx_wordforms_pid ON public.sphinx_wordforms USING btree (pid);
CREATE UNIQUE INDEX idx_sphinx_wordforms_wildspeed_word_unique_lower ON public.sphinx_wordforms USING btree (lower((word)) varchar_pattern_ops);
CREATE INDEX idx_sphinx_wordforms_word ON public.sphinx_wordforms USING btree (word);

-- создавать внешние ключи после создания индексов быстрее, чем наоборот
ALTER TABLE ONLY public.sphinx_wordforms ADD CONSTRAINT v3_sphinx_wordforms_fk1 FOREIGN KEY (pid) REFERENCES public.sphinx_wordforms(id);

CREATE INDEX /*CONCURRENTLY*/ IF NOT EXISTS custom_query_group_name_name_trigram_index ON public.custom_query_group_name USING GIN (lower(name) gin_trgm_ops);
CREATE INDEX /*CONCURRENTLY*/ IF NOT EXISTS sphinx_wordforms_word_trigram_index ON public.sphinx_wordforms USING GIN (lower(word) gin_trgm_ops);

SELECT COUNT(*) FROM sphinx_wordforms; -- 1,241,857 записей
