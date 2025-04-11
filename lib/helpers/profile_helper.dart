import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileHelper {
  static Future<void> updateFirebaseProfileIfNeeded({
    required SharedPreferences prefs,
    required Function(String name, String photoUrl) onProfileUpdated,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cachedName = prefs.getString('name') ?? '';
    final cachedPhotoUrl = prefs.getString('photo_url') ?? '';

    final newName = user.displayName ?? 'Usuário';
    final newPhotoUrl = user.photoURL ?? '';

    if (newName != cachedName || newPhotoUrl != cachedPhotoUrl) {
      await prefs.setString('name', newName);
      await prefs.setString('photo_url', newPhotoUrl);
      onProfileUpdated(newName, newPhotoUrl);
    }
  }

  static Future<void> updateDisplayName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != newName) {
      await user.updateDisplayName(newName);
    }
  }
}
