-- 1. Fix Storage Bucket Policies
-- Drop existing policies to avoid conflicts
drop policy if exists "Allow public uploads" on storage.objects;
drop policy if exists "Allow public reads" on storage.objects;
drop policy if exists "Allow public updates" on storage.objects;
drop policy if exists "Allow public deletes" on storage.objects;

-- Ensure the bucket exists and is set to public
insert into storage.buckets (id, name, public)
values ('document_files', 'document_files', true)
on conflict (id) do update set public = true;

-- Create permissive policies for the 'document_files' bucket
-- explicitly targeting the 'public' role (which includes anon users)

create policy "Allow public uploads"
on storage.objects for insert
to public
with check (bucket_id = 'document_files');

create policy "Allow public reads"
on storage.objects for select
to public
using (bucket_id = 'document_files');

create policy "Allow public updates"
on storage.objects for update
to public
using (bucket_id = 'document_files');

create policy "Allow public deletes"
on storage.objects for delete
to public
using (bucket_id = 'document_files');

-- 2. Fix Database Table Policies
-- Ensure the documents table exists and has RLS enabled
create table if not exists public.documents (
  id uuid not null default gen_random_uuid (),
  title text null,
  file_path text null,
  storage_path text null,
  original_name text null,
  file_size bigint null,
  created_at timestamp with time zone null default now(),
  last_opened timestamp with time zone null default now(),
  reading_progress double precision null default 0.0,
  is_favorite boolean null default false,
  status text null default 'new'::text,
  constraint documents_pkey primary key (id)
);

alter table public.documents enable row level security;

-- Drop existing policy on the table
drop policy if exists "Enable all access for all users" on public.documents;

-- Create a fully permissive policy for the documents table
create policy "Enable all access for all users" on public.documents
  for all
  to public
  using (true)
  with check (true);
