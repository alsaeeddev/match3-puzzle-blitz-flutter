library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/core/localization/app_strings.dart';
import 'package:match3_game/core/theme/app_theme.dart';
import 'package:match3_game/features/home/presentation/screens/splash_screen.dart';
import 'package:match3_game/features/settings/domain/models/settings_model.dart';
import 'package:match3_game/services/storage/storage_service_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const SystemUiOverlayStyle kLightSystemUi = SystemUiOverlayStyle(
  // Android: icons light (white)
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    // iOS: ulta hota hai, dark brightness = light icons
    statusBarBrightness: Brightness.dark,
    // Android navigation bar
    systemNavigationBarColor: Color(0xFF0F0C29),
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
);

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(kLightSystemUi);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] Caught framework error: ${details.exception}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[PlatformDispatcher] Caught unhandled error: $error\n$stack');
      return true;
    };

    // runApp ko block nahi karna
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));

    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageServiceImpl(prefs);
    await storageService.init();

    runApp(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const Match3BlitzApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('[ZonedGuarded] Uncaught zone error: $error\n$stackTrace');
  });
}

// Root widget of the Match-3 Blitz application.
class Match3BlitzApp extends ConsumerWidget {
  const Match3BlitzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const defaults = AppSettings();

    final appTheme =
        ref.watch(settingsProvider.select((s) => s.value?.theme)) ??
            defaults.theme;
    final colorBlind =
        ref.watch(settingsProvider.select((s) => s.value?.colorBlindMode)) ??
            defaults.colorBlindMode;
    final strings = ref.watch(stringsProvider);

    final themeMode = switch (appTheme) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    final lightTheme = AppTheme.lightTheme(colorBlindMode: colorBlind);
    final darkTheme = AppTheme.darkTheme(colorBlindMode: colorBlind);

    return MaterialApp(
      title: strings.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: lightTheme.copyWith(
        appBarTheme: lightTheme.appBarTheme.copyWith(
          systemOverlayStyle: kLightSystemUi,
        ),
      ),
      darkTheme: darkTheme.copyWith(
        appBarTheme: darkTheme.appBarTheme.copyWith(
          systemOverlayStyle: kLightSystemUi,
        ),
      ),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: kLightSystemUi,
          child: Directionality(
            textDirection: strings.textDirection,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}