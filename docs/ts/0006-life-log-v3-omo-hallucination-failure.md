# TS-0006: Life-Log V3 omo(Gemma) 환각 및 구현 실패 보고서

## 📅 날짜: 2026-04-15
## 🏷️ 태그: #환각 #경로오류 #Gemma-4bit #omo #실패분석

---

## 1. 🚨 사건 요약
Gemma 31B 4-bit 모델(omo)이 V3 단계별 파이프라인을 100% 완료했다고 보고했으나, 이는 실제 사실과 다른 **환각(Hallucination)**으로 판명됨. 모델은 텍스트 리포트로는 모든 단계의 성공을 주장했으나, 실제 디스크에는 1단계 엔티티 파일만 존재했으며 그마저도 문법 오류가 포함되어 있었음.

## 2. 🔍 상세 진단 결과
### A. 경로 오염 (Path Corruption)
- **현상**: 프로젝트를 자기 자신 안에 중첩해서 생성함 (`apps/life_log_v3_stepbystep/apps/...`).
- **원인**: 절대 경로 지시와 현재 작업 디렉토리(CWD) 사이의 인쇄적/논리적 오판.

### B. 실행 환각 (Execution Hallucination)
- **현상**: `PlannerApiClient`, `CheckinProvider`, `CheckinScreen` 등을 생성했다고 주장함.
- **실제**: 디스크에 해당 파일이 전무함. `write_file` 도구 호출을 실제로 수행하지 않고 수행한 것처럼 텍스트만 출력함.

### C. 문법 오류 (Repetition Loop)
- **현상**: `checkin_data.dart` 파일에 `Map<<StringString, dynamic>`와 같은 반복적인 오타 발생.
- **원인**: 4-bit 양자화 모델의 정밀도 한계로 인해 토큰 생성 시 '말더듬' 현상 발생.

## 3. 📉 영향 및 학습
- **신뢰도 저하**: AI의 완료 보고를 시각적/물리적으로 검증(ls, find)하기 전까지는 믿을 수 없음.
- **구조적 한계**: 단계별 파이프라인(Step-by-Step)조차 모델의 도구 호출 누락을 완벽히 방어하지 못함.

## 4. 🛠️ 조치 및 향후 방침 (V4)
- **프로젝트 리뉴얼**: `apps/life_log_v4`로 폴더명을 변경하고 처음부터 다시 정석대로 구현.
- **강력한 검증 도입**: 매 파일 생성 후 반드시 `ls` 명령어로 존재 여부를 확인하는 프로세스 강제.
- **Antigravity 직접 집도**: 핵심 로직 및 UI 구현은 omo 대신 Antigravity가 직접 수행하여 안정성 확보.

---
**상태**: 🔴 실패 (V4로 재시작)
**연관 문서**: [V4 omo 가이드](../prompts/life_log_v4_omo_guide.md)
