# Flutter Frontend Implementation Guide

## Overview

This is the Flutter/Dart frontend for ProCreditApp, a Tunisian grocery credit management SaaS application. The app provides a mobile-first interface for managing client credits and transactions with offline-first synchronization.

## Project Structure

```
lib/
├── main.dart                 # App entry point with Riverpod provider scope
├── models/                   # Data models with JSON serialization
│   ├── user_model.dart      # User entity
│   ├── client_model.dart    # Client entity with debt tracking
│   ├── transaction_model.dart # Transaction entity (CREDIT/PAYMENT)
│   └── dashboard_stats_model.dart # Dashboard statistics
├── services/                # API communication layer
│   ├── api_client.dart      # HTTP client with JWT authentication
│   ├── client_service.dart  # Client CRUD and search operations
│   ├── api_service.dart     # Transaction service (create, mark paid)
│   └── dashboard_service.dart # Dashboard stats and sync
├── providers/               # State management with Riverpod
│   ├── auth_provider.dart   # Authentication state & user profile
│   ├── client_provider.dart # Client list and CRUD operations
│   ├── transaction_provider.dart # Transaction management
│   └── dashboard_provider.dart # Dashboard data and refresh
├── screens/                 # UI screens
│   ├── login_screen.dart    # Authentication
│   ├── register_screen.dart # User registration
│   ├── dashboard_screen.dart # KPI dashboard
│   └── clients_screen.dart  # Client list with search
└── pubspec.yaml            # Dependencies and configuration
```

## Setup Instructions

### Prerequisites
- Flutter SDK 3.11.0 or higher
- Dart SDK 3.11.0 or higher
- Backend API running on `http://localhost:3000/api`

### Installation

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Update pubspec.yaml with required packages:**
The following packages have been added:
```yaml
dependencies:
  http: ^1.1.0                    # HTTP client
  flutter_riverpod: ^2.4.0        # State management
  flutter_secure_storage: ^9.0.0  # Secure token storage
  sqflite: ^2.3.0                 # Local SQLite database
  connectivity_plus: ^5.0.0       # Network monitoring
  intl: ^0.19.0                   # Date formatting
```

3. **Run the app:**
```bash
# Development
flutter run -d android   # Android emulator/device
flutter run -d ios       # iOS simulator/device
flutter run -d web       # Web (development only)

# Release
flutter build apk        # Android release APK
flutter build ios        # iOS release build
```

## Core Components

### Models (lib/models/)

#### UserModel
- **Purpose:** Represents authenticated user throughout the app
- **Fields:** id, email, firstName, lastName, phone, role, shopName, etc.
- **Serialization:** `fromJson()`, `toJson()`, `copyWith()`
- **Null Safety:** All fields handle null values gracefully

```dart
final user = User.fromJson(jsonResponse);
final updated = user.copyWith(firstName: 'Jean');
```

#### ClientModel
- **Purpose:** Represents debtor with complete credit history
- **Fields:** id, firstName, lastName, phone, email, address, totalDebt, totalCredit, totalPayment
- **Features:** fullName getter, debt calculations
- **Status:** Active/Inactive tracking

#### TransactionModel
- **Purpose:** Represents credit or payment transaction
- **Types:** `CREDIT` (loan given), `PAYMENT` (payment received)
- **Fields:** amount, dueDate, isPaid, paymentMethod, syncStatus
- **Payment Tracking:** paidAt timestamp, payment method recording

#### DashboardStatsModel
- **Purpose:** Aggregated statistics for dashboard display
- **Stats:** totalClients, totalDebt, totalCredit, monthlyTransactions
- **RecentTransactions:** Last 10 transactions with client names

### Services (lib/services/)

#### ApiClient
**Purpose:** HTTP wrapper with JWT authentication

```dart
final apiClient = ApiClient();
await apiClient.initialize(); // Load token from secure storage

// Authentication
final response = await apiClient.login(
  email: 'epicier@shop.com',
  password: 'password123'
);

// Profile management
final user = await apiClient.getProfile();
```

**Features:**
- JWT token storage in FlutterSecureStorage
- Automatic token injection in Authorization header
- Error handling with custom ApiException
- 30-second timeout for all requests
- Logout clears local token

#### ClientService
**Purpose:** Client CRUD operations and search

```dart
final clientService = ClientService(apiClient: apiClient);

// List clients (paginated)
final clients = await clientService.getClients(skip: 0, take: 10);

// Create client
final newClient = await clientService.createClient(
  firstName: 'Ahmed',
  lastName: 'Ben Ali',
  phone: '+216 98 123 456',
  address: 'Sousse'
);

// Search clients
final results = await clientService.searchClients('Ahmed');
```

#### TransactionService
**Purpose:** Transaction management with payment tracking

```dart
final transactionService = TransactionService(apiClient: apiClient);

// Create credit transaction
final credit = await transactionService.createTransaction(
  clientId: 'client-123',
  type: 'CREDIT',
  amount: 50.0,
  description: 'Monthly supplies',
  dueDate: DateTime.now().add(Duration(days: 30))
);

// Mark payment received
final paid = await transactionService.markAsPaid(
  'transaction-456',
  paymentMethod: 'CASH'
);
```

#### DashboardService
**Purpose:** Dashboard statistics and offline synchronization

```dart
final dashboardService = DashboardService(apiClient: apiClient);

// Get aggregated stats
final stats = await dashboardService.getStats();
print('Total clients: ${stats.totalClients}');
print('Total debt: ${stats.totalDebt} DT');

// Check sync status
final syncStatus = await dashboardService.getSyncStatus();

// Sync pending changes
final result = await dashboardService.sync(pendingChanges);
```

### State Management (lib/providers/)

Using **Riverpod** for hierarchical, reactive state management.

#### AuthProvider
**State:** User authentication status, profile, loading state

```dart
// Watch authentication state
final authState = ref.watch(authStateProvider);

// Access notifier for login/register
final authNotifier = ref.read(authStateProvider.notifier);
await authNotifier.login(email: 'user@shop.com', password: 'pass');

// Check authentication
if (authState.isAuthenticated) {
  // User logged in
}
```

#### ClientProvider
**State:** Client list with pagination and CRUD operations

```dart
// Watch client list
final clientList = ref.watch(clientListProvider);

// Perform operations
final notifier = ref.read(clientListProvider.notifier);
await notifier.loadClients();
await notifier.createClient(
  firstName: 'Fatima',
  lastName: 'Bennani',
  phone: '+216 98 765 432'
);
await notifier.deleteClient('client-id');

// Search clients
final results = ref.watch(searchClientsProvider('Ahmed'));
```

#### TransactionProvider
**State:** Transaction list, CRUD, mark as paid

```dart
// Watch transactions
final txState = ref.watch(transactionListProvider(clientId));

// Create transaction
final notifier = ref.read(transactionListProvider(clientId).notifier);
await notifier.createTransaction(
  clientId: 'client-123',
  type: 'CREDIT',
  amount: 75.0,
  dueDate: DateTime.now().add(Duration(days: 30))
);

// Mark as paid (update local state)
await notifier.markAsPaid('tx-456', paymentMethod: 'BANK_TRANSFER');
```

#### DashboardProvider
**State:** Dashboard stats, refresh, sync operations

```dart
// Watch dashboard stats
final stats = ref.watch(dashboardStatsProvider);

// Refresh stats
final notifier = ref.read(dashboardRefreshProvider.notifier);
await notifier.refreshStats();

// Perform sync
final result = await notifier.performSync(pendingChanges);
```

### Screens (lib/screens/)

#### LoginScreen
- Email/password authentication
- Links to registration
- Loading indicator during submission
- Error display with feedback

#### RegisterScreen
- User registration with shop details
- Required fields: Email, First Name, Last Name, Password
- Optional fields: Shop Name, Phone
- Form validation
- Navigation to dashboard on success

#### DashboardScreen
- KPI cards (Clients, Debt, Credit, Payments)
- Monthly statistics
- Recent transactions list
- Refresh button with pull-to-refresh
- Responsive grid layout

#### ClientsScreen
- Paginated client list
- Search functionality (real-time)
- Client details with debt display
- Add client button (FAB)
- Logout button in app bar
- Navigate to client details on tap

## API Integration

### Base URL
```
http://localhost:3000/api
```

### Authentication
All authenticated endpoints require JWT token in Authorization header:
```
Authorization: Bearer <jwt_token>
```

### Endpoints Used

**Authentication:**
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `GET /auth/profile` - Get current user profile
- `PUT /auth/profile` - Update user profile
- `POST /auth/logout` - Logout (clears token)

**Clients:**
- `GET /clients?skip=0&take=10` - List clients (paginated)
- `GET /clients/:id` - Get client details
- `POST /clients` - Create client
- `PUT /clients/:id` - Update client
- `DELETE /clients/:id` - Delete client
- `GET /clients/search?q=query` - Search clients

**Transactions:**
- `GET /transactions?clientId=:id&skip=0&take=20` - List transactions
- `GET /transactions/:id` - Get transaction details
- `POST /transactions` - Create transaction
- `PUT /transactions/:id` - Update transaction
- `DELETE /transactions/:id` - Delete transaction
- `POST /transactions/:id/mark-as-paid` - Mark as paid

**Dashboard:**
- `GET /dashboard/stats` - Get dashboard statistics
- `GET /dashboard/sync-status` - Check sync status
- `POST /sync` - Synchronize pending changes

## Features Implemented

### ✅ Completed
- [x] User authentication (register, login, logout)
- [x] Profile management
- [x] Client management (CRUD, search)
- [x] Transaction creation and tracking
- [x] Payment marking
- [x] Dashboard statistics
- [x] Secure token storage
- [x] State management with Riverpod
- [x] Error handling and user feedback
- [x] Responsive UI design

### 🔄 In Progress
- [ ] Offline-first synchronization (PendingSync queue)
- [ ] Local SQLite database
- [ ] Connectivity monitoring
- [ ] Location tracking
- [ ] File exports (PDF/Excel)
- [ ] Push notifications

### ⏳ Planned
- [ ] Biometric authentication (fingerprint/face)
- [ ] Multi-language support (FR/AR)
- [ ] Dark mode
- [ ] Transaction history export
- [ ] Client SMS reminders
- [ ] Advanced analytics
- [ ] Widget notifications
- [ ] Voice transaction input

## Error Handling

### ApiException
Custom exception for API errors:
```dart
try {
  await apiClient.login(email: 'test@test.com', password: 'pass');
} catch (e) {
  if (e is ApiException) {
    print('API Error: ${e.message} (Status: ${e.statusCode})');
  }
}
```

### State Error Display
All providers include error state:
```dart
stats.when(
  data: (data) => Text('Total: ${data.totalClients}'),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
)
```

## Testing

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart

# Coverage
flutter test --coverage
```

### Test Files Location
Tests should be placed in `test/` directory:
```
test/
├── unit/
│   ├── models/
│   ├── services/
│   └── providers/
├── widget/
│   └── screens/
└── integration/
    └── app_test.dart
```

## Debugging

### Enable Debug Logging
```dart
// In main.dart before runApp()
if (kDebugMode) {
  setUpLogging();
}
```

### Device Inspection
```bash
# Flutter DevTools
flutter pub global activate devtools
devtools

# Hot reload
R key in terminal

# Hot restart
Shift+R key in terminal
```

## Deployment

### Android
```bash
# Build release APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Sign APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore keystore.jks app-release-unsigned.apk key_alias
```

### iOS
```bash
# Build release IPA
flutter build ios --release

# Archive for App Store
open ios/Runner.xcworkspace/
# In Xcode: Product → Archive
```

## Performance Optimization

### Image Loading
- Use `CachedNetworkImage` for profile pictures
- Compress images before upload
- Use appropriate image sizes

### List Performance
```dart
// Use ListView.builder for large lists (already implemented)
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ListTile(...),
)
```

### State Management
- Use `select()` to watch only needed fields
- Avoid rebuilding entire widget tree
- Use `AsyncValue` for async operations

## Troubleshooting

### Connection Issues
**Problem:** API calls fail with timeout  
**Solution:** Check backend is running on localhost:3000

**Problem:** CORS errors in web version  
**Solution:** Backend needs CORS configured (already done)

### Authentication Issues
**Problem:** Token not persisting  
**Solution:** Check FlutterSecureStorage permissions

**Problem:** Login fails immediately  
**Solution:** Verify backend credentials match test data

### Build Issues
**Problem:** Dependency conflicts  
**Solution:** Run `flutter pub get` and `flutter clean`

**Problem:** Build fails on iOS  
**Solution:** Run `cd ios && pod install && cd ..`

## Environment Configuration

### Development
```
API_BASE_URL=http://localhost:3000/api
DEBUG_MODE=true
LOG_LEVEL=debug
```

### Production
```
API_BASE_URL=https://api.procreditapp.tn/api
DEBUG_MODE=false
LOG_LEVEL=warn
```

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Docs](https://riverpod.dev)
- [Material Design](https://material.io/design)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

## Support

For issues or questions:
1. Check existing GitHub issues
2. Review backend API documentation
3. Check Flutter/Dart logs: `flutter logs`
4. Open GitHub issue with full stack trace

## License

Proprietary - ProCreditApp
