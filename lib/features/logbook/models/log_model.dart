import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final ObjectId? id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final String date;
  @HiveField(5)
  final String description;
  @HiveField(6)
  final String authorId; 
  @HiveField(7)
  final String teamId; 

  LogModel({
    this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.description,
    required this.authorId,
    required this.teamId,
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'],
      category: map['category'],
      date: map['date'],
      description: map['description'],
      authorId: map['authorID'],
      teamId: map['teamId'],
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
      'authorID': authorId,
      'teamId': teamId,
    };
  }
}
