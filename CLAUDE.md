# CLAUDE.md

이 저장소에서 작업하는 Claude Code(또는 개발자)가 처음에 읽는 안내입니다.
지금까지의 개발 이력과 결정 사항은 [docs/HANDOFF.md](docs/HANDOFF.md) 에 있으니 작업 전에 꼭 읽어 주세요.

## 한눈에 보기
- 나라장터(조달청) 입찰공고를 15분마다 자동 수집해 추천 점수를 매기고, 웹 화면과 엑셀 메일로 보여주는 도구입니다.
- 서버가 없습니다. GitHub Pages(정적 화면) + GitHub Actions(수집·메일) + Supabase(로그인·설정 저장)로 돌아갑니다.
- 사용자는 한국어를 씁니다. 화면 문구, 커밋 메시지, 답변 모두 한국어로 합니다.

## 구조
| 경로 | 내용 |
|---|---|
| `index.html` | 첫 화면 (업무 도구 카드 선택) |
| `nara/index.html` | 공개 공고 조회 화면 (로그인 없음) |
| `nara/admin/index.html` | 관리 화면 (Supabase 로그인, 추천 기준·가입자·발송 일정·수신자) |
| `nara/bot/nara.py` | 실행 진입점: `tick`, `update-site`, `rebuild`, `excel`, `send-test` |
| `nara/bot/nara_bids.py` | 나라장터 API 수집·추천 점수 로직 |
| `nara/bot/config.json` | Supabase 설정 전 기본 추천 기준 |
| `nara/bot/schema.sql` | Supabase 표·권한 (여러 번 실행해도 안전) |
| `nara/bot/supabase/functions/nara-live/` | '갱신' 버튼용 Edge Function |
| `.github/workflows/nara.yml` | 15분마다 수집·메일, 데이터는 `nara-data` 브랜치에 덮어쓰기 |

`nara-data` 브랜치는 봇이 매번 강제로 덮어씁니다. 이 브랜치에 직접 커밋하지 마세요.

## 작업 규칙
- **화면을 고치면 회사 저장소에도 똑같이 반영합니다.** 회사 저장소 `Victex-HR/Homepage` 의 `nara/` 폴더가 같은 화면입니다
  (기본 브랜치 `claude/gifted-knuth-40yji1`). 두 저장소의 `nara/` 차이는 `DATA_BASE` 한 줄(데이터 읽는 주소)과 README 뿐이어야 합니다.
- 회사 저장소의 자동 수집(schedule)은 꺼져 있습니다. 같은 API 키로 두 곳에서 부르면 호출 한도를 넘기므로 켜지 마세요.
- 비밀값(API 키, 비밀번호, service_role 키)은 코드·문서·채팅에 쓰지 않습니다. 이름만 적고 값은 GitHub Secrets / Supabase Secrets 에만 둡니다.
- 공개 화면은 누구나 볼 수 있으므로 `config.json` 과 화면에 넣는 내용은 공개된다고 생각합니다.

## 로컬에서 확인
```
cd nara/bot
pip install openpyxl
export NARA_API_KEY=...            # 공공데이터포털 인증키 (값은 본인이 보관)
python nara.py update-site --days-back 3   # 공고 수집 + nara/data 생성
cd ../.. && python -m http.server 8000      # http://localhost:8000/nara/ 에서 화면 확인
```
github.io 가 아닌 주소에서는 화면이 `nara/data/` 를 읽으므로 로컬에서도 바로 확인됩니다.
수동 실행은 GitHub Actions 탭 > `NARA 입찰공고 수집·메일 발송` > Run workflow 로도 할 수 있습니다.

자세한 설정 방법은 [nara/bot/README.md](nara/bot/README.md) 에 있습니다.
