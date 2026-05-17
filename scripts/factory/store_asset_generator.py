import os
import sys
from datetime import datetime
from pathlib import Path
try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
except ImportError:
    Image = None

class StoreAssetGenerator:
    """Autonomous Store Asset & Mockup Generator for premium App Store submissions."""
    def __init__(self, base_report_dir: str):
        self.report_dir = Path(base_report_dir).expanduser().resolve()
        self.report_dir.mkdir(parents=True, exist_ok=True)

    def generate_store_mockup(self, screenshot_path: str, marketing_text: str, output_name: str = "mockup_store") -> dict:
        """Composes a high-fidelity marketing screenshot wrapper for App Store Connect (1242x2688)."""
        screen_p = Path(screenshot_path).expanduser().resolve()

        if Image is None:
            return {
                "status": "SKIPPED",
                "message": "Pillow (PIL) is not installed. Mockup generation skipped."
            }

        if not screen_p.exists():
            # If the screenshot doesn't exist, create a fallback solid-colored placeholder screen
            print(f"⚠️ Screenshot not found at {screen_p}. Generating a placeholder mockup screen.")
            img_screen = Image.new('RGB', (800, 1600), color=(18, 18, 26))
            draw_screen = ImageDraw.Draw(img_screen)
            draw_screen.rectangle([20, 20, 780, 1580], outline=(0, 255, 136), width=3)
            draw_screen.text((100, 750), "[ SFX Edge Screen Capture ]", fill=(255, 255, 255))
        else:
            img_screen = Image.open(screen_p).convert('RGB')

        try:
            # 1. Create standard iPhone Portrait canvas (1242 x 2688)
            canvas_w, canvas_h = 1242, 2688
            canvas = Image.new('RGB', (canvas_w, canvas_h), color=(9, 9, 15)) # Deep Slate `#09090F`
            draw = ImageDraw.Draw(canvas)

            # 2. Draw a premium neon purple to black vertical gradient background
            for y in range(canvas_h):
                ratio = y / canvas_h
                # Interpolating between Void Indigo (#1A0033) and black (#000000)
                r = int(26 * (1.0 - ratio))
                g = int(0)
                b = int(51 * (1.0 - ratio))
                draw.line([(0, y), (canvas_w, y)], fill=(r, g, b))

            # 3. Add Quantum Glow Circles
            # Draw a soft neon pink glow in the upper-left, and a green glow in the bottom-right
            glow_pink = Image.new('RGBA', (600, 600), (0, 0, 0, 0))
            draw_gp = ImageDraw.Draw(glow_pink)
            draw_gp.ellipse([50, 50, 550, 550], fill=(255, 0, 127, 25))
            glow_pink = glow_pink.filter(ImageFilter.GaussianBlur(50))
            canvas.paste(glow_pink, (-100, -100), glow_pink)

            glow_green = Image.new('RGBA', (600, 600), (0, 0, 0, 0))
            draw_gg = ImageDraw.Draw(glow_green)
            draw_gg.ellipse([50, 50, 550, 550], fill=(0, 255, 136, 15))
            glow_green = glow_green.filter(ImageFilter.GaussianBlur(60))
            canvas.paste(glow_green, (700, 1800), glow_green)

            # 4. Compose Mockup Phone Frame
            # Phone body bounds
            phone_w, phone_h = 860, 1760
            phone_x = (canvas_w - phone_w) // 2
            phone_y = canvas_h - phone_h - 100 # Align near bottom

            # Outer bezel shadow
            draw.rounded_rectangle(
                [phone_x - 15, phone_y - 15, phone_x + phone_w + 15, phone_y + phone_h + 15],
                radius=45, fill=(5, 5, 8), outline=(255, 0, 127, 30), width=4
            )

            # Matte black frame bezel
            draw.rounded_rectangle(
                [phone_x - 5, phone_y - 5, phone_x + phone_w + 5, phone_y + phone_h + 5],
                radius=40, fill=(15, 15, 20), outline=(255, 255, 255, 15), width=8
            )

            # Inner Screen positioning & pasting
            screen_resized = img_screen.resize((phone_w - 20, phone_h - 20))
            canvas.paste(screen_resized, (phone_x + 10, phone_y + 10))

            # iPhone dynamic island notch
            notch_w, notch_h = 240, 60
            notch_x = (canvas_w - notch_w) // 2
            notch_y = phone_y + 25
            draw.rounded_rectangle(
                [notch_x, notch_y, notch_x + notch_w, notch_y + notch_h],
                radius=30, fill=(0, 0, 0)
            )

            # 5. Write Premium Branding Copy (Marketing Text)
            # Draw beautiful typography background banner
            text_y = 280
            draw.text(
                (canvas_w // 2, text_y),
                marketing_text,
                fill=(255, 255, 255),
                anchor="mm",
                align="center",
                # Fallback to default but double font-size via bold overlays if custom fonts aren't mapped
            )

            # Neon accent bar under text
            bar_w, bar_h = 300, 6
            bar_x = (canvas_w - bar_w) // 2
            draw.rounded_rectangle(
                [bar_x, text_y + 80, bar_x + bar_w, text_y + 80 + bar_h],
                radius=3, fill=(0, 255, 136) # Quantum Green accent bar
            )

            # 6. Save premium composed mockup
            out_filename = f"{output_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
            out_path = self.report_dir / out_filename
            canvas.save(out_path)

            print(f"💎 [MOCKUP] Premium Store Screenshot Composed: {out_path}")
            return {
                "status": "SUCCESS",
                "timestamp": datetime.now().isoformat(),
                "composed_asset": str(out_path),
                "width": canvas_w,
                "height": canvas_h
            }

        except Exception as e:
            return {"status": "FAILURE", "error": str(e)}

if __name__ == "__main__":
    import sys
    generator = StoreAssetGenerator(Path(__file__).parent / "reports")
    screen_in = sys.argv[1] if len(sys.argv) > 1 else ""
    copy_in = sys.argv[2] if len(sys.argv) > 2 else "당신의 남은 삶을 4,160주 격자로 성찰하십시오"
    result = generator.generate_store_mockup(screen_in, copy_in)
    print(result)
