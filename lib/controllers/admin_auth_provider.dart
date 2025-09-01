import 'package:delloniweb/model/admin_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  AdminModel? _currentAdmin;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  AdminModel? get currentAdmin => _currentAdmin;

  AdminAuthProvider() {
    _checkAuthState();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    notifyListeners();
  }

  Future<void> _checkAuthState() async {
    _setLoading(true);
    
    try {
      // Check if user is already signed in
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // Check if user is admin
        bool isAdmin = await _verifyAdminStatus(firebaseUser.uid);
        if (isAdmin) {
          await _loadAdminData(firebaseUser.uid);
          _setAuthenticated(true);
        } else {
          await signOut();
        }
      }
    } catch (e) {
      _setError('Failed to check authentication status');
    }
    
    _setLoading(false);
  }

  Future<bool> _verifyAdminStatus(String userId) async {
    try {
      DocumentSnapshot adminDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (adminDoc.exists) {
        Map<String, dynamic> data = adminDoc.data() as Map<String, dynamic>;
        return data['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadAdminData(String userId) async {
    try {
      DocumentSnapshot adminDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
          Map<String, dynamic>? locationData;
          if(adminDoc.exists) {
              DocumentSnapshot locationDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('location')
                  .doc('current')
                  .get();

            locationData = 
                  locationDoc.exists ? locationDoc.data() as Map<String, dynamic> : null;
          }
      
      if (adminDoc.exists) {
        _currentAdmin = AdminModel.fromFirestore(
          adminDoc.data() as Map<String, dynamic>,
          locationData,
        );
      }
    } catch (e) {
      _setError('Failed to load admin data');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Verify admin status
        bool isAdmin = await _verifyAdminStatus(user.uid);
        
        if (isAdmin) {
          await _loadAdminData(user.uid);
          
          // Save login state if remember me is checked
          if (rememberMe) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('remember_admin', true);
            await prefs.setString('admin_email', email);
          }
          
          _setAuthenticated(true);
        } else {
          await _auth.signOut();
          _setError('Access denied. Admin privileges required.');
        }
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _setError('No admin account found with this email.');
          break;
        case 'wrong-password':
          _setError('Incorrect password. Please try again.');
          break;
        case 'invalid-email':
          _setError('Invalid email address format.');
          break;
        case 'user-disabled':
          _setError('This admin account has been disabled.');
          break;
        case 'too-many-requests':
          _setError('Too many failed attempts. Please try again later.');
          break;
        default:
          _setError('Login failed. Please try again.');
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    }

    _setLoading(false);
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _auth.signOut();
      
      // Clear remember me preference
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_admin');
      await prefs.remove('admin_email');
      
      _currentAdmin = null;
      _setAuthenticated(false);
    } catch (e) {
      _setError('Failed to sign out');
    }
    
    _setLoading(false);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email');
    }
  }

  void clearError() {
    _setError(null);
  }
}

// class AdminModel {
//   final String uid;
//   final String email;
//   final String name;
//   final String role;
//   final bool isActive;
//   final DateTime createdAt;
//   final DateTime? lastLoginAt;
//   final List<String> permissions;

//   AdminModel({
//     required this.uid,
//     required this.email,
//     required this.name,
//     required this.role,
//     required this.isActive,
//     required this.createdAt,
//     this.lastLoginAt,
//     required this.permissions,
//   });

//   factory AdminModel.fromFirestore(Map<String, dynamic> data) {
//     return AdminModel(
//       uid: data['uid'] ?? '',
//       email: data['email'] ?? '',
//       name: data['name'] ?? '',
//       role: data['role'] ?? 'admin',
//       isActive: data['isActive'] ?? false,
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
//       permissions: List<String>.from(data['permissions'] ?? []),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'uid': uid,
//       'email': email,
//       'name': name,
//       'role': role,
//       'isActive': isActive,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
//       'permissions': permissions,
//     };
//   }

//   bool hasPermission(String permission) {
//     return permissions.contains(permission) || permissions.contains('all');
//   }
// }