import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';  // ✅ 이 줄 추가!
import '/presentation/viewmodel/doctor/d_consultation_record_viewmodel.dart';
import '/presentation/model/doctor/d_consultation_record.dart';
import 'd_result_detail_screen.dart';

class DInferenceResultScreen extends StatefulWidget {
  final String baseUrl;

  const DInferenceResultScreen({super.key, required this.baseUrl});

  @override
  State<DInferenceResultScreen> createState() => _DInferenceResultScreenState();
}

class _DInferenceResultScreenState extends State<DInferenceResultScreen> {
  @override
  void initState() {
    super.initState();
    final viewModel = context.read<ConsultationRecordViewModel>();
    final userId = context.read<AuthViewModel>().currentUser?.registerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userId != null) {
        viewModel.fetchRecords(userId);  // ✅ 인자 전달
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ConsultationRecordViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '진단 결과 목록',
          style: textTheme.headlineLarge,
        ),
        elevation: 1,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.error != null
              ? Center(
                  child: Text(
                    '오류: ${viewModel.error}',
                    style: textTheme.bodyMedium,
                  ),
                )
              : _buildListView(viewModel.records, textTheme),
    );
  }

  Widget _buildListView(List<ConsultationRecord> records, TextTheme textTheme) {
    final sortedRecords = List.from(records)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final imageBaseUrl = widget.baseUrl.replaceAll('/api', '');

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sortedRecords.length,
      itemBuilder: (context, index) {
        final record = sortedRecords[index];
        final listIndex = sortedRecords.length - index;

        String formattedTime = '시간 정보 없음';
        try {
          final parts = record.originalImagePath.split('/').last.split('_');
          if (parts.length >= 2) {
            final t = parts[1];
            formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(
              '${t.substring(0, 4)}-${t.substring(4, 6)}-${t.substring(6, 8)} ${t.substring(8, 10)}:${t.substring(10, 12)}:00',
            ));
          }
        } catch (e) {
          formattedTime = '시간 파싱 오류';
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              '[$listIndex] $formattedTime',
              style: textTheme.labelLarge,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('사용자 ID: ${record.userId}', style: textTheme.bodyMedium),
                Text('파일명: ${record.originalImageFilename}', style: textTheme.bodyMedium),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultDetailScreen(
                    originalImageUrl: '$imageBaseUrl${record.originalImagePath}',
                    processedImageUrls: {
                      1: '$imageBaseUrl${record.processedImagePath}',
                    },
                    modelInfos: {
                      1: {
                        'model_used': record.modelUsed,
                        'confidence': record.confidence ?? 0.0,
                        'class_name': 'Dental Issue', // 필요 시 class name 수정
                        'lesion_points': record.lesionPoints ?? [],
                      },
                    },
                    userId: record.userId,
                    inferenceResultId: record.id,
                    baseUrl: widget.baseUrl,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
