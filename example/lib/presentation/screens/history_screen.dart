import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '/presentation/viewmodel/doctor/d_consultation_record_viewmodel.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/model/doctor/d_consultation_record.dart';
import 'history_result_detail_screen.dart'; // ✅ 바뀐 상세화면 import
import 'history_xray_result_detail_screen.dart'; // ✅ X-ray용 상세화면 import

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
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildRecordList(
                                viewModel.records
                                    .where((r) => r.userId == currentUser.registerId)
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildRecordList(List<ConsultationRecord> records) {
    final imageBaseUrl = widget.baseUrl.replaceAll('/api', '');

    final List<ConsultationRecord> sortedRecords = List.from(records)
      ..sort((a, b) {
        final atime = _extractDateTimeFromFilename(a.originalImagePath);
        final btime = _extractDateTimeFromFilename(b.originalImagePath);
        return btime.compareTo(atime);
      });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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

        final modelFilename = getModelFilename(record.originalImagePath);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            trailing: record.isRequested == 'Y'
                ? Text(
                    record.isReplied == 'Y' ? '🟢 답변 완료' : '🔵 신청중',
                    style: TextStyle(
                      color: record.isReplied == 'Y' ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : null,
            onTap: () {
              final isXray = record.imageType == 'xray';
              final originalUrl = '$imageBaseUrl${record.originalImagePath}';
              final model1Url = '$imageBaseUrl/images/${isXray ? 'xmodel1' : 'model1'}/$modelFilename';
              final model2Url = '$imageBaseUrl/images/${isXray ? 'xmodel2' : 'model2'}/$modelFilename';

              final screen = isXray
                  ? HistoryXrayResultDetailScreen( // ✅ 만들 예정인 새 화면
                      originalImageUrl: originalUrl,
                      model1ImageUrl: model1Url,
                      model2ImageUrl: model2Url,
                      model1Result: record.model1InferenceResult ?? {},
                      userId: record.userId,
                      inferenceResultId: record.id,
                      baseUrl: widget.baseUrl,
                    )
                  : HistoryResultDetailScreen(
                      originalImageUrl: originalUrl,
                      processedImageUrls: {
                        1: model1Url,
                        2: model2Url,
                        3: '$imageBaseUrl/images/model3/$modelFilename',
                      },
                      modelInfos: {
                        1: record.model1InferenceResult ?? {},
                        2: record.model2InferenceResult ?? {},
                        3: record.model3InferenceResult ?? {},
                      },
                      userId: record.userId,
                      inferenceResultId: record.id,
                      baseUrl: widget.baseUrl,
                    );

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              ).then((_) {
                final userId = context.read<AuthViewModel>().currentUser?.registerId;
                if (userId != null) {
                  context.read<ConsultationRecordViewModel>().fetchRecords(userId);
                }
              });
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

  String getModelFilename(String path) {
    final filename = path.split('/').last;
    return filename.replaceFirst('processed_', '');
  }
}
