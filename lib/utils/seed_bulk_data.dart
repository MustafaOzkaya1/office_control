import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:office_control/models/user_model.dart';
import 'package:office_control/models/task_model.dart';
import 'package:office_control/models/attendance_model.dart';
import 'package:uuid/uuid.dart';

/// 100 çalışan ve 10 aylık veri oluşturur
class SeedBulkData {
  static final _random = Random();
  static final _uuid = const Uuid();
  static final _db = FirebaseDatabase.instance;

  // Türk isimleri
  static final List<String> _firstNames = [
    'Ahmet',
    'Mehmet',
    'Mustafa',
    'Ali',
    'Hüseyin',
    'Hasan',
    'İbrahim',
    'Ömer',
    'Yusuf',
    'Murat',
    'Emre',
    'Burak',
    'Cem',
    'Deniz',
    'Ege',
    'Fatih',
    'Gökhan',
    'Halil',
    'İsmail',
    'Kadir',
    'Levent',
    'Mahmut',
    'Necati',
    'Oğuz',
    'Polat',
    'Rıza',
    'Serkan',
    'Tarık',
    'Uğur',
    'Volkan',
    'Yılmaz',
    'Zafer',
    'Baran',
    'Caner',
    'Doruk',
    'Erdem',
    'Furkan',
    'Görkem',
    'Harun',
    'Kaan',
    'Ayşe',
    'Fatma',
    'Zeynep',
    'Elif',
    'Merve',
    'Büşra',
    'Esra',
    'Selin',
    'Deniz',
    'Ebru',
    'Gamze',
    'Hande',
    'İrem',
    'Jale',
    'Kübra',
    'Leman',
    'Melis',
    'Naz',
    'Özge',
    'Pınar',
    'Rabia',
    'Sibel',
    'Tuğba',
    'Ülkü',
    'Vildan',
    'Yasemin',
    'Zehra',
    'Aslı',
    'Başak',
    'Cansu',
    'Damla',
    'Ece',
    'Fulya',
    'Gül',
    'Hilal',
    'Işıl',
    'Kardelen',
    'Lale',
  ];

  static final List<String> _lastNames = [
    'Yılmaz',
    'Kaya',
    'Demir',
    'Çelik',
    'Şahin',
    'Yıldız',
    'Yıldırım',
    'Öztürk',
    'Aydın',
    'Özdemir',
    'Arslan',
    'Doğan',
    'Kılıç',
    'Aslan',
    'Çetin',
    'Kara',
    'Koç',
    'Kurt',
    'Özkan',
    'Şimşek',
    'Polat',
    'Korkmaz',
    'Çakır',
    'Erdoğan',
    'Güneş',
    'Ak',
    'Acar',
    'Aktaş',
    'Akın',
    'Aksoy',
    'Akyüz',
    'Albayrak',
    'Altın',
    'Arıkan',
    'Ateş',
    'Avcı',
    'Aygün',
    'Bal',
    'Başaran',
    'Bayrak',
    'Bilgin',
    'Bozkurt',
    'Bulut',
    'Can',
    'Ceylan',
    'Coşkun',
    'Dağ',
    'Demirci',
    'Dinç',
    'Duran',
    'Ekinci',
    'Elmas',
    'Erdem',
    'Ergün',
    'Eroğlu',
    'Ersoy',
    'Güler',
    'Gümüş',
    'Güngör',
    'Işık',
    'Kahraman',
    'Kaplan',
    'Karaca',
  ];

  static final List<String> _positions = [
    'Yazılım Geliştirici',
    'Kıdemli Yazılım Geliştirici',
    'Frontend Developer',
    'Backend Developer',
    'Full Stack Developer',
    'Mobile Developer',
    'DevOps Mühendisi',
    'QA Mühendisi',
    'UI/UX Tasarımcı',
    'Grafik Tasarımcı',
    'Proje Yöneticisi',
    'Ürün Yöneticisi',
    'Scrum Master',
    'İş Analisti',
    'Veri Analisti',
    'Data Scientist',
    'Sistem Yöneticisi',
    'Network Uzmanı',
    'Siber Güvenlik Uzmanı',
    'Teknik Destek',
    'Müşteri İlişkileri',
    'İnsan Kaynakları',
    'Muhasebe Uzmanı',
    'Pazarlama Uzmanı',
    'Satış Temsilcisi',
    'Stajyer',
  ];

  static final List<String> _taskTitles = [
    'API endpoint geliştirme',
    'Veritabanı optimizasyonu',
    'UI komponent tasarımı',
    'Bug fix - login ekranı',
    'Kullanıcı testleri',
    'Dokümantasyon güncelleme',
    'Code review',
    'Sprint planlama',
    'Performans analizi',
    'Güvenlik taraması',
    'Mobil uygulama güncelleme',
    'Dashboard geliştirme',
    'Raporlama modülü',
    'Bildirim sistemi',
    'Ödeme entegrasyonu',
    'E-posta şablonları',
    'Cache mekanizması',
    'Log sistemi kurulumu',
    'Yedekleme sistemi',
    'CI/CD pipeline',
    'Unit test yazımı',
    'Integration test',
    'Load testing',
    'Müşteri toplantısı',
    'Proje sunumu hazırlama',
    'Haftalık rapor',
    'Tasarım revizyonu',
    'Veritabanı migration',
    'Server kurulumu',
    'SSL sertifika yenileme',
    'Domain yapılandırması',
    'Firewall kuralları',
    'Kullanıcı eğitimi',
    'Sistem bakımı',
    'Yeni özellik araştırması',
    'Rakip analizi',
    'A/B test analizi',
    'SEO optimizasyonu',
    'Sosyal medya içerik',
    'Blog yazısı hazırlama',
  ];

  static String _randomPhone() {
    return '+90 5${_random.nextInt(10)}${_random.nextInt(10)} ${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)} ${_random.nextInt(10)}${_random.nextInt(10)} ${_random.nextInt(10)}${_random.nextInt(10)}';
  }

  static DateTime _randomEntryTime(DateTime date) {
    // Çoğu kişi 7:30-9:00 arası gelir, bazıları geç kalır
    int hour = 8;
    int minute = 0;

    final chance = _random.nextDouble();
    if (chance < 0.1) {
      // %10 erken gelenler (7:00-7:30)
      hour = 7;
      minute = _random.nextInt(30);
    } else if (chance < 0.3) {
      // %20 tam zamanında (7:45-8:15)
      hour = _random.nextBool() ? 7 : 8;
      minute = hour == 7 ? 45 + _random.nextInt(15) : _random.nextInt(15);
    } else if (chance < 0.7) {
      // %40 normal (8:00-8:45)
      hour = 8;
      minute = _random.nextInt(45);
    } else if (chance < 0.9) {
      // %20 biraz geç (8:45-9:30)
      hour = _random.nextBool() ? 8 : 9;
      minute = hour == 8 ? 45 + _random.nextInt(15) : _random.nextInt(30);
    } else {
      // %10 çok geç (9:30-10:30)
      hour = _random.nextBool() ? 9 : 10;
      minute = hour == 9 ? 30 + _random.nextInt(30) : _random.nextInt(30);
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
      _random.nextInt(60),
    );
  }

  static DateTime _randomExitTime(DateTime date, DateTime entryTime) {
    // Çoğu kişi 17:00-18:30 arası çıkar
    int hour = 17;
    int minute = 0;

    final chance = _random.nextDouble();
    if (chance < 0.05) {
      // %5 çok erken çıkanlar (15:00-16:00) - izin vs
      hour = 15 + _random.nextInt(2);
      minute = _random.nextInt(60);
    } else if (chance < 0.15) {
      // %10 erken çıkanlar (16:00-17:00)
      hour = 16;
      minute = _random.nextInt(60);
    } else if (chance < 0.5) {
      // %35 normal (17:00-17:30)
      hour = 17;
      minute = _random.nextInt(30);
    } else if (chance < 0.8) {
      // %30 biraz geç (17:30-18:30)
      hour = _random.nextBool() ? 17 : 18;
      minute = hour == 17 ? 30 + _random.nextInt(30) : _random.nextInt(30);
    } else {
      // %20 mesai (18:30-21:00)
      hour = 18 + _random.nextInt(3);
      minute = hour == 18 ? 30 + _random.nextInt(30) : _random.nextInt(60);
    }

    // En az 4 saat çalışmış olsun
    final exitTime = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
      _random.nextInt(60),
    );
    if (exitTime.difference(entryTime).inHours < 4) {
      return entryTime.add(
        Duration(hours: 4 + _random.nextInt(4), minutes: _random.nextInt(60)),
      );
    }

    return exitTime;
  }

  static bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  static bool _shouldWorkToday(DateTime date) {
    if (_isWeekend(date)) return false;
    // %5 izin/hastalık
    return _random.nextDouble() > 0.05;
  }

  static TaskDifficulty _randomDifficulty() {
    final chance = _random.nextDouble();
    if (chance < 0.3) return TaskDifficulty.easy;
    if (chance < 0.65) return TaskDifficulty.medium;
    if (chance < 0.9) return TaskDifficulty.hard;
    return TaskDifficulty.veryHard;
  }

  static TaskStatus _randomStatus(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt).inDays;
    final chance = _random.nextDouble();

    if (age > 30) {
      // Eski taskler büyük ihtimalle tamamlanmış
      if (chance < 0.85) return TaskStatus.done;
      if (chance < 0.95) return TaskStatus.inProgress;
      return TaskStatus.todo;
    } else if (age > 7) {
      if (chance < 0.6) return TaskStatus.done;
      if (chance < 0.85) return TaskStatus.inProgress;
      return TaskStatus.todo;
    } else {
      if (chance < 0.3) return TaskStatus.done;
      if (chance < 0.6) return TaskStatus.inProgress;
      return TaskStatus.todo;
    }
  }

  /// 100 çalışan ve 10 aylık veri oluşturur
  static Future<void> seedAll() async {
    print('🚀 Toplu veri oluşturma başlıyor...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final employees = <Map<String, dynamic>>[];
    final usedNames = <String>{};

    // 100 çalışan oluştur
    print('👥 100 çalışan oluşturuluyor...');
    for (int i = 0; i < 100; i++) {
      String firstName, lastName, fullName;
      do {
        firstName = _firstNames[_random.nextInt(_firstNames.length)];
        lastName = _lastNames[_random.nextInt(_lastNames.length)];
        fullName = '$firstName $lastName';
      } while (usedNames.contains(fullName));
      usedNames.add(fullName);

      final uid = _uuid.v4();
      final email =
          '${firstName.toLowerCase()}.${lastName.toLowerCase()}${i}@sirket.com'
              .replaceAll('ı', 'i')
              .replaceAll('ğ', 'g')
              .replaceAll('ü', 'u')
              .replaceAll('ş', 's')
              .replaceAll('ö', 'o')
              .replaceAll('ç', 'c')
              .replaceAll('İ', 'I');

      // 10 ay önce ile 1 ay önce arası rastgele işe başlama
      final startMonthsAgo = 1 + _random.nextInt(10);
      final createdAt = DateTime.now().subtract(
        Duration(days: startMonthsAgo * 30 + _random.nextInt(28)),
      );

      employees.add({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'position': _positions[_random.nextInt(_positions.length)],
        'phone': _randomPhone(),
        'role': 'employee',
        'createdAt': createdAt.toIso8601String(),
        'isApproved': true,
        'startDate': createdAt,
      });

      if ((i + 1) % 20 == 0) {
        print('   ✓ ${i + 1}/100 çalışan oluşturuldu');
      }
    }

    print('✅ 100 çalışan bilgisi hazır');
    print('');

    // Firebase'e çalışanları ekle
    print('📤 Çalışanlar Firebase\'e yükleniyor...');
    for (int i = 0; i < employees.length; i++) {
      final emp = employees[i];
      await _db.ref('users/${emp['uid']}').set({
        'uid': emp['uid'],
        'email': emp['email'],
        'firstName': emp['firstName'],
        'lastName': emp['lastName'],
        'position': emp['position'],
        'phone': emp['phone'],
        'role': emp['role'],
        'createdAt': emp['createdAt'],
        'isApproved': emp['isApproved'],
      });

      if ((i + 1) % 20 == 0) {
        print('   ✓ ${i + 1}/100 çalışan yüklendi');
      }
    }
    print('✅ Çalışanlar yüklendi');
    print('');

    // Her çalışan için attendance ve task verisi oluştur
    print('📊 Devam ve görev verileri oluşturuluyor...');
    final now = DateTime.now();

    for (int empIndex = 0; empIndex < employees.length; empIndex++) {
      final emp = employees[empIndex];
      final uid = emp['uid'] as String;
      final startDate = emp['startDate'] as DateTime;

      // Attendance verisi oluştur
      DateTime currentDate = startDate;
      while (currentDate.isBefore(now)) {
        if (_shouldWorkToday(currentDate)) {
          final entryTime = _randomEntryTime(currentDate);
          final exitTime = _randomExitTime(currentDate, entryTime);
          final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);

          final entryId = _uuid.v4();
          final exitId = _uuid.v4();

          final entryRecord = {
            'id': entryId,
            'userId': uid,
            'type': 'entry',
            'timestamp': entryTime.toIso8601String(),
            'location': 'Main Office',
            'doorId': 'main-office',
          };

          final exitRecord = {
            'id': exitId,
            'userId': uid,
            'type': 'exit',
            'timestamp': exitTime.toIso8601String(),
            'location': 'Main Office',
            'doorId': 'main-office',
          };

          final totalMinutes = exitTime.difference(entryTime).inMinutes;

          await _db.ref('users/$uid/attendance/$dateKey').set({
            'date': dateKey,
            'userId': uid,
            'totalMinutesWorked': totalMinutes,
            'records': {entryId: entryRecord, exitId: exitRecord},
          });
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Task verisi oluştur (5-15 arası task)
      final taskCount = 5 + _random.nextInt(11);
      for (int t = 0; t < taskCount; t++) {
        final taskId = _uuid.v4();
        final daysAgo = _random.nextInt(
          now.difference(startDate).inDays.clamp(1, 300),
        );
        final createdAt = now.subtract(Duration(days: daysAgo));
        final status = _randomStatus(createdAt);
        final difficulty = _randomDifficulty();

        DateTime? startedAt;
        DateTime? completedAt;
        int? durationMinutes;

        if (status == TaskStatus.inProgress || status == TaskStatus.done) {
          startedAt = createdAt.add(Duration(hours: _random.nextInt(48)));
        }

        if (status == TaskStatus.done && startedAt != null) {
          // Zorluğa göre süre
          final baseMinutes = {
            TaskDifficulty.easy: 30,
            TaskDifficulty.medium: 120,
            TaskDifficulty.hard: 300,
            TaskDifficulty.veryHard: 600,
          }[difficulty]!;

          durationMinutes = baseMinutes + _random.nextInt(baseMinutes);
          completedAt = startedAt.add(Duration(minutes: durationMinutes));
        }

        final task = {
          'id': taskId,
          'userId': uid,
          'title': _taskTitles[_random.nextInt(_taskTitles.length)],
          'description': _random.nextBool()
              ? 'Detaylı açıklama ve notlar...'
              : null,
          'status': status.name,
          'difficulty': difficulty.name,
          'createdAt': createdAt.toIso8601String(),
          'startedAt': startedAt?.toIso8601String(),
          'completedAt': completedAt?.toIso8601String(),
          'durationMinutes': durationMinutes,
        };

        await _db.ref('users/$uid/tasks/$taskId').set(task);
      }

      if ((empIndex + 1) % 10 == 0) {
        print('   ✓ ${empIndex + 1}/100 çalışan verisi tamamlandı');
      }
    }

    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎉 TOPLU VERİ OLUŞTURMA TAMAMLANDI!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Oluşturulan veriler:');
    print('   • 100 çalışan');
    print('   • ~10 ay devam kaydı (hafta içi günler)');
    print('   • 500-1500 arası görev');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Sadece belirli sayıda çalışan için veri oluşturur (test için)
  static Future<void> seedSample({int count = 10}) async {
    print('🚀 Örnek veri oluşturma başlıyor ($count çalışan)...');

    final employees = <Map<String, dynamic>>[];
    final usedNames = <String>{};

    for (int i = 0; i < count; i++) {
      String firstName, lastName, fullName;
      do {
        firstName = _firstNames[_random.nextInt(_firstNames.length)];
        lastName = _lastNames[_random.nextInt(_lastNames.length)];
        fullName = '$firstName $lastName';
      } while (usedNames.contains(fullName));
      usedNames.add(fullName);

      final uid = _uuid.v4();
      final email =
          '${firstName.toLowerCase()}.${lastName.toLowerCase()}${i}@sirket.com'
              .replaceAll('ı', 'i')
              .replaceAll('ğ', 'g')
              .replaceAll('ü', 'u')
              .replaceAll('ş', 's')
              .replaceAll('ö', 'o')
              .replaceAll('ç', 'c');

      final startMonthsAgo = 1 + _random.nextInt(10);
      final createdAt = DateTime.now().subtract(
        Duration(days: startMonthsAgo * 30),
      );

      employees.add({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'position': _positions[_random.nextInt(_positions.length)],
        'phone': _randomPhone(),
        'startDate': createdAt,
      });

      // Firebase'e ekle
      await _db.ref('users/$uid').set({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'position': employees.last['position'],
        'phone': employees.last['phone'],
        'role': 'employee',
        'createdAt': createdAt.toIso8601String(),
        'isApproved': true,
      });

      // Son 30 gün attendance
      final now = DateTime.now();
      DateTime currentDate = createdAt;
      while (currentDate.isBefore(now)) {
        if (_shouldWorkToday(currentDate)) {
          final entryTime = _randomEntryTime(currentDate);
          final exitTime = _randomExitTime(currentDate, entryTime);
          final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);

          final entryId = _uuid.v4();
          final exitId = _uuid.v4();

          await _db.ref('users/$uid/attendance/$dateKey').set({
            'date': dateKey,
            'userId': uid,
            'totalMinutesWorked': exitTime.difference(entryTime).inMinutes,
            'records': {
              entryId: {
                'id': entryId,
                'userId': uid,
                'type': 'entry',
                'timestamp': entryTime.toIso8601String(),
                'location': 'Main Office',
              },
              exitId: {
                'id': exitId,
                'userId': uid,
                'type': 'exit',
                'timestamp': exitTime.toIso8601String(),
                'location': 'Main Office',
              },
            },
          });
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 5-10 task
      final taskCount = 5 + _random.nextInt(6);
      for (int t = 0; t < taskCount; t++) {
        final taskId = _uuid.v4();
        final daysAgo = _random.nextInt(90);
        final taskCreatedAt = now.subtract(Duration(days: daysAgo));
        final status = _randomStatus(taskCreatedAt);
        final difficulty = _randomDifficulty();

        await _db.ref('users/$uid/tasks/$taskId').set({
          'id': taskId,
          'userId': uid,
          'title': _taskTitles[_random.nextInt(_taskTitles.length)],
          'status': status.name,
          'difficulty': difficulty.name,
          'createdAt': taskCreatedAt.toIso8601String(),
        });
      }

      print('✓ ${i + 1}/$count: $fullName');
    }

    print('🎉 Örnek veri oluşturma tamamlandı!');
  }
}
