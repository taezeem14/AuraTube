import os
from PIL import Image, ImageDraw, ImageFilter

def create_auratube_icon(size=512):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background squircle / rounded rect with dark obsidian gradient
    pad = int(size * 0.05)
    rect_box = [pad, pad, size - pad, size - pad]
    radius = int(size * 0.22)

    # Base dark tile
    draw.rounded_rectangle(rect_box, radius=radius, fill=(11, 14, 20, 255), outline=(0, 102, 255, 120), width=int(size * 0.015))

    # 2. Glowing blue central YouTube-style capsule
    tube_pad_x = int(size * 0.16)
    tube_pad_y = int(size * 0.24)
    tube_box = [tube_pad_x, tube_pad_y, size - tube_pad_x, size - tube_pad_y]
    tube_radius = int(size * 0.14)

    # Create gradient badge
    badge = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(badge)
    
    # Gradient layers
    steps = 40
    for i in range(steps):
        t = i / float(steps)
        r = int(0 + (0 - 0) * t)
        g = int(102 + (190 - 102) * t)
        b = int(255 + (255 - 255) * t)
        color = (r, g, b, 255)
        shrink = int(i * (size * 0.002))
        sub_box = [tube_box[0] + shrink, tube_box[1] + shrink, tube_box[2] - shrink, tube_box[3] - shrink]
        if sub_box[2] > sub_box[0] and sub_box[3] > sub_box[1]:
            bdraw.rounded_rectangle(sub_box, radius=max(4, tube_radius - shrink), fill=color)

    # Neon glow shadow
    glow = badge.filter(ImageFilter.GaussianBlur(int(size * 0.04)))
    img = Image.alpha_composite(img, glow)
    img = Image.alpha_composite(img, badge)

    # 3. Play button triangle in center
    pdraw = ImageDraw.Draw(img)
    center_x = size // 2
    center_y = size // 2
    tri_w = int(size * 0.14)
    tri_h = int(size * 0.16)

    # Triangle points (pointing right)
    points = [
        (center_x - tri_w // 2 + int(size * 0.02), center_y - tri_h // 2),
        (center_x + tri_w // 2 + int(size * 0.02), center_y),
        (center_x - tri_w // 2 + int(size * 0.02), center_y + tri_h // 2)
    ]
    pdraw.polygon(points, fill=(255, 255, 255, 255))

    return img

def main():
    os.makedirs("assets/icon", exist_ok=True)
    icon = create_auratube_icon(512)
    icon.save("assets/icon/app_icon.png")
    print("Saved assets/icon/app_icon.png")

    # Android mipmaps
    mipmaps = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": 48,
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": 72,
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": 96,
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": 144,
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": 192,
    }

    for path, res in mipmaps.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = icon.resize((res, res), Image.Resampling.LANCZOS)
        resized.save(path)
        print(f"Saved {path} ({res}x{res})")

if __name__ == "__main__":
    main()
