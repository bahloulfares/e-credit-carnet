from PIL import Image, ImageDraw
import os

def create_money_logo(size):
    """Create money icon with gold coin and dollar sign"""
    # Green gradient background
    img = Image.new('RGB', (size, size), (34, 139, 34))
    draw = ImageDraw.Draw(img)
    
    # Gold coin colors
    gold = (255, 215, 0)
    dark_gold = (218, 165, 32)
    
    # Coin dimensions
    center = size // 2
    coin_radius = int(size * 0.4)
    
    # Draw outer gold circle
    draw.ellipse(
        [center - coin_radius, center - coin_radius, 
         center + coin_radius, center + coin_radius],
        fill=gold
    )
    
    # Draw inner shadow circle for 3D effect
    inner_radius = coin_radius - max(2, size // 40)
    draw.ellipse(
        [center - inner_radius, center - inner_radius,
         center + inner_radius, center + inner_radius],
        fill=dark_gold
    )
    
    # Draw dollar sign with white lines
    line_width = max(3, size // 30)
    
    # Vertical line of $
    top_y = center - int(coin_radius * 0.6)
    bottom_y = center + int(coin_radius * 0.6)
    draw.line([(center, top_y), (center, bottom_y)], 
              fill=(255, 255, 255), width=line_width)
    
    # Top curve of S
    top_curve_y = center - int(coin_radius * 0.3)
    draw.arc(
        [center - int(coin_radius * 0.3), top_y,
         center + int(coin_radius * 0.3), top_curve_y],
        start=0, end=180, fill=(255, 255, 255), width=line_width
    )
    
    # Middle section
    mid_top = center - int(coin_radius * 0.15)
    mid_bottom = center + int(coin_radius * 0.15)
    draw.line([(center - int(coin_radius * 0.25), mid_top),
               (center + int(coin_radius * 0.25), mid_top)],
              fill=(255, 255, 255), width=line_width)
    
    # Bottom curve of S
    bottom_curve_y = center + int(coin_radius * 0.3)
    draw.arc(
        [center - int(coin_radius * 0.3), bottom_curve_y,
         center + int(coin_radius * 0.3), bottom_y],
        start=180, end=360, fill=(255, 255, 255), width=line_width
    )
    
    return img

# Android icon sizes
android_sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192
}

# iOS icon sizes
ios_sizes = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024
}

print("💰 Generating ProCreditApp money icons...")

# Generate Android icons
for folder, size in android_sizes.items():
    path = f'front/android/app/src/main/res/{folder}'
    os.makedirs(path, exist_ok=True)
    
    icon = create_money_logo(size)
    icon.save(f'{path}/ic_launcher.png')
    print(f'✓ {folder}/ic_launcher.png ({size}x{size})')

# Generate iOS icons
ios_path = 'front/ios/Runner/Assets.xcassets/AppIcon.appiconset'
os.makedirs(ios_path, exist_ok=True)

for filename, size in ios_sizes.items():
    icon = create_money_logo(size)
    icon.save(f'{ios_path}/{filename}')
    print(f'✓ {filename} ({size}x{size})')

print(f"\n✅ Generated {len(android_sizes) + len(ios_sizes)} icons!")
print("📱 Ready to rebuild APK")
