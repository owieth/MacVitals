#!/usr/bin/env python3
"""Generate the DMG installer background image for MacVitals."""

from PIL import Image, ImageDraw, ImageFilter
import math
import os

W, H = 1400, 800  # retina 2x (700x400 logical)
OUT = os.path.join(os.path.dirname(__file__), "../assets/dmg-background.png")

# Colors from app icon
BG = (28, 28, 28)
AMBER_START = (232, 144, 10)
AMBER_END = (245, 200, 66)

img = Image.new("RGBA", (W, H), BG + (255,))
draw = ImageDraw.Draw(img)

# Subtle vignette (darker corners)
vignette = Image.new("RGBA", (W, H), (0, 0, 0, 0))
vdraw = ImageDraw.Draw(vignette)
for i in range(80, 0, -1):
    alpha = int((1 - i / 80) ** 2 * 60)
    vdraw.ellipse([i * 3, i * 3, W - i * 3, H - i * 3], outline=(0, 0, 0, alpha))
vignette = vignette.filter(ImageFilter.GaussianBlur(80))
img = Image.alpha_composite(img, vignette)
draw = ImageDraw.Draw(img)

# Icon positions in retina pixels (logical × 2):
# App icon at logical (180, 190) → retina (360, 380)
# Applications link at logical (520, 190) → retina (1040, 380)
APP_X, ICON_Y = 360, 380
LINK_X = 1040
ICON_SIZE_R = 200  # ~100pt icon @ 2x

# Arrow between the two icons
ARROW_Y = ICON_Y
SHAFT_X0 = APP_X + ICON_SIZE_R // 2 + 30   # just right of app icon
SHAFT_X1 = LINK_X - ICON_SIZE_R // 2 - 30  # just left of Applications icon
SHAFT_THICK = 5
SEGMENTS = 100

for i in range(SEGMENTS):
    t = i / SEGMENTS
    x0 = int(SHAFT_X0 + (SHAFT_X1 - SHAFT_X0) * t)
    x1 = int(SHAFT_X0 + (SHAFT_X1 - SHAFT_X0) * (t + 1 / SEGMENTS)) + 1
    r = int(AMBER_START[0] + (AMBER_END[0] - AMBER_START[0]) * t)
    g = int(AMBER_START[1] + (AMBER_END[1] - AMBER_START[1]) * t)
    b = int(AMBER_START[2] + (AMBER_END[2] - AMBER_START[2]) * t)
    draw.rectangle(
        [x0, ARROW_Y - SHAFT_THICK // 2, x1, ARROW_Y + SHAFT_THICK // 2],
        fill=(r, g, b, 210),
    )

# Arrowhead
HEAD_SIZE = 26
TIP_X = SHAFT_X1
arrowhead = [
    (TIP_X + HEAD_SIZE, ARROW_Y),
    (TIP_X, ARROW_Y - HEAD_SIZE // 2),
    (TIP_X, ARROW_Y + HEAD_SIZE // 2),
]
draw.polygon(arrowhead, fill=AMBER_END + (220,))

# Save as RGB PNG (no alpha needed, Finder background must be opaque)
final = img.convert("RGB")
final.save(OUT, "PNG", dpi=(144, 144))
print(f"Saved {W}x{H} background to {os.path.abspath(OUT)}")
