import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/coin.dart';
import 'fallback_data.dart';

class CoinGeckoService {
  static const String baseUrl = 'https://api.coingecko.com/api/v3';
  
  // Cache để tránh gọi API quá nhiều
  static Map<String, dynamic> _cache = {};
  static Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Đếm số request để tránh rate limit
  static int _requestCount = 0;
  static DateTime _lastResetTime = DateTime.now();
  static const int _maxRequestsPerMinute = 10; // CoinGecko free tier cho phép 10-50 requests/minute
  
  // Kiểm tra và chờ nếu cần thiết để tránh rate limit
  Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    
    // Reset counter mỗi phút
    if (now.difference(_lastResetTime).inMinutes >= 1) {
      _requestCount = 0;
      _lastResetTime = now;
    }
    
    // Nếu đã gọi quá nhiều request, chờ
    if (_requestCount >= _maxRequestsPerMinute) {
      final waitTime = 60 - now.difference(_lastResetTime).inSeconds;
      if (waitTime > 0) {
        print('Rate limit reached, waiting ${waitTime} seconds...');
        await Future.delayed(Duration(seconds: waitTime));
        _requestCount = 0;
        _lastResetTime = DateTime.now();
      }
    }
    
    _requestCount++;
  }
  
  // Kiểm tra cache
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTime.containsKey(key)) {
      return false;
    }
    
    final cacheAge = DateTime.now().difference(_cacheTime[key]!);
    return cacheAge < _cacheDuration;
  }
  
  // Lưu vào cache
  void _saveToCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTime[key] = DateTime.now();
  }
  
  // Gọi API với retry logic
  Future<http.Response> _makeRequest(Uri url, {int maxRetries = 3}) async {
    await _checkRateLimit();
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.get(url).timeout(
          const Duration(seconds: 10),
        );
        
        if (response.statusCode == 429) {
          // Rate limited, chờ lâu hơn
          final waitTime = attempt * 30; // 30s, 60s, 90s
          print('Rate limited (429), waiting ${waitTime} seconds before retry $attempt/$maxRetries');
          await Future.delayed(Duration(seconds: waitTime));
          continue;
        }
        
        return response;
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
        
        print('Request failed (attempt $attempt/$maxRetries): $e');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    throw Exception('Failed after $maxRetries attempts');
  }

  // Get list of coins with market data
  Future<List<Coin>> getCoinMarkets({
    String vsCurrency = 'usd',
    int perPage = 100,
    int page = 1,
  }) async {
    try {
      final cacheKey = 'coins_markets_${vsCurrency}_${perPage}_$page';
      
      // Kiểm tra cache trước
      if (_isCacheValid(cacheKey)) {
        print('Loading coins from cache');
        final List<dynamic> cachedData = _cache[cacheKey];
        return cachedData.map((coin) => Coin.fromJson(coin)).toList();
      }
      
      final url = Uri.parse(
        '$baseUrl/coins/markets?vs_currency=$vsCurrency&order=market_cap_desc&per_page=$perPage&page=$page&sparkline=false',
      );
      
      final response = await _makeRequest(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Lưu vào cache
        _saveToCache(cacheKey, data);
        
        return data.map((coin) => Coin.fromJson(coin)).toList();
      } else {
        throw Exception('Failed to load coins: ${response.statusCode}');
      }
    } catch (e) {
      print('Get coin markets error: $e');
      
      // Nếu có lỗi, thử trả về data từ cache cũ nếu có
      final cacheKey = 'coins_markets_${vsCurrency}_${perPage}_$page';
      if (_cache.containsKey(cacheKey)) {
        print('Returning stale cache data due to error');
        final List<dynamic> cachedData = _cache[cacheKey];
        return cachedData.map((coin) => Coin.fromJson(coin)).toList();
      }
      
      // Nếu không có cache, trả về fallback data
      if (e.toString().contains('429') || e.toString().contains('Failed host lookup')) {
        print('Using fallback data due to API error: $e');
        return FallbackData.getBasicCoins();
      }
      
      rethrow;
    }
  }

  // Get single coin details
  Future<Coin?> getCoinById(String id) async {
    try {
      final cacheKey = 'coin_$id';
      
      // Kiểm tra cache trước
      if (_isCacheValid(cacheKey)) {
        print('Loading coin $id from cache');
        return Coin.fromJson(_cache[cacheKey]);
      }
      
      final url = Uri.parse(
        '$baseUrl/coins/markets?vs_currency=usd&ids=$id',
      );
      
      final response = await _makeRequest(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          _saveToCache(cacheKey, data[0]);
          return Coin.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      print('Get coin by id error: $e');
      
      // Thử trả về cache cũ nếu có
      final cacheKey = 'coin_$id';
      if (_cache.containsKey(cacheKey)) {
        print('Returning stale cache data for coin $id due to error');
        return Coin.fromJson(_cache[cacheKey]);
      }
      
      return null;
    }
  }

  // Get market chart data (for charts)
  Future<List<List<dynamic>>> getMarketChart({
    required String id,
    String vsCurrency = 'usd',
    int days = 1,
  }) async {
    try {
      final cacheKey = 'chart_${id}_${vsCurrency}_$days';
      
      // Kiểm tra cache trước
      if (_isCacheValid(cacheKey)) {
        print('Loading chart for $id from cache');
        return List<List<dynamic>>.from(_cache[cacheKey]);
      }
      
      final url = Uri.parse(
        '$baseUrl/coins/$id/market_chart?vs_currency=$vsCurrency&days=$days',
      );
      
      final response = await _makeRequest(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final chartData = List<List<dynamic>>.from(data['prices']);
        
        // Lưu vào cache
        _saveToCache(cacheKey, chartData);
        
        return chartData;
      } else {
        throw Exception('Failed to load chart data: ${response.statusCode}');
      }
    } catch (e) {
      print('Get market chart error: $e');
      
      // Thử trả về cache cũ
      final cacheKey = 'chart_${id}_${vsCurrency}_$days';
      if (_cache.containsKey(cacheKey)) {
        print('Returning stale chart cache for $id due to error');
        return List<List<dynamic>>.from(_cache[cacheKey]);
      }
      
      rethrow;
    }
  }

  // Search coins
  Future<List<Coin>> searchCoins(String query) async {
    try {
      // Sử dụng cache từ getCoinMarkets thay vì gọi API mới
      final coins = await getCoinMarkets(perPage: 250);
      return coins.where((coin) {
        return coin.name.toLowerCase().contains(query.toLowerCase()) ||
            coin.symbol.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Search coins error: $e');
      return [];
    }
  }
  
  // Phương thức để xóa cache khi cần
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
    print('Cache cleared');
  }
  
  // Phương thức để lấy thông tin cache
  static Map<String, String> getCacheInfo() {
    return {
      'total_entries': _cache.length.toString(),
      'oldest_entry': _cacheTime.values.isEmpty 
          ? 'None' 
          : _cacheTime.values.reduce((a, b) => a.isBefore(b) ? a : b).toString(),
      'newest_entry': _cacheTime.values.isEmpty 
          ? 'None' 
          : _cacheTime.values.reduce((a, b) => a.isAfter(b) ? a : b).toString(),
    };
  }
}
