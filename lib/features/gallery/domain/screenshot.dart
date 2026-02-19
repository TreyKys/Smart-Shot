import 'package:isar/isar.dart';

part 'screenshot.g.dart';

@collection
class Screenshot {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, unique: true, replace: true)
  late String filePath;

  @Index()
  late DateTime timestamp;

  @Index(type: IndexType.value, caseSensitive: false)
  String? ocrText;

  List<String>? tags;

  String? actionUrl;

  bool isProcessed = false;
}
