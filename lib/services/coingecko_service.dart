import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coin.dart';

class CoinGeckoService {
  static const String baseUrl = 'https://api.coingecko.com/api/v3';

  // Get list of coins with market data
  Future<List<Coin>> getCoinMarkets({
    String vsCurrency = 'usd',
    int perPage = 100,
    int page = 1,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/coins/markets?vs_currency=$vsCurrency&order=market_cap_desc&per_page=$perPage&page=$page&sparkline=false',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((coin) => Coin.fromJson(coin)).toList();
      } else {
        throw Exception('Failed to load coins: ${response.statusCode}');
      }
    } catch (e) {
      print('Get coin markets error: $e');
      rethrow;
    }
  }

  // Get single coin details
  Future<Coin?> getCoinById(String id) async {
    try {
      final url = Uri.parse(
        '$baseUrl/coins/markets?vs_currency=usd&ids=$id',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return Coin.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      print('Get coin by id error: $e');
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
      final url = Uri.parse(
        '$baseUrl/coins/$id/market_chart?vs_currency=$vsCurrency&days=$days',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<List<dynamic>>.from(data['prices']);
      } else {
        throw Exception('Failed to load chart data: ${response.statusCode}');
      }
    } catch (e) {
      print('Get market chart error: $e');
      rethrow;
    }
  }

  // Search coins
  Future<List<Coin>> searchCoins(String query) async {
    try {
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
}
