-- Create the documents table
create table public.documents (
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

-- Enable Row Level Security (RLS)
alter table public.documents enable row level security;

-- Create a policy that allows all operations for now (for development)
-- WARNING: In production, you should restrict this to authenticated users
create policy "Enable all access for all users" on public.documents
  for all using (true) with check (true);

-- Create the storage bucket for files
insert into storage.buckets (id, name, public)
values ('document_files', 'document_files', true);

-- Create storage policy to allow public uploads (for development)
create policy "Allow public uploads" on storage.objects
  for insert with check (bucket_id = 'document_files');

-- Create storage policy to allow public reads
create policy "Allow public reads" on storage.objects
  for select using (bucket_id = 'document_files');

-- Create storage policy to allow public updates
create policy "Allow public updates" on storage.objects
  for update using (bucket_id = 'document_files');

-- Create storage policy to allow public deletes
create policy "Allow public deletes" on storage.objects
  for delete using (bucket_id = 'document_files');
