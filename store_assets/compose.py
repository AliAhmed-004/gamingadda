#!/usr/bin/env python3
"""Composes Play Store marketing images from the raw app screenshots.

Outputs:
  store_assets/phone/*.png     1080x2340 framed screenshots with headlines
  store_assets/feature_graphic.png  1024x500
  store_assets/app_icon_512.png     512x512
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).parent
RAW = ROOT / "raw"
OUT_PHONE = ROOT / "phone"
FONTS = ROOT / "fonts"
ICONS = ROOT.parent / "assets" / "icons"

# Play Store phone screenshots must be exactly 16:9 or 9:16.
W, H = 1080, 1920


def font(path: str, size: int, weight: int | None = None) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONTS / path), size)
    if weight is not None:
        try:
            f.set_variation_by_axes([weight])
        except OSError:
            pass
    return f


def headline_font(size: int) -> ImageFont.FreeTypeFont:
    return font("Fredoka-SemiBold.ttf", size, weight=600)


def sub_font(size: int) -> ImageFont.FreeTypeFont:
    return font("Nunito-ExtraBold.ttf", size, weight=800)


def hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def vertical_gradient(size: tuple[int, int], top: str, bottom: str) -> Image.Image:
    w, h = size
    t, b = hex_rgb(top), hex_rgb(bottom)
    col = Image.new("RGB", (1, h))
    px = col.load()
    for y in range(h):
        k = y / max(h - 1, 1)
        px[0, y] = tuple(round(t[c] + (b[c] - t[c]) * k) for c in range(3))
    return col.resize((w, h))


def add_bubbles(img: Image.Image, seed: int) -> None:
    """Soft translucent circles for depth."""
    rng = math.sin
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    w, h = img.size
    for i in range(9):
        r = int(70 + 160 * abs(rng(seed * 3.7 + i * 1.3)))
        x = int(w * abs(rng(seed * 1.9 + i * 2.1)))
        y = int(h * abs(rng(seed * 2.3 + i * 3.7)))
        alpha = 14 + int(12 * abs(rng(i * 1.7 + seed)))
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, alpha))
    blurred = overlay.filter(ImageFilter.GaussianBlur(6))
    img.paste(blurred, (0, 0), blurred)


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0] - 1, img.size[1] - 1], radius=radius, fill=255
    )
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def paste_shadow(
    canvas: Image.Image, box: tuple[int, int, int, int], radius: int, blur: int = 40
) -> None:
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(box, radius=radius, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    canvas.alpha_composite(shadow)


def draw_phone(
    canvas: Image.Image,
    shot: Image.Image,
    center_x: int,
    top: int,
    shot_width: int,
) -> int:
    """Draws a phone mockup; returns the bottom y of the device."""
    scale = shot_width / shot.width
    shot_r = shot.resize((shot_width, int(shot.height * scale)), Image.LANCZOS)

    bezel = 16
    corner = 70
    x0 = center_x - shot_width // 2 - bezel
    y0 = top
    x1 = center_x + shot_width // 2 + bezel
    y1 = top + shot_r.height + bezel * 2

    paste_shadow(canvas, (x0 + 8, y0 + 26, x1 + 8, y1 + 26), corner + bezel)
    ImageDraw.Draw(canvas).rounded_rectangle(
        [x0, y0, x1, y1], radius=corner + bezel, fill=(23, 23, 33, 255)
    )
    canvas.alpha_composite(rounded(shot_r, corner), (x0 + bezel, y0 + bezel))
    return y1


def draw_centered_text(
    canvas: Image.Image,
    text: str,
    fnt: ImageFont.FreeTypeFont,
    center_x: int,
    y: int,
    fill=(255, 255, 255, 255),
    shadow_alpha: int = 90,
) -> int:
    """Draws horizontally centered text; returns bottom y."""
    d = ImageDraw.Draw(canvas)
    box = d.textbbox((0, 0), text, font=fnt)
    tw, th = box[2] - box[0], box[3] - box[1]
    x = center_x - tw // 2 - box[0]
    d.text((x + 3, y + 5 - box[1]), text, font=fnt, fill=(0, 0, 0, shadow_alpha))
    d.text((x, y - box[1]), text, font=fnt, fill=fill)
    return y + th


SCREENS = [
    # id, headline lines, subline, gradient top->bottom
    ("home", ["Many Games.", "One App."], "All your favourite games in one place", "#14B8A6", "#0F4C44"),
    ("ludo", ["Race Your", "Tokens Home!"], "Classic Ludo for 2\u20134 players", "#4F7DF0", "#1E1B4B"),
    ("checkers", ["Crown", "Your Kings!"], "Classic checkers vs a clever AI", "#2DD4BF", "#134E4A"),
    ("card_match", ["Match. Collect.", "Win!"], "Fast card fun vs AI or a friend", "#4ADE80", "#14532D"),
    ("tic_tac_toe", ["X vs O \u2014", "Game On!"], "Beat the AI on Easy, Medium or Hard", "#FB923C", "#7C2D12"),
    ("stack", ["How High", "Can You Stack?"], "One-tap arcade action", "#A78BFA", "#3B0764"),
]


def compose_screenshot(
    sid: str, headline: list[str], subline: str, top: str, bottom: str
) -> None:
    canvas = vertical_gradient((W, H), top, bottom).convert("RGBA")
    add_bubbles(canvas, seed=sum(map(ord, sid)))

    y = 100
    for line in headline:
        y = draw_centered_text(canvas, line, headline_font(112), W // 2, y) + 16
    y = draw_centered_text(canvas, subline, sub_font(52), W // 2, y + 20,
                           fill=(255, 255, 255, 225)) + 10

    shot = Image.open(RAW / f"{sid}.png")
    phone_top = max(y + 50, 480)
    if shot.width > shot.height:  # landscape capture
        shot_w = 1000
        device_h = int(shot.height * shot_w / shot.width) + 32
        draw_phone(canvas, shot, W // 2,
                   phone_top + (H - phone_top - device_h) // 2, shot_w)
    else:
        # Portrait phone intentionally bleeds off the bottom edge. Games
        # whose key content sits near the bottom get a narrower phone so
        # (almost) the whole screen stays visible.
        width = 660 if sid in ("stack", "card_match") else 760
        draw_phone(canvas, shot, W // 2, phone_top, width)

    canvas.convert("RGB").save(OUT_PHONE / f"{sid}.png")
    print(f"phone/{sid}.png")


def compose_feature_graphic() -> None:
    w, h = 1024, 500
    canvas = vertical_gradient((w, h), "#14B8A6", "#0B3D37").convert("RGBA")
    add_bubbles(canvas, seed=5)

    logo = Image.open(ICONS / "gaming_adda_logo.png").convert("RGBA")
    logo = rounded(logo.resize((240, 240), Image.LANCZOS), 56)
    paste_shadow(canvas, (52, 62, 292, 302), 56, blur=24)
    canvas.alpha_composite(logo, (52, 62))

    d = ImageDraw.Draw(canvas)
    title_f = headline_font(88)
    d.text((334, 86), "Gaming Adda", font=title_f, fill=(0, 0, 0, 80))
    d.text((330, 82), "Gaming Adda", font=title_f, fill=(255, 255, 255, 255))
    d.text((334, 206), "Many fun games in one free app", font=sub_font(40),
           fill=(255, 255, 255, 230))

    tiles = ["ludo", "checkers", "card_match", "tic_tac_toe", "stack"]
    size, gap = 118, 24
    total = len(tiles) * size + (len(tiles) - 1) * gap
    x = (w - total) // 2
    y = 330
    for name in tiles:
        icon = Image.open(ICONS / f"{name}.png").convert("RGBA")
        icon = rounded(icon.resize((size, size), Image.LANCZOS), 28)
        paste_shadow(canvas, (x + 2, y + 8, x + size + 2, y + size + 8), 28, blur=12)
        canvas.alpha_composite(icon, (x, y))
        x += size + gap
    canvas.convert("RGB").save(ROOT / "feature_graphic.png")
    print("feature_graphic.png")


def compose_icon() -> None:
    icon = Image.open(ICONS / "gaming_adda_logo.png").convert("RGBA")
    icon.resize((512, 512), Image.LANCZOS).save(ROOT / "app_icon_512.png")
    print("app_icon_512.png")


if __name__ == "__main__":
    OUT_PHONE.mkdir(exist_ok=True)
    for sid, headline, subline, top, bottom in SCREENS:
        compose_screenshot(sid, headline, subline, top, bottom)
    compose_feature_graphic()
    compose_icon()
    print("done")
