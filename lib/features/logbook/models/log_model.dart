import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id;
  final String title;
  final String category;
  final String date;
  final String description;

  LogModel({
    this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.description,
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'],
      category: map['category'],
      date: map['date'],
      description: map['description'],
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      '_id': id?? ObjectId(),
      'title': title,
      'category': category,
      'date': date,
      'description': description,
    };
  }
}
