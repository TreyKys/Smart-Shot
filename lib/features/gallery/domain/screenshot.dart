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

  /// Short specific subject line, e.g. "Uber receipt, 12 Mar".
  ///
  /// Deliberately separate from [tags]: tags are a closed vocabulary so the
  /// gallery can offer stable filters, while this is free text the model may
  /// phrase however it likes. Searchable, never a filter facet.
  @Index(type: IndexType.value, caseSensitive: false)
  String? topic;

  List<String>? tags;
  List<String>? urls;
  List<String>? emails;
  List<String>? phoneNumbers;
  List<String>? dates;
  List<String>? cryptoAddresses;
  List<SuggestedAction>? suggestedActions;

  String? actionUrl; // Deprecated, kept for compatibility if needed

  /// Perceptual dHash fingerprint — stored in SharedPreferences, not Isar
  @ignore
  String? perceptualHash;

  /// File size in bytes — computed on demand, not persisted in Isar
  @ignore
  int? fileSizeBytes;

  bool isProcessed = false;
}
