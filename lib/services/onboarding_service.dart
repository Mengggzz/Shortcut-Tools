import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding satu-kali: petunjuk gestur dasar aplikasi.
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static const _key = 'onboarding_seen_v1';

  Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
