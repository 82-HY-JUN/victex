-- GitHub 의 예약 실행(schedule)은 무료 저장소에서 몇 시간씩 밀리거나 건너뛰는 일이 잦다.
-- 그래서 Supabase 가 15분마다 GitHub 에 "수집 실행"을 직접 요청하게 한다 (workflow_dispatch).
-- 사용법: 아래 'github_pat_여기에_토큰' 부분만 실제 토큰으로 바꿔 SQL Editor 에서 한 번 Run.
--   토큰: GitHub > Settings > Developer settings > Fine-grained tokens
--         Repository access = Only select repositories (victex), Permissions > Actions = Read and write

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- 토큰은 Supabase Vault 에 암호화해 보관 (다시 실행하면 같은 이름이 있어 오류가 나므로, 바꿀 때는 아래 update 사용)
select vault.create_secret('github_pat_여기에_토큰', 'github_dispatch_token');
-- 토큰을 바꿀 때:
-- select vault.update_secret((select id from vault.secrets where name = 'github_dispatch_token'), 'github_pat_새토큰');

select cron.schedule('nara-dispatch', '*/15 * * * *', $$
  select net.http_post(
    url := 'https://api.github.com/repos/82-HY-JUN/victex/actions/workflows/nara.yml/dispatches',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'github_dispatch_token'),
      'Accept', 'application/vnd.github+json',
      'X-GitHub-Api-Version', '2022-11-28',
      'User-Agent', 'nara-cron'),
    body := '{"ref":"main"}'::jsonb);
$$);

-- 확인: 최근 요청 결과 (status_code 204 이면 정상)
-- select id, status_code, content, created from net._http_response order by created desc limit 5;
-- 끄기: select cron.unschedule('nara-dispatch');
