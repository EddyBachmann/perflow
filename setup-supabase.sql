-- ============================================================
-- PERFLOW — SCHEMA SUPABASE
-- Cole este SQL no SQL Editor do Supabase e execute
-- ============================================================

-- PROFILES (espelha auth.users)
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  name text,
  email text,
  created_at timestamptz default now() not null
);
alter table public.profiles enable row level security;
create policy "Ver proprio perfil" on public.profiles for select using (auth.uid() = id);
create policy "Atualizar proprio perfil" on public.profiles for update using (auth.uid() = id);
create policy "Inserir proprio perfil" on public.profiles for insert with check (auth.uid() = id);

-- Auto-criar perfil no signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, new.raw_user_meta_data->>'name', new.email)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- MEAL LOGS
create table if not exists public.meal_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  description text,
  kcal integer,
  proteina numeric,
  carboidrato numeric,
  gordura numeric,
  created_at timestamptz default now() not null
);
alter table public.meal_logs enable row level security;
create policy "Ver proprias refeicoes" on public.meal_logs for select using (auth.uid() = user_id);
create policy "Inserir proprias refeicoes" on public.meal_logs for insert with check (auth.uid() = user_id);

-- PROTOCOL LOGS
create table if not exists public.protocol_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  protocol_name text not null,
  created_at timestamptz default now() not null
);
alter table public.protocol_logs enable row level security;
create policy "Ver proprios protocolos" on public.protocol_logs for select using (auth.uid() = user_id);
create policy "Inserir proprios protocolos" on public.protocol_logs for insert with check (auth.uid() = user_id);

-- GOALS
create table if not exists public.goals (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  objetivo text not null,
  meta_kcal integer not null,
  updated_at timestamptz default now() not null,
  unique(user_id)
);
alter table public.goals enable row level security;
create policy "Ver proprias metas" on public.goals for select using (auth.uid() = user_id);
create policy "Gerenciar proprias metas" on public.goals for all using (auth.uid() = user_id);

-- Confirmacao
select 'Schema Perflow criado com sucesso!' as status;
