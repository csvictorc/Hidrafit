import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileHelper {
  static Future<void> updateFirebaseProfileIfNeeded({
    required BuildContext context,
    required SharedPreferences prefs,
    required Function(String name, String photoUrl) onProfileUpdated,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cachedName = prefs.getString('name') ?? '';
    final cachedPhotoUrl = prefs.getString('photo_url') ?? '';

    final loc = AppLocalizations.of(context)!;
    final newName = user.displayName ?? loc.user;
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
