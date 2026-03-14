import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/add_client_screen.dart';
import 'screens/client_details_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/admin_main_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/api_health_screen.dart';
import 'screens/app_lock_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/app_lock_provider.dart';
import 'providers/theme_provider.dart';
import 'constants/app_constants.dart';

void main() {
  validateRuntimeConfig();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'ProCrédit',
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: AuthGateScreen(),
      routes: {
        Routes.login: (context) => const LoginScreen(),
        Routes.register: (context) => const RegisterScreen(),
        Routes.dashboard: (context) => AuthGateScreen(),
        Routes.clients: (context) => const ClientsScreen(),
        Routes.addClient: (context) => const AddClientScreen(),
        Routes.adminEpiciers: (context) => const AdminMainScreen(),
        Routes.profile: (context) => const ProfileScreen(),
        Routes.apiHealth: (context) => const ApiHealthScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == Routes.clientDetails) {
          final clientId = settings.arguments as String?;
          if (clientId == null || clientId.isEmpty) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(child: Text(context.l10n.t('clientIdRequired'))),
              ),
            );
          }
          return MaterialPageRoute(
            builder: (_) => ClientDetailsScreen(clientId: clientId),
          );
        }

        if (settings.name == Routes.transactions) {
          final args = settings.arguments as Map<String, dynamic>?;
          final clientId = args?['clientId'] as String?;
          final clientName = args?['clientName'] as String?;

          if (clientId == null || clientName == null) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text(context.l10n.t('clientIdAndNameRequired')),
                ),
              ),
            );
          }

          return MaterialPageRoute(
            builder: (_) =>
                TransactionsScreen(clientId: clientId, clientName: clientName),
          );
        }

        return null;
      },
    );
  }
}

class AuthGateScreen extends ConsumerStatefulWidget {
  final Duration lockTimeout;
  final DateTime Function() now;

  static DateTime _defaultNow() => DateTime.now();

  const AuthGateScreen({
    super.key,
    this.lockTimeout = const Duration(minutes: 5),
    this.now = _defaultNow,
  });

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen>
    with WidgetsBindingObserver {
  // Heure à laquelle l'app est passée en arrière-plan
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused) {
      _pausedAt = widget.now();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      if (_pausedAt != null &&
          widget.now().difference(_pausedAt!) >= widget.lockTimeout) {
        ref.read(appLockProvider.notifier).lock();
      }
      _pausedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final lockState = ref.watch(appLockProvider);

    // Initialisation en cours
    if (authState.isLoading && authState.user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(context.l10n.t('loading')),
            ],
          ),
        ),
      );
    }

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // Écran de verrouillage PIN (si activé et verrouillé)
    if (lockState.isLocked) {
      return const AppLockScreen();
    }

    if (authState.user?.role == 'SUPER_ADMIN') {
      return const AdminMainScreen();
    }

    return const DashboardScreen();
  }
}
