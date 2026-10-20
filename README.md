# 나라장터 입찰공고 자동조회

- `index.html` 업무 도구 첫 화면 (카드 선택)
- `nara/` 공개 화면, `nara/admin/` 관리 화면 (GitHub Pages)
- `nara/bot/` 수집·메일 발송 스크립트와 Supabase 설정 (`schema.sql`, `supabase/functions/nara-live`)
- `.github/workflows/nara.yml` 15분마다 수집해 `nara-data` 브랜치에 공고 데이터를 올림

자세한 설정은 [nara/bot/README.md](nara/bot/README.md) 를 보세요.
