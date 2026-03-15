import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'question.g.dart';

/// Question Option
/// Represents a single option for a question
@JsonSerializable()
class QuestionOption {
  final String key;                     // A, B, C, D
  final String text;

  const QuestionOption({
    required this.key,
    required this.text,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) =>
      _$QuestionOptionFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionOptionToJson(this);
}

/// Question Model
/// Represents a single quiz/exam question
@JsonSerializable(explicitToJson: true)
class QuestionModel {
  final String id;
  @JsonKey(defaultValue: 'main')
  final String source;                  // main/mock/review
  final List<String> category;          // 分类数组（支持多个分类）
  final String type;                    // single/multiple/judge/essay
  final String question;                // 题干
  final List<QuestionOption>? options;  // 选项
  final String? answer;                 // 答案 (多选用|分隔)
  final String? explanation;            // 解析
  final int? difficulty;                // 难度 1-3
  final String? imageUrl;               // Base64图片数据URI
  final String? originalType;           // 原始中文题型
  final String? originalSource;         // 原始中文来源

  const QuestionModel({
    required this.id,
    required this.source,
    required this.category,
    required this.type,
    required this.question,
    this.options,
    this.answer,
    this.explanation,
    this.difficulty,
    this.imageUrl,
    this.originalType,
    this.originalSource,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Use the same logic as fromNewJson to ensure type is correctly determined from originalType
    // This is needed because Hive stores data with the type field, but it may be incorrect
    final typeRaw = json['type'] as String?;
    final originalTypeRaw = json['originalType'] as String?;

    // PRIORITY: originalType (most accurate) > type field
    String correctedType;
    if (originalTypeRaw != null && !_isEnglishTypeCode(originalTypeRaw)) {
      // Use originalType (Chinese) as source of truth
      correctedType = _mapType(originalTypeRaw);
    } else if (typeRaw == null) {
      correctedType = 'single';
    } else if (_isEnglishTypeCode(typeRaw)) {
      correctedType = typeRaw;
    } else {
      correctedType = _mapType(typeRaw);
    }

    // Create a new json with corrected type
    final correctedJson = Map<String, dynamic>.from(json);
    correctedJson['type'] = correctedType;

    return _$QuestionModelFromJson(correctedJson);
  }

  /// Factory constructor for new JSON format
  factory QuestionModel.fromNewJson(Map<String, dynamic> json) {
    final typeRaw = json['type'] as String?;
    final originalTypeRaw = json['originalType'] as String?;
    final sourceRaw = json['source'] as String?;

    // Handle both Chinese type names and English codes
    // PRIORITY: originalType (most accurate) > type field
    String type;
    if (originalTypeRaw != null && !_isEnglishTypeCode(originalTypeRaw)) {
      // Use originalType (Chinese) as source of truth
      type = _mapType(originalTypeRaw);
    } else if (typeRaw == null) {
      type = 'single';
    } else if (_isEnglishTypeCode(typeRaw)) {
      // Already an English code (from Hive storage), use as-is
      type = typeRaw;
    } else {
      // Chinese name, map to English code
      type = _mapType(typeRaw);
    }

    // Handle both Chinese source names and English codes
    // If already an English code, use it directly; otherwise map from Chinese
    String source;
    if (sourceRaw == null) {
      source = 'main';
    } else if (_isEnglishSourceCode(sourceRaw)) {
      // Already an English code (from Hive storage), use as-is
      source = sourceRaw;
    } else {
      // Chinese name, map to English code
      source = _mapSource(sourceRaw);
    }

    // 转换答案 (string or array -> string)
    final answer = json['answer'];
    String? answerStr;
    if (answer is List) {
      answerStr = (answer as List).join('|');
    } else if (answer is String) {
      answerStr = answer as String;
    }

    // 转换分类 - 支持字符串和数组两种格式
    final categoryRaw = json['category'];
    List<String> categoryList;
    if (categoryRaw is List) {
      categoryList = (categoryRaw as List).map((e) => e.toString()).toList();
    } else if (categoryRaw is String) {
      categoryList = [categoryRaw as String];
    } else {
      categoryList = ['默认分类'];
    }

    // 转换选项 (对象数组 -> QuestionOption数组)
    // 支持两种格式：
    // 1. 新JSON格式: {label: "A", content: "..."}
    // 2. Hive存储格式(toJson): {key: "A", text: "..."}
    final options = json['options'] as List?;
    List<QuestionOption>? optionsList;
    if (options != null && options.isNotEmpty) {
      optionsList = options.map((o) {
        if (o is! Map) return QuestionOption(key: 'A', text: '');
        final optionMap = o as Map<String, dynamic>;

        // 支持两种格式
        final key = (optionMap['label'] as String?) ??
                   (optionMap['key'] as String?) ?? 'A';
        final text = (optionMap['content'] as String?) ??
                    (optionMap['text'] as String?) ?? '';

        return QuestionOption(
          key: key,
          text: text,
        );
      }).toList();
    }

    // 读取 explanation 字段
    final explanation = json['explanation'] as String?;
    // 调试日志：检查是否有 explanation
    if (explanation != null && explanation.isNotEmpty) {
      // print('📖 Found explanation for question: ${(json['question'] as String?)?.substring(0, 20)}...');
    }

    return QuestionModel(
      id: generateUniqueId(json),  // Use unique ID instead of original ID
      source: source,
      category: categoryList,
      type: type,
      question: (json['question'] as String?) ?? '',
      options: optionsList,
      answer: answerStr,
      imageUrl: json['image'] as String?,
      // Preserve originalType if it exists (from Hive), otherwise map back from English code
      originalType: json['originalType'] as String? ??
          (_isEnglishTypeCode(type) ? _mapEnglishToChineseType(type) : typeRaw),
      // Preserve originalSource if it exists (from Hive), otherwise use raw source value
      originalSource: json['originalSource'] as String? ??
          (_isEnglishSourceCode(source) ? _mapEnglishToChinese(source) : sourceRaw),
      explanation: explanation,
      difficulty: (json['difficulty'] as num?)?.toInt(),
    );
  }

  /// Generate a unique, stable ID for a question based on its content
  /// This ensures the same question always gets the same ID, even after re-import
  static String generateUniqueId(Map<String, dynamic> json) {
    final originalId = json['id']?.toString() ?? '0';
    final question = json['question'] as String? ?? '';
    final source = json['source'] as String? ?? 'main';

    // Use first 50 chars of question + original ID + source to create stable unique ID
    final combined = '${source}_$originalId${question.length > 50 ? question.substring(0, 50) : question}';

    // Generate UUID v5 (name-based) for stability
    return const Uuid().v5(Uuid.NAMESPACE_OID, combined);
  }

  /// Map Chinese type to English code
  static String _mapType(String chineseType) {
    switch (chineseType) {
      case '单选题': return 'single';
      case '多选题': return 'multiple';
      case '判断题': return 'judge';
      case '简答题': return 'essay';
      default: return 'single';
    }
  }

  /// Check if type is already an English code
  static bool _isEnglishTypeCode(String type) {
    return type == 'single' || type == 'multiple' || type == 'judge' || type == 'essay';
  }

  /// Map English type code back to Chinese name
  static String _mapEnglishToChineseType(String englishType) {
    switch (englishType) {
      case 'single': return '单选题';
      case 'multiple': return '多选题';
      case 'judge': return '判断题';
      case 'essay': return '简答题';
      default: return englishType;
    }
  }

  /// Map Chinese source to English code
  static String _mapSource(String chineseSource) {
    switch (chineseSource) {
      case '理论题试题': return 'main';
      case '理论题模拟题': return 'mock';
      case '人工智能训练师复习题': // No space
      case '人工智能训练师 复习题': // With space
        return 'review';
      default: return 'main';
    }
  }

  /// Check if source is already an English code
  static bool _isEnglishSourceCode(String source) {
    return source == 'main' || source == 'mock' || source == 'review';
  }

  /// Map English source code back to Chinese name
  static String _mapEnglishToChinese(String englishSource) {
    switch (englishSource) {
      case 'main': return '理论题试题';
      case 'mock': return '理论题模拟题';
      case 'review': return '人工智能训练师复习题';
      default: return englishSource;
    }
  }

  Map<String, dynamic> toJson() => _$QuestionModelToJson(this);

  /// Check if this is a single choice question
  bool get isSingleChoice => type == 'single';

  /// Check if this is a multiple choice question
  bool get isMultipleChoice => type == 'multiple';

  /// Check if this is a true/false question
  bool get isJudge => type == 'judge';

  /// Check if this is a fill-in-the-blank question (deprecated, use isEssay)
  bool get isFill => type == 'fill';

  /// Check if this is an essay question
  bool get isEssay => type == 'essay';

  /// Get answer as list for multiple choice
  List<String> get answerList => answer?.split('|') ?? [];

  /// Check if the given answer is correct
  bool isCorrect(String userAnswer) {
    if (answer == null) return false;
    if (isMultipleChoice) {
      final userAnswers = userAnswer.split('|')..sort();
      final correctAnswers = answerList..sort();
      return _listsEqual(userAnswers, correctAnswers);
    }
    return userAnswer.trim().toLowerCase() == answer!.trim().toLowerCase();
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].trim().toLowerCase() != b[i].trim().toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  /// Copy with method for immutability
  QuestionModel copyWith({
    String? id,
    String? source,
    List<String>? category,
    String? type,
    String? question,
    List<QuestionOption>? options,
    String? answer,
    String? explanation,
    int? difficulty,
    String? imageUrl,
    String? originalType,
    String? originalSource,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      source: source ?? this.source,
      category: category ?? this.category,
      type: type ?? this.type,
      question: question ?? this.question,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      imageUrl: imageUrl ?? this.imageUrl,
      originalType: originalType ?? this.originalType,
      originalSource: originalSource ?? this.originalSource,
    );
  }
}
