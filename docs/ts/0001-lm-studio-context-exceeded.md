# 1. LM Studio "Model context exceeded" 에러 해결

Date: 2026-03-28

## Problem
- LM Studio를 통한 모델 연결 직후 또는 채팅 도중 "Model context exceeded" 메시지와 함께 추론이 중단되는 현상 발생.

## Cause
- LM Studio의 기본 컨텍스트 윈도우(Context Window) 설정값이 Qwen3-Coder 30B 모델이 요구하거나 현재 작업 중인 코드 맥락을 수용하기에 너무 작게 설정되어 있었음.

## Solution
1. LM Studio 설정 내 `Context Length`를 **64K**로 확장하여 해결.
2. 최초 모델 로딩 시 VRAM 할당 시간을 충분히 확보하여 안정적인 구동 확인.

## Note
- PC 스펙(하드웨어 성능)에 따라 64K 설정 시 초기 로딩 및 응답 속도에 차이가 있을 수 있습니다.
- 작업 효율성과 시스템 부하 사이의 균형을 위해 향후 필요시 채팅 경험에 맞춰 재조정될 수 있습니다.
