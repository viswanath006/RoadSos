class FirstAidGuide {
  const FirstAidGuide({
    required this.id,
    required this.title,
    required this.category,
    required this.steps,
    required this.disclaimer,
  });

  final String id;
  final String title;
  final String category;
  final List<String> steps;
  final String disclaimer;

  FirstAidGuide copyWith({
    String? id,
    String? title,
    String? category,
    List<String>? steps,
    String? disclaimer,
  }) {
    return FirstAidGuide(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      steps: steps ?? this.steps,
      disclaimer: disclaimer ?? this.disclaimer,
    );
  }
}
