import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final List<Function()> _listeners = [];
  String? _cachedName;
  String? _cachedUsername;
  String? _cachedEmail;

  // Add a listener to be notified when profile is updated
  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  // Remove a listener
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners that profile has been updated
  void notifyProfileUpdated() {
    // Clear cache so next fetch gets fresh data
    _cachedName = null;
    _cachedUsername = null;
    _cachedEmail = null;
    
    // Notify all listeners
    for (final listener in _listeners) {
      listener();
    }
  }

  // Get user profile data with caching
  Future<Map<String, String?>> getUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'name': null, 'username': null, 'email': null};
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _cachedName = data['name'] as String?;
        _cachedUsername = data['username'] as String?;
        _cachedEmail = user.email;
        
        return {
          'name': _cachedName,
          'username': _cachedUsername,
          'email': _cachedEmail,
        };
      } else {
        _cachedEmail = user.email;
        return {
          'name': null,
          'username': null,
          'email': _cachedEmail,
        };
      }
    } catch (e) {
      return {'name': null, 'username': null, 'email': null};
    }
  }

  // Get cached values if available
  String? get cachedName => _cachedName;
  String? get cachedUsername => _cachedUsername;
  String? get cachedEmail => _cachedEmail;
} 