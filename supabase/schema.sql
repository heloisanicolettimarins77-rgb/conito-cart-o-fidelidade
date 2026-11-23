-- Conito — Cartão fidelidade
-- Cole este arquivo inteiro no Supabase: SQL Editor > New query > Run.
-- Pode rodar de novo sem problema (é idempotente).

-- ---------- tabelas ----------

create table if not exists public.clientes (
  k          text primary key,              -- hash do telefone (mesmo esquema do artifact antigo)
  nome       text not null check (char_length(nome) <= 60),
  tel        text,                          -- WhatsApp completo, só o admin enxerga
  t4         text,                          -- 4 últimos dígitos
  selos      integer not null default 0 check (selos >= 0),
  resgates   integer not null default 0 check (resgates >= 0),
  em         timestamptz not null default now(),   -- última marcação
  criado_em  timestamptz not null default now()
);

create table if not exists public.config (
  id          integer primary key default 1 check (id = 1),
  alvo        integer not null default 10 check (alvo between 1 and 20),
  link        text not null default '',
  comunidade  text not null default ''
);

create table if not exists public.admins (
  email text primary key
);

insert into public.config (id) values (1) on conflict (id) do nothing;

-- Quem pode entrar na área do administrador (troque/adicione e-mails aqui).
insert into public.admins (email) values ('vivi@conito.com.br') on conflict do nothing;

-- Cliente que já existia no artifact (sem telefone completo; o admin completa na ficha).
insert into public.clientes (k, nome, t4, selos, resgates, em)
values ('e526ae8c11', 'Nicole', '3350', 1, 0, to_timestamp(1791394536208 / 1000.0))
on conflict (k) do nothing;

-- ---------- funções ----------

create or replace function public.sou_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- Visão pública do cartão: a cliente consulta pelo hash do telefone
-- e recebe só nome, 4 dígitos e contagem (nunca o telefone, nunca a lista).
create or replace function public.consultar_cartao(p_k text)
returns table (nome text, t4 text, selos integer, resgates integer)
language sql stable security definer
set search_path = public
as $$
  select c.nome, c.t4, c.selos, c.resgates
  from public.clientes c
  where c.k = p_k
  limit 1;
$$;

revoke all on function public.sou_admin() from public;
revoke all on function public.consultar_cartao(text) from public;
grant execute on function public.sou_admin() to anon, authenticated;
grant execute on function public.consultar_cartao(text) to anon, authenticated;

-- ---------- segurança (RLS) ----------

alter table public.clientes enable row level security;
alter table public.config   enable row level security;
alter table public.admins   enable row level security;

drop policy if exists "admin gerencia clientes" on public.clientes;
create policy "admin gerencia clientes" on public.clientes
  for all to authenticated
  using (public.sou_admin()) with check (public.sou_admin());

drop policy if exists "todos leem config" on public.config;
create policy "todos leem config" on public.config
  for select to anon, authenticated using (true);

drop policy if exists "admin altera config" on public.config;
create policy "admin altera config" on public.config
  for all to authenticated
  using (public.sou_admin()) with check (public.sou_admin());

-- admins: sem policy = ninguém lê/escreve pela API (só pelo painel do Supabase).

grant select on public.config to anon, authenticated;
grant select, insert, update, delete on public.clientes to authenticated;
grant insert, update on public.config to authenticated;
