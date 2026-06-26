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
        openDate: DateTime.parse(json['open_date'] as String),
        notificationEmail: json['notification_email'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        openedAt: json['opened_at'] != null ? DateTime.parse(json['opened_at'] as String) : null,
        answers: (json['answers'] as List<dynamic>? ?? [])
            .map((a) => CapsuleAnswer.fromJson(a as Map<String, dynamic>))
            .toList(),
        reflections: (json['reflections'] as List<dynamic>? ?? [])
            .map((r) => Reflection.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  int get daysUntilOpen => openDate.difference(DateTime.now()).inDays;
  bool get isOpenable => DateTime.now().isAfter(openDate);
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
