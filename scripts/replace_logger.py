#!/usr/bin/env python3
"""
批量替换 debugPrint 为 AppLogger
"""
import os
from pathlib import Path

# 项目根目录
PROJECT_ROOT = Path(__file__).parent.parent

# 需要处理的文件
FILES = [
    'lib/data/datasources/local/question_local_datasource.dart',
    'lib/presentation/pages/exam/exam_page.dart',
    'lib/presentation/providers/exam_setup_provider.dart',
    'lib/presentation/pages/exam/exam_setup_page.dart',
    'lib/presentation/providers/exam_provider.dart',
    'lib/app/router.dart',
    'lib/domain/usecases/generate_exam_questions.dart',
    'lib/domain/usecases/start_exam.dart',
    'lib/data/services/question_initialization.dart',
    'lib/presentation/providers/question_provider.dart',
    'lib/main.dart',
    'lib/presentation/pages/wrong_book/wrong_book_page.dart',
    'lib/domain/usecases/submit_exam.dart',
]

def replace_in_file(file_path: Path):
    """在单个文件中替换 debugPrint"""
    if not file_path.exists():
        print(f"⚠️  文件不存在: {file_path.relative_to(PROJECT_ROOT)}")
        return False

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        # 添加导入（如果还没有）
        if "import 'package:logger/logger.dart';" not in content and "import '../../../core/utils/app_logger.dart';" not in content:
            # 计算相对导入路径
            rel_path = file_path.relative_to(PROJECT_ROOT / 'lib')
            depth = len(rel_path.parts) - 1  # 'lib' 的深度
            import_path = '../' * depth + 'core/utils/app_logger.dart'

            # 在第一个 import 后添加
            lines = content.split('\n')
            import_index = -1
            for i, line in enumerate(lines):
                if line.strip().startswith('import ') and 'package:flutter/foundation.dart' in line:
                    import_index = i + 1
                    break

            if import_index > 0:
                lines.insert(import_index, f"import '{import_path}';")
                content = '\n'.join(lines)

        # 替换 debugPrint
        content = content.replace('debugPrint(', 'AppLogger.debug(')

        if content != original:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ {file_path.relative_to(PROJECT_ROOT)}")
            return True
        else:
            print(f"⏭️  {file_path.relative_to(PROJECT_ROOT)} (无需修改)")
            return True

    except Exception as e:
        print(f"❌ {file_path.relative_to(PROJECT_ROOT)}: {e}")
        return False

def main():
    print("=" * 50)
    print("批量替换 debugPrint 为 AppLogger")
    print("=" * 50)
    print()

    success_count = 0
    for file_str in FILES:
        file_path = PROJECT_ROOT / file_str
        if replace_in_file(file_path):
            success_count += 1

    print()
    print("=" * 50)
    print(f"完成: {success_count}/{len(FILES)} 个文件已处理")
    print("=" * 50)
    print()
    print("接下来请运行:")
    print("  flutter pub get")
    print("  dart run build_runner build")

if __name__ == "__main__":
    main()
