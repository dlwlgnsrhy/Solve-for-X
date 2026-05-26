#!/bin/bash

# Ensure gh CLI is installed
if ! command -v gh &> /dev/null
then
    echo "❌ GitHub CLI (gh)가 설치되어 있지 않습니다. brew install gh 로 설치해 주세요."
    exit 1
fi

# Check authentication status
gh auth status &> /dev/null
if [ $? -ne 0 ]; then
    echo "🔑 GitHub CLI에 로그인되어 있지 않습니다. 로그인을 시작합니다..."
    gh auth login
fi

echo "🚀 GitHub 리포지토리에 '웰다잉 유서 앱 고도화' 마일스톤 및 이슈를 생성합니다..."

# 1. Create Milestones
echo "📅 마일스톤 생성 중..."
gh api repos/:owner/:repo/milestones -F title="[Milestone 2] Cream Postcard Custom Styling & Fonts" -F description="아침에 디자인하신 크림색 명조 엽서 감성 테마와 폰트들을 Flutter 앱 안에 완벽하게 이식하는 시각적 융합 단계" &> /dev/null
gh api repos/:owner/:repo/milestones -F title="[Milestone 3] Life-Value Prompt Deck & Empathy Feed" -F description="유서를 가볍고 위트있게 한 줄씩 시작하게 돕는 성찰 질문 덱과 소셜 피드 교감 보관소를 구축하는 기획 고도화 단계" &> /dev/null

# 2. Create Issues for Milestone 2
echo "🏷️ Milestone 2 관련 이슈 생성 중..."
gh issue create --title "Noto Serif KR 및 Cormorant Garamond 폰트 에셋 수급 및 Flutter 파이프라인 연동" \
  --body "### Goal
임종 유언 앱의 creamPostcard 템플릿에 명조 서체 구글 폰트를 연동하여 감성을 극대화합니다.

### Tasks
- [ ] Noto Serif KR 폰트 적용
- [ ] Cormorant Garamond 영문 이탤릭 폰트 적용
- [ ] 오프라인 대응 폴백 폰트 매핑" \
  --milestone "[Milestone 2] Cream Postcard Custom Styling & Fonts" &> /dev/null

gh issue create --title "사용자 아침 디자인(imjong-care-app.html) 100% 무결점 재현 엽서 3D 전/후면 레이아웃 구현" \
  --body "### Goal
네온 SF 스타일을 완전히 배제하고, 아침에 디자인한 크림색 배경, 10px 안쪽 가이드선, 우표 데코, 미니멀한 엽서 본연의 감성을 Flutter 3D 카드에 100% 이식합니다.

### Tasks
- [ ] 4px Sharp BorderRadius 적용
- [ ] 10px 마진 안쪽 액센트 선 Stack 빌드
- [ ] 바코드 및 지문 스캔 걷어내고 우표 장식 및 미니멀 아날로그 서명선 이식" \
  --milestone "[Milestone 2] Cream Postcard Custom Styling & Fonts" &> /dev/null

# 3. Create Issues for Milestone 3
echo "🏷️ Milestone 3 관련 이슈 생성 중..."
gh issue create --title "유서 입력을 돕는 가치 성찰 랜덤 질문 덱(Prompt Deck) 인터랙티브 모듈 구현" \
  --body "### Goal
유서를 가볍고 위트 있게 한 줄씩 시작할 수 있게 돕는 7가지 성찰 질문 덱과 폼 자동 주입(Apply) 엔진을 장착합니다.

### Tasks
- [ ] 7가지 웰다잉 라이트 밸류 질문 데이터 구축
- [ ] 🎲 SHUFFLE 및 자동 작성 적용 기능 장착" \
  --milestone "[Milestone 3] Life-Value Prompt Deck & Empathy Feed" &> /dev/null

gh issue create --title "3D 유서 엽서를 모아보고 하트 리액션을 교감하는 공감 아카이브 허브 화면 고도화" \
  --body "### Goal
히스토리 허브에 POSTCARD 필터 칩을 연동하고, 리스트 내 카드들이 엽서 템플릿을 온전히 계승하여 아름답게 보이게 만듭니다.

### Tasks
- [ ] POSTCARD 필터 칩 추가
- [ ] _GridCardItem 내 엽서 질감 및 Noto Serif KR 폰트 일관성 적용" \
  --milestone "[Milestone 3] Life-Value Prompt Deck & Empathy Feed" &> /dev/null

echo "🎉 GitHub Milestones 및 Issues가 완벽하게 실시간 등록/동기화되었습니다!"
