import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _role = 'staff';

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        try {
          final doc = await DatabaseService().getUserDocument(user.uid);
          _role = doc?['role'] ?? 'staff';
        } catch (e) {
          debugPrint('Error fetching user role: $e');
          _role = 'staff';
        }
      } else {
        _role = 'staff';
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _role == 'admin' || _user?.email == 'admin@gmail.com';

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signup(String email, String password, String displayName, String role) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user?.updateDisplayName(displayName);
    await DatabaseService().createUserDocument(credential.user!.uid, {
      'email': email,
      'displayName': displayName,
      'role': role,
    });
    _user = _auth.currentUser;
    _role = role;
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    await _user?.updateDisplayName(name);
    _user = _auth.currentUser;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
