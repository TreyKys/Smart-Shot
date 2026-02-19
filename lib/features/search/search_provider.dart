import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_shot/core/database/isar_service.dart';
import 'package:smart_shot/features/gallery/domain/screenshot.dart';

part 'search_provider.g.dart';

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

@riverpod
Future<List<Screenshot>> searchResults(SearchResultsRef ref) async {
  final query = ref.watch(searchQueryProvider);
  final isar = await ref.watch(isarProvider.future);

  if (query.trim().isEmpty) {
    return [];
  }

  final terms = query.trim().split(RegExp(r'\s+'));
  if (terms.isEmpty) return [];

  final firstTerm = terms.first;

  // Search across OCR text, clean text, and tags
  var candidates = await isar.screenshots
      .filter()
      .group((q) => q
          .ocrTextContains(firstTerm, caseSensitive: false)
          .or()
          .cleanTextContains(firstTerm, caseSensitive: false)
          .or()
          .tagsElementContains(firstTerm, caseSensitive: false))
      .sortByTimestampDesc()
      .findAll();

  // Filter in memory for remaining terms
  if (terms.length > 1) {
    final remainingTerms = terms.sublist(1);
    candidates = candidates.where((s) {
      final ocr = s.ocrText?.toLowerCase() ?? '';
      final clean = s.cleanText?.toLowerCase() ?? '';
      final tags = s.tags?.map((t) => t.toLowerCase()).join(' ') ?? '';

      // Combine all searchable text for checking
      final combined = "$ocr $clean $tags";

      return remainingTerms.every((term) => combined.contains(term.toLowerCase()));
    }).toList();
  }

  return candidates;
}
