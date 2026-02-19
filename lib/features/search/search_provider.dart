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

  // For MVP, perform a case-insensitive contains search on the full query string.
  // This supports "Wifi Password" if they appear adjacent.
  // To support "Wifi ... Password", we need more complex filtering.
  // Attempting to filter by multiple terms if they are separated.

  final terms = query.trim().split(RegExp(r'\s+'));

  // If we have multiple terms, we can try to filter for the first one,
  // then filter the list in Dart for the rest. This is efficient enough for 1000 items.

  if (terms.isEmpty) return [];

  final firstTerm = terms.first;

  // Fetch candidates that match the first term
  var candidates = await isar.screenshots
      .filter()
      .ocrTextContains(firstTerm, caseSensitive: false)
      .sortByTimestampDesc()
      .findAll();

  // Filter in memory for remaining terms
  if (terms.length > 1) {
    final remainingTerms = terms.sublist(1);
    candidates = candidates.where((s) {
      final text = s.ocrText?.toLowerCase() ?? '';
      return remainingTerms.every((term) => text.contains(term.toLowerCase()));
    }).toList();
  }

  return candidates;
}
