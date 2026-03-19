#!/usr/bin/env python3
"""
Generate a high-resolution macOS app icon for the Panchanga app.
Inspired by Apple News app icon style - clean, colorful gradients with symbols.
"""

import os
from PIL import Image, ImageDraw


def create_icon(size):
    """Create a single icon at the given size."""

    # Colors - Deep purple/blue gradient like Apple News
    bg_color_1 = (63, 38, 160)   # Rich purple
    bg_color_2 = (30, 30, 90)    # Deep indigo

    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw diagonal gradient
    for y in range(size):
        ratio = y / size
        r = int(bg_color_1[0] * (1 - ratio) + bg_color_2[0] * ratio)
        g = int(bg_color_1[1] * (1 - ratio) + bg_color_2[1] * ratio)
        b = int(bg_color_1[2] * (1 - ratio) + bg_color_2[2] * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    # Calculate positions based on size
    margin = int(size * 0.05)
    radius = int(size * 0.20)
    moon_radius = int(size * 0.22)
    moon_x = int(size * 0.38)
    moon_y = int(size * 0.38)

    # Draw rounded corner overlay (to clean up edges)
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw_overlay = ImageDraw.Draw(overlay)
    draw_overlay.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        fill=(255, 255, 255, 255)
    )

    # Apply rounded corners to background
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    for y in range(size):
        for x in range(size):
            if overlay.getpixel((x, y))[3] > 0:
                result.putpixel((x, y), img.getpixel((x, y)))

    draw = ImageDraw.Draw(result)

    # Draw moon glow
    glow_color = (255, 230, 150, 50)
    for r in range(moon_radius + 10, moon_radius + 3, -1):
        draw.ellipse(
            [moon_x - r, moon_y - r, moon_x + r, moon_y + r],
            fill=glow_color
        )

    # Draw crescent moon
    moon_color = (255, 250, 230)  # Warm white
    draw.ellipse(
        [moon_x - moon_radius, moon_y - moon_radius,
         moon_x + moon_radius, moon_y + moon_radius],
        fill=moon_color
    )

    # Crescent cutout
    cutout_radius = int(moon_radius * 0.75)
    cutout_x = moon_x + int(moon_radius * 0.4)
    cutout_color = bg_color_2
    draw.ellipse(
        [cutout_x - cutout_radius, moon_y - cutout_radius,
         cutout_x + cutout_radius, moon_y + cutout_radius],
        fill=cutout_color
    )

    # Draw stars
    star_positions = [
        (int(size * 0.72), int(size * 0.18), int(size * 0.04)),
        (int(size * 0.85), int(size * 0.30), int(size * 0.028)),
        (int(size * 0.65), int(size * 0.55), int(size * 0.022)),
        (int(size * 0.90), int(size * 0.55), int(size * 0.032)),
    ]

    for sx, sy, sr in star_positions:
        draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(255, 255, 255, 230))

    # Draw decorative circle with "P" - simplified as concentric circles
    circle_x = int(size * 0.68)
    circle_y = int(size * 0.65)
    circle_r = int(size * 0.22)

    # Outer circle
    draw.ellipse(
        [circle_x - circle_r, circle_y - circle_r,
         circle_x + circle_r, circle_y + circle_r],
        fill=(255, 255, 255, 30),
        outline=(255, 255, 255, 80),
        width=max(1, int(size * 0.01))
    )

    # Inner circle
    inner_r = int(circle_r * 0.7)
    draw.ellipse(
        [circle_x - inner_r, circle_y - inner_r,
         circle_x + inner_r, circle_y + inner_r],
        fill=(255, 255, 255, 50)
    )

    # Small decorative dots (like Devanagari vowel marks)
    dot_x = circle_x + int(circle_r * 0.8)
    dot_y = circle_y - int(circle_r * 0.6)
    dot_r = int(size * 0.03)
    draw.ellipse([dot_x - dot_r, dot_y - dot_r, dot_x + dot_r, dot_y + dot_r], fill=(255, 200, 100, 200))

    # Second dot
    dot_x2 = circle_x + int(circle_r * 0.9)
    dot_y2 = circle_y - int(circle_r * 0.3)
    draw.ellipse([dot_x2 - dot_r, dot_y2 - dot_r, dot_x2 + dot_r, dot_y2 + dot_r], fill=(255, 200, 100, 180))

    # Apply final rounded corner mask
    final = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    final.paste(result, (0, 0), mask=overlay)

    return final


def generate_icons():
    """Generate all required icon sizes."""

    # Icon sizes required for macOS
    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (64, "icon_64x64.png"),
        (128, "icon_64x64@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
        (1024, "icon_1024x1024.png"),
    ]

    output_dir = "/Users/thotas/Development/OpenCode/Panchangam/PanchangApp/Sources/PanchangApp/Assets.xcassets/AppIcon.appiconset"

    print("Generating app icons...")

    for size, filename in sizes:
        # Generate icon
        icon = create_icon(size)

        # Save
        output_path = os.path.join(output_dir, filename)
        icon.save(output_path, "PNG")
        print(f"  Created {filename} ({size}x{size})")

    print(f"\nAll icons generated successfully in {output_dir}")


if __name__ == "__main__":
    generate_icons()
