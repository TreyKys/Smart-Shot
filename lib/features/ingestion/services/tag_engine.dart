import 'dart:io';
import 'package:flutter/foundation.dart';

/// Local keyword-scoring tag engine.
/// Runs entirely on-device with no network calls.
/// Acts as a safety net when AI returns zero tags and deduplicates/normalises
/// the combined AI + local tag set.
class TagEngine {
  TagEngine._();

  static const Map<String, List<String>> _categories = {
    '#Finance': [
      'bank', 'account', 'balance', 'transaction', 'transfer', 'wire',
      'invoice', 'payment', 'receipt', 'total', 'subtotal', 'tax', 'vat',
      'paypal', 'stripe', 'venmo', 'cashapp', 'zelle', 'visa', 'mastercard',
      'amex', 'credit card', 'debit card', 'statement', 'interest rate',
      'loan', 'mortgage', 'salary', 'paycheck', 'deposit', 'withdrawal',
      'iban', 'swift', 'routing number', 'account number', r'$', '£', '€', '¥',
    ],
    '#Receipts': [
      'receipt', 'order #', 'order number', 'subtotal', 'grand total', 'qty',
      'quantity', 'cashier', 'thank you for your purchase', 'store',
      'register', 'change due', 'cash tendered', 'items purchased',
    ],
    '#Web3': [
      '0x', 'bitcoin', 'btc', 'ethereum', 'eth', 'solana', 'sol', 'bnb',
      'polygon', 'matic', 'defi', 'nft', 'token', 'wallet', 'metamask',
      'seed phrase', 'private key', 'public key', 'gas fee', 'gwei',
      'opensea', 'uniswap', 'aave', 'compound', 'staking', 'yield',
      'dao', 'smart contract', 'web3', 'dapp', 'txhash', 'block explorer',
      'coinbase', 'binance', 'kraken', 'bybit', 'okx', 'ledger', 'trezor',
    ],
    '#TradingCharts': [
      'candlestick', 'rsi', 'macd', 'bollinger', 'support', 'resistance',
      'moving average', 'ema', 'sma', 'fibonacci', 'chart', 'bullish',
      'bearish', 'long position', 'short position', 'stop loss', 'take profit',
      'tradingview', 'ticker', 'volume', 'market cap', 'order book',
      'bid', 'ask', 'spread', 'liquidation', 'futures', 'options', 'leverage',
    ],
    '#Code': [
      'function', 'const ', 'var ', 'let ', 'import ', 'export ', 'class ',
      'struct', 'if (', 'else {', 'for (', 'while (', 'return ', 'null',
      'undefined', 'github', 'gitlab', 'commit', 'pull request', 'merge',
      'branch', 'def ', 'print(', 'console.log', '#!/', '```', 'async',
      'await', 'promise', 'callback', 'api', 'endpoint', 'stack overflow',
      'terminal', 'bash', 'python', 'javascript', 'dart', 'flutter',
      'error:', 'exception', 'traceback', 'npm', 'gradle', 'xcode',
    ],
    '#SocialMedia': [
      'instagram', 'twitter', 'x.com', 'tiktok', 'facebook', 'youtube',
      'snapchat', 'linkedin', 'reddit', 'pinterest', 'threads', 'telegram',
      'whatsapp', 'discord', 'followers', 'following', 'likes', 'retweet',
      'story', 'reel', 'subscribe', 'notification', 'mention',
    ],
    '#Memes': [
      'meme', 'lol', 'lmao', 'rofl', 'bruh', 'based', 'cringe', 'ratio',
      'slay', 'no cap', 'fr fr', 'bussin', 'lowkey', 'highkey', 'ngl',
      'smh', 'facepalm', 'when you', 'me when', 'nobody:',
    ],
    '#Travel': [
      'flight', 'boarding pass', 'gate', 'airline', 'airport', 'passport',
      'visa', 'hotel', 'check-in', 'checkout', 'reservation', 'booking',
      'airbnb', 'booking.com', 'expedia', 'itinerary',
      'departure', 'arrival', 'terminal', 'baggage', 'seat number',
    ],
    '#Health': [
      'doctor', 'patient', 'diagnosis', 'prescription', 'medication', 'dosage',
      ' mg', 'pill', 'tablet', 'symptom', 'blood pressure', 'glucose',
      'heart rate', 'bpm', 'workout', 'exercise', 'hospital', 'clinic',
      'pharmacy', 'appointment', 'insurance', 'medical', 'nutrition', 'sleep',
    ],
    '#Education': [
      'lecture', 'course', 'syllabus', 'assignment', 'homework', 'exam',
      'quiz', 'grade', 'university', 'college', 'school', 'student',
      'professor', 'textbook', 'chapter', 'lesson', 'learning', 'study',
      'coursera', 'udemy', 'khan academy', 'duolingo', 'research', 'thesis',
    ],
    '#Shopping': [
      'amazon', 'ebay', 'etsy', 'shopify', 'cart', 'checkout', 'order',
      'shipping', 'delivery', 'tracking', 'return', 'refund', 'discount',
      'coupon', 'promo code', 'sale', 'wishlist', 'add to cart',
    ],
    '#Food': [
      'restaurant', 'menu', 'recipe', 'ingredient', 'ubereats', 'doordash',
      'grubhub', 'delivery', 'pizza', 'burger', 'coffee', 'breakfast',
      'lunch', 'dinner', 'dessert', 'calories per serving',
    ],
    '#News': [
      'breaking news', 'reuters', 'bbc', 'cnn', 'the guardian', 'headline',
      'report', 'journalist', 'article', 'published', 'editor', 'press',
      'according to', 'spokesperson', 'government', 'policy', 'election',
    ],
    '#Legal': [
      'terms of service', 'privacy policy', 'agreement', 'contract', 'clause',
      'liability', 'indemnify', 'arbitration', 'jurisdiction', 'plaintiff',
      'defendant', 'court', 'lawsuit', 'attorney', 'notary',
      'gdpr', 'copyright', 'trademark', 'patent', 'dmca',
    ],
    '#Entertainment': [
      'netflix', 'spotify', 'apple music', 'hulu', 'disney+', 'movie',
      'episode', 'season', 'trailer', 'review', 'rating', 'concert',
      'ticket', 'event', 'festival', 'stream',
    ],
    '#Gaming': [
      'game', 'player', 'score', 'level', 'achievement', 'leaderboard',
      'steam', 'xbox', 'playstation', 'nintendo', 'twitch', 'fps', 'rpg',
      'quest', 'mission', 'respawn', 'health bar', 'inventory',
    ],
    '#Productivity': [
      'todo', 'to-do', 'task', 'checklist', 'deadline', 'reminder',
      'calendar', 'schedule', 'meeting', 'agenda', 'notion',
      'trello', 'jira', 'slack', 'asana', 'note',
    ],
    '#Memories': [
      'birthday', 'anniversary', 'wedding', 'graduation', 'party',
      'vacation', 'trip', 'family', 'friends', 'celebration',
    ],
  };

  /// Score OCR text against all categories and return best-matching tags.
  static List<String> suggestFromOcr(String ocrText) {
    if (ocrText.trim().isEmpty) return [];
    final lower = ocrText.toLowerCase();

    final scores = <String, int>{};
    for (final entry in _categories.entries) {
      var score = 0;
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) score++;
      }
      if (score > 0) scores[entry.key] = score;
    }

    if (scores.isEmpty) return [];

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topScore = sorted.first.value;
    return sorted
        .where((e) => e.value >= 2 || (e.value >= 1 && e.key == sorted.first.key))
        .take(3)
        .map((e) => e.key)
        .toList();
  }

  /// Returns true if the image is likely junk (blank/dark/corrupted screen).
  static bool isLikelyJunk(String ocrText, File file) {
    final textLen = ocrText.trim().length;
    if (textLen < 3) return true;
    if (textLen < 10) {
      try {
        if (file.lengthSync() < 30 * 1024) return true;
      } catch (_) {}
    }
    return false;
  }

  /// Merge AI tags and local tags, deduplicating case-insensitively.
  /// AI tags take precedence and appear first.
  /// Local tags are only appended when AI returned fewer than 2 tags —
  /// avoids false positives when AI already has high-confidence results.
  /// Total capped at 5.
  static List<String> merge(List<String> aiTags, List<String> localTags) {
    final seen = <String>{};
    final result = <String>[];

    for (final tag in aiTags) {
      final norm = normalize(tag);
      if (norm.isEmpty) continue;
      if (seen.add(norm.toLowerCase())) result.add(norm);
    }

    if (aiTags.length < 2) {
      for (final tag in localTags) {
        final norm = normalize(tag);
        if (norm.isEmpty) continue;
        if (seen.add(norm.toLowerCase())) result.add(norm);
      }
    }

    return result.take(5).toList();
  }

  /// Ensures a tag has a '#' prefix and is non-empty after trimming.
  static String normalize(String tag) {
    final t = tag.trim();
    if (t.isEmpty) return '';
    return t.startsWith('#') ? t : '#$t';
  }
}
