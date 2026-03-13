import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr'));

  void setFrench() => state = const Locale('fr');
  void setArabic() => state = const Locale('ar');

  void toggle() {
    state = state.languageCode == 'fr'
        ? const Locale('ar')
        : const Locale('fr');
  }
}
