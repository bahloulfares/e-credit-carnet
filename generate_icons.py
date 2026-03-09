#!/usr/bin/env python3
"""Generate better launcher icons for Flutter app - Money theme"""

from PIL import Image, ImageDraw
import os

def create_better_logo(size: int) -> Image.Image:
    """Create a better, more visible money logo"""
    # Create image with rounded background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background gradient (simulated with green colors)
    for y in range(size // 2):
        ratio = y / (size // 2) if size // 2 > 0 else 0
        color = (
            int(46 + (76 - 46) * ratio),
            int(125 + (175 - 125) * ratio),
            int(50 + (80 - 50) * ratio)
        )
        draw.line([(0, y), (size, y)], fill=color, width=1)
    
    # Bottom half lighter green
    for y in range(size // 2, size):
        draw.line([(0, y), (size, y)], fill=(76, 175, 80), width=1)
    
    # Main coin circle
    center = size // 2
    coin_radius = int(size * 0.35)
    
    # Outer circle - darker gold
    draw.ellipse(
        [(center - coin_radius, center - coin_radius),
         (center + coin_radius, center + coin_radius)],
        fill=(218, 165, 32),
        outline=(184, 134, 11),
        width=max(1, size // 48)
    )
    
    # Inner lighter circle - bright gold
    inner_radius = int(coin_radius * 0.85)
    draw.ellipse(
        [(center - inner_radius, center - inner_radius),
         (center + inner_radius, center + inner_radius)],
        fill=(255, 215, 0)
    )
    
    # Draw dollar sign - simple lines approach
    line_width = max(2, size // 24)
    line_x = center
    line_top = center - int(coin_radius * 0.35)
    line_bottom = center + int(coin_radius * 0.35)
    
    # Vertical line
    draw.line(
        [(line_x, line_top), (line_x, line_bottom)],
        fill=(255, 255, 255),
        width=line_width
    )
    
    # Top horizontal line
    h_length = int(coin_radius * 0.3)
    draw.line(
        [(line_x - h_length, line_top + int(coin_radius * 0.1)), 
         (line_x + h_length, line_top + int(coin_radius * 0.1))],
        fill=(255, 255, 255),
        width=line_width
    )
    
    # Bottom horizontal line
    draw.line(
        [(line_x - h_length, line_bottom - int(coin_radius * 0.1)), 
         (line_x + h_length, line_bottom - int(coin_radius * 0.1))],
        fill=(255, 255, 255),
        width=line_width
    )
    
    return img


# Sizes for Android
android_sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# Sizes for iOS
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
    print("Generating improved Android launcher icons...")
    android_base = os.path.join(workspace_root, 'front', 'android', 'app', 'src', 'main', 'res')
    for folder, size in android_sizes.items():
        dir_path = os.path.join(android_base, folder)
        os.makedirs(dir_path, exist_ok=True)
        
        logo = create_better_logo(size)
        output_path = os.path.join(dir_path, 'ic_launcher.png')
        logo.save(output_path, 'PNG')
        print(f"  ✓ {folder}/ic_launcher.png ({size}x{size})")
    
    # Generate iOS icons
    print("Generating improved iOS launcher icons...")
    ios_base = os.path.join(workspace_root, 'front', 'ios', 'Runner', 'Assets.xcassets')
    icon_dir = os.path.join(ios_base, 'AppIcon.appiconset')
    os.makedirs(icon_dir, exist_ok=True)
    
    for filename, size in ios_sizes['AppIcon.appiconset']:
        logo = create_better_logo(size)
        output_path = os.path.join(icon_dir, filename)
        logo.save(output_path, 'PNG')
        print(f"  ✓ AppIcon.appiconset/{filename} ({size}x{size})")
    
    print("\n✅ All improved icons generated successfully!")

if __name__ == '__main__':
    main()
