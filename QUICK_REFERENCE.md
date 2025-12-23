# DoseTime - Quick Reference Card

## 🚀 Start Full Stack

### Terminal 1: Start Django Backend
```powershell
cd C:\Users\hruda\Desktop\dose_time\backend
python manage.py runserver
# Runs on http://127.0.0.1:8000/
```

### Terminal 2: Start Flutter Frontend
```powershell
cd C:\Users\hruda\Desktop\dose_time
flutter run -d chrome
# Web app opens on http://localhost:****/
```

---

## 🔑 Key Services

| Service | File | Purpose |
|---------|------|---------|
| DjangoApiService | `django_api_service.dart` | HTTP client for all Django APIs |
| AuthService | `auth_service.dart` | JWT auth & token management |
| PrescriptionService | `prescription_service.dart` | Medication CRUD |
| MedicationLogService | `medication_log_service.dart` | Log medication taken |
| NotificationPreferenceService | `notification_preference_service.dart` | Notification settings |

---

## 📱 API Examples

### Register User
```dart
final authService = await ref.watch(authServiceProvider.future);
await authService.register(
  username: 'john_doe',
  email: 'john@example.com',
  password: 'SecurePass123',
  role: 'patient',
  phoneNumber: '+1234567890',
);
```

### Login User
```dart
final authService = await ref.watch(authServiceProvider.future);
bool success = await authService.login(
  username: 'john_doe',
  password: 'SecurePass123',
);
```

### Create Prescription
```dart
final prescService = ref.watch(prescriptionServiceProvider);
final prescription = await prescService.createPrescription(
  medicationName: 'Aspirin',
  dosage: '500mg',
  medicationType: 'tablet',
  frequency: 'twice_daily',
  reminderTimes: ['09:00', '21:00'],
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 30)),
);
```

### Mark Medication Taken
```dart
final logService = ref.watch(medicationLogServiceProvider);
await logService.markTaken(
  logId: 'log_uuid',
  notes: 'Took with food',
);
```

### Get User Prescriptions
```dart
final prescriptions = ref.watch(prescriptionsProvider);
prescriptions.when(
  data: (list) => Text('${list.length} prescriptions'),
  loading: () => CircularProgressIndicator(),
  error: (err, st) => Text('Error: $err'),
);
```

---

## 🔐 Authentication Flow

```
1. Register/Login
   ↓
2. Get JWT Tokens (access + refresh)
   ↓
3. Store Tokens in SharedPreferences
   ↓
4. Use Access Token in Authorization Header
   ↓
5. Auto-refresh when token expires
   ↓
6. Logout to clear tokens
```

---

## 📂 Project Structure

```
dose_time/
├── backend/
│   ├── manage.py
│   ├── requirements.txt
│   ├── config/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── core/
│   │   ├── models.py (User model)
│   │   ├── serializers.py
│   │   ├── views.py
│   │   └── urls.py
│   ├── meds/
│   │   ├── models.py (Prescription, MedicationLog)
│   │   ├── serializers.py
│   │   ├── views.py
│   │   └── urls.py
│   └── notifications/
│       ├── models.py (NotificationPreference)
│       ├── serializers.py
│       ├── views.py
│       └── urls.py
│
├── lib/
│   ├── services/
│   │   ├── django_api_service.dart (HTTP client)
│   │   ├── auth_service.dart (JWT auth)
│   │   ├── prescription_service.dart
│   │   ├── medication_log_service.dart
│   │   └── notification_preference_service.dart
│   ├── providers/
│   │   └── (Riverpod providers)
│   ├── features/
│   │   ├── auth/
│   │   │   └── screens/
│   │   ├── medications/
│   │   │   └── screens/
│   │   └── settings/
│   │       └── screens/
│   └── main.dart
│
└── pubspec.yaml
```

---

## 🛠️ Common Tasks

### Create Admin User
```powershell
cd backend
python manage.py createsuperuser
# Access: http://127.0.0.1:8000/admin/
```

### Create Database Backup
```powershell
cd backend
sqlite3 dosetime_fresh.sqlite3 ".dump" > backup.sql
```

### Reset Database
```powershell
cd backend
.\reset_and_migrate.bat
# Or manually:
python manage.py makemigrations
python manage.py migrate
```

### Regenerate Flutter Code
```powershell
cd ..\
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🔍 Debugging

### Check Backend Logs
```powershell
# Terminal where Django is running
# Look for [timestamp] Django version logs
# Check requests in Django console
```

### Check Token in SharedPreferences
```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('django_access_token');
print('Token: $token');
```

### Test API Directly
```powershell
# Windows PowerShell
curl -X GET http://127.0.0.1:8000/api/core/users/me/ `
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Flutter Debug Console
```
Add this to see API logs:
ref.watch(loggerProvider).i('Debug message');
```

---

## 📊 Data Models

### User Model
```dart
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "patient|doctor|caretaker",
  "phone_number": "+1234567890",
  "profile_image": "https://..."
}
```

### Prescription Model
```dart
{
  "id": "uuid",
  "medication_name": "Aspirin",
  "dosage": "500mg",
  "medication_type": "tablet|capsule|liquid|injection|inhaler|cream|patch|other",
  "frequency": "once_daily|twice_daily|three_times_daily|...",
  "reminder_times": ["09:00", "21:00"],
  "start_date": "2025-12-23",
  "end_date": "2026-12-23",
  "instructions": "Take with water",
  "is_active": true
}
```

### Medication Log Model
```dart
{
  "id": "uuid",
  "prescription_id": "uuid",
  "taken_at": "2025-12-23T09:30:00Z",
  "is_taken": true,
  "notes": "Took with food"
}
```

### Notification Preference Model
```dart
{
  "user": 1,
  "quiet_hours_start": "22:00",
  "quiet_hours_end": "08:00",
  "enable_daily_summary": true,
  "enable_medication_reminders": true,
  "channels": ["email", "push", "sms"]
}
```

---

## 🌐 API Endpoints

### Authentication
```
POST /auth/token/              Login
POST /auth/token/refresh/      Refresh Token
```

### Users
```
POST   /api/core/register/     Register
GET    /api/core/users/me/     Get Current User
PATCH  /api/core/users/{id}/   Update User
```

### Prescriptions
```
GET    /api/meds/prescriptions/             List
POST   /api/meds/prescriptions/             Create
GET    /api/meds/prescriptions/{id}/        Get
PATCH  /api/meds/prescriptions/{id}/        Update
DELETE /api/meds/prescriptions/{id}/        Delete
```

### Medication Logs
```
GET  /api/meds/logs/                      List
POST /api/meds/logs/                      Create
POST /api/meds/logs/{id}/mark_taken/      Mark Taken
```

### Notifications
```
GET   /api/notifications/prefs/     Get
PATCH /api/notifications/prefs/     Update
```

---

## ⚠️ Important Notes

1. **Token Expiry**: Access tokens last 30 minutes, refresh tokens 7 days
2. **Base URL**: `http://127.0.0.1:8000/api/` for development
3. **CORS**: All origins allowed in dev (restrict in production)
4. **Errors**: All services throw exceptions - use try/catch
5. **Offline**: Implement Hive caching for offline support

---

## 📚 Documentation

- `MIGRATION_COMPLETE.md` - Overview of what was done
- `FIREBASE_TO_DJANGO_MIGRATION.md` - Detailed migration guide
- `COMPLETE_SETUP_GUIDE.md` - Full API documentation
- `backend/IMPLEMENTATION_COMPLETE.md` - Backend setup details

---

## 🆘 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Backend won't start | `netstat -ano \| findstr :8000` then kill process |
| Flutter can't connect | Check base URL in `django_api_service.dart` |
| Token expired | Auto-refresh happens; if error, log in again |
| Database locked | Run `.\reset_and_migrate.bat` in backend |
| Compilation error | `flutter clean && flutter pub get` |

---

**Version**: December 23, 2025  
**Status**: ✅ Firebase Removed, Django Ready  
**Backend**: 🟢 Running  
**Frontend**: ✅ Services Implemented  

**Next**: Update UI screens to use services → Test → Deploy 🚀
