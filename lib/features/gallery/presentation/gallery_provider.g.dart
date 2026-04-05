// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$galleryStreamHash() => r'b282526a17d31dd040f7251a6856cbf254cb04c5';

/// See also [galleryStream].
@ProviderFor(galleryStream)
final galleryStreamProvider =
    AutoDisposeStreamProvider<List<Screenshot>>.internal(
  galleryStream,
  name: r'galleryStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$galleryStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GalleryStreamRef = AutoDisposeStreamProviderRef<List<Screenshot>>;
String _$uniqueTagsHash() => r'a99832f7e67577cbe96c38fe6964604b237e1465';

/// See also [uniqueTags].
@ProviderFor(uniqueTags)
final uniqueTagsProvider = AutoDisposeStreamProvider<List<String>>.internal(
  uniqueTags,
  name: r'uniqueTagsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$uniqueTagsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UniqueTagsRef = AutoDisposeStreamProviderRef<List<String>>;
String _$selectedTagHash() => r'92447d53e5a3d6776f9c7b886db92c466289f534';

/// See also [SelectedTag].
@ProviderFor(SelectedTag)
final selectedTagProvider =
    AutoDisposeNotifierProvider<SelectedTag, String?>.internal(
  SelectedTag.new,
  name: r'selectedTagProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedTagHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedTag = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
