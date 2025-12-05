import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:office_control/models/user_model.dart';

/// Test hesapları oluşturmak için seed fonksiyonu
/// Bu fonksiyonu sadece bir kez çalıştırın
class SeedData {
  static Future<void> createTestAccounts() async {
    final auth = FirebaseAuth.instance;
    final db = FirebaseDatabase.instance;

    // Test Employee Hesabı
    const employeeEmail = 'employee@test.com';
    const employeePassword = 'Test123!';

    // Test Admin Hesabı
    const adminEmail = 'admin@test.com';
    const adminPassword = 'Admin123!';

    try {
      // Employee hesabı oluştur
      print('Creating employee account...');
      final employeeCredential = await auth.createUserWithEmailAndPassword(
        email: employeeEmail,
        password: employeePassword,
      );

      final employee = Employee(
        uid: employeeCredential.user!.uid,
        email: employeeEmail,
        firstName: 'Test',
        lastName: 'Employee',
        position: 'Yazılım Geliştirici',
        phone: '+90 555 111 2233',
        createdAt: DateTime.now(),
        isApproved: true,
      );

      await db.ref('users/${employee.uid}').set(employee.toMap());
      print('✓ Employee account created: $employeeEmail');

      // Sign out
      await auth.signOut();

      // Admin hesabı oluştur
      print('Creating admin account...');
      final adminCredential = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      final admin = Admin(
        uid: adminCredential.user!.uid,
        email: adminEmail,
        firstName: 'Test',
        lastName: 'Admin',
        position: 'Sistem Yöneticisi',
        phone: '+90 555 444 5566',
        createdAt: DateTime.now(),
        permissions: ['all'],
        isApproved: true,
      );

      await db.ref('users/${admin.uid}').set(admin.toMap());
      print('✓ Admin account created: $adminEmail');

      // Sign out
      await auth.signOut();

      // Office location ekle
      print('Creating office location...');
      await db.ref('office/location').set({
        'id': 'main-office',
        'name': 'Main Office',
        'latitude': 41.0082, // İstanbul koordinatları (örnek)
        'longitude': 28.9784,
        'radiusMeters': 100.0,
        'espIpAddress': '192.168.1.100',
        'espSsid': 'Office_ESP32',
      });
      print('✓ Office location created');

      // Patron komut varsayılan değeri (true = kapı erişimi aktif) - root'ta /patronkomut
      await db.ref('patronkomut').set(true);
      print('✓ Patron komut initialized (default: true)');

      print('\n========================================');
      print('TEST HESAPLARI OLUŞTURULDU!');
      print('========================================');
      print('\n📧 EMPLOYEE HESABI:');
      print('   Email: $employeeEmail');
      print('   Şifre: $employeePassword');
      print('\n👑 ADMIN HESABI:');
      print('   Email: $adminEmail');
      print('   Şifre: $adminPassword');
      print('========================================\n');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('⚠️ Hesap zaten mevcut: ${e.message}');
        print('\nMevcut hesap bilgileri:');
        print('📧 EMPLOYEE: $employeeEmail / $employeePassword');
        print('👑 ADMIN: $adminEmail / $adminPassword');
      } else {
        print('❌ Hata: ${e.message}');
      }
    } catch (e) {
      print('❌ Beklenmeyen hata: $e');
    }
  }

  /// Mevcut ofis konumunun yarıçapını 100 metreye günceller
  static Future<void> updateOfficeRadiusTo100() async {
    final db = FirebaseDatabase.instance;

    try {
      print('Updating office location radius to 100 meters...');

      // Mevcut ofis konumunu al
      final snapshot = await db.ref('office/location').get();
      if (!snapshot.exists || snapshot.value == null) {
        print('⚠️ Ofis konumu bulunamadı. Önce ofis konumu oluşturun.');
        return;
      }

      final currentData = Map<String, dynamic>.from(snapshot.value as Map);

      // Yarıçapı 100'e güncelle
      await db.ref('office/location/radiusMeters').set(100.0);

      print('✓ Ofis konumu yarıçapı 100 metreye güncellendi!');
      print('   Önceki yarıçap: ${currentData['radiusMeters']} metre');
      print('   Yeni yarıçap: 100 metre');
    } catch (e) {
      print('❌ Güncelleme hatası: $e');
    }
  }
}
