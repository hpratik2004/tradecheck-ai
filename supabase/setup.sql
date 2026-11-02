-- TradeCheck AI: Supabase setup for the tariff vector store
-- Run once in the Supabase SQL Editor.
-- The vector size 3072 matches Google's gemini-embedding-001 model.
-- If you use a different embeddings model, change 3072 to that model's dimension.

create extension if not exists vector;

create table if not exists documents (
  id bigserial primary key,
  content text,          -- "HS 940521: Electric table desk bedside or floor lamps ..."
  metadata jsonb,        -- {"hs6": "940521", ...}
  embedding vector(3072)
);

-- Search function used by the n8n Supabase Vector Store node
create or replace function match_documents (
  query_embedding vector(3072),
  match_count int default null,
  filter jsonb default '{}'
) returns table (id bigint, content text, metadata jsonb, similarity float)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select id, content, metadata,
         1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- Block access through the public API; n8n uses the secret key, which bypasses RLS
alter table documents enable row level security;

-- To reload the tariff, empty the table first, then run the Tariff Loader workflow once:
-- truncate table documents;
