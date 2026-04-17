import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive/hive.dart';

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  String? id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final String date;
  @HiveField(4)
  final String description;
  @HiveField(5)
  final String authorId;
  @HiveField(6)
  final String teamId;
  @HiveField(7)
  final bool isPublic;


  LogModel({
    this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.description,
    required this.authorId,
    required this.teamId,
    required this.isPublic,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'],
      category: map['category'],
      date: map['date'],
      description: map['description'],
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? true,
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
      'title': title,
      'category': category,
      'date': date,
      'description': description,
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic,
    };
  }
}
