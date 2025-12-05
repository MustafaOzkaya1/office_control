import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:office_control/models/office_location_model.dart';
import 'package:office_control/services/database_service.dart';
import 'package:office_control/services/location_service.dart';
import 'package:office_control/utils/app_theme.dart';
import 'package:office_control/widgets/custom_text_field.dart';
import 'package:office_control/widgets/custom_button.dart';

class OfficeLocationScreen extends StatefulWidget {
  const OfficeLocationScreen({super.key});

  @override
  State<OfficeLocationScreen> createState() => _OfficeLocationScreenState();
}

class _OfficeLocationScreenState extends State<OfficeLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  final _locationService = LocationService();

  final _nameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _radiusController = TextEditingController();
  final _espIpController = TextEditingController();
  final _espSsidController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGettingLocation = false;
  OfficeLocation? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final location = await _dbService.getOfficeLocation();
      if (location != null) {
        _currentLocation = location;
        _nameController.text = location.name;
        _latitudeController.text = location.latitude.toString();
        _longitudeController.text = location.longitude.toString();
        _radiusController.text = location.radiusMeters.toString();
        _espIpController.text = location.espIpAddress ?? '';
        _espSsidController.text = location.espSsid ?? '';
      } else {
        // Default values
        _radiusController.text = '100';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yükleme hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final (hasPermission, isDeniedForever) = 
          await _locationService.checkAndRequestPermissionWithStatus();
      
      if (!hasPermission) {
        if (mounted) {
          if (isDeniedForever) {
            _showLocationPermissionDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konum izni gerekli. Lütfen izin verin.'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      final position = await _locationService.getCurrentPosition();
      
      if (position != null) {
        setState(() {
          _latitudeController.text = position.latitude.toStringAsFixed(6);
          _longitudeController.text = position.longitude.toStringAsFixed(6);
        });
        
        if (mounted) {
          // Konum alındıktan sonra otomatik kaydetme seçeneği sun
          _showSaveLocationDialog(position.latitude, position.longitude);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum alınamadı. Lütfen tekrar deneyin.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isGettingLocation = false);
  }

  void _showSaveLocationDialog(double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppColors.success),
            SizedBox(width: 8),
            Text('Konum Alındı'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mevcut konumunuz:'),
            const SizedBox(height: 8),
            Text(
              'Enlem: ${latitude.toStringAsFixed(6)}\nBoylam: ${longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text('Bu konumu ofis konumu olarak kaydetmek ister misiniz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Sadece koordinatları kaydet, diğer alanlar mevcut değerlerini korur
              await _saveLocationWithCoordinates(latitude, longitude);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLocationWithCoordinates(double latitude, double longitude) async {
    setState(() => _isSaving = true);

    try {
      // Mevcut değerleri koru, sadece koordinatları güncelle
      final location = OfficeLocation(
        id: _currentLocation?.id ?? 'main-office',
        name: _nameController.text.trim().isEmpty 
            ? (_currentLocation?.name ?? 'Ana Ofis')
            : _nameController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        radiusMeters: _radiusController.text.trim().isEmpty
            ? (_currentLocation?.radiusMeters ?? 100.0)
            : double.parse(_radiusController.text.trim()),
        espIpAddress: _espIpController.text.trim().isEmpty
            ? _currentLocation?.espIpAddress
            : _espIpController.text.trim(),
        espSsid: _espSsidController.text.trim().isEmpty
            ? _currentLocation?.espSsid
            : _espSsidController.text.trim(),
      );

      await _dbService.updateOfficeLocation(location);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ofis konumu başarıyla kaydedildi!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Mevcut konumu yeniden yükle
        await _loadCurrentLocation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Konum İzni Gerekli'),
          ],
        ),
        content: const Text(
          'Konum bilgisi alabilmek için konum iznine ihtiyacımız var. Lütfen ayarlardan konum iznini etkinleştirin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final location = OfficeLocation(
        id: _currentLocation?.id ?? 'main-office',
        name: _nameController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        radiusMeters: double.parse(_radiusController.text.trim()),
        espIpAddress: _espIpController.text.trim().isEmpty
            ? null
            : _espIpController.text.trim(),
        espSsid: _espSsidController.text.trim().isEmpty
            ? null
            : _espSsidController.text.trim(),
      );

      await _dbService.updateOfficeLocation(location);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ofis konumu başarıyla kaydedildi!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        // Mevcut konumu yeniden yükle
        await _loadCurrentLocation();
        // Kısa bir gecikme sonrası geri dön
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme hatası: $e\nLütfen Firebase Rules kontrol edin.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    _espIpController.dispose();
    _espSsidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofis Konumu Ayarları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.info),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Çalışanlar kapı açmak için bu konumun belirtilen yarıçapı içinde olmalıdır.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.info,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Office Name
                    CustomTextField(
                      controller: _nameController,
                      label: 'Ofis Adı',
                      hint: 'Ana Ofis',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ofis adı gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    Text(
                      'Konum Bilgileri',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Get Current Location Button
                    OutlinedButton.icon(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _isGettingLocation
                            ? 'Konum Alınıyor...'
                            : 'Mevcut Konumu Kullan',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Latitude & Longitude
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _latitudeController,
                            label: 'Enlem (Latitude)',
                            hint: '41.0082',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enlem gerekli';
                              }
                              final lat = double.tryParse(value);
                              if (lat == null || lat < -90 || lat > 90) {
                                return 'Geçersiz enlem';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _longitudeController,
                            label: 'Boylam (Longitude)',
                            hint: '28.9784',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Boylam gerekli';
                              }
                              final lon = double.tryParse(value);
                              if (lon == null || lon < -180 || lon > 180) {
                                return 'Geçersiz boylam';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Radius
                    CustomTextField(
                      controller: _radiusController,
                      label: 'Erişim Yarıçapı (metre)',
                      hint: '100',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Yarıçap gerekli';
                        }
                        final radius = double.tryParse(value);
                        if (radius == null || radius <= 0) {
                          return 'Geçerli bir yarıçap girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Çalışanların kapıyı açabilmesi için ofise ne kadar yakın olması gerektiğini belirler.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // ESP32 Section
                    Text(
                      'ESP32 Ayarları',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _espIpController,
                            label: 'ESP32 IP Adresi',
                            hint: '192.168.1.100',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _espSsidController,
                            label: 'ESP32 WiFi SSID',
                            hint: 'Office_ESP32',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    CustomButton(
                      text: 'Kaydet',
                      isLoading: _isSaving,
                      icon: Icons.save,
                      onPressed: _saveLocation,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

