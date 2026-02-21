class Quote {
  final String text;
  final String author;
  final DateTime createdAt;

  Quote({
    required this.text,
    required this.author,
    required this.createdAt,
  });

  int get wordCount => text.split(' ').length;

  String get displayAuthor => author.isEmpty ? "Unknown" : "- $author";

  int get typingDurationMs => (wordCount * 150).clamp(1000, 5000);

  Quote copyWith({
    String? text,
    String? author,
    DateTime? createdAt,
  }) {
    return Quote(
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
