import 'package:flutter/material.dart';
import '../services/coingecko_service.dart';
import '../services/fallback_data.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Map<String, String> cacheInfo = {};
  String apiStatus = 'Chưa kiểm tra';
  bool isTestingApi = false;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  void _loadCacheInfo() {
    setState(() {
      cacheInfo = CoinGeckoService.getCacheInfo();
    });
  }

  Future<void> _testApi() async {
    setState(() {
      isTestingApi = true;
      apiStatus = 'Đang kiểm tra...';
    });

    try {
      final service = CoinGeckoService();
      final coins = await service.getCoinMarkets(perPage: 5);
      
      if (mounted) {
        setState(() {
          apiStatus = 'API hoạt động bình thường (${coins.length} coins)';
          isTestingApi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('429')) {
            apiStatus = 'API bị rate limit (429) - Sử dụng cache/fallback';
          } else if (e.toString().contains('Failed host lookup')) {
            apiStatus = 'Không có kết nối internet';
          } else {
            apiStatus = 'Lỗi API: ${e.toString()}';
          }
          isTestingApi = false;
        });
      }
    }
    
    _loadCacheInfo();
  }

  void _clearCache() {
    CoinGeckoService.clearCache();
    _loadCacheInfo();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache đã được xóa')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Debug & Cache Info'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trạng thái API',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(apiStatus),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isTestingApi ? null : _testApi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD400),
                          foregroundColor: Colors.black,
                        ),
                        child: isTestingApi
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Text('Kiểm tra API'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cache Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Thông tin Cache',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearCache,
                          child: const Text('Xóa Cache'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...cacheInfo.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Fallback Data Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dữ liệu Fallback',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Số lượng coins: ${FallbackData.getBasicCoins().length}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Fallback data sẽ được sử dụng khi:\n'
                      '• API trả về lỗi 429 (rate limit)\n'
                      '• Không có kết nối internet\n'
                      '• Không có cache cũ khả dụng',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Rate Limiting Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate Limiting',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CoinGecko Free API giới hạn:\n'
                      '• 10-50 requests/phút\n'
                      '• Cache tự động 5 phút\n'
                      '• Retry với backoff khi lỗi 429',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}