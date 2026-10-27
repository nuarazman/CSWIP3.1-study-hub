-- CSWIP 3.1 Study Hub cloud sync schema
-- Run this whole script in Supabase Dashboard > SQL Editor.
-- IMPORTANT: Never put a Supabase service_role key in the browser app.
create extension if not exists pgcrypto;

create table if not exists public.cswip_study_vaults (
  id bigint generated always as identity primary key,
  code_hash text not null unique,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.cswip_study_vaults enable row level security;

-- No direct table access for anon/authenticated clients. All access is through
-- narrowly-scoped RPC functions that check a high-entropy recovery code.
revoke all on table public.cswip_study_vaults from anon, authenticated;
grant usage on schema public to anon, authenticated;

create or replace function public.cswip_ping()
returns jsonb
language sql
security definer
set search_path = pg_catalog, public
as $$ select jsonb_build_object('ok', true); $$;

create or replace function public.cswip_create_vault(p_code text, p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_hash text;
begin
  if p_code is null or length(p_code) < 40 or length(p_code) > 100 then
    raise exception 'Invalid recovery code format';
  end if;
  if p_payload is null or pg_column_size(p_payload) > 500000 then
    raise exception 'Invalid or oversized study data';
  end if;
  v_hash := encode(digest(convert_to(p_code, 'UTF8'), 'sha256'), 'hex');
  insert into public.cswip_study_vaults(code_hash, payload)
  values (v_hash, p_payload);
  return jsonb_build_object('ok', true);
exception when unique_violation then
  raise exception 'Vault already exists; generate a new recovery code';
end;
$$;

create or replace function public.cswip_open_vault(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare v_payload jsonb;
begin
  if p_code is null or length(p_code) < 40 or length(p_code) > 100 then
    return null;
  end if;
  select payload into v_payload
  from public.cswip_study_vaults
  where code_hash = encode(digest(convert_to(p_code, 'UTF8'), 'sha256'), 'hex');
  return v_payload;
end;
$$;

create or replace function public.cswip_save_vault(p_code text, p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare v_hash text;
begin
  if p_code is null or length(p_code) < 40 or length(p_code) > 100 then
    raise exception 'Invalid recovery code format';
  end if;
  if p_payload is null or pg_column_size(p_payload) > 500000 then
    raise exception 'Invalid or oversized study data';
  end if;
  v_hash := encode(digest(convert_to(p_code, 'UTF8'), 'sha256'), 'hex');
  update public.cswip_study_vaults
  set payload = p_payload, updated_at = now()
  where code_hash = v_hash;
  if not found then raise exception 'Vault not found'; end if;
  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.cswip_ping() from public;
revoke all on function public.cswip_create_vault(text, jsonb) from public;
revoke all on function public.cswip_open_vault(text) from public;
revoke all on function public.cswip_save_vault(text, jsonb) from public;

grant execute on function public.cswip_ping() to anon, authenticated;
grant execute on function public.cswip_create_vault(text, jsonb) to anon, authenticated;
grant execute on function public.cswip_open_vault(text) to anon, authenticated;
grant execute on function public.cswip_save_vault(text, jsonb) to anon, authenticated;

-- Recommended: add project-level rate limits / abuse protection if you publish
-- this beyond personal use. The recovery code is a bearer secret: anyone who
-- obtains it can read and replace the vault's study data.
