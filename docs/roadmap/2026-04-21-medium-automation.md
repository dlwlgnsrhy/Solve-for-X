# 2026-04-21 Medium 블로그 자동화 파이프라인 구축

> **Phase 1: Base Camp** — SRE Blog (Medium) 자동화 파이프라인 구축
> **Phase 3: Knowledge Target** — SFX Career Vault 지식 퍼블리싱 브릿지 엔진으로 확장

---

## 📋 오늘 한 일 (2026.04.21)

### 1. browser-harness 로컬 환경 구축
- `browser-use/browser-harness` 복제 및 설치 (`~/workspace/browser-harness`)
- Python 가상환경 설정 (`cdp-use`, `websockets` 의존성)
- 로컬 Chrome 브라우저 CDP 연결 (`--remote-debugging-port=9222`)
- daemon.py를 통한 Unix Socket 브릿지 설정 (`/tmp/bu-default.sock`)
- Chrome 세션 검증: 탭 조회, 페이지 정보, 스크린샷 등 기본 조작 확인

### 2. Medium 로그인 세션 확인 및 자동 연결
- Chrome 프로필 (`~/.hermes/browser-harness-chrome-profile`)의 Medium 쿠키 확인
- Medium 계정 `@dlwlgnsrhy` (이름: lee)으로 이미 로그인 상태 확인
- 세션 쿠키가 Chrome 프로필에 영구 저장되어 매번 로그인 불필요

### 3. Medium 에디터 구조 분석 및 자동화 흐름 파악
- Medium editor (`https://medium.com/new-story`)의 Lexical editor 구조 분석
- 제목 설정: `h3.graf--h3.graf--leading.graf--title` contentEditable 조작
- 본문 설정: `p.graf--p.graf-after--h3` contentEditable 조작
- Draft 저장 감지: `.metabar-block`의 "DraftSaved" 상태 폴링
- Publish 버튼: metabar-block 내부 버튼 클릭 (가장 안정적인 방법)
- Submission 페이지 구조 분석:
  - Story preview (title, subtitle, image quality score)
  - Topics 입력 (최대 5개, Enter 키로 확인)
  - Publication (선택사항, "Submit" 버튼으로 제출)
  - CAPTCHA (reCAPTCHA Enterprise, 수동 해결 필요)

### 4. helpers.py 확장 (8개 Medium 전용 헬퍼 함수)
```python
medium_new_story()           # 에디터 열기
medium_set_title(title)      # 제목 설정
medium_set_body(body)        # 본문 설정
medium_wait_for_draft()      # Draft 저장 대기
medium_publish()             # Publish 페이지 이동
medium_add_topics(topics)    # Topics 설정 (최대 5개)
medium_get_submission_state() # 제출 페이지 상태 확인
medium_final_publish()       # 최종 Publish (CAPTCHA 수동 해결 필요)
```
- 모든 함수 테스트 완료 (실제 브라우저에서 작동 확인)

### 5. Medium 글쓰기 도메인 스킬 생성
- `domain-skills/medium/publishing.md` 생성
- CAPTCHA 한계 명시적 문서화
- 사용 예시 및 오류 처리 가이드 포함

---

## ⚠️ 현재 한계점

### CAPTCHA (reCAPTCHA Enterprise)
- Medium의 최종 Publish 버튼은 reCAPTCHA Enterprise 사용
- **에이전트 자동화 불가**: 사용자가 수동으로 CAPTCHA 해결 필요
- 에이전트는 제목, 본문, Topics까지 자동 설정하고 Publish 페이지까지 이동 가능
- CAPTCHA 해결 후 `medium_final_publish()` 호출로 게시 완료

### 추가 고려사항
- Medium의 클래스명은 해시값이라 변경 가능 (tag/class 패턴으로 선택 권장)
- Draft 저장은 필수 (저장 전 Publish 시도 시 팝업 발생)
- Topics는 하나씩 Enter 키로 확인해야 함
- Publication 제출은 "Submit" 버튼, 일반 게시는 "Publish" 버튼

---

## 📅 이후 계획

### 단기 (이번 주)
1. **CAPTCHA 우회 방안 연구**
   - reCAPTCHA solving API 연동 검토 (2Captcha, CapMonster, etc.)
   - 또는 Selenium/Playwright의 CAPTCHA extension 활용
   - 또는 수동 CAPTCHA 해결 후 에이전트가 자동으로 `medium_final_publish()` 호출하는 워크플로우

2. **Telegram 봇 연동**
   - `python-telegram-bot` 라이브러리 사용
   - Telegram 메시지 수신 → 브라우저 해리스 호출 → Medium 게시 → 결과 Telegram 보고
   - 예: `/blog "제목" "본문"` 명령어

3. **contentEditable richer 텍스트 지원**
   - HTML 포맷팅 (볼드, 이탤릭, 코드 블록, 목록 등)
   - 이미지 삽입 (Unsplash, 로컬 파일 업로드)

### 중기 (1-2개월)
4. **SFX Career Vault 통합** (Phase 3)
   - 오늘 작성한 helpers.py를 SFX 프로젝트의 libs/로 이동
   - Git commit 메시지 파싱 → Medium 블로그 초안 자동 생성
   - 지식 자산의 자동 이식 파이프라인

5. **Publication 자동 제출**
   - 팔로우한 Publication 목록 조회
   - 적절한 Publication에 자동 제출

6. **크롤링/분석 연동**
   - Medium scraping.md skill과 publishing.md skill 통합
   - 인기 글 분석 → 콘텐츠 아이디어 생성 → 자동 게시

### 장기 (3-6개월)
7. **AI 기반 콘텐츠 생성 연동**
   - AI 에이전트가 연구 → 글쓰기 → 게시까지 전체 자동화
   - CAPTCHA 해결이 가능해지면 완전히 무인화

8. **다중 플랫폼 배포**
   - Medium + Dev.to + Hashnode 등으로 자동 동시 게시

---

## 📁 관련 파일

| 파일 | 경로 | 설명 |
|------|------|------|
| helpers.py | `~/workspace/browser-harness/helpers.py` | Medium 헬퍼 함수 8개 |
| publishing.md | `~/workspace/browser-harness/domain-skills/medium/publishing.md` | Medium 글쓰기 도메인 스킬 |
| scraping.md | `~/workspace/browser-harness/domain-skills/medium/scraping.md` | Medium 읽기/스크래핑 스킬 (미리 존재) |
| article-hydration.md | `~/workspace/browser-harness/domain-skills/medium/article-hydration.md` | Medium DOM 추출 스킬 (미리 존재) |

---

## 🔗 연동 참조

- **ROADMAP.md**: Phase 1 Base Camp, Phase 3 Knowledge Target
- **git**: `git log --oneline`로 변경 이력 추적
- **Telegram 봇**: 추후 연동 예정 (BotFather Token + Chat ID 필요)

---

*기록: 2026-04-21 | 작성: Hermes Agent | 검토 필요: 없음*
