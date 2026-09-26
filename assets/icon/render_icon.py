"""
Renders the Musick app icon (gradient background + stylized double music-note
glyph) directly with Pillow, at every resolution the Android launcher needs:
  - legacy square mipmap-*/ic_launcher.png
  - adaptive mipmap-*/ic_launcher_foreground.png (glyph only, transparent)
  - adaptive mipmap-*/ic_launcher_background.png (gradient only)
  - a 512x512 preview / Play Store listing image
Colors and geometry mirror assets/icon/ic_launcher_master.svg so the two
representations (vector source of truth + generated rasters) stay in sync.
"""
from PIL import Image, ImageDraw
import math
import os

BASE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(BASE, "..", "..", "android", "app", "src", "main", "res")

# Brand gradient: indigo -> blue -> teal (diagonal, top-left to bottom-right)
GRAD_STOPS = [
    (0.00, (91, 79, 232)),
    (0.55, (62, 123, 240)),
    (1.00, (24, 201, 201)),
]

NOTE_TOP = (255, 255, 255)
NOTE_BOTTOM = (234, 241, 255)


def lerp(a, b, t):
    return a + (b - a) * t


def gradient_color(t):
    t = max(0.0, min(1.0, t))
    for i in range(len(GRAD_STOPS) - 1):
        t0, c0 = GRAD_STOPS[i]
        t1, c1 = GRAD_STOPS[i + 1]
        if t0 <= t <= t1:
            local_t = 0 if t1 == t0 else (t - t0) / (t1 - t0)
            return tuple(int(lerp(c0[k], c1[k], local_t)) for k in range(3))
    return GRAD_STOPS[-1][1]


def make_background(size, rounded=False, corner_ratio=0.23):
    """Diagonal gradient square, optionally with rounded corners (legacy icon)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    diag = size * 1.4142
    for y in range(size):
        for x in range(size):
            t = ((x + y) / 2) / diag * 1.55  # spread gradient diagonally
            px[x, y] = gradient_color(t) + (255,)

    if rounded:
        mask = Image.new("L", (size, size), 0)
        d = ImageDraw.Draw(mask)
        radius = int(size * corner_ratio)
        d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
        img.putalpha(mask)

    # subtle inner ring for depth
    d = ImageDraw.Draw(img)
    r = size * 0.36
    cx = cy = size / 2
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 255, 255, 20), width=max(1, int(size * 0.012)))
    return img


def draw_note_glyph(draw, scale, offset=(0, 0)):
    """Draws the double-eighth-note glyph at a reference 512x512 scale,
    then callers pass a transform via scale/offset to fit any canvas."""

    def pt(x, y):
        return (offset[0] + x * scale, offset[1] + y * scale)

    def vgrad_polygon(points, y_top, y_bottom):
        # Approximate a vertical gradient fill by drawing horizontal gradient bands
        xs = [p[0] for p in points]
        ys = [p[1] for p in points]
        bbox = (min(xs), min(ys), max(xs), max(ys))
        return bbox

    fill_top = NOTE_TOP + (255,)
    # Simple flat white-ish fill (gradient too subtle to matter at icon size)
    fill = (245, 248, 255, 255)

    # Beam connecting the two note stems
    beam = [pt(198, 158), pt(342, 122), pt(342, 168), pt(198, 204)]
    draw.polygon(beam, fill=fill)

    # Left stem + note head
    draw.rounded_rectangle(
        [pt(188, 196), pt(208, 346)], radius=10 * scale, fill=fill
    )
    left_head_center = pt(176, 352)
    _ellipse_rotated(draw, left_head_center, 42 * scale, 32 * scale, -12, fill)

    # Right stem + note head
    draw.rounded_rectangle(
        [pt(332, 140), pt(352, 290)], radius=10 * scale, fill=fill
    )
    right_head_center = pt(320, 296)
    _ellipse_rotated(draw, right_head_center, 42 * scale, 32 * scale, -12, fill)


def _ellipse_rotated(draw, center, rx, ry, angle_deg, fill):
    """Draws a rotated ellipse by rasterizing a polygon approximation."""
    cx, cy = center
    angle = math.radians(angle_deg)
    pts = []
    steps = 48
    for i in range(steps):
        theta = 2 * math.pi * i / steps
        ex = rx * math.cos(theta)
        ey = ry * math.sin(theta)
        rx_ = ex * math.cos(angle) - ey * math.sin(angle)
        ry_ = ex * math.sin(angle) + ey * math.cos(angle)
        pts.append((cx + rx_, cy + ry_))
    draw.polygon(pts, fill=fill)


def make_legacy_icon(size):
    img = make_background(size, rounded=True, corner_ratio=0.23)
    draw = ImageDraw.Draw(img)
    scale = size / 512
    draw_note_glyph(draw, scale)
    return img


def make_foreground(size):
    """Glyph only, transparent background, centered & scaled into the 66/108
    Android adaptive-icon safe zone."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Reference glyph spans roughly x:[134,384] y:[90,384] in the 512 canvas
    # (i.e. centered-ish). We scale it down to fit the 66/108 safe zone and
    # recenter around the canvas midpoint.
    safe_ratio = 0.60  # glyph occupies ~60% of the canvas, matching the 66/108 safe zone
    glyph_ref_size = 512
    scale = (size * safe_ratio) / glyph_ref_size
    # Bounding box (approx) of the glyph in the 512 reference to compute center offset
    glyph_bbox = (134, 90, 384, 384)
    glyph_cx = (glyph_bbox[0] + glyph_bbox[2]) / 2
    glyph_cy = (glyph_bbox[1] + glyph_bbox[3]) / 2
    offset_x = size / 2 - glyph_cx * scale
    offset_y = size / 2 - glyph_cy * scale
    draw_note_glyph(draw, scale, offset=(offset_x, offset_y))
    return img


def make_adaptive_background(size):
    return make_background(size, rounded=False)


def main():
    legacy_sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    adaptive_sizes = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}

    for density, size in legacy_sizes.items():
        out_dir = os.path.join(RES, f"mipmap-{density}")
        os.makedirs(out_dir, exist_ok=True)
        make_legacy_icon(size).save(os.path.join(out_dir, "ic_launcher.png"))

    for density, size in adaptive_sizes.items():
        out_dir = os.path.join(RES, f"mipmap-{density}")
        os.makedirs(out_dir, exist_ok=True)
        make_foreground(size).save(os.path.join(out_dir, "ic_launcher_foreground.png"))
        make_adaptive_background(size).save(os.path.join(out_dir, "ic_launcher_background.png"))

    # Preview / Play Store listing image
    preview = make_legacy_icon(512)
    preview.save(os.path.join(BASE, "ic_launcher_preview.png"))
    print("Icon rendering complete.")


if __name__ == "__main__":
    main()
