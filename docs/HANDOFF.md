# 개발 이력과 인수인계

이 문서는 Claude 프로젝트 "나라장터 입찰공고 자동조회 및 웹플랫폼 구축" 에서 진행한 작업을 정리한 것입니다.
Claude 프로젝트 채팅 기록을 볼 수 없어도 이 문서와 저장소만으로 개발을 이어갈 수 있게 하는 것이 목적입니다.
(2026-10-20 기준. 큰 변경을 할 때마다 아래 '변경 이력' 과 '결정 사항' 을 갱신해 주세요.)

## 1. 지금 돌아가는 것
| 항목 | 위치 |
|---|---|
| 첫 화면 | https://82-hy-jun.github.io/victex/ |
| 공고 조회 | https://82-hy-jun.github.io/victex/nara/ |
| 관리 화면 | https://82-hy-jun.github.io/victex/nara/admin/ |
| 자동 수집·메일 | 이 저장소 Actions `NARA 입찰공고 수집·메일 발송` (15분마다) |
| 공고 데이터 | 이 저장소 `nara-data` 브랜치 (봇이 매번 덮어씀) |
| 로그인·설정 저장 | Supabase 프로젝트 (표 구조는 `nara/bot/schema.sql`) |
| 메일 발송 | 회사 메일 서버 `gw.victex.co.kr:465` (SSL), 2026-10-20 시험 발송 성공 |
| 회사 저장소 | `Victex-HR/Homepage` 의 `nara/` (같은 화면, 자동 수집은 꺼짐) |

모든 것이 GitHub 와 Supabase 위에서 돌아가므로 **Claude 가 없어도 수집·화면·메일은 계속 동작합니다.**
Claude 에 의존하는 것은 아래 6장의 '아침 수집 예약 작업' 하나뿐입니다.

## 2. 비밀값과 설정 (이름만, 값은 적지 않음)
GitHub `82-HY-JUN/victex` > Settings > Secrets and variables > Actions
- Secrets: `NARA_API_KEY`, `SUPABASE_SERVICE_KEY`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `MAIL_FROM`
- Variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (선택: `MAIL_TO`, `MAIL_TIME` 은 Supabase 없이 메일만 보낼 때)

Supabase
- Authentication > URL Configuration > Site URL: 관리 화면 주소
- Edge Functions > Secrets: `NARA_API_KEY` ('갱신' 버튼용 `nara-live` 함수를 배포한 경우)

`NARA_API_KEY` 는 공공데이터포털(data.go.kr)에서 발급한 인증키입니다. 활용신청한 서비스:
- 조달청 나라장터 공공데이터개방표준서비스 (15058815, `getDataSetOpnStdBidPblancInfo`)
- 조달청 나라장터 사전규격정보서비스 (사전규격 탭용, 별도 신청)

키나 비밀번호를 잃어버리면 각 발급처에서 새로 만들어 위 이름 그대로 다시 넣으면 됩니다.

## 3. 동작 흐름
1. Actions 가 15분마다 `nara/bot` 에서 `python nara.py tick` 실행
2. 하루 첫 실행 때 사흘 전~어제 공고를 다시 받아 늦게 올라온 공고를 채움. 오늘 공고는 15분마다 덧붙이고 2시간마다 전체를 다시 받음. 최근 60일 보관
3. 추천 기준(Supabase `settings`, 없으면 `config.json`)으로 점수 계산. 기준이 바뀌면 수집 없이 점수만 다시 계산
4. Supabase `schedules` 에 시각이 된 일정이 있으면 전날 공고 엑셀(추천 / 진행 중 추천 전체 / 전체 공고 3개 시트)을 `recipients` 에 메일 발송, `send_log` 에 기록
5. 결과 데이터를 `nara-data` 브랜치에 강제 푸시 → 화면은 `raw.githubusercontent.com/<계정>/<저장소>/nara-data/` 에서 읽음

점수 규칙: 그룹별로 공고명에 키워드가 있으면 30점, 키워드가 더 있으면 하나에 10점(최대 20점), 투찰가능업종에만 있으면 10점, 발주처 일치 20점.
키워드 앞의 `^` 는 단어 첫머리 일치, 4자 이하 영문 약어는 앞뒤가 영문자가 아닐 때만 일치.

## 4. 결정 사항 (왜 이렇게 했는지)
- **서버 없이 GitHub Pages + Actions + Supabase**: 비용 없이 운영하고 관리할 서버를 두지 않기 위해.
- **데이터는 `nara-data` 브랜치에 덮어쓰기**: 15분마다 쌓이는 데이터가 저장소 이력을 키우지 않도록.
- **1시간 단위로 100건씩 나눠 받고, 빠지면 다시 받기**: 한 번에 많이 받으면 페이지가 밀려 공고가 빠지고 연결이 끊김.
- **처음 가입한 사람이 관리자**: 별도 관리자 설정 없이 시작하기 위해. 이후 가입자는 관리자가 승인.
- **개인 저장소로 이전 (2026-10-18~20)**: 회사 저장소 권한과 무관하게 운영하기 위해 `82-HY-JUN/victex` 로 옮김.
  회사 저장소에는 같은 화면을 남기되 자동 수집은 끔 (같은 API 키로 두 곳에서 15분마다 부르면 호출 한도 초과 위험).
- **화면 변경은 두 저장소에 모두 반영**: 사용자 요청. 두 `nara/` 의 차이는 `DATA_BASE` 한 줄과 README 뿐.
- **회사 메일로 발송**: 사용자 결정. 비밀번호를 바꾸거나 계정이 정지되면 발송이 멈추므로 그때 `SMTP_PASSWORD` 를 갱신.
  해외(GitHub 서버) 로그인 차단 시 실패할 수 있음. 대안은 발송 전용 Gmail 앱 비밀번호.
- **공개 화면은 로그인 없음**: 주소를 아는 누구나 볼 수 있으므로 키워드·발주처도 공개됨을 감안.

## 5. 변경 이력
| 날짜 | 내용 |
|---|---|
| 2026-10-08 | Claude 프로젝트 공유 폴더에서 로컬 스크립트(`nara_bids.py`)로 일일 조회·추천 리포트 시작 |
| 2026-10-12 | 실데이터 수집 자동화, Claude 예약 작업으로 아침마다 아티팩트 화면 갱신 |
| 2026-10-16 | 회사 저장소 `Victex-HR/Homepage` 에 `nara/` 화면·관리 화면·Actions 수집 구축, Supabase 연결 |
| 2026-10-16~ | 사전규격 합치기, 탭 재구성(전체·추천·입찰·사전규격·보관함), 공고 보관 기능 |
| 2026-10-18~20 | 개인 저장소 `82-HY-JUN/victex` 로 이전, 첫 화면 카드 선택 화면, 추천 카드에 공고 보기 링크, 수동 실행에 시험 발송 주소 |
| 2026-10-20 | 회사 저장소 자동 수집 끔 (Homepage PR #2), 회사 SMTP 로 시험 메일 발송 성공 |

## 6. 남은 일 / 알아둘 점
- **회사 저장소 화면의 데이터가 멈춰 있음**: 회사 `nara/` 화면은 `Victex-HR/Homepage` 의 `nara-data` 를 읽는데,
  자동 수집을 끈 뒤(2026-10-20 12:27) 갱신되지 않습니다. 회사 화면도 쓰려면 회사 `DATA_BASE` 를
  `https://raw.githubusercontent.com/82-HY-JUN/victex/nara-data/` 로 바꾸는 것이 가장 간단합니다 (개인 저장소가 공개여야 함).
- **회사 홈페이지 배너 PR**: `Victex-HR/Homepage` PR #1 (홈 화면에 나라장터 추천 배너) 이 열려 있음.
- **Claude 아침 수집 예약 작업**: 평일 07:47(한국시간)에 Claude 가 프로젝트 공유 폴더의 옛 스크립트로 아티팩트 화면을 갱신합니다.
  GitHub Actions 와 별개인 옛 방식이라 Claude 를 쓰지 못하게 되면 이것만 멈추고, 실제 서비스에는 영향이 없습니다.
- **발송 일정**: 관리 화면 '발송 일정' 탭에 일정이 있어야 메일이 나갑니다.
- Actions 예약 실행은 저장소에 60일간 활동이 없으면 GitHub 가 자동으로 멈춥니다. 멈추면 Actions 탭에서 다시 켭니다.

## 7. 다른 곳에서 개발을 이어가는 방법
어떤 방법이든 출발점은 이 저장소입니다. 새 Claude 에게는 "CLAUDE.md 와 docs/HANDOFF.md 를 먼저 읽고 시작해" 라고 하면 됩니다.

**A. Claude Code 웹 (claude.ai/code)**: 브라우저만 있으면 됩니다.
1. claude.ai/code 접속 → GitHub 연결 → 저장소 `82-HY-JUN/victex` 선택
2. 요청 작성. 결과는 브랜치·PR 로 올라오고, 병합하면 1~2분 뒤 화면에 반영

**B. Claude Code 데스크톱 앱 / 터미널(CLI)**: 내 PC 에서 작업.
1. `git clone https://github.com/82-HY-JUN/victex.git && cd victex`
2. `claude` 실행 (CLI 설치: https://code.claude.com/docs) — 시작할 때 `CLAUDE.md` 를 자동으로 읽음
3. 수정 후 `git push` 하면 GitHub Pages 에 반영

**C. 사람 개발자에게 넘길 때**: 저장소 협업자로 초대하고 이 문서를 전달. 비밀값은 저장소 관리자가 직접 넣습니다.

**D. 코드 없이 운영만 할 때**
- 추천 기준·수신자·발송 일정: 관리 화면에서 변경
- 즉시 수집 / 시험 메일: Actions 탭 > `NARA 입찰공고 수집·메일 발송` > Run workflow
- 실패 확인: Actions 탭의 빨간 실행을 열어 로그 확인
