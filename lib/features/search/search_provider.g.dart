// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchResultsHash() => r'2ff529c21d42cc24d178a811869007cc04a74b74';

/// See also [searchResults].
@ProviderFor(searchResults)
final searchResultsProvider =
    AutoDisposeFutureProvider<List<Screenshot>>.internal(
  searchResults,
  name: r'searchResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SearchResultsRef = AutoDisposeFutureProviderRef<List<Screenshot>>;
String _$searchQueryHash() => r'2c146927785523a0ddf51b23b777a9be4afdc092';

/// See also [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
  SearchQuery.new,
  name: r'searchQueryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$searchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchQuery = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
