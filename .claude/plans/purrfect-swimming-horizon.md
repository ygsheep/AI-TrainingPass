# 移动端答题应用模板 - Flutter实现计划

## 一、项目概述

**目标**: 创建一个通用的移动端答题应用模板，可通过更换题库快速生成不同的考试APP

**核心功能**:
- 题库答题（顺序/随机/分类练习）
- 模拟考试（倒计时、防作弊、成绩结算）
- 错题本（错题收集、智能复习推荐）
- 题库更新（手动导入 + 在线下载）

**技术栈**: Flutter + Dart

---

## 二、项目结构

```
lib/
├── main.dart                     # 应用入口
│
├── app/                          # 应用配置
│   ├── app.dart                  # 根组件
│   ├── router.dart               # 路由配置
│   └── theme.dart                # 主题配置
│
├── core/                         # 核心层
│   ├── constants/                # 常量
│   │   ├── storage_keys.dart     # 存储键
│   │   └── api_endpoints.dart    # API端点
│   │
│   ├── errors/                   # 异常处理
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   │
│   ├── network/                  # 网络层
│   │   ├── api_client.dart       # Dio封装
│   │   └── network_info.dart     # 网络状态
│   │
│   └── utils/                    # 工具类
│       ├── json_converter.dart   # JSON转换
│       └── date_formatter.dart   # 日期格式化
│
├── data/                         # 数据层
│   ├── models/                   # 数据模型
│   │   ├── question.dart         # 题目模型
│   │   ├── question_bank.dart    # 题库模型
│   │   ├── user_answer.dart      # 答题记录
│   │   ├── wrong_question.dart   # 错题
│   │   ├── exam_record.dart      # 考试记录
│   │   └── app_config.dart       # 应用配置
│   │
│   ├── repositories/             # 仓储实现
│   │   ├── question_repository_impl.dart
│   │   ├── exam_repository_impl.dart
│   │   └── config_repository_impl.dart
│   │
│   └── datasources/              # 数据源
│       ├── local/                # 本地数据源
│       │   ├── question_local_datasource.dart
│       │   ├── hive_service.dart # Hive服务
│       │   └── file_service.dart # 文件服务
│       │
│       └── remote/               # 远程数据源
│           └── question_remote_datasource.dart
│
├── domain/                       # 领域层
│   ├── entities/                 # 领域实体
│   │   ├── question.dart
│   │   ├── question_bank.dart
│   │   └── exam_statistics.dart
│   │
│   ├── repositories/             # 仓储接口
│   │   ├── question_repository.dart
│   │   ├── exam_repository.dart
│   │   └── config_repository.dart
│   │
│   └── usecases/                 # 用例
│       ├── load_question_bank.dart
│       ├── submit_answer.dart
│       ├── start_exam.dart
│       ├── add_to_wrong_book.dart
│       └── update_question_bank.dart
│
├── presentation/                 # 表现层
│   ├── providers/                # 状态管理 (Provider/Riverpod)
│   │   ├── question_provider.dart
│   │   ├── exam_provider.dart
│   │   ├── wrong_book_provider.dart
│   │   └── config_provider.dart
│   │
│   ├── pages/                    # 页面
│   │   ├── home/                 # 首页
│   │   │   └── home_page.dart
│   │   │
│   │   ├── practice/             # 练习模式
│   │   │   ├── practice_page.dart
│   │   │   └── question_detail_page.dart
│   │   │
│   │   ├── exam/                 # 模拟考试
│   │   │   ├── exam_setup_page.dart
│   │   │   ├── exam_page.dart
│   │   │   └── exam_result_page.dart
│   │   │
│   │   ├── wrong_book/           # 错题本
│   │   │   └── wrong_book_page.dart
│   │   │
│   │   ├── history/              # 历史记录
│   │   │   └── history_page.dart
│   │   │
│   │   └── settings/             # 设置
│   │       └── settings_page.dart
│   │
│   └── widgets/                  # 通用组件
│       ├── question_card/        # 题目卡片
│       ├── option_button/        # 选项按钮
│       ├── progress_bar/         # 进度条
│       ├── countdown_timer/      # 倒计时
│       ├── score_display/        # 成绩展示
│       └── empty_state/          # 空状态
│
└── assets/                       # 资源文件
    ├── images/
    └── data/
        └── default_questions.json # 默认题库
```

---

## 三、技术选型

| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter | 3.24+ | UI框架 |
| Dart | 3.5+ | 编程语言 |
| **状态管理** | | |
| flutter_riverpod | 2.6+ | 状态管理 (推荐) |
| provider | 6.1+ | 状态管理 (备选) |
| **数据存储** | | |
| hive | 2.2+ | 本地NoSQL数据库 |
| hive_flutter | 1.1+ | Hive Flutter扩展 |
| path_provider | 2.1+ | 文件路径 |
| **网络请求** | | |
| dio | 5.7+ | HTTP客户端 |
| connectivity_plus | 6.0+ | 网络状态检测 |
| **UI组件** | | |
| flutter_markdown | 0.7+ | Markdown渲染 |
| cached_network_image | 3.4+ | 图片缓存 |
| flutter_slidable | 3.1+ | 滑动操作 |
| **工具库** | | |
| json_annotation | 4.9+ | JSON序列化注解 |
| json_serializable | 6.8+ | JSON代码生成 |
| freezed_annotation | 2.4+ | 不可变类注解 |
| freezed | 2.5+ | 不可变类生成 |
| intl | 0.20+ | 国际化 |
| uuid | 4.5+ | UUID生成 |

---

## 四、数据存储结构

### 4.1 Hive Boxes 结构

```dart
// 用户数据 Box: 'user_data'
{
  'user_answers': List<UserAnswer>,      // 答题记录
  'study_progress': StudyProgress,       // 学习进度
  'exam_history': List<ExamRecord>,      // 考试历史
  'wrong_questions': List<WrongQuestion>, // 错题本
}

// 题库 Box: 'question_bank'
{
  'questions': List<Question>,           // 题目列表
  'categories': List<String>,            // 分类列表
  'version': String,                     // 题库版本
  'last_updated': DateTime,              // 更新时间
}

// 应用配置 Box: 'app_config'
{
  'app_config': AppConfig,               // 应用配置
  'user_settings': UserSettings,         // 用户设置
}
```

### 4.2 文件存储结构

```
// Android路径
/data/data/com.example.examapp/databases/
├── hive/                              # Hive数据库文件
│   ├── user_data.hive
│   ├── user_data.lock
│   ├── question_bank.hive
│   ├── question_bank.lock
│   ├── app_config.hive
│   └── app_config.lock
│
└── question_banks/                     # 题库JSON文件
    ├── default_questions.json
    └── imported_questions.json
```

---

## 五、核心数据模型

### 5.1 题目模型 (data/models/question.dart)

```dart
@JsonSerializable()
class QuestionModel {
  final String id;
  final String source;                  // main/mock/review
  final String category;                // 分类
  final String type;                    // single/multiple/judge/fill
  final String question;                // 题干
  final List<Option>? options;          // 选项
  final String answer;                  // 答案 (多选用|分隔)
  final String? explanation;            // 解析
  final int? difficulty;                // 难度 1-3

  QuestionModel({
    required this.id,
    required this.source,
    required this.category,
    required this.type,
    required this.question,
    this.options,
    required this.answer,
    this.explanation,
    this.difficulty,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionModelToJson(this);
}

@JsonSerializable()
class Option {
  final String key;                     // A/B/C/D
  final String text;

  Option({required this.key, required this.text});

  factory Option.fromJson(Map<String, dynamic> json) =>
      _$OptionFromJson(json);

  Map<String, dynamic> toJson() => _$OptionToJson(this);
}
```

### 5.2 答题记录 (data/models/user_answer.dart)

```dart
@JsonSerializable()
class UserAnswerModel {
  final String id;
  final String questionId;
  final String userAnswer;              // 用户答案
  final bool isCorrect;
  final int timeSpent;                  // 耗时(秒)
  final DateTime answeredAt;

  UserAnswerModel({
    required this.id,
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.timeSpent,
    required this.answeredAt,
  });

  factory UserAnswerModel.fromJson(Map<String, dynamic> json) =>
      _$UserAnswerModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserAnswerModelToJson(this);
}
```

### 5.3 错题记录 (data/models/wrong_question.dart)

```dart
@JsonSerializable()
class WrongQuestionModel {
  final String id;
  final String questionId;
  final QuestionModel question;
  final List<UserAnswerModel> wrongAnswers;
  final bool mastered;                  // 是否已掌握
  final int reviewCount;                // 复习次数
  final DateTime lastReviewAt;
  final String? notes;                  // 用户笔记

  WrongQuestionModel({
    required this.id,
    required this.questionId,
    required this.question,
    required this.wrongAnswers,
    this.mastered = false,
    this.reviewCount = 0,
    required this.lastReviewAt,
    this.notes,
  });

  factory WrongQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$WrongQuestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$WrongQuestionModelToJson(this);
}
```

### 5.4 考试记录 (data/models/exam_record.dart)

```dart
@JsonSerializable()
class ExamRecordModel {
  final String id;
  final ExamConfigModel config;
  final List<String> questionIds;       // 题目ID列表
  final List<UserAnswerModel> answers;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;                  // 实际用时(秒)
  final int score;                      // 得分
  final bool passed;                    // 是否及格
  final int correctCount;               // 正确数
  final int totalCount;                 // 总题数

  ExamRecordModel({
    required this.id,
    required this.config,
    required this.questionIds,
    required this.answers,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.score,
    required this.passed,
    required this.correctCount,
    required this.totalCount,
  });

  factory ExamRecordModel.fromJson(Map<String, dynamic> json) =>
      _$ExamRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExamRecordModelToJson(this);
}

@JsonSerializable()
class ExamConfigModel {
  final String name;                    // 考试名称
  final int questionCount;              // 题目数量
  final int duration;                   // 时长(分钟)
  final int passScore;                  // 及格分
  final List<String>? categories;       // 选择的分类
  final bool randomOrder;               // 是否随机排序
  final bool antiCheat;                 // 是否开启防作弊

  ExamConfigModel({
    required this.name,
    required this.questionCount,
    required this.duration,
    required this.passScore,
    this.categories,
    this.randomOrder = true,
    this.antiCheat = true,
  });

  factory ExamConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ExamConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExamConfigModelToJson(this);
}
```

### 5.5 应用配置 (data/models/app_config.dart)

```dart
@JsonSerializable()
class AppConfigModel {
  final String appName;                 // 应用名称
  final String appVersion;              // 应用版本
  final String questionBankVersion;     // 题库版本
  final String? updateUrl;              // 题库更新URL
  final DateTime? lastUpdateCheck;      // 上次更新检查时间
  final int defaultExamDuration;        // 默认考试时长(分钟)
  final int defaultPassScore;           // 默认及格分

  AppConfigModel({
    required this.appName,
    required this.appVersion,
    required this.questionBankVersion,
    this.updateUrl,
    this.lastUpdateCheck,
    this.defaultExamDuration = 60,
    this.defaultPassScore = 60,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) =>
      _$AppConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigModelToJson(this);
}

@JsonSerializable()
class UserSettingsModel {
  final bool soundEnabled;              // 音效开关
  final bool vibrateEnabled;            // 震动开关
  final bool autoSubmit;                // 自动提交
  final String themeMode;               // 主题模式 light/dark/system

  UserSettingsModel({
    this.soundEnabled = true,
    this.vibrateEnabled = true,
    this.autoSubmit = false,
    this.themeMode = 'system',
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsModelToJson(this);
}
```

---

## 六、开发步骤

### Phase 1: 项目初始化 ✅ 已完成
```
✅ 创建Flutter项目
✅ 配置pubspec.yaml依赖
✅ 设置目录结构
✅ 配置代码生成 (build_runner)
✅ 配置主题和路由
✅ 初始化Hive服务
```

### Phase 2: 数据层实现 ✅ 已完成
```
✅ 创建数据模型 (with json_serializable)
✅ 实现HiveService (数据库初始化、CRUD)
✅ 实现FileService (题库文件导入/导出)
✅ 实现QuestionLocalDatasource
✅ 实现Repository层
```

### Phase 3: 领域层实现
```
□ 定义Repository接口
□ 定义UseCase
□ 定义Entity实体
```

### Phase 4: 状态管理实现
```
□ QuestionProvider (题目管理)
□ ExamProvider (考试管理)
□ WrongBookProvider (错题管理)
□ ConfigProvider (配置管理)
```

### Phase 5: UI组件开发
```
□ 通用组件:
  ├── QuestionCard (题目卡片)
  ├── OptionButton (选项按钮)
  ├── ProgressBar (进度条)
  ├── CountdownTimer (倒计时)
  └── ScoreDisplay (成绩展示)

□ 页面开发:
  ├── HomePage (首页)
  ├── PracticePage (练习模式)
  ├── QuestionDetailPage (答题页)
  ├── ExamSetupPage (考试设置)
  ├── ExamPage (考试页)
  ├── ExamResultPage (成绩页)
  ├── WrongBookPage (错题本)
  ├── HistoryPage (历史记录)
  └── SettingsPage (设置页)
```

### Phase 6: 核心功能实现
```
□ 练习模式
  ├── 顺序练习
  ├── 随机练习
  └── 分类练习

□ 模拟考试
  ├── 考试配置
  ├── 倒计时功能
  ├── 切屏检测
  └── 成绩结算

□ 错题本
  ├── 自动收集错题
  ├── 错题重练
  └── 掌握标记

□ 题库更新
  ├── 手动导入JSON
  └── 在线更新 (可选)
```

### Phase 7: 打包发布
```
□ 生成APK (Android)
□ 配置签名 (Release)
□ 应用图标/启动页
□ 权限配置
□ 测试与调优
```

---

## 七、题库JSON格式规范

### 7.1 题库文件结构

```json
{
  "meta": {
    "name": "题库名称",
    "version": "1.0.0",
    "description": "题库描述",
    "author": "作者",
    "created_at": "2025-01-01",
    "total_questions": 1000
  },
  "categories": [
    {"id": "foundation", "name": "基础知识"},
    {"id": "practical", "name": "实操技能"},
    {"id": "safety", "name": "安全规范"}
  ],
  "questions": [
    {
      "id": "unique_id",
      "source": "main",
      "category": "foundation",
      "type": "single",
      "question": "题目内容",
      "options": [
        {"key": "A", "text": "选项A"},
        {"key": "B", "text": "选项B"},
        {"key": "C", "text": "选项C"},
        {"key": "D", "text": "选项D"}
      ],
      "answer": "A",
      "explanation": "答案解析",
      "difficulty": 1
    }
  ]
}
```

### 7.2 题目类型说明

| type | 说明 | answer格式 |
|------|------|------------|
| single | 单选题 | "A" |
| multiple | 多选题 | "A\|B\|C" |
| judge | 判断题 | "true" 或 "false" |
| fill | 填空题 | "答案1\|答案2" (多个答案用\|分隔) |

---

## 八、打包与分发

### 8.1 APK打包命令

```bash
# Release APK
flutter build apk --release

# 分架构打包 (更小的体积)
flutter build apk --split-per-abi --release

# App Bundle (Google Play)
flutter build appbundle --release
```

### 8.2 应用配置

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/data/

  android:
    applicationId: com.example.examapp
    versionCode: 1
    versionName: "1.0.0"
```

---

## 九、模板化配置

通过修改 `assets/data/app_config.json` 可快速生成不同考试APP：

```json
{
  "app_name": "AI训练师考试",
  "app_icon": "assets/icon.png",
  "primary_color": "#1976D2",
  "question_bank_file": "ai_training_questions.json",
  "default_exam_duration": 90,
  "default_pass_score": 60,
  "update_url": "https://example.com/api/updates"
}
```

---

## 十、UI/UX 设计系统

### 10.1 设计风格

**风格**: Swiss Modernism (瑞士现代主义) + Minimalism

**特点**:
- 极简主义，高对比度
- 网格系统，数学化间距
- 单色基调 + 品牌强调色
- 清晰的视觉层级
- 无阴影或极微妙阴影
- 专注内容，去除装饰

**适用场景**: 职业考试、专业认证、学习培训

### 10.2 色彩系统

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  // Light Mode
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5E5);

  // Dark Mode
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF242424);
  static const Color darkBorder = Color(0xFF333333);

  // Primary (品牌色 - 可配置)
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Text Colors
  static const Color textPrimary = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textDisabled = Color(0xFFCCCCCC);

  // Dark Mode Text
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextTertiary = Color(0xFF808080);
}
```

### 10.3 字体系统

```dart
// lib/core/theme/app_text_style.dart
class AppTypography {
  static const String fontFamily = 'SF Pro Display'; // iOS/Android
  static const String fontFamilyFallback = 'Roboto';

  // Display (标题)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  // Headline (小标题)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  // Body (正文)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Label (标签)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}
```

### 10.4 响应式断点

```dart
// lib/core/utils/responsive.dart
class Breakpoints {
  static const double mobile = 375;   // 手机
  static const double tablet = 768;   // 平板
  static const double desktop = 1024; // 桌面/大平板
}

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.tablet &&
      MediaQuery.of(context).size.width < Breakpoints.desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.desktop;
}
```

### 10.5 组件设计规范

#### 10.5.1 按钮组件

```dart
// lib/presentation/widgets/buttons/app_button.dart
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;

  const AppButton({
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: _getPadding(),
        decoration: BoxDecoration(
          color: _getBackgroundColor(isEnabled),
          borderRadius: BorderRadius.circular(12),
          border: type == AppButtonType.outline
              ? Border.all(color: AppColors.primary)
              : null,
        ),
        child: Text(
          text,
          style: _getTextStyle(),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }
}

enum AppButtonType { primary, secondary, outline, text }
enum AppButtonSize { small, medium, large }
```

#### 10.5.2 选项按钮

```dart
// lib/presentation/widgets/questions/option_button.dart
class OptionButton extends StatelessWidget {
  final String keyLabel;
  final String content;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;

  const OptionButton({
    required this.keyLabel,
    required this.content,
    required this.onTap,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            _buildKeyLabel(),
            const SizedBox(width: 12),
            Expanded(child: _buildContent()),
            if (showResult) _buildResultIcon(),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (!showResult) {
      return isSelected
          ? AppColors.primary.withOpacity(0.1)
          : Colors.transparent;
    }

    if (isSelected) {
      return isCorrect ? AppColors.success : AppColors.error;
    }

    return isCorrect
        ? AppColors.success.withOpacity(0.1)
        : Colors.transparent;
  }

  Color _getBorderColor() {
    if (!showResult) {
      return isSelected ? AppColors.primary : AppColors.lightBorder;
    }

    if (isSelected) {
      return isCorrect ? AppColors.success : AppColors.error;
    }

    return isCorrect ? AppColors.success : AppColors.lightBorder;
  }
}
```

#### 10.5.3 进度指示器

```dart
// lib/presentation/widgets/progress/quiz_progress.dart
class QuizProgress extends StatelessWidget {
  final int current;
  final int total;
  final double progress;

  const QuizProgress({
    required this.current,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 进度条
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.lightBorder,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        // 文字提示
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '题目 $current / $total',
              style: AppTypography.bodySmall,
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

### 10.6 页面布局设计

#### 10.6.1 首页 (HomePage)

```
┌─────────────────────────────────────────────┐
│  [Logo]  QuizMaster                [设置]   │  <- AppBar
├─────────────────────────────────────────────┤
│                                             │
│  欢迎回来                                   │  <- 标题
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  开始练习                            │   │
│  │  随时答题，巩固知识                  │   │  <- 主卡片
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────┐  ┌─────────────┐         │
│  │  模拟考试     │  │  错题本      │         │  <- 次要卡片
│  └─────────────┘  └─────────────┘         │
│                                             │
│  ┌─────────────┐  ┌─────────────┐         │
│  │  历史记录    │  │  题库更新    │         │
│  └─────────────┘  └─────────────┘         │
│                                             │
├─────────────────────────────────────────────┤
│  [首页] [练习] [考试] [错题] [我的]         │  <- BottomNav
└─────────────────────────────────────────────┘

Mobile: 1列布局
Tablet: 2列网格
Desktop: 3列网格
```

#### 10.6.2 答题页面 (QuestionPage)

```
┌─────────────────────────────────────────────┐
│  [←]  练习模式                [题目导航]   │  <- AppBar
├─────────────────────────────────────────────┤
│  ████████░░░░░░░░  5/20                     │  <- 进度条
├─────────────────────────────────────────────┤
│                                             │
│  [单选题]  基础知识                          │  <- 题目标签
│                                             │
│  题目内容显示在这里...                       │
│  支持多行文本显示                            │
│  ┌─────────────────────────────────────┐   │
│  │ A 选项内容                          │   │
│  ├─────────────────────────────────────┤   │  <- 选项列表
│  │ B 选项内容                          │   │     (可滚动)
│  ├─────────────────────────────────────┤   │
│  │ C 选项内容                          │   │
│  ├─────────────────────────────────────┤   │
│  │ D 选项内容                          │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  [提交答案]                                 │  <- 提交按钮
│                                             │
├─────────────────────────────────────────────┤
│  [上一题]  [收藏]  [下一题]                 │  <- 底部操作栏
└─────────────────────────────────────────────┘

Mobile: 全屏内容，底部固定操作栏
Tablet: 居中内容，两侧留白
Desktop: 居中内容，最大宽度 800px
```

#### 10.6.3 考试页面 (ExamPage)

```
┌─────────────────────────────────────────────┐
│  [退出]  模拟考试              [⏱ 59:32]   │  <- AppBar (倒计时)
├─────────────────────────────────────────────┤
│  ████████░░░░░░░░  15/100                   │  <- 进度条
├─────────────────────────────────────────────┤
│                                             │
│  题目内容区域（同答题页面）                   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ A 选项内容                          │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │ B 选项内容                          │   │
│  └─────────────────────────────────────┘   │
│  ...                                        │
│                                             │
│  [暂存]  [提交试卷]                         │  <- 操作按钮
│                                             │
├─────────────────────────────────────────────┤
│  [答题卡]                                  │  <- 答题卡按钮
└─────────────────────────────────────────────┘

答题卡弹窗:
┌─────────────────────────────────────────────┐
│  答题卡                          [×]        │
├─────────────────────────────────────────────┤
│  ● ○ ○ ● ○ ○ ○ ○ ○ ○                     │
│  ○ ○ ● ○ ○ ○ ○ ● ○ ○                     │  <- 题目网格
│  ...                                        │     (已答/未答/当前)
│                                             │
│  ● 已答  ○ 未答  ● 当前                    │
├─────────────────────────────────────────────┤
│           [关闭答题卡]                       │
└─────────────────────────────────────────────┘
```

#### 10.6.4 错题本页面 (WrongBookPage)

```
┌─────────────────────────────────────────────┐
│  [←]  错题本              [筛选] [复习]    │  <- AppBar
├─────────────────────────────────────────────┤
│                                             │
│  全部 ▼  基础知识 ▼  未掌握 ▼              │  <- 筛选栏
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ 题目预览...                 [→]     │   │
│  │ 错误2次 | 最后复习: 3天前           │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ 题目预览...                 [→]     │   │  <- 错题列表
│  │ 错误1次 | 最后复习: 7天前           │   │    (可滑动删除)
│  └─────────────────────────────────────┘   │
│  ...                                        │
│                                             │
└─────────────────────────────────────────────┘

滑动操作:
- 左滑: 标记已掌握 / 删除
- 右滑: 开始复习
```

### 10.7 触摸目标尺寸

```dart
// lib/core/constants/touch_targets.dart
class TouchTargets {
  // 最小触摸尺寸 (WCAG 2.1 AAA)
  static const double minSize = 44;

  // 推荐触摸尺寸
  static const double recommendedSize = 48;

  // 大按钮
  static const double largeSize = 56;

  // 间距
  static const double spacing = 8;
  static const double spacingLarge = 16;
}
```

### 10.8 交互动画时长

```dart
// lib/core/constants/animation.dart
class AnimationDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);

  static const Duration pageTransition = Duration(milliseconds: 250);
  static const Duration modalTransition = Duration(milliseconds: 300);
}

class AnimationCurves {
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve sharpCurve = Curves.easeOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}
```

### 10.9 Flutter 最佳实践

```dart
// lib/app/router.dart - 使用 go_router
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/practice',
      builder: (context, state) => const PracticePage(),
    ),
    GoRoute(
      path: '/question/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return QuestionPage(questionId: id);
      },
    ),
  ],
);

// 处理返回键
PopScope(
  canPop: false,
  onPopInvoked: (didPop) {
    if (didPop) return;
    // 显示退出确认对话框
    _showExitConfirmation(context);
  },
  child: const ExamPage(),
);
```

### 10.10 主题配置

```dart
// lib/app/theme.dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.lightSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
    );
  }
}
```

### 10.11 无障碍设计

```dart
// 确保所有交互元素都有语义标签
Semantics(
  button: true,
  label: '选择A选项',
  child: OptionButton(...),
)

// 支持屏幕阅读器
MergeSemantics(
  child: Column(
    children: [
      Text('题目内容'),
      OptionButton(...),
    ],
  ),
)

// 焦点管理
FocusScope(
  node: _focusScopeNode,
  autofocus: true,
  child: Column(
    children: options.map((option) =>
      Focus(
        onKey: (node, event) {
          // 处理键盘导航
        },
        child: OptionButton(...),
      )
    ).toList(),
  ),
)
```

---

## 十一、注意事项

1. **数据迁移**: Hive升级时需注意版本兼容
2. **内存优化**: 大题库需分页加载
3. **电池优化**: 长时间考试需优化功耗
4. **防作弊限制**: Android需要覆盖系统返回键
5. **文件导入**: 支持从文件管理器/云盘导入
6. **响应式测试**: 确保在 375px / 768px / 1024px / 1440px 下测试
7. **触摸测试**: 移动端确保所有按钮 ≥ 44px
