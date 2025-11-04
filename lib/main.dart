import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'auth/login_page.dart';
import 'pages/home_page.dart';
import 'pages/market_page.dart';
import 'pages/trade_page.dart';
import 'pages/assets_page.dart';
import 'pages/news_page.dart';
import 'pages/admin_main_dashboard.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/coingecko_service.dart';
import 'services/notification_service.dart';
import 'services/portfolio_service.dart';
import 'services/alert_service.dart';
import 'services/admin_service.dart';

// 🔔 Background message handler (phải là top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background notification: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  // 🔔 Đăng ký background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Notification Service
  try {
    await NotificationService().initialize();
    print('✅ Notification service with FCM initialized');
  } catch (e) {
    print('❌ Notification initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<CoinGeckoService>(create: (_) => CoinGeckoService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<PortfolioService>(create: (_) => PortfolioService()),
        Provider<AlertService>(create: (_) => AlertService()),
        Provider<AdminService>(create: (_) => AdminService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Crypto Trading App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// Auth Wrapper to handle login state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData) {
          return const UserRoleChecker();
        }
        
        return const LoginPage();
      },
    );
  }
}

// Widget để kiểm tra role và điều hướng
class UserRoleChecker extends StatefulWidget {
  const UserRoleChecker({super.key});

  @override
  State<UserRoleChecker> createState() => _UserRoleCheckerState();
}

class _UserRoleCheckerState extends State<UserRoleChecker> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isActive = true;
  
  // Subscription để theo dõi thay đổi
  Stream<UserModel?>? _userStream;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _listenToUserChanges();
  }

  void _listenToUserChanges() {
    final userId = _authService.currentUserId;
    if (userId != null) {
      _userStream = _firestoreService.streamUserData(userId);
      _userStream!.listen((user) {
        if (user != null && !user.isActive && mounted) {
          // Tài khoản bị khóa trong khi đang sử dụng
          _showAccountLockedDialog();
        }
      });
    }
  }

  void _showAccountLockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.red),
            SizedBox(width: 8),
            Text('Tài khoản bị khóa'),
          ],
        ),
        content: const Text(
          'Tài khoản của bạn đã bị khóa bởi quản trị viên.\n'
          'Vui lòng liên hệ hỗ trợ để biết thêm chi tiết.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkUserRole() async {
    try {
      final user = await _adminService.getCurrentUser();
      
      if (user == null) {
        // Nếu không lấy được thông tin user, đăng xuất
        await _authService.signOut();
        return;
      }

      // Kiểm tra tài khoản có bị khóa không
      if (!user.isActive) {
        if (mounted) {
          // Hiển thị thông báo tài khoản bị khóa
          _showAccountLockedDialog();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isAdmin = user.isAdmin;
          _isActive = user.isActive;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Nếu tài khoản không hoạt động, hiển thị màn hình trống
    // (Dialog sẽ hiển thị và đăng xuất)
    if (!_isActive) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Nếu là admin, hiển thị dashboard admin
    if (_isAdmin) {
      return const AdminMainDashboard();
    }

    // Nếu là user thường, hiển thị app chính
    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    MarketPage(),
    NewsPage(),
    TradePage(),
    AssetsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Thị trường'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Tin tức'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Giao dịch'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Tài sản'),
        ],
      ),
    );
  }
}
