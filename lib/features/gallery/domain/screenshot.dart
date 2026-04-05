import 'package:isar/isar.dart';

part 'screenshot.g.dart';

@embedded
class SuggestedAction {
  String? label;
  String? payload;
  String? intentType;
}

@collection
class Screenshot {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, unique: true, replace: true)
  late String filePath;

  @Index()
  late DateTime timestamp;

  @Index(type: IndexType.value, caseSensitive: false)
  String? ocrText;

  @Index(type: IndexType.value, caseSensitive: false)
  String? cleanText;

  List<String>? tags;
  List<String>? urls;
  List<String>? emails;
  List<String>? phoneNumbers;
  List<String>? dates;
  List<String>? cryptoAddresses;
  List<SuggestedAction>? suggestedActions;

  String? actionUrl; // Deprecated, kept for compatibility if needed

  bool isProcessed = false;
}
