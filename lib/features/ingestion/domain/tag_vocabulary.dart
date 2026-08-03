/// The single closed set of tags the app recognises.
///
/// Both the local [TagEngine] and the Gemini response schema draw from this
/// list, so a tag can never come back that the gallery has no filter for.
///
/// The previous prompt shipped an open-ended list that invited the model to
/// "invent precise variants", and the list itself contained near-duplicates
/// (#Receipt vs #Receipts) and heavy overlap (#Crypto / #Web3 / #NFT / #DeFi).
/// That produces a tag drawer that grows without bound and never groups
/// anything usefully. Specificity now lives in [Screenshot.topic] instead,
/// which is searchable free text rather than a filter facet.
class TagVocabulary {
  TagVocabulary._();

  /// Content categories, ordered roughly by how often they occur.
  static const List<String> tags = [
    '#Finance',
    '#Receipts',
    '#Web3',
    '#TradingCharts',
    '#Code',
    '#SocialMedia',
    '#Memes',
    '#Travel',
    '#Health',
    '#Education',
    '#Shopping',
    '#Food',
    '#News',
    '#Legal',
    '#Entertainment',
    '#Gaming',
    '#Productivity',
    '#Memories',
    '#Junk',
  ];

  /// Bare names without the leading '#', for schema enums.
  static List<String> get bareNames =>
      tags.map((t) => t.substring(1)).toList(growable: false);

  static final Set<String> _lookup = {
    for (final t in tags) t.toLowerCase(),
  };

  /// Maps historical / model-invented tags onto the closed set. Anything not
  /// listed and not already valid is dropped rather than shown to the user.
  static const Map<String, String> _aliases = {
    '#receipt': '#Receipts',
    '#invoice': '#Receipts',
    '#crypto': '#Web3',
    '#nft': '#Web3',
    '#defi': '#Web3',
    '#personalfinance': '#Finance',
    '#portfolio': '#Finance',
    '#fitness': '#Health',
    '#medical': '#Health',
    '#to-do': '#Productivity',
    '#todo': '#Productivity',
    // The old prompt banned these but the model emitted them anyway; they all
    // mean the same thing as #Junk.
    '#blankimage': '#Junk',
    '#empty': '#Junk',
    '#nocontent': '#Junk',
    '#unknown': '#Junk',
    '#blank': '#Junk',
    // Every image here is a screenshot, so the tag carries no information.
    '#screenshot': '',
  };

  /// Normalises a single tag onto the closed vocabulary.
  /// Returns an empty string when the tag has no valid mapping.
  static String canonical(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return '';
    if (!t.startsWith('#')) t = '#$t';
    final lower = t.toLowerCase();

    if (_lookup.contains(lower)) {
      // Return the canonical casing rather than whatever the model sent.
      return tags.firstWhere((v) => v.toLowerCase() == lower);
    }
    return _aliases[lower] ?? '';
  }

  /// Normalises a list, dropping unmappable entries and duplicates while
  /// preserving order.
  static List<String> canonicalize(Iterable<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final t in raw) {
      final c = canonical(t);
      if (c.isEmpty) continue;
      if (seen.add(c)) out.add(c);
    }
    return out;
  }
}
