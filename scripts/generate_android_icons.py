#!/usr/bin/env python3
"""
生成 Android APK 图标各尺寸
从 data/icon.png 生成并替换到 android/app/src/main/res/mipmap-*/ 文件夹
"""

from PIL import Image
import os
from pathlib import Path

# 项目根目录
PROJECT_ROOT = Path(__file__).parent.parent

# 源图标路径
SOURCE_ICON = PROJECT_ROOT / "data" / "icon.png"

# Android 图标尺寸配置
ICONS = {
    "mipmap-mdpi": 48,      # 48x48
    "mipmap-hdpi": 72,      # 72x72
    "mipmap-xhdpi": 96,     # 96x96
    "mipmap-xxhdpi": 144,   # 144x144
    "mipmap-xxxhdpi": 192,  # 192x192
}


def generate_icons():
    """生成各尺寸图标"""

    # 检查源文件是否存在
    if not SOURCE_ICON.exists():
        print(f"错误: 源图标不存在 {SOURCE_ICON}")
        return False

    # 打开源图标
    try:
        with Image.open(SOURCE_ICON) as img:
            # 转换为 RGBA 模式（支持透明度）
            if img.mode != 'RGBA':
                img = img.convert('RGBA')

            print(f"源图标: {SOURCE_ICON}")
            print(f"原始尺寸: {img.size}")
            print(f"模式: {img.mode}")
            print("-" * 50)

            # 生成各尺寸图标
            for folder, size in ICONS.items():
                # 目标路径
                target_dir = PROJECT_ROOT / "android" / "app" / "src" / "main" / "res" / folder
                target_file = target_dir / "ic_launcher.png"

                # 确保目录存在
                target_dir.mkdir(parents=True, exist_ok=True)

                # 调整尺寸（使用高质量重采样）
                resized = img.resize((size, size), Image.Resampling.LANCZOS)

                # 保存
                resized.save(target_file, "PNG", optimize=True)

                print(f"✓ {folder:15} ({size:3}x{size:3}) -> {target_file.relative_to(PROJECT_ROOT)}")

            print("-" * 50)
            print("生成完成！")
            return True

    except Exception as e:
        print(f"错误: {e}")
        return False


def main():
    """主函数"""
    print("=" * 50)
    print("Android APK 图标生成工具")
    print("=" * 50)
    print()

    if generate_icons():
        print()
        print("提示: 运行以下命令重新构建 APK:")
        print("  flutter build apk")
    else:
        print()
        print("生成失败，请检查错误信息。")


if __name__ == "__main__":
    main()
