import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/add_client_screen.dart';
import 'screens/client_details_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/admin_epiciers_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/auth_provider.dart';
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

    return MaterialApp(
      title: 'ProCreditApp',
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
      home: const AuthGateScreen(),
      routes: {
        Routes.login: (context) => const LoginScreen(),
        Routes.register: (context) => const RegisterScreen(),
        Routes.dashboard: (context) => const AuthGateScreen(),
        Routes.clients: (context) => const ClientsScreen(),
        Routes.addClient: (context) => const AddClientScreen(),
        Routes.adminEpiciers: (context) => const AdminEpiciersScreen(),
        Routes.profile: (context) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == Routes.clientDetails) {
          final clientId = settings.arguments as String?;
          if (clientId == null || clientId.isEmpty) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Client ID is required')),
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
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text('Client ID and name required for transactions'),
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

class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Show loading during initialization
    if (authState.isLoading && authState.user == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement...'),
            ],
          ),
        ),
      );
    }

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    if (authState.user?.role == 'SUPER_ADMIN') {
      return const AdminEpiciersScreen();
    }

    return const DashboardScreen();
  }
}
