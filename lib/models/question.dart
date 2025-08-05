import 'dart:convert';

class Question {
  final String id;
  final String question;
  final List<String> options;
  final bool allowMultiple;
  final int? maxSelections;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.allowMultiple,
    this.maxSelections,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      allowMultiple: json['allow_multiple'],
      maxSelections: json['max_selections'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'allow_multiple': allowMultiple,
      'max_selections': maxSelections,
    };
  }

  static List<Question> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Question.fromJson(json)).toList();
  }
}
