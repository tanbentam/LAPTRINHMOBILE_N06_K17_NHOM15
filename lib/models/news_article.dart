class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final DateTime timestamp;
  final String? thumbnailUrl;
  final NewsSource source;
  final String url;
  final String? author;
  final int? upvotes;
  final int? comments;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.timestamp,
    this.thumbnailUrl,
    required this.source,
    required this.url,
    this.author,
    this.upvotes,
    this.comments,
  });

  factory NewsArticle.fromRedditJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    
    return NewsArticle(
      id: data['id'] ?? '',
      title: data['title'] ?? 'No title',
      summary: _extractSummary(data['selftext'] ?? ''),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (data['created_utc'] as num).toInt() * 1000,
      ),
      thumbnailUrl: _getValidThumbnail(data['thumbnail']),
      source: NewsSource.reddit,
      url: 'https://reddit.com${data['permalink']}',
      author: data['author'],
      upvotes: data['ups'],
      comments: data['num_comments'],
    );
  }

  factory NewsArticle.fromCoinGeckoJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'No title',
      summary: json['description'] ?? '',
      timestamp: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      thumbnailUrl: null,
      source: NewsSource.coinGecko,
      url: json['url'] ?? '',
    );
  }

  factory NewsArticle.fromCryptoCompareJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'No title',
      summary: json['body'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['published_on'] as num? ?? 0).toInt() * 1000,
      ),
      thumbnailUrl: json['imageurl'],
      source: NewsSource.cryptoCompare,
      url: json['url'] ?? json['guid'] ?? '',
      author: json['source'],
    );
  }

  static String _extractSummary(String text) {
    if (text.isEmpty) return 'Click to read more...';
    
    // Remove markdown links and formatting
    String cleaned = text
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'[*_~`]'), '')
        .trim();
    
    // Limit to 150 characters
    if (cleaned.length > 150) {
      return '${cleaned.substring(0, 150)}...';
    }
    return cleaned;
  }

  static String? _getValidThumbnail(dynamic thumbnail) {
    if (thumbnail == null || thumbnail is! String) return null;
    if (thumbnail == 'self' || 
        thumbnail == 'default' || 
        thumbnail == 'nsfw' ||
        thumbnail == 'spoiler' ||
        thumbnail.isEmpty) {
      return null;
    }
    return thumbnail;
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

enum NewsSource {
  reddit,
  coinGecko,
  cryptoCompare,
}

extension NewsSourceExtension on NewsSource {
  String get displayName {
    switch (this) {
      case NewsSource.reddit:
        return 'Reddit';
      case NewsSource.coinGecko:
        return 'CoinGecko';
      case NewsSource.cryptoCompare:
        return 'CryptoCompare';
    }
  }

  String get icon {
    switch (this) {
      case NewsSource.reddit:
        return '🔴';
      case NewsSource.coinGecko:
        return '🦎';
      case NewsSource.cryptoCompare:
        return '📰';
    }
  }
}
