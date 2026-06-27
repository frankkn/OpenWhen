class CapsuleAnswer {
  final String? id;
  final String? capsuleId;
  final int questionNumber;
  final String questionText;
  final String? answerText;

  CapsuleAnswer({
    this.id,
    this.capsuleId,
    required this.questionNumber,
    required this.questionText,
    this.answerText,
  });

  factory CapsuleAnswer.fromJson(Map<String, dynamic> json) => CapsuleAnswer(
        id: json['id'],
        capsuleId: json['capsule_id'],
        questionNumber: json['question_number'],
        questionText: json['question_text'],
        answerText: json['answer_text'],
      );

  Map<String, dynamic> toJson() => {
        'question_number': questionNumber,
        'question_text': questionText,
        'answer_text': answerText,
      };
}

enum CapsuleMode { free, aiAssisted }

enum CapsuleStatus { locked, opened }

class Capsule {
  final String id;
  final String? userId;
  final String? title;
  final String? content;
  final CapsuleMode mode;
  final CapsuleStatus status;
  final DateTime openDate;
  final String? notificationEmail;
  final DateTime createdAt;
  final DateTime? openedAt;
  final List<CapsuleAnswer> answers;
  final List<Reflection> reflections;

  Capsule({
    required this.id,
    this.userId,
    this.title,
    this.content,
    required this.mode,
    required this.status,
    required this.openDate,
    this.notificationEmail,
    required this.createdAt,
    this.openedAt,
    this.answers = const [],
    this.reflections = const [],
  });

  factory Capsule.fromJson(Map<String, dynamic> json) => Capsule(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        title: json['title'] as String?,
        content: json['content'] as String?,
        mode: json['mode'] == 'free' ? CapsuleMode.free : CapsuleMode.aiAssisted,
        status: json['status'] == 'opened' ? CapsuleStatus.opened : CapsuleStatus.locked,
        openDate: DateTime.parse(json['open_date'] as String).toLocal(),
        notificationEmail: json['notification_email'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        openedAt: json['opened_at'] != null ? DateTime.parse(json['opened_at'] as String).toLocal() : null,
        answers: (json['answers'] as List<dynamic>? ?? [])
            .map((a) => CapsuleAnswer.fromJson(a as Map<String, dynamic>))
            .toList(),
        reflections: (json['reflections'] as List<dynamic>? ?? [])
            .map((r) => Reflection.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  int get daysUntilOpen => openDate.difference(DateTime.now()).inDays;
  bool get isOpenable => DateTime.now().isAfter(openDate);

  /// 卡片顯示用標題：有填標題就用標題，否則用開封日組成「致 OOOO年O月O日 的我」。
  String get displayTitle {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;
    return '致 ${openDate.year}年${openDate.month}月${openDate.day}日 的我';
  }

  /// 友善的剩餘時間文字（避免不到一天時顯示「還有 0 天」）
  String get remainingText {
    final diff = openDate.difference(DateTime.now());
    if (diff.isNegative) return '可以開封了';
    if (diff.inDays >= 1) return '還有 ${diff.inDays} 天';
    if (diff.inHours >= 1) return '還有 ${diff.inHours} 小時';
    if (diff.inMinutes >= 1) return '還有 ${diff.inMinutes} 分鐘';
    return '即將可開封';
  }
}

class Reflection {
  final String? id;
  final String? capsuleId;
  final String questionText;
  final String? answerText;

  Reflection({
    this.id,
    this.capsuleId,
    required this.questionText,
    this.answerText,
  });

  factory Reflection.fromJson(Map<String, dynamic> json) => Reflection(
        id: json['id'],
        capsuleId: json['capsule_id'],
        questionText: json['question_text'],
        answerText: json['answer_text'],
      );

  Reflection copyWith({String? answerText}) => Reflection(
        id: id,
        capsuleId: capsuleId,
        questionText: questionText,
        answerText: answerText ?? this.answerText,
      );
}
