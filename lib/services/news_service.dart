import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

class NewsService {
  static const String _redditBaseUrl = 'https://www.reddit.com';
  static const String _coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  
  // Cache để giảm số lần gọi API
  static DateTime? _lastRedditFetch;
  static List<NewsArticle>? _cachedRedditNews;
  static DateTime? _lastCoinGeckoFetch;
  static List<NewsArticle>? _cachedCoinGeckoNews;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Lấy tin tức từ Reddit r/CryptoCurrency
  static Future<List<NewsArticle>> fetchRedditNews({
    String subreddit = 'CryptoCurrency',
    int limit = 25,
    bool forceRefresh = false,
  }) async {
    // Kiểm tra cache
    if (!forceRefresh && 
        _cachedRedditNews != null && 
        _lastRedditFetch != null &&
        DateTime.now().difference(_lastRedditFetch!) < _cacheDuration) {
      return _cachedRedditNews!;
    }

    try {
      final url = Uri.parse(
        '$_redditBaseUrl/r/$subreddit/hot.json?limit=$limit',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CryptoPortfolioApp/1.0',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final posts = data['data']['children'] as List;

        final articles = posts
            .map((post) {
              try {
                return NewsArticle.fromRedditJson(post);
              } catch (e) {
                print('Error parsing Reddit post: $e');
                return null;
              }
            })
            .whereType<NewsArticle>()
            .toList();

        // Lưu vào cache
        _cachedRedditNews = articles;
        _lastRedditFetch = DateTime.now();

        return articles;
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again later.');
      } else {
        throw Exception('Failed to load Reddit news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching Reddit news: $e');
      // Trả về cache cũ nếu có
      if (_cachedRedditNews != null) {
        return _cachedRedditNews!;
      }
      rethrow;
    }
  }

  /// Lấy tin tức từ CoinGecko Status Updates
  static Future<List<NewsArticle>> fetchCoinGeckoNews({
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    // Kiểm tra cache
    if (!forceRefresh && 
        _cachedCoinGeckoNews != null && 
        _lastCoinGeckoFetch != null &&
        DateTime.now().difference(_lastCoinGeckoFetch!) < _cacheDuration) {
      return _cachedCoinGeckoNews!;
    }

    try {
      final url = Uri.parse(
        '$_coinGeckoBaseUrl/status_updates?per_page=$limit',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updates = data['status_updates'] as List;

        final articles = updates
            .map((update) {
              try {
                return NewsArticle.fromCoinGeckoJson(update);
              } catch (e) {
                print('Error parsing CoinGecko update: $e');
                return null;
              }
            })
            .whereType<NewsArticle>()
            .toList();

        // Lưu vào cache
        _cachedCoinGeckoNews = articles;
        _lastCoinGeckoFetch = DateTime.now();

        return articles;
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again later.');
      } else {
        throw Exception('Failed to load CoinGecko news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching CoinGecko news: $e');
      // Trả về cache cũ nếu có
      if (_cachedCoinGeckoNews != null) {
        return _cachedCoinGeckoNews!;
      }
      rethrow;
    }
  }

  /// Lấy tất cả tin tức từ nhiều nguồn
  static Future<List<NewsArticle>> fetchAllNews({
    bool forceRefresh = false,
  }) async {
    try {
      final results = await Future.wait([
        fetchRedditNews(forceRefresh: forceRefresh),
        fetchCoinGeckoNews(forceRefresh: forceRefresh),
      ]);

      final allNews = [...results[0], ...results[1]];
      
      // Sắp xếp theo thời gian mới nhất
      allNews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return allNews;
    } catch (e) {
      print('Error fetching all news: $e');
      rethrow;
    }
  }

  /// Lấy tin tức theo loại (Market hoặc Social)
  static Future<List<NewsArticle>> fetchNewsByType({
    required NewsType type,
    bool forceRefresh = false,
  }) async {
    switch (type) {
      case NewsType.market:
        return fetchCoinGeckoNews(forceRefresh: forceRefresh);
      case NewsType.social:
        return fetchRedditNews(forceRefresh: forceRefresh);
    }
  }

  /// Xóa cache
  static void clearCache() {
    _cachedRedditNews = null;
    _lastRedditFetch = null;
    _cachedCoinGeckoNews = null;
    _lastCoinGeckoFetch = null;
  }
}

enum NewsType {
  market,
  social,
}
