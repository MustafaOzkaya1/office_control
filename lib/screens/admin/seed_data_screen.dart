import 'package:flutter/material.dart';
import 'package:office_control/utils/app_theme.dart';
import 'package:office_control/utils/seed_bulk_data.dart';

class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  bool _isSeeding = false;
  final List<String> _logs = [];

  Future<void> _seedFullData() async {
    setState(() {
      _isSeeding = true;
      _logs.clear();
    });

    _addLog('Toplu veri olusturma basliyor...');

    try {
      await SeedBulkData.seedAll();
      _addLog('TAMAMLANDI!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toplu veri basariyla olusturuldu!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      _addLog('HATA: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isSeeding = false);
  }

  Future<void> _seedSampleData() async {
    setState(() {
      _isSeeding = true;
      _logs.clear();
    });

    _addLog('Ornek veri olusturma basliyor (10 calisan)...');

    try {
      await SeedBulkData.seedSample(count: 10);
      _addLog('TAMAMLANDI! (10 ornek calisan)');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ornek veri basariyla olusturuldu!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _addLog('HATA: $e');
    }

    setState(() => _isSeeding = false);
  }

  void _addLog(String message) {
    setState(() => _logs.add(message));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplu Veri Olustur'),
        backgroundColor: AppColors.cardBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context),
            const SizedBox(height: 24),
            _buildButtons(),
            const SizedBox(height: 24),
            if (_logs.isNotEmpty) _buildLogSection(context),
            const SizedBox(height: 24),
            _buildDataStructureCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                'Veri Olusturma Hakkinda',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Calisan Sayisi', '100 kisi'),
          _buildInfoRow('Donem', 'Son 10 ay'),
          _buildInfoRow('Giris Saati', '~08:00 (+-1.5 saat)'),
          _buildInfoRow('Cikis Saati', '~17:00 (+-2 saat)'),
          _buildInfoRow('Gorev/Kisi', '5-15 adet'),
          const Divider(height: 24),
          Text(
            'Bu islem Firebase e cok sayida veri yazacaktir.',
            style: TextStyle(color: AppColors.warning, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSeeding ? null : _seedSampleData,
            icon: _isSeeding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.science),
            label: const Text('Ornek (10 Kisi)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSeeding ? null : _seedFullData,
            icon: _isSeeding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            label: const Text('Tam (100 Kisi)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Islem Gunlugu',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.builder(
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _logs[index],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.greenAccent,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataStructureCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: AppColors.accent),
              const SizedBox(width: 12),
              Text(
                'Firebase Veri Yapisi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'users/\n'
              '  {uid}/\n'
              '    - email, firstName, lastName...\n'
              '    attendance/\n'
              '      {yyyy-MM-dd}/\n'
              '        - totalMinutesWorked\n'
              '        records/\n'
              '          {recordId}/\n'
              '    tasks/\n'
              '      {taskId}/\n'
              '        - title, status, difficulty',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

