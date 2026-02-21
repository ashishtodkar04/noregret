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

  // For persistence if needed later
  Map<String, dynamic> toMap() => {
    'text': text,
    'author': author,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Quote.fromMap(Map<String, dynamic> map) => Quote(
    text: map['text'],
    author: map['author'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}