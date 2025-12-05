# Smart Office Access Control

ESP32 WiFi modülü ile entegre akıllı ofis giriş kontrol sistemi. Firebase Authentication ve Realtime Database kullanarak çalışan yönetimi, görev takibi ve kapı erişim kontrolü sağlar.

## 🚀 Özellikler

### 🔐 Kimlik Doğrulama
- Firebase Authentication ile güvenli giriş
- Admin ve Employee rolleri
- Şifremi unuttum özelliği
- Erişim talebi sistemi (onay gerektirir)

### 👥 Kullanıcı Yönetimi
- Admin: Tüm yetkilere sahip, erişim taleplerini onaylayabilir
- Employee: Standart çalışan erişimi
- Guest: Misafir erişim talebi

### 📋 Görev Yönetimi
- Görev oluşturma ve takip
- Zorluk seviyeleri (Kolay, Orta, Zor, Çok Zor)
- Görev durumları (To-Do, In Progress, Done)
- Tamamlama süresi kaydı
- Puan sistemi

### 🚪 Kapı Erişim Kontrolü
- ESP32 WiFi modülü ile kapı açma
- Konum tabanlı erişim kontrolü (100 metre yarıçap)
- Giriş/Çıkış kaydı
- Çalışma saati takibi

### 📊 Dashboard
- Günlük çalışma özeti
- Giriş/Çıkış timeline
- Aktif görevler listesi
- Bildirimler

## 📱 Ekranlar

1. **Login Screen** - Admin/Employee giriş
2. **Request Access** - Yeni kullanıcı erişim talebi
3. **Dashboard** - Ana sayfa
4. **Profile** - Kullanıcı profili ve istatistikler
5. **Settings** - Uygulama ayarları
6. **Admin Panel** - Bekleyen talepler ve kullanıcı yönetimi
7. **Create Task** - Yeni görev oluşturma

## 🗄️ Firebase RTDB Yapısı

```
root/
├── users/
│   └── {uid}/
│       ├── uid
│       ├── email
│       ├── firstName
│       ├── lastName
│       ├── position
│       ├── phone
│       ├── role (admin/employee/guest)
│       ├── isApproved
│       ├── createdAt
│       ├── tasks/
│       │   └── {taskId}/
│       │       ├── id
│       │       ├── title
│       │       ├── description
│       │       ├── status (todo/inProgress/done)
│       │       ├── difficulty (easy/medium/hard/veryHard)
│       │       ├── createdAt
│       │       ├── startedAt
│       │       ├── completedAt
│       │       └── durationMinutes
│       └── attendance/
│           └── {date}/
│               ├── date
│               ├── userId
│               ├── totalMinutesWorked
│               └── records/
│                   └── {recordId}/
│                       ├── id
│                       ├── type (entry/exit)
│                       ├── timestamp
│                       └── location
├── access_requests/
│   └── {requestId}/
│       ├── id
│       ├── email
│       ├── firstName
│       ├── lastName
│       ├── position
│       ├── phone
│       ├── reason
│       ├── status (pending/approved/rejected)
│       └── createdAt
└── office/
    └── location/
        ├── id
        ├── name
        ├── latitude
        ├── longitude
        ├── radiusMeters
        ├── espIpAddress
        └── espSsid
```

## 🔧 ESP32 API Endpoints

ESP32 cihazının aşağıdaki endpoint'leri sağlaması gerekmektedir:

- `GET /door/open` - Kapıyı aç
- `GET /door/close` - Kapıyı kapat
- `GET /door/status` - Kapı durumunu al
- `GET /ping` - Bağlantı kontrolü

## 🛠️ Kurulum

1. Flutter bağımlılıklarını yükleyin:
```bash
flutter pub get
```

2. Firebase projenizi yapılandırın (zaten yapılandırılmış)

3. Firebase RTDB'de office location ayarlayın:
```json
{
  "office": {
    "location": {
      "id": "main-office",
      "name": "Main Office",
      "latitude": 41.0082,
      "longitude": 28.9784,
      "radiusMeters": 100,
      "espIpAddress": "192.168.1.100",
      "espSsid": "Office_ESP32"
    }
  }
}
```

4. Admin kullanıcı oluşturun (Firebase Console'dan veya ilk kullanıcıyı manuel ekleyin)

5. Uygulamayı çalıştırın:
```bash
flutter run
```

## 📦 Bağımlılıklar

- `firebase_core` - Firebase
- `firebase_auth` - Authentication
- `firebase_database` - Realtime Database
- `geolocator` - Konum servisleri
- `permission_handler` - İzin yönetimi
- `network_info_plus` - WiFi bilgisi
- `http` - HTTP istekleri
- `provider` - State management
- `google_fonts` - Özel fontlar
- `flutter_spinkit` - Loading animasyonları
- `intl` - Tarih/saat formatlama
- `uuid` - Benzersiz ID oluşturma
- `shared_preferences` - Yerel depolama

## 🎨 Tema

Uygulama koyu tema kullanmaktadır:
- **Ana Renk**: Zeytin Yeşili (#8B7355)
- **Vurgu Rengi**: Altın (#D4AF37)
- **Arka Plan**: Koyu Kahverengi (#1A1A18)
- **Font**: DM Sans

## 📄 Lisans

Bu proje özel kullanım içindir.
