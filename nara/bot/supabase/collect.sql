-- 수집 시각 관리 (Supabase SQL Editor 에 통째로 붙여넣고 Run. 여러 번 실행해도 안전)
-- GitHub 의 예약 실행은 몇 시간씩 밀려서 쓰지 않고, Supabase 가 GitHub 에 "수집 실행"을 직접 요청한다.
--   1) 관리 화면 '발송 일정' 탭의 수집 시각(기본 08:30·13:00·17:00, 한국시간)
--   2) 발송 일정 시각 (메일을 그 시각에 보내기 위해)
--   3) 공개 화면의 '갱신' 버튼 (5분에 한 번까지)
--
-- 처음 한 번만: 아래 'github_pat_여기에_토큰' 을 실제 토큰으로 바꿔 실행한다.
--   토큰: GitHub > Settings > Developer settings > Fine-grained tokens
--         Repository access = Only select repositories (victex), Permissions > Actions = Read and write
-- 토큰을 바꿀 때만 따로 실행:
--   select vault.update_secret((select id from vault.secrets where name = 'github_dispatch_token'), 'github_pat_새토큰');

create extension if not exists pg_cron;
create extension if not exists pg_net;

do $$ begin
  if not exists (select 1 from vault.secrets where name = 'github_dispatch_token') then
    perform vault.create_secret('github_pat_여기에_토큰', 'github_dispatch_token');
  end if;
end $$;

-- 수집 시각 (관리 화면에서 편집, 공개 화면에서도 읽음)
insert into public.settings (key, value) values ('collect_times', '["08:30", "13:00", "17:00"]'::jsonb)
  on conflict (key) do nothing;
drop policy if exists "settings public collect_times" on public.settings;
create policy "settings public collect_times" on public.settings for select using (key = 'collect_times');

create table if not exists public.collect_state (
  id int primary key default 1 check (id = 1),
  last_slot timestamptz,      -- 마지막으로 실행 요청한 정해진 시각
  last_request timestamptz,   -- 마지막 실행 요청 (정해진 시각·갱신 버튼 모두)
  last_status int
);
insert into public.collect_state (id) values (1) on conflict do nothing;
alter table public.collect_state enable row level security;
drop policy if exists "collect_state read" on public.collect_state;
create policy "collect_state read" on public.collect_state for select using (true);

-- GitHub Actions 수집 실행 요청
create or replace function public.nara_dispatch() returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  perform net.http_post(
    url := 'https://api.github.com/repos/82-HY-JUN/victex/actions/workflows/nara.yml/dispatches',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'github_dispatch_token'),
      'Accept', 'application/vnd.github+json',
      'X-GitHub-Api-Version', '2022-11-28',
      'User-Agent', 'nara-cron'),
    body := '{"ref":"main"}'::jsonb);
  update collect_state set last_request = now() where id = 1;
end $$;
revoke all on function public.nara_dispatch() from public, anon, authenticated;

-- 5분마다: 지난 정해진 시각(수집 시각 + 발송 일정 시각) 중 아직 요청하지 않은 것이 있으면 실행
create or replace function public.nara_tick() returns void
language plpgsql security definer set search_path = public as $$
declare
  now_kst timestamp := now() at time zone 'Asia/Seoul';
  slot timestamptz;
begin
  select max((now_kst::date + t) at time zone 'Asia/Seoul') into slot
  from (
    select (jsonb_array_elements_text(value))::time as t from settings where key = 'collect_times'
    union
    select send_time from schedules
      where active and extract(isodow from now_kst)::int = any(weekdays)
  ) s
  where now_kst::date + t <= now_kst and now_kst::date + t > now_kst - interval '30 minutes';
  if slot is not null and slot > coalesce((select last_slot from collect_state where id = 1), '-infinity') then
    update collect_state set last_slot = slot where id = 1;
    perform nara_dispatch();
  end if;
end $$;
revoke all on function public.nara_tick() from public, anon, authenticated;

-- 공개 화면 '갱신' 버튼: 5분 안에 이미 요청했으면 다시 부르지 않음
create or replace function public.request_collect() returns text
language plpgsql security definer set search_path = public as $$
declare last timestamptz := (select last_request from collect_state where id = 1);
begin
  if last is not null and last > now() - interval '5 minutes' then return 'recent'; end if;
  perform nara_dispatch();
  return 'started';
end $$;
grant execute on function public.request_collect() to anon, authenticated;

-- 5분마다 확인 (예전 15분 요청 일정이 있으면 지움)
do $$ begin
  if exists (select 1 from cron.job where jobname = 'nara-dispatch') then perform cron.unschedule('nara-dispatch'); end if;
end $$;
select cron.schedule('nara-tick', '*/5 * * * *', 'select public.nara_tick()');

-- 확인: 최근 GitHub 응답 (status_code 204 이면 정상)
-- select status_code, content, created from net._http_response order by created desc limit 5;
