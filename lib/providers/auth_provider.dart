import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH PROVIDER
// handles everything related to authentication — login, signup, logout
// also keeps track of whether the current user is an admin or regular staff
// uses Firebase Auth to manage sessions automatically
// ─────────────────────────────────────────────────────────────────────────────
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  String _role = 'staff'; // default role is staff until proven otherwise

  // constructor — listens to firebase's auth state stream
  // this fires automatically whenever the user logs in or logs out
  // if user logs in: fetch their role from firestore
  // if user logs out: reset role back to staff
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        try {
          // FIREBASE PULL: reads the user document from firestore to get their role
          final doc = await DatabaseService().getUserDocument(user.uid);
          _role = doc?['role'] ?? 'staff'; // if no role saved, default to staff
        } catch (e) {
          debugPrint('Error fetching user role: $e');
          _role = 'staff';
        }
      } else {
        // user logged out — reset to default
        _role = 'staff';
      }
      notifyListeners(); // tells main.dart to decide: show login or main shell
    });
  }

  // exposes the current firebase user object (contains email, displayName, uid)
  User? get user => _user;

  // returns true if the user is logged in — used in main.dart to route to the right screen
  bool get isAuthenticated => _user != null;

  // returns true if user is admin — checks both the role saved in firestore and the email
  // the email check is a fallback in case the role wasn't saved properly
  bool get isAdmin => _role == 'admin' || _user?.email == 'admin@gmail.com';

  // ─── LOGIN ───────────────────────────────────────────────────────────────
  // signs the user in using firebase auth
  // after this succeeds, authStateChanges() above will fire and update the app
  // navigation to the main screen is handled automatically by the Consumer in main.dart
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ─── SIGNUP ──────────────────────────────────────────────────────────────
  // creates a new firebase auth account
  // then pushes a user document to firestore with their email, name, and role
  // this is how we store whether someone is admin or staff
  Future<void> signup(String email, String password, String displayName, String role) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user?.updateDisplayName(displayName);

    // FIREBASE PUSH: saves user info (role) to firestore after account creation
    await DatabaseService().createUserDocument(credential.user!.uid, {
      'email': email,
      'displayName': displayName,
      'role': role,
    });

    _user = _auth.currentUser;
    _role = role;
    notifyListeners();
  }

  // ─── UPDATE DISPLAY NAME ─────────────────────────────────────────────────
  // updates the display name in firebase auth (not firestore)
  // used from more_screen.dart's name edit field
  Future<void> updateDisplayName(String name) async {
    await _user?.updateDisplayName(name);
    _user = _auth.currentUser; // refresh local user reference
    notifyListeners();
  }

  // ─── LOGOUT ──────────────────────────────────────────────────────────────
  // signs out from firebase — authStateChanges() fires and sets _user to null
  // which causes main.dart to switch back to LoginScreen automatically
  Future<void> logout() async {
    await _auth.signOut();
  }
}
