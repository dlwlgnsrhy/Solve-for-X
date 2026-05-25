# 📊 Production Report: {{execution_id}}

**Date:** {{timestamp}}
**Worker:** {{worker_identity}}
**Status:** {{status}}

## 📝 Summary
{{logs_summary}}

## 📦 Artifacts Produced
| Path | Type | Verification |
| :--- | :--- | :--- |
{{#artifacts}}
| `{{path}}` | {{type}} | ✅ |
{{/artifacts}}

## ⚠️ Errors / Warnings
{{#errors}}
- {{this}}
{{/errors}}

## 📈 Metrics
- **Duration:** {{metrics.duration_seconds}}s
- **Complexity:** {{metrics.complexity_score}}/10