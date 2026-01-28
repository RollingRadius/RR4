/// Security Question Model
class SecurityQuestionModel {
  final String questionId;
  final String questionText;
  final String category;
  final int displayOrder;

  SecurityQuestionModel({
    required this.questionId,
    required this.questionText,
    required this.category,
    required this.displayOrder,
  });

  factory SecurityQuestionModel.fromJson(Map<String, dynamic> json) {
    return SecurityQuestionModel(
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      category: json['category'] as String,
      displayOrder: json['display_order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'category': category,
      'display_order': displayOrder,
    };
  }

  // Getter for backward compatibility
  String get questionKey => questionId;
}

/// Security Question with Answer (for signup)
class SecurityQuestionAnswer {
  final String questionId;
  final String questionText;
  final String answer;

  SecurityQuestionAnswer({
    required this.questionId,
    required this.questionText,
    required this.answer,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'answer': answer,
    };
  }
}
