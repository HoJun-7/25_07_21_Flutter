import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '/presentation/viewmodel/doctor/d_consultation_record_viewmodel.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/model/doctor/d_consultation_record.dart';
import 'result_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String baseUrl;

  const HistoryScreen({super.key, required this.baseUrl});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    final viewModel = context.read<ConsultationRecordViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthViewModel>().currentUser?.registerId;
      if (userId != null) {
        viewModel.fetchRecords(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ConsultationRecordViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('이전 진단 기록'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3869A8),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFDCE7F6),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.error != null
              ? Center(child: Text('오류: ${viewModel.error}'))
              : currentUser == null
                  ? const Center(child: Text('로그인이 필요합니다.'))
                  : _buildListView(
                      viewModel.records.where((r) => r.userId == currentUser.registerId).toList(),
                    ),
    );
  }

  Widget _buildListView(List<ConsultationRecord> records) {
    final imageBaseUrl = widget.baseUrl.replaceAll('/api', '');

    final List<ConsultationRecord> sortedRecords = List.from(records)
      ..sort((a, b) {
        final atime = _extractDateTimeFromFilename(a.originalImagePath);
        final btime = _extractDateTimeFromFilename(b.originalImagePath);
        return btime.compareTo(atime);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedRecords.length,
      itemBuilder: (context, index) {
        final record = sortedRecords[index];
        final listIndex = sortedRecords.length - index;

        String formattedTime;
        try {
          final time = _extractDateTimeFromFilename(record.originalImagePath);
          formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(time);
        } catch (e) {
          formattedTime = '시간 파싱 오류';
        }

        // ✅ "processed_" 제거한 파일명 추출
        final modelFilename = getModelFilename(record.originalImagePath);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              '[$listIndex] $formattedTime',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('사용자 ID: ${record.userId}'),
                Text('파일명: $modelFilename'),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultDetailScreen(
                    originalImageUrl: '$imageBaseUrl${record.originalImagePath}',
                    processedImageUrls: {
                      1: '$imageBaseUrl/images/model1/$modelFilename',
                      //1: '$imageBaseUrl${record.processedImagePath}',
                      2: '$imageBaseUrl/images/model2/$modelFilename',
                      3: '$imageBaseUrl/images/model3/$modelFilename',
                    },
                    modelInfos: {
                      1: {
                        'model_used': record.modelUsed,
                        'confidence': record.confidence ?? 0.0,
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

  DateTime _extractDateTimeFromFilename(String imagePath) {
    final filename = imagePath.split('/').last;
    final parts = filename.split('_');
    if (parts.length < 2) throw FormatException('잘못된 파일명 형식: $filename');
    final timePart = parts[1];
    final y = timePart.substring(0, 4);
    final m = timePart.substring(4, 6);
    final d = timePart.substring(6, 8);
    final h = timePart.substring(8, 10);
    final min = timePart.substring(10, 12);
    final sec = timePart.substring(12, 14);
    return DateTime.parse('$y-$m-$d' 'T' '$h:$min:$sec');
  }

  // ✅ "processed_" 제거 함수
  String getModelFilename(String path) {
    final filename = path.split('/').last;
    return filename.replaceFirst('processed_', '');
  }
}
