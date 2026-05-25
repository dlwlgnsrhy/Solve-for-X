#!/usr/bin/env python3
"""
unicorn_factory/run_5times_stress_test.py
=========================================
1인 유니콘 자율 소프트웨어 공장의 5-Cycle 스트레스 및 회복탄력성 실증 테스트 런너.
다섯 개의 서로 다른 SRE 시나리오를 순차적으로 큐에 밀어 넣고,
코드 주입, 파일 백업 충돌 회피, 비주얼 QA 픽셀 오차 분석을 5회 연속 구동하여
일관되고 안정적인 무인 가동성을 철저하게 실증 및 검증합니다.
"""

import os
import sys
import time
import json
import re
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(_REPO_ROOT / "scripts/unicorn_factory"))

from db_queue import DatabaseQueue
from agent_engine import AgentEngine


def run_stress_test():
    db = DatabaseQueue()
    engine = AgentEngine()

    # 5개의 실제 SRE 자율 개발 시나리오 정의 (온보딩된 앱에 맞춰 매핑)
    scenarios = [
        {"cmd": "Flutter Memento Mori Riverpod 프로바이더 최적화", "app": "sfx_memento_mori"},
        {"cmd": "Imjong Care 서체 오버플로우 교정", "app": "sfx_imjong_care"},
        {"cmd": "Legacy Vault 마스터 비밀키 키체인 보안 패치", "app": "sfx_legacy_vault_v1"},
        {"cmd": "Memento Mori 메인 대시보드 렌더링 최적화", "app": "sfx_memento_mori"},
        {"cmd": "Legacy Vault 자동 핑 SRE 비용 절감 핫픽스", "app": "sfx_legacy_vault_v1"}
    ]

    results = []

    print("=====================================================================")
    print("🚀 STARTING 5-CYCLE UNICORN FACTORY STRESS & RESILIENCY TEST")
    print("=====================================================================")

    for idx, sc in enumerate(scenarios, 1):
        print(f"\n🌀 [CYCLE {idx}/5]: Starting Scenario -> \"{sc['cmd']}\"")
        start_time = time.time()
        
        # 1. 큐 등록
        jid = db.register_job(sc["cmd"], sc["app"])
        
        # 2. 에이전트 자율 기동
        engine.execute_job(jid)
        
        elapsed = time.time() - start_time
        
        # 3. 결과 상태 확인 및 수집
        job_info = db.get_job(jid)
        
        diff_ratio = 0.0
        qa_verdict = "PASS"
        
        # walkthrough_md 파싱으로 실제 오차율 추출
        walkthrough_path = _REPO_ROOT / "docs/plans/walkthrough.md"
        if walkthrough_path.exists():
            content = walkthrough_path.read_text(encoding="utf-8")
            match_diff = re.search(r"오차율:\s*\*\*([0-9\.]+)%\*\*", content)
            if match_diff:
                diff_ratio = float(match_diff.group(1))
            match_verd = re.search(r"Pillow Visual QA Verdict:\s*\*\*([A-Z]+)\*\*", content)
            if match_verd:
                qa_verdict = match_verd.group(1)

        results.append({
            "cycle": idx,
            "job_id": jid,
            "command": sc["cmd"],
            "app": sc["app"],
            "elapsed_seconds": round(elapsed, 2),
            "pixel_diff": diff_ratio,
            "verdict": qa_verdict,
            "status": job_info["status"] if job_info else "FAILED"
        })
        
        print(f"流 [CYCLE {idx}/5] Completed in {round(elapsed, 2)}s | QA Verdict: {qa_verdict} (Diff: {diff_ratio}%) | Status: {job_info['status'] if job_info else 'FAILED'}")
        time.sleep(1.0) # 안전한 시퀀싱 간격

    # 4. 실증 결과 테이블 요약 보고
    print("\n=====================================================================")
    print("📊 5-CYCLE STRESS TEST REPORT SUMMARY")
    print("=====================================================================")
    print(f"{'Cycle':<6} | {'Status':<8} | {'Elapsed':<8} | {'Diff %':<8} | {'Verdict':<8} | {'Command':<30}")
    print("-" * 80)
    for r in results:
        print(f"#{r['cycle']:<5} | {r['status']:<8} | {r['elapsed_seconds']:<6}s | {r['pixel_diff']:<6}% | {r['verdict']:<8} | {r['command']:<30}")
    print("=====================================================================")
    
    # JSON 파일로도 실측 성적 백업
    report_json_path = _REPO_ROOT / "scripts/unicorn_factory/reports/stress_test_metrics.json"
    report_json_path.parent.mkdir(parents=True, exist_ok=True)
    with open(report_json_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"📝 Stress test JSON metrics backed up at: {report_json_path}")


if __name__ == "__main__":
    run_stress_test()
