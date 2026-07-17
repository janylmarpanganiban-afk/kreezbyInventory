import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/inventory_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/login_screen.dart';
import 'screens/orders_screen.dart';
import 'providers/orders_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/reports_screen.dart';
import 'screens/more_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ],
      child: const KreezbyApp(),
    ),
  );
}

class KreezbyApp extends StatelessWidget {
  const KreezbyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kreezby',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0056C6),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0056C6),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const MainShell() : const LoginScreen();
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const InventoryScreen(),
    const OrdersScreen(),
    const ReportsScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0056C6),
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
