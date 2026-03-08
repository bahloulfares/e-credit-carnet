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
import 'constants/app_constants.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ProCreditApp',
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
          return MaterialPageRoute(
            builder: (_) => TransactionsScreen(
              clientId: args?['clientId'] as String?,
              clientName: args?['clientName'] as String?,
            ),
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

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    if (authState.user?.role == 'SUPER_ADMIN') {
      return const AdminEpiciersScreen();
    }

    return const DashboardScreen();
  }
}
