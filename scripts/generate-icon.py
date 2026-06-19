#!/usr/bin/env python3
import math
import os
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT_ICNS = ROOT / 'Resources' / 'tickeys-swift.icns'
ICONSET_DIR = ROOT / '.build' / 'tickeys-swift.iconset'
PREVIEW_PNG = ROOT / '.build' / 'tickeys-swift-preview.png'
SIZES = [16, 32, 64, 128, 256, 512, 1024]

ICON_COLORS = {
    'background_top': (23, 32, 66),
    'background_bottom': (57, 106, 173),
    'keycap': (245, 244, 242),
    'keycap_top': (236, 234, 229),
    'keycap_shadow': (211, 216, 228),
    'keycap_highlight': (255, 255, 255),
    'keyboard_line': (183, 191, 206),
    'sound_line': (255, 198, 92),
    'sound_line_inner': (255, 235, 180),
}

ICONSET_DIR.mkdir(parents=True, exist_ok=True)
ROOT.joinpath('.build').mkdir(parents=True, exist_ok=True)


def lerp(a, b, t):
    return a + (b - a) * t


def blend_color(c1, c2, t):
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))


def create_background(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    for y in range(size):
        t = y / (size - 1)
        color = blend_color(ICON_COLORS['background_top'], ICON_COLORS['background_bottom'], t)
        for x in range(size):
            img.putpixel((x, y), (*color, 255))
    return img


def draw_keys(draw, size):
    keys = 4
    key_spacing = size * 0.05
    key_width = (size - key_spacing * (keys + 1)) / keys
    key_height = size * 0.14
    depth = size * 0.05
    base_y = size * 0.72
    radius = key_height * 0.18
    start_x = key_spacing

    for index in range(keys):
        x = start_x + index * (key_width + key_spacing)
        y = base_y - key_height
        front = [
            (x, y),
            (x + key_width, y),
            (x + key_width + depth, base_y),
            (x + depth, base_y)
        ]
        draw.polygon(front, fill=ICON_COLORS['keycap'])

        top = [
            (x, y),
            (x + key_width, y),
            (x + key_width - size * 0.02, y + key_height * 0.18),
            (x + size * 0.02, y + key_height * 0.18)
        ]
        draw.polygon(top, fill=ICON_COLORS['keycap_top'])

        side = [
            (x + key_width, y),
            (x + key_width + depth, base_y),
            (x + key_width + depth, base_y - key_height * 0.2),
            (x + key_width, y + key_height * 0.18)
        ]
        draw.polygon(side, fill=ICON_COLORS['keycap_shadow'])

        detail_y = y + key_height * 0.32
        draw.line(
            [(x + key_width * 0.12, detail_y), (x + key_width * 0.88, detail_y)],
            fill=ICON_COLORS['keycap_highlight'], width=max(1, int(size * 0.01))
        )


def draw_sound_lines(draw, size):
    left = size * 0.18
    right = size * 0.82
    center = size * 0.50
    top = size * 0.11
    slant_length = size * 0.32
    thickness = max(4, int(size * 0.05))
    bottom_y = top + slant_length

    middle_start_y = top + size * 0.01
    current_middle_length = bottom_y - middle_start_y
    target_length = current_middle_length * 0.5
    horizontal_offset = size * 0.10
    vertical_offset = math.sqrt(max(0.0, target_length * target_length - horizontal_offset * horizontal_offset))
    slant_start_y = bottom_y - vertical_offset
    middle_start_y = bottom_y - target_length

    extra_offset = size * 0.06

    draw.line(
        [(left - extra_offset, slant_start_y), (center - horizontal_offset - extra_offset, bottom_y)],
        fill=ICON_COLORS['sound_line'], width=thickness
    )
    draw.line(
        [(right + extra_offset, slant_start_y), (center + horizontal_offset + extra_offset, bottom_y)],
        fill=ICON_COLORS['sound_line'], width=thickness
    )
    draw.line(
        [(center, middle_start_y), (center, bottom_y)],
        fill=ICON_COLORS['sound_line'], width=max(3, int(size * 0.05))
    )


def draw_keyboard_base(draw, size):
    left = size * 0.18
    right = size * 0.82
    extra_offset = size * 0.06
    top_y = size * 0.52
    bottom_y = size * 0.66

    draw.rectangle(
        [(left - extra_offset, top_y), (right + extra_offset, bottom_y)],
        fill=ICON_COLORS['keycap'], outline=None
    )
    draw.line(
        [(left - extra_offset + size * 0.04, top_y + size * 0.01), (right + extra_offset - size * 0.04, top_y + size * 0.01)],
        fill=ICON_COLORS['keycap_highlight'], width=max(1, int(size * 0.015))
    )
    draw.line(
        [(left - extra_offset, bottom_y), (right + extra_offset, bottom_y)],
        fill=ICON_COLORS['keyboard_line'], width=max(2, int(size * 0.015))
    )


def create_icon(size):
    img = create_background(size)
    draw = ImageDraw.Draw(img)

    draw_sound_lines(draw, size)
    draw_keyboard_base(draw, size)

    return img


def save_iconset():
    for size in SIZES:
        img = create_icon(size)
        filename = ICONSET_DIR / f'icon_{size}x{size}.png'
        img.save(filename, format='PNG')
        if size >= 16:
            img2 = img.resize((size // 2, size // 2), Image.LANCZOS)
            img2.save(ICONSET_DIR / f'icon_{size // 2}x{size // 2}.png', format='PNG')


if __name__ == '__main__':
    save_iconset()
    os.system(f'iconutil -c icns "{ICONSET_DIR}" -o "{OUT_ICNS}"')
    preview = create_icon(1024)
    preview.save(PREVIEW_PNG, format='PNG')
    print(f'Generated {OUT_ICNS}')
    print(f'Preview PNG: {PREVIEW_PNG}')
