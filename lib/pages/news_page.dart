import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import 'news_detail_page.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<NewsArticle> _marketNews = [];
  List<NewsArticle> _socialNews = [];
  
  bool _isLoadingMarket = true;
  bool _isLoadingSocial = true;
  
  String? _errorMarket;
  String? _errorSocial;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNews({bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() {
        _isLoadingMarket = true;
        _isLoadingSocial = true;
        _errorMarket = null;
        _errorSocial = null;
      });
    }

    // Load Market News
    _loadMarketNews(forceRefresh: forceRefresh);
    
    // Load Social News
    _loadSocialNews(forceRefresh: forceRefresh);
  }

  Future<void> _loadMarketNews({bool forceRefresh = false}) async {
    try {
      final news = await NewsService.fetchNewsByType(
        type: NewsType.market,
        forceRefresh: forceRefresh,
      );
      
      if (mounted) {
        setState(() {
          _marketNews = news;
          _isLoadingMarket = false;
          _errorMarket = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMarket = false;
          _errorMarket = e.toString();
        });
      }
    }
  }

  Future<void> _loadSocialNews({bool forceRefresh = false}) async {
    try {
      final news = await NewsService.fetchNewsByType(
        type: NewsType.social,
        forceRefresh: forceRefresh,
      );
      
      if (mounted) {
        setState(() {
          _socialNews = news;
          _isLoadingSocial = false;
          _errorSocial = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSocial = false;
          _errorSocial = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tin Tức Crypto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.trending_up),
              text: 'Market News',
            ),
            Tab(
              icon: Icon(Icons.forum),
              text: 'Social News',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Market News Tab
          _buildNewsTab(
            news: _marketNews,
            isLoading: _isLoadingMarket,
            error: _errorMarket,
            onRefresh: () => _loadMarketNews(forceRefresh: true),
            emptyMessage: 'Không có tin tức market',
          ),
          
          // Social News Tab
          _buildNewsTab(
            news: _socialNews,
            isLoading: _isLoadingSocial,
            error: _errorSocial,
            onRefresh: () => _loadSocialNews(forceRefresh: true),
            emptyMessage: 'Không có tin tức social',
          ),
        ],
      ),
    );
  }

  Widget _buildNewsTab({
    required List<NewsArticle> news,
    required bool isLoading,
    required String? error,
    required Future<void> Function() onRefresh,
    required String emptyMessage,
  }) {
    if (isLoading && news.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null && news.isEmpty) {
      return _buildErrorWidget(error, onRefresh);
    }

    if (news.isEmpty) {
      return _buildEmptyWidget(emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: news.length,
        itemBuilder: (context, index) {
          return _buildNewsCard(news[index]);
        },
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(article: article),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail (nếu có)
            if (article.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: article.thumbnailUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSourceColor(article.source),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              article.source.icon,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              article.source.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        article.getTimeAgo(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Summary
                  Text(
                    article.summary,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Author & Stats (Reddit only)
                  if (article.source == NewsSource.reddit) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (article.author != null) ...[
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'u/${article.author}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Icon(Icons.arrow_upward, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${article.upvotes ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.comment, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${article.comments ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, Future<void> Function() onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi khi tải tin tức',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.contains('timeout') 
                  ? 'Kết nối bị timeout. Vui lòng kiểm tra mạng.'
                  : error.contains('Too many requests')
                      ? 'Quá nhiều yêu cầu. Vui lòng thử lại sau.'
                      : 'Vui lòng kiểm tra kết nối mạng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(NewsSource source) {
    switch (source) {
      case NewsSource.reddit:
        return Colors.orange;
      case NewsSource.coinGecko:
        return Colors.green;
    }
  }
}
