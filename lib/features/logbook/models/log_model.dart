class LogModel {
  final String title;
  final String category;
  final String date;
  final String description;

  LogModel({
    required this.title,
    required this.category,
    required this.date,
    required this.description,
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'],
      category: map['category'],
      date: map['date'],
      description: map['description'],
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'date': date,
      'description': description,
    };
  }
}