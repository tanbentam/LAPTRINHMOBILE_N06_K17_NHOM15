import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'auth/login_page.dart';
import 'pages/home_page.dart';
import 'pages/market_page.dart';
import 'pages/trade_page.dart';
import 'pages/assets_page.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/coingecko_service.dart';
import 'services/notification_service.dart';
import 'services/portfolio_service.dart';
import 'services/alert_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // Note: You need to add google-services.json (Android) and GoogleService-Info.plist (iOS)
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  // Initialize Notification Service
  try {
    await NotificationService().initialize();
    print('✅ Notification service initialized');
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
          return const MainScreen();
        }
        
        return const LoginPage();
      },
    );
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
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Giao dịch'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Tài sản'),
        ],
      ),
    );
  }
}
