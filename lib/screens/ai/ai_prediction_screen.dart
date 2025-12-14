import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:office_control/models/ai_interaction_model.dart';
import 'package:office_control/providers/auth_provider.dart';
import 'package:office_control/services/database_service.dart';
import 'package:office_control/utils/app_theme.dart';

class AIPredictionScreen extends StatefulWidget {
  const AIPredictionScreen({super.key});

  @override
  State<AIPredictionScreen> createState() => _AIPredictionScreenState();
}

class _AIPredictionScreenState extends State<AIPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedDifficulty = 'medium';
  final DatabaseService _databaseService = DatabaseService();
  StreamSubscription<AIPredictResponse?>? _responseSubscription;
  AIPredictResponse? _currentResponse;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _responseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _askAI() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgisi bulunamadı'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _currentResponse = null;
    });

    // İsteği gönder
    await _databaseService.sendAIPredictRequest(
      uid: uid,
      description: _descriptionController.text.trim(),
      difficulty: _selectedDifficulty,
    );

    // Cevabı dinle
    _responseSubscription?.cancel();
    _responseSubscription = _databaseService
        .aiPredictResponseStream(uid)
        .listen((response) {
          if (mounted) {
            setState(() {
              _currentResponse = response;
              if (response != null && (response.hasData || response.hasError)) {
                _isLoading = false;
              }
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Tahmin Modülü')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: AppColors.accent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bu iş ne kadar sürer?',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AI\'ya işinizi anlatın, tahmini süreyi öğrenin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // İş Açıklaması
              Text(
                'İş Açıklaması',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Örn: SQL optimizasyonu, API endpoint geliştirme, UI tasarımı...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen iş açıklaması girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Zorluk Seviyesi
              Text(
                'Zorluk Seviyesi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _DifficultySelector(
                selectedDifficulty: _selectedDifficulty,
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Sor Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _askAI,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('AI\'ya Sor'),
                ),
              ),
              const SizedBox(height: 24),

              // Cevap Gösterimi
              if (_currentResponse != null)
                _ResponseCard(response: _currentResponse!),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  final String selectedDifficulty;
  final ValueChanged<String> onChanged;

  const _DifficultySelector({
    required this.selectedDifficulty,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final difficulties = [
      {
        'value': 'easy',
        'label': 'Kolay',
        'icon': Icons.sentiment_satisfied_alt,
      },
      {'value': 'medium', 'label': 'Orta', 'icon': Icons.sentiment_neutral},
      {'value': 'hard', 'label': 'Zor', 'icon': Icons.sentiment_dissatisfied},
      {'value': 'very_hard', 'label': 'Çok Zor', 'icon': Icons.whatshot},
    ];

    return Row(
      children: difficulties.map((diff) {
        final isSelected = selectedDifficulty == diff['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(diff['value'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.2)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    diff['icon'] as IconData,
                    color: isSelected ? AppColors.accent : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    diff['label'] as String,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final AIPredictResponse response;

  const _ResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    if (response.hasError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                response.error ?? 'Bir hata oluştu',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    if (!response.hasData) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text('AI Tahmini', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 20),
          if (response.humanTime != null) ...[
            Text(
              'Tahmini Süre',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              response.humanTime!,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (response.predictedMinutes != null) ...[
            const SizedBox(height: 12),
            Text(
              'Yaklaşık ${response.predictedMinutes} dakika',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
