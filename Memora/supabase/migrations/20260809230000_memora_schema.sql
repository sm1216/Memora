-- Memora: profiles, memories, tags, storage

-- Profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Traveler',
  email text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Profiles are viewable by owner"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1), 'Traveler'),
    new.email
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Memories
create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  short_id text not null unique,
  title text not null default 'Untitled',
  story text not null default '',
  location_name text not null default '',
  country_code text not null default 'XX',
  latitude double precision not null default 0,
  longitude double precision not null default 0,
  start_date date not null default current_date,
  end_date date not null default current_date,
  is_public boolean not null default true,
  cover_path text,
  photo_paths text[] not null default '{}',
  steps jsonb not null default '[]'::jsonb,
  collaborator_names text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists memories_user_id_idx on public.memories(user_id);
create index if not exists memories_short_id_idx on public.memories(short_id);

alter table public.memories enable row level security;

create policy "Owners full access memories"
  on public.memories for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Public memories readable by anyone"
  on public.memories for select
  using (is_public = true);

-- NFC tags
create table if not exists public.nfc_tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'NFC tag',
  memory_id uuid references public.memories(id) on delete set null,
  short_id text,
  is_connected boolean not null default false,
  last_written_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists nfc_tags_user_id_idx on public.nfc_tags(user_id);

alter table public.nfc_tags enable row level security;

create policy "Owners full access tags"
  on public.nfc_tags for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Storage bucket for memory media
insert into storage.buckets (id, name, public)
values ('memories', 'memories', true)
on conflict (id) do nothing;

create policy "Anyone can view memory media"
  on storage.objects for select
  using (bucket_id = 'memories');

create policy "Authenticated users upload own media"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'memories'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users update own media"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'memories'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users delete own media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'memories'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
