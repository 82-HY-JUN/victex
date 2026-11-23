# 홈페이지 리뉴얼 결과물

회사 홈페이지 작업 저장소(victex-hr/homepage)의 `original/`, `Renewal_1/` ~ `Renewal_5/` 를 복사해 둔 보기용 사본입니다.
여기서 직접 고치지 말고, 회사 저장소에서 수정한 뒤 다시 복사하세요.

```bash
# victex 저장소 루트에서, 회사 저장소가 ../homepage 에 있을 때
git -C ../homepage archive HEAD original Renewal_1 Renewal_2 Renewal_3 Renewal_4 Renewal_5 | tar -x -C homepage
```

새 시안을 추가하면 `index.html` 에 카드를 하나 더 넣고, `shots/` 에 1440×810 첫 화면 캡처를 넣습니다.
