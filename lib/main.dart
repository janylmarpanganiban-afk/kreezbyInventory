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

// this is the entry point of the whole app
// we initialize firebase first before anything runs
void main() async {
  // makes sure flutter is ready before we touch firebase
  WidgetsFlutterBinding.ensureInitialized();

  // connects to firebase using the auto-generated options (firebase_options.dart)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // wraps the whole app with providers so any screen can access shared data
  // think of MultiProvider as the "global state" container for the app
  runApp(
    MultiProvider(
      providers: [
        // handles login, logout, and user role (admin vs staff)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // manages all inventory items — fetches from firestore on startup
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        // manages all orders — fetches from firestore on startup
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ],
      child: const KreezbyApp(),
    ),
  );
}

// root widget of the app — sets up theme and decides which screen to show first
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
        // inter font from google fonts for a cleaner look
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

      // this is the key part — listens to auth state
      // if user is logged in -> show MainShell (tabbar + screens)
      // if not logged in -> show LoginScreen
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const MainShell() : const LoginScreen();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABBAR / BOTTOM NAVIGATION
// this is the main shell that holds all 5 tabs
// it keeps track of which tab is currently selected using _currentIndex
// ─────────────────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // tracks which tab is active (0 = dashboard, 1 = inventory, etc.)
  int _currentIndex = 0;

  // list of all tab screens — order matches the tab bar items below
  final List<Widget> _screens = [
    const DashboardScreen(),   // tab 0: home / overview
    const InventoryScreen(),   // tab 1: inventory list
    const OrdersScreen(),      // tab 2: orders history + create order
    const ReportsScreen(),     // tab 3: sales and stock reports
    const MoreScreen(),        // tab 4: profile, help, logout
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // shows the currently selected screen
      body: _screens[_currentIndex],

      // tabbar — this is what you tap to switch screens
      // onTap updates _currentIndex which triggers a rebuild showing the new screen
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
