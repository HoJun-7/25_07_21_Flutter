import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '/presentation/viewmodel/history_viewmodel.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/model/history.dart';
import 'history_result_detail_screen.dart';
import 'history_xray_result_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String baseUrl;

  const HistoryScreen({super.key, required this.baseUrl});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<String> statuses = ['ALL', '신청 안함', '응답 대기중', '응답 완료'];
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = context.read<AuthViewModel>().currentUser?.registerId;
      if (userId != null) {
        await context.read<HistoryViewModel>().fetchRecords(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    final imageBaseUrl = widget.baseUrl.replaceAll('/api', '');

    return WillPopScope(
      onWillPop: () async {
        context.go('/home');
        return false;
      },
      child: Scaffold(
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
                    : Center(
                        child: ConstrainedBox(
                          constraints: kIsWeb
                              ? const BoxConstraints(maxWidth: 600)
                              : const BoxConstraints(),
                          child: Column(
                            children: [
                              _buildStatusChips(),
                              Expanded(
                                child: PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) => setState(() => _selectedIndex = index),
                                  itemCount: statuses.length,
                                  itemBuilder: (context, index) {
                                    final filtered = _filterRecords(
                                      viewModel.records.where((r) => r.userId == currentUser.registerId).toList(),
                                      statuses[index],
                                    );
                                    return _buildRecordList(filtered, imageBaseUrl);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  List<HistoryRecord> _filterRecords(List<HistoryRecord> all, String status) {
    if (status == 'ALL') return all;
    if (status == '신청 안함') {
      return all.where((r) => r.isRequested == 'N').toList();
    }
    if (status == '응답 대기중') {
      return all.where((r) => r.isRequested == 'Y' && r.isReplied == 'N').toList();
    }
    if (status == '응답 완료') {
      return all.where((r) => r.isRequested == 'Y' && r.isReplied == 'Y').toList();
    }
    return all;
  }

  Color _getChipColor(String status) {
    switch (status) {
      case 'ALL':
        return Colors.red;
      case '신청 안함':
        return Colors.blue;
      case '응답 대기중':
        return Colors.yellow.shade700;
      case '응답 완료':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChips() {
    return Container(
      margin: const EdgeInsets.all(12),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / statuses.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                left: _selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  width: itemWidth,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: _getChipColor(statuses[_selectedIndex]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Row(
                children: List.generate(statuses.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: SizedBox(
                      width: itemWidth,
                      child: Center(
                        child: Text(
                          statuses[index],
                          style: TextStyle(
                            color: _selectedIndex == index ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordList(List<HistoryRecord> records, String imageBaseUrl) {
    records.sort((a, b) {
      final atime = _extractDateTimeFromFilename(a.originalImagePath);
      final btime = _extractDateTimeFromFilename(b.originalImagePath);
      return btime.compareTo(atime);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final modelFilename = getModelFilename(record.originalImagePath);
        final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(
          _extractDateTimeFromFilename(record.originalImagePath),
        );

        final isXray = record.imageType == 'xray';
        final route = isXray ? '/history_xray_result_detail' : '/history_result_detail';

        final modelUrls = isXray
            ? {
                1: '$imageBaseUrl/images/xmodel1/$modelFilename',
                2: '$imageBaseUrl/images/xmodel2/$modelFilename',
              }
            : {
                1: '$imageBaseUrl/images/model1/$modelFilename',
                2: '$imageBaseUrl/images/model2/$modelFilename',
                3: '$imageBaseUrl/images/model3_1/$modelFilename',
                4: '$imageBaseUrl/images/model3_2/$modelFilename',
              };

        final modelData = isXray
            ? {
                1: record.model1InferenceResult ?? {},
                2: record.model2InferenceResult ?? {},
              }
            : {
                1: record.model1InferenceResult ?? {},
                2: record.model2InferenceResult ?? {},
                3: record.model3InferenceResult ?? {},
                4: record.model3InferenceResult ?? {},
              };

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text('[$index] $formattedTime', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('사용자 ID: ${record.userId}'),
                Text('파일명: $modelFilename'),
              ],
            ),
            onTap: () {
              context.push(
                route,
                extra: {
                  'originalImageUrl': '$imageBaseUrl${record.originalImagePath}',
                  'processedImageUrls': modelUrls,
                  'modelInfos': modelData,
                  'userId': record.userId,
                  'inferenceResultId': record.id,
                  'baseUrl': widget.baseUrl,
                  'isRequested': record.isRequested == 'Y' ? 'Y' : 'N',
                  'isReplied': record.isReplied == 'Y' ? 'Y' : 'N',
                },
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
    final timePart = parts[1];
    return DateTime.parse(
      '${timePart.substring(0, 4)}-${timePart.substring(4, 6)}-${timePart.substring(6, 8)}T${timePart.substring(8, 10)}:${timePart.substring(10, 12)}:${timePart.substring(12, 14)}',
    );
  }

  String getModelFilename(String path) {
    return path.split('/').last;
  }
}
