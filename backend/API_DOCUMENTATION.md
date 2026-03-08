# ProCreditApp Backend API Documentation

## Base URL
```
http://localhost:3000/api
```

## Authentication
All protected endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <token>
```

## Response Format
All endpoints return JSON responses with the following structure:

### Success Response
```json
{
  "message": "Operation successful",
  "data": {}
}
```

### Error Response
```json
{
  "error": "Error message description"
}
```

---

## Authentication Endpoints

### 1. Register
**POST** `/auth/register`

Create a new user account (Épicier)

**Request Body:**
```json
{
  "email": "epicier@example.com",
  "firstName": "Ahmed",
  "lastName": "Ben",
  "password": "SecurePassword@123",
  "shopName": "Épicerie Ben Ahmed",
  "phone": "+216 20 123 456"
}
```

**Response (201):**
```json
{
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "cuid123",
    "email": "epicier@example.com",
    "firstName": "Ahmed",
    "lastName": "Ben",
    "role": "EPICIER",
    "shopName": "Épicerie Ben Ahmed",
    "subscriptionStatus": "TRIAL",
    "trialEndDate": "2024-01-15T00:00:00Z"
  }
}
```

---

### 2. Login
**POST** `/auth/login`

Authenticate user and get JWT token

**Request Body:**
```json
{
  "email": "epicier@example.com",
  "password": "SecurePassword@123"
}
```

**Response (200):**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "cuid123",
    "email": "epicier@example.com",
    "firstName": "Ahmed",
    "lastName": "Ben",
    "role": "EPICIER"
  }
}
```

---

### 3. Get Profile
**GET** `/auth/profile`

Get current user profile

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "user": {
    "id": "cuid123",
    "email": "epicier@example.com",
    "firstName": "Ahmed",
    "lastName": "Ben",
    "shopName": "Épicerie Ben Ahmed",
    "shopPhone": "+216 71 123 456",
    "subscriptionStatus": "TRIAL"
  }
}
```

---

### 4. Update Profile
**PUT** `/auth/profile`

Update user profile information

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "firstName": "Ahmed",
  "lastName": "Ben",
  "shopName": "New Shop Name",
  "shopAddress": "New Address",
  "shopPhone": "+216 71 000 000",
  "phone": "+216 20 000 000"
}
```

**Response (200):**
```json
{
  "message": "Profile updated successfully",
  "user": {
    "id": "cuid123",
    "email": "epicier@example.com",
    "firstName": "Ahmed",
    "lastName": "Ben",
    "shopName": "New Shop Name"
  }
}
```

---

### 5. Logout
**POST** `/auth/logout`

Logout user (invalidate session on client side)

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Logged out successfully"
}
```

---

## Client Management Endpoints

### 1. Create Client
**POST** `/clients`

Create a new client (debtor)

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "firstName": "Mohamed",
  "lastName": "Mansour",
  "phone": "+216 20 123 456",
  "email": "client@example.com",
  "address": "Tunis, Tunisia"
}
```

**Response (201):**
```json
{
  "message": "Client created successfully",
  "client": {
    "id": "client123",
    "firstName": "Mohamed",
    "lastName": "Mansour",
    "phone": "+216 20 123 456",
    "email": "client@example.com",
    "address": "Tunis, Tunisia",
    "totalDebt": 0,
    "totalCredit": 0,
    "totalPayment": 0,
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

---

### 2. Get All Clients
**GET** `/clients`

List all clients with pagination

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `skip` (optional): Number of records to skip (default: 0)
- `take` (optional): Number of records to return (default: 10)

**Example:** `/clients?skip=0&take=20`

**Response (200):**
```json
{
  "clients": [
    {
      "id": "client123",
      "firstName": "Mohamed",
      "lastName": "Mansour",
      "totalDebt": 250.50,
      "totalCredit": 300.00,
      "totalPayment": 50.00
    }
  ],
  "skip": 0,
  "take": 20
}
```

---

### 3. Get Client by ID
**GET** `/clients/:id`

Get detailed client information with transactions

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "client": {
    "id": "client123",
    "firstName": "Mohamed",
    "lastName": "Mansour",
    "phone": "+216 20 123 456",
    "totalDebt": 250.50,
    "totalCredit": 300.00,
    "totalPayment": 50.00,
    "transactions": [
      {
        "id": "trans123",
        "type": "CREDIT",
        "amount": 100.00,
        "description": "Achat 1",
        "transactionDate": "2024-01-01T10:00:00Z",
        "isPaid": false
      }
    ]
  }
}
```

---

### 4. Update Client
**PUT** `/clients/:id`

Update client information

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "firstName": "Mohamed",
  "lastName": "Mansour",
  "phone": "+216 20 234 567",
  "address": "Updated Address"
}
```

**Response (200):**
```json
{
  "message": "Client updated successfully",
  "client": {
    "id": "client123",
    "firstName": "Mohamed",
    "lastName": "Mansour",
    "phone": "+216 20 234 567"
  }
}
```

---

### 5. Delete Client
**DELETE** `/clients/:id`

Soft delete a client (mark as inactive)

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Client deleted successfully"
}
```

---

### 6. Search Clients
**GET** `/clients/search?q=<query>`

Search clients by name, phone, or email

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `q` (required): Search query

**Response (200):**
```json
{
  "clients": [
    {
      "id": "client123",
      "firstName": "Mohamed",
      "lastName": "Mansour",
      "phone": "+216 20 123 456"
    }
  ]
}
```

---

## Transaction Management Endpoints

### 1. Create Transaction
**POST** `/transactions`

Create a new transaction (credit or payment)

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "clientId": "client123",
  "type": "CREDIT",
  "amount": 100.50,
  "description": "Achat provisions",
  "dueDate": "2024-01-15T00:00:00Z",
  "paymentMethod": "cash"
}
```

**Response (201):**
```json
{
  "message": "Transaction created successfully",
  "transaction": {
    "id": "trans123",
    "clientId": "client123",
    "type": "CREDIT",
    "amount": 100.50,
    "description": "Achat provisions",
    "transactionDate": "2024-01-01T10:00:00Z",
    "dueDate": "2024-01-15T00:00:00Z",
    "isPaid": false
  }
}
```

---

### 2. Get Transactions
**GET** `/transactions`

List all transactions with filters

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `clientId` (optional): Filter by client ID
- `skip` (optional): Number of records to skip
- `take` (optional): Number of records to return

**Example:** `/transactions?clientId=client123&skip=0&take=20`

**Response (200):**
```json
{
  "transactions": [
    {
      "id": "trans123",
      "clientId": "client123",
      "type": "CREDIT",
      "amount": 100.50,
      "transactionDate": "2024-01-01T10:00:00Z",
      "isPaid": false
    }
  ],
  "skip": 0,
  "take": 20
}
```

---

### 3. Get Transaction by ID
**GET** `/transactions/:id`

Get detailed transaction information

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "transaction": {
    "id": "trans123",
    "clientId": "client123",
    "type": "CREDIT",
    "amount": 100.50,
    "description": "Achat provisions",
    "transactionDate": "2024-01-01T10:00:00Z",
    "dueDate": "2024-01-15T00:00:00Z",
    "isPaid": false
  }
}
```

---

### 4. Update Transaction
**PUT** `/transactions/:id`

Update transaction details

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "description": "Updated description",
  "dueDate": "2024-01-20T00:00:00Z"
}
```

**Response (200):**
```json
{
  "message": "Transaction updated successfully",
  "transaction": {
    "id": "trans123",
    "description": "Updated description",
    "dueDate": "2024-01-20T00:00:00Z"
  }
}
```

---

### 5. Mark Transaction as Paid
**POST** `/transactions/:id/mark-as-paid`

Mark a credit transaction as paid

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "paymentMethod": "D17"
}
```

**Response (200):**
```json
{
  "message": "Transaction marked as paid",
  "transaction": {
    "id": "trans123",
    "isPaid": true,
    "paidAt": "2024-01-10T14:00:00Z",
    "paymentMethod": "D17"
  }
}
```

---

### 6. Delete Transaction
**DELETE** `/transactions/:id`

Soft delete a transaction

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Transaction deleted successfully"
}
```

---

## Dashboard Endpoints

### 1. Get Dashboard Statistics
**GET** `/dashboard/stats`

Get dashboard overview with statistics

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "stats": {
    "totalClients": 42,
    "totalDebt": 5250.75,
    "totalCredit": 6000.00,
    "totalPayment": 750.00,
    "monthlyTransactions": 15,
    "monthlyAmount": 1250.50,
    "recentTransactions": [
      {
        "id": "trans123",
        "type": "CREDIT",
        "amount": 100.50,
        "client": {
          "firstName": "Mohamed",
          "lastName": "Mansour"
        },
        "createdAt": "2024-01-10T14:00:00Z"
      }
    ]
  }
}
```

---

### 2. Get Sync Status
**GET** `/dashboard/sync-status`

Get synchronization status

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "pendingSyncs": 3,
  "lastSync": {
    "syncStartTime": "2024-01-10T14:00:00Z",
    "syncEndTime": "2024-01-10T14:01:00Z",
    "status": "success",
    "itemsSynced": 10
  }
}
```

---

## Synchronization Endpoints

### 1. Sync Data
**POST** `/sync`

Synchronize offline data with server

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "changes": [
    {
      "entityType": "client",
      "entityId": "client123",
      "operationType": "CREATE",
      "data": {
        "id": "client123",
        "firstName": "Mohamed",
        "lastName": "Mansour",
        "phone": "+216 20 123 456"
      }
    },
    {
      "entityType": "transaction",
      "entityId": "trans123",
      "operationType": "UPDATE",
      "data": {
        "id": "trans123",
        "description": "Updated",
        "isPaid": true
      }
    }
  ]
}
```

**Response (200):**
```json
{
  "message": "Sync completed",
  "itemsSynced": 2,
  "itemsFailed": 0
}
```

---

## Health Check

### Health Status
**GET** `/health`

Check if server is running

**Response (200):**
```json
{
  "status": "OK",
  "timestamp": "2024-01-10T14:00:00Z"
}
```

---

## Error Codes

| Status Code | Description |
|-----------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Internal Server Error |

---

## Notes for Mobile Integration

1. **Token Storage**: Store JWT token securely using `flutter_secure_storage`
2. **Retry Logic**: Implement exponential backoff for failed requests
3. **Offline Queue**: Maintain `pending_sync` table locally for offline operations
4. **Network Detection**: Implement connectivity detection and auto-sync when online
5. **Error Handling**: Always handle error responses and show user-friendly messages

---

## Example Mobile Integration (Dart/Flutter)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  static const String baseUrl = 'http://localhost:3000/api';
  String? token;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['token'];
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  Future<List<dynamic>> getClients() async {
    final response = await http.get(
      Uri.parse('$baseUrl/clients'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['clients'];
    } else {
      throw Exception('Failed to load clients');
    }
  }
}
```

---

## Support

For issues or questions, contact: support@procreditapp.com
