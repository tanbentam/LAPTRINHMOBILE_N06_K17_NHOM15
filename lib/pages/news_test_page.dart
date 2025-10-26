import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../models/news_article.dart';

/// Page để test News Service nhanh
/// Sử dụng: Thêm vào navigation hoặc gọi trực tiếp để debug
class NewsTestPage extends StatefulWidget {
  const NewsTestPage({super.key});

  @override
  State<NewsTestPage> createState() => _NewsTestPageState();
}

class _NewsTestPageState extends State<NewsTestPage> {
  bool _isLoading = false;
  String _status = 'Chưa test';
  List<NewsArticle> _results = [];
  String? _error;

  Future<void> _testReddit() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang test Reddit API...';
      _error = null;
      _results = [];
    });

    try {
      final news = await NewsService.fetchRedditNews(forceRefresh: true);
      setState(() {
        _status = '✅ Thành công! Nhận được ${news.length} bài viết';
        _results = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Lỗi';
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testCoinGecko() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang test CoinGecko API...';
      _error = null;
      _results = [];
    });

    try {
      final news = await NewsService.fetchCoinGeckoNews(forceRefresh: true);
      setState(() {
        _status = '✅ Thành công! Nhận được ${news.length} bài viết';
        _results = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Lỗi';
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testAll() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang test cả 2 API...';
      _error = null;
      _results = [];
    });

    try {
      final news = await NewsService.fetchAllNews(forceRefresh: true);
      setState(() {
        _status = '✅ Thành công! Nhận được ${news.length} bài viết tổng';
        _results = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Lỗi';
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Service Tester'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              color: _error != null 
                  ? Colors.red[50] 
                  : _results.isNotEmpty 
                      ? Colors.green[50] 
                      : Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Icon(
                        _error != null 
                            ? Icons.error 
                            : _results.isNotEmpty 
                                ? Icons.check_circle 
                                : Icons.info,
                        size: 48,
                        color: _error != null 
                            ? Colors.red 
                            : _results.isNotEmpty 
                                ? Colors.green 
                                : Colors.blue,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testReddit,
              icon: const Text('🔴', style: TextStyle(fontSize: 20)),
              label: const Text('Test Reddit API'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCoinGecko,
              icon: const Text('🦎', style: TextStyle(fontSize: 20)),
              label: const Text('Test CoinGecko API'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAll,
              icon: const Icon(Icons.all_inclusive),
              label: const Text('Test Cả Hai'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Results
            if (_results.isNotEmpty) ...[
              const Text(
                'Kết quả (5 bài đầu):',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length > 5 ? 5 : _results.length,
                  itemBuilder: (context, index) {
                    final article = _results[index];
                    return Card(
                      child: ListTile(
                        leading: Text(
                          article.source.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          article.getTimeAgo(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: article.thumbnailUrl != null
                            ? const Icon(Icons.image, color: Colors.green)
                            : const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
