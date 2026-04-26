"""Script to generate all app icons for BBplay from JPEG 1080x1080."""

from PIL import Image

SOURCE = 'assets/images/4AJ5QrzEqo_6b1KNkn42kULwGDIdtZnpJkWE7ZALAEayZbh_E-GX4V8tGY32jhvRIiwt5tM--p-IfnKTerrwkjF7.jpg'

# Android mipmap sizes
ANDROID_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

print("=== ANDROID ICONS ===")
img = Image.open(SOURCE).convert('RGBA')
for folder, size in ANDROID_SIZES.items():
    out_path = f'android/app/src/main/res/{folder}/ic_launcher.png'
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(out_path)
    print(f'  OK {out_path} ({size}x{size})')

# iOS AppIcon sizes
IOS_SIZES = [
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

ios_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
print("\n=== iOS ICONS ===")
for filename, size in IOS_SIZES:
    out_path = f'{ios_dir}/{filename}'
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(out_path)
    print(f'  OK {out_path} ({size}x{size})')

# Web icons
print("\n=== WEB ICONS ===")
favicon = img.resize((32, 32), Image.LANCZOS)
favicon.save('web/favicon.png')
print('  OK web/favicon.png (32x32)')

web_icons = [
    ('web/icons/Icon-192.png', 192),
    ('web/icons/Icon-512.png', 512),
    ('web/icons/Icon-maskable-192.png', 192),
    ('web/icons/Icon-maskable-512.png', 512),
]
for path, size in web_icons:
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(path)
    print(f'  OK {path} ({size}x{size})')

print("\nAll icons generated successfully!")
