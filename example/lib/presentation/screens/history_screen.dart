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
  String _searchQuery = '';
  final List<String> _hospitals = [
    '서울 치과 병원',
    '강남 종합 치과',
    '부산 중앙 치과',
    '대구 사랑 치과',
    '인천 미소 치과',
    '광주 건강 치과',
    '대전 행복 치과',
    '울산 치과 센터',
  ];

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<ConsultationRecordViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ConsultationRecordViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    // 검색어에 따라 병원 리스트 필터링
    final filteredHospitals = _hospitals
        .where((hospital) => hospital.contains(_searchQuery))
        .toList();

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
                                    .where(
                                        (r) => r.userId == currentUser.registerId)
                                    .toList(),
                              ),
                              const SizedBox(height: 20),
                              // 병원 검색창
                              TextField(
                                decoration: InputDecoration(
                                  labelText: '병원 검색',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              // 병원 리스트 표시
                              _buildHospitalList(filteredHospitals),
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
                Text('파일명: ${record.originalImageFilename}'),
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

  Widget _buildHospitalList(List<String> hospitals) {
    if (hospitals.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hospitals.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final hospital = hospitals[index];
        return ListTile(
          leading: const Icon(Icons.local_hospital, color: Color(0xFF3869A8)),
          title: Text(hospital),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('병원 선택'),
                content: Text('$hospital 을(를) 선택했습니다.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          },
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
}
