#!/usr/bin/env python3
"""Convert SVG logo to PNG for Flutter launcher icons"""

from PIL import Image, ImageDraw
import os

# Define color scheme (matching the SVG)
GOLD = (255, 215, 0)
ORANGE = (255, 165, 0)
GREEN = (76, 175, 80)
DARK_GREEN = (46, 125, 50)
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)

def create_logo(size: int) -> Image.Image:
    """Create the money logo as PNG (size x size pixels)"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background with gradient (simplified: solid dark green)
    bg_color = DARK_GREEN
    draw.rounded_rectangle(
        [(0, 0), (size, size)],
        radius=int(size * 0.2),
        fill=bg_color
    )
    
    # Coin circle center
    center = size // 2
    coin_radius = int(size * 0.35)
    
    # Draw coin (gold gradient simulated with two circles)
    draw.ellipse(
        [(center - coin_radius, center - coin_radius),
         (center + coin_radius, center + coin_radius)],
        fill=GOLD,
        outline=(218, 165, 32)
    )
    
    # Coin highlight/shine
    shine_radius = int(coin_radius * 0.9)
    draw.ellipse(
        [(center - shine_radius, center - shine_radius),
         (center + shine_radius, center + shine_radius)],
        outline=WHITE,
        width=int(size * 0.02)
    )
    
    # Draw dollar sign ($)
    # Using simple approximation with text
    try:
        # Try to use a larger font if available
        font_size = int(size * 0.5)
        # This will use default font; in production you'd use a custom TTF
        draw.text(
            (center, center),
            "$",
            fill=WHITE,
            anchor="mm",
            font=None  # Uses default font
        )
    except:
        # Fallback if font rendering fails
        pass
    
    return img

# Sizes needed for Android and iOS
android_sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

ios_sizes = {
    'AppIcon.appiconset': [
        ('Icon-App-20x20@1x.png', 20),
        ('Icon-App-20x20@2x.png', 40),
        ('Icon-App-20x20@3x.png', 60),
        ('Icon-App-29x29@1x.png', 29),
        ('Icon-App-29x29@2x.png', 58),
        ('Icon-App-29x29@3x.png', 87),
        ('Icon-App-40x40@1x.png', 40),
        ('Icon-App-40x40@2x.png', 80),
        ('Icon-App-40x40@3x.png', 120),
        ('Icon-App-60x60@2x.png', 120),
        ('Icon-App-60x60@3x.png', 180),
        ('Icon-App-76x76@1x.png', 76),
        ('Icon-App-76x76@2x.png', 152),
        ('Icon-App-83.5x83.5@2x.png', 167),
        ('Icon-App-1024x1024@1x.png', 1024),
    ]
}

def main():
    workspace_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    # Generate Android icons
    print("Generating Android launcher icons...")
    android_base = os.path.join(workspace_root, 'front', 'android', 'app', 'src', 'main', 'res')
    for folder, size in android_sizes.items():
        dir_path = os.path.join(android_base, folder)
        os.makedirs(dir_path, exist_ok=True)
        
        logo = create_logo(size)
        output_path = os.path.join(dir_path, 'ic_launcher.png')
        logo.save(output_path, 'PNG')
        print(f"  ✓ {folder}/ic_launcher.png ({size}x{size})")
    
    # Generate iOS icons
    print("Generating iOS launcher icons...")
    ios_base = os.path.join(workspace_root, 'front', 'ios', 'Runner', 'Assets.xcassets')
    icon_dir = os.path.join(ios_base, 'AppIcon.appiconset')
    os.makedirs(icon_dir, exist_ok=True)
    
    for filename, size in ios_sizes['AppIcon.appiconset']:
        logo = create_logo(size)
        output_path = os.path.join(icon_dir, filename)
        logo.save(output_path, 'PNG')
        print(f"  ✓ AppIcon.appiconset/{filename} ({size}x{size})")
    
    print("\n✅ All icons generated successfully!")

if __name__ == '__main__':
    main()
