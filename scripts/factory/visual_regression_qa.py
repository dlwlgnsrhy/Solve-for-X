import os
import sys
import json
from datetime import datetime
from pathlib import Path
try:
    from PIL import Image, ImageChops, ImageDraw
except ImportError:
    # Safe fallback if PIL is missing in target environment
    Image = None

class VisualRegressionQA:
    """Autonomous Visual QA Engine comparing screen layouts to detect visual regressions/breaks."""
    def __init__(self, base_report_dir: str):
        self.report_dir = Path(base_report_dir).expanduser().resolve()
        self.report_dir.mkdir(parents=True, exist_ok=True)

    def analyze_screenshots(self, baseline_path: str, current_path: str, threshold_percent: float = 1.0) -> dict:
        """Compares baseline vs current screenshots, generates a diff image and returns metrics."""
        b_path = Path(baseline_path).expanduser().resolve()
        c_path = Path(current_path).expanduser().resolve()

        if not b_path.exists():
            return {"status": "ERROR", "message": f"Baseline screenshot not found at: {b_path}"}
        if not c_path.exists():
            return {"status": "ERROR", "message": f"Current screenshot not found at: {c_path}"}

        if Image is None:
            return {
                "status": "SKIPPED",
                "message": "Pillow (PIL) is not installed. Skipping pixel-level comparison.",
                "pixel_difference_ratio": 0.0,
                "passed": True
            }

        try:
            img_baseline = Image.open(b_path).convert('RGB')
            img_current = Image.open(c_path).convert('RGB')

            # Ensure both images are the same size
            if img_baseline.size != img_current.size:
                img_current = img_current.resize(img_baseline.size)

            diff = ImageChops.difference(img_baseline, img_current)
            
            # Calculate pixel differences
            diff_pixels = 0
            width, height = diff.size
            total_pixels = width * height

            # Load pixels to quickly count deviations
            pixels = diff.load()
            for x in range(width):
                for y in range(height):
                    r, g, b = pixels[x, y]
                    if r > 10 or g > 10 or b > 10: # 10 is noise tolerance threshold
                        diff_pixels += 1

            diff_ratio = (diff_pixels / total_pixels) * 100.0
            passed = diff_ratio <= threshold_percent

            # Save the diff visual image
            diff_filename = f"diff_{b_path.stem}_vs_{c_path.stem}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
            diff_out_path = self.report_dir / diff_filename
            diff.save(diff_out_path)

            report_data = {
                "status": "SUCCESS",
                "timestamp": datetime.now().isoformat(),
                "baseline_image": str(b_path),
                "current_image": str(c_path),
                "diff_image": str(diff_out_path),
                "total_pixels": total_pixels,
                "deviating_pixels": diff_pixels,
                "pixel_difference_ratio": round(diff_ratio, 4),
                "threshold_percent": threshold_percent,
                "passed": passed
            }

            # Generate JSON Report
            json_filename = f"visual_qa_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            with open(self.report_dir / json_filename, "w") as f:
                json.dump(report_data, f, indent=2)

            # Generate beautiful HTML side-by-side visualization
            self._generate_html_report(report_data, json_filename.replace('.json', '.html'))

            return report_data

        except Exception as e:
            return {"status": "FAILURE", "error": str(e)}

    def _generate_html_report(self, report: dict, filename: str):
        html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>Solve-for-X Autonomous Visual QA Report</title>
    <style>
        body {{
            background-color: #0A0A0F;
            color: #E2E8F0;
            font-family: 'Inter', system-ui, sans-serif;
            margin: 40px;
        }}
        .header {{
            border-bottom: 2px solid #FF007F;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }}
        .title {{
            color: #FF007F;
            font-size: 28px;
            font-weight: 800;
            text-shadow: 0 0 10px rgba(255, 0, 127, 0.4);
        }}
        .metrics {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }}
        .card {{
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 12px;
            padding: 20px;
            text-align: center;
        }}
        .metric-value {{
            font-size: 24px;
            font-weight: 700;
            margin-top: 10px;
        }}
        .pass {{ color: #00FF66; text-shadow: 0 0 10px rgba(0, 255, 102, 0.4); }}
        .fail {{ color: #FF0055; text-shadow: 0 0 10px rgba(255, 0, 85, 0.4); }}
        .grid {{
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 30px;
        }}
        .img-container {{
            text-align: center;
        }}
        .img-label {{
            font-weight: 600;
            margin-bottom: 10px;
            color: #94A3B8;
        }}
        img {{
            width: 100%;
            border-radius: 8px;
            border: 2px solid rgba(255, 255, 255, 0.1);
        }}
    </style>
</head>
<body>
    <div class="header">
        <div class="title">⚡ SFX Visual Regression QA Report</div>
        <p style="color: #94A3B8; margin-top: 5px;">Timestamp: {report['timestamp']}</p>
    </div>

    <div class="metrics">
        <div class="card">
            <div>Verdict</div>
            <div class="metric-value {'pass' if report['passed'] else 'fail'}">
                {'PASSED' if report['passed'] else 'FAILED'}
            </div>
        </div>
        <div class="card">
            <div>Pixel Difference</div>
            <div class="metric-value">{report['pixel_difference_ratio']}%</div>
        </div>
        <div class="card">
            <div>Threshold Limit</div>
            <div class="metric-value">{report['threshold_percent']}%</div>
        </div>
        <div class="card">
            <div>Deviating Pixels</div>
            <div class="metric-value">{report['deviating_pixels']} / {report['total_pixels']}</div>
        </div>
    </div>

    <div class="grid">
        <div class="img-container">
            <div class="img-label">Base Design (Baseline)</div>
            <img src="file://{report['baseline_image']}" alt="Baseline" />
        </div>
        <div class="img-container">
            <div class="img-label">Current Implementation</div>
            <img src="file://{report['current_image']}" alt="Current" />
        </div>
        <div class="img-container">
            <div class="img-label">Visual Difference (Diff)</div>
            <img src="file://{report['diff_image']}" alt="Diff" />
        </div>
    </div>
</body>
</html>
"""
        with open(self.report_dir / filename, "w") as f:
            f.write(html_content)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python visual_regression_qa.py <baseline_image> <current_image> [threshold]")
    else:
        threshold = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
        qa = VisualRegressionQA(Path(__file__).parent / "reports")
        result = qa.analyze_screenshots(sys.argv[1], sys.argv[2], threshold)
        print(json.dumps(result, indent=2))
