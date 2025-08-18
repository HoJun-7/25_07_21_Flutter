import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '/presentation/viewmodel/history_viewmodel.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/model/history.dart';
import 'history_result_detail_screen.dart';
import 'history_xray_result_detail_screen.dart';

// ✅ 색상 팔레트 정의 (테마화)
const Color primaryColor = Color(0xFF3869A8); // 앱바/헤더
const Color secondaryColor = Color(0xFFF1F4F8); // 배경 (기존보다 밝게)
const Color cardColor = Colors.white; // 카드 배경
const Color chipColor = Color(0xFFE2EAF5); // 칩 배경
const Color textColor = Color(0xFF1E2741); // 짙은 글씨색
const Color subtitleColor = Color(0xFF8B92A4); // 서브 글씨색
const Color completedColor = Color(0xFF4CAF50); // 응답 완료
const Color pendingColor = Color(0xFFFFC107); // 응답 대기중
const Color notRequestedColor = Color(0xFF2196F3); // 신청 안함

class HistoryScreen extends StatefulWidget {
  final String baseUrl;

  const HistoryScreen({super.key, required this.baseUrl});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<String> statuses = ['ALL', '신청 안함', '응답 대기중', '응답 완료'];

  final _dateFmt = DateFormat('yyyy.MM.dd');
  final _timeFmt = DateFormat('HH:mm');

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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    return WillPopScope(
      onWillPop: () async {
        context.go('/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('진료 기록', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: secondaryColor,
        body: SafeArea(
          child: kIsWeb
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _buildMainBody(viewModel, currentUser),
                  ),
                )
              : _buildMainBody(viewModel, currentUser),
        ),
      ),
    );
  }

  Widget _buildMainBody(HistoryViewModel viewModel, dynamic currentUser) {
    final imageBaseUrl = widget.baseUrl.replaceAll('/api', '');

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
          child:
              Text('오류: ${viewModel.error}', style: const TextStyle(color: Colors.red)));
    }

    if (currentUser == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return Column(
      children: [
        _buildStatusChips(),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final filtered = _filterRecords(
                viewModel.records
                    .where((r) => r.userId == currentUser.registerId)
                    .toList(),
                statuses[index],
              );
              if (filtered.isEmpty) {
                return const Center(
                    child: Text('기록이 없습니다.',
                        style: TextStyle(color: subtitleColor)));
              }
              return _buildRecordList(filtered, imageBaseUrl);
            },
          ),
        ),
      ],
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
        return primaryColor;
      case '신청 안함':
        return notRequestedColor;
      case '응답 대기중':
        return pendingColor;
      case '응답 완료':
        return completedColor;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 44,
      decoration: BoxDecoration(
        color: chipColor,
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
                  margin: const EdgeInsets.all(4),
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
                            color: _selectedIndex == index ? Colors.white : textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
    final sorted = [...records]..sort((a, b) {
        final at = _extractDateTimeFromFilename(a.originalImagePath);
        final bt = _extractDateTimeFromFilename(b.originalImagePath);
        return bt.compareTo(at);
      });

    final List<Widget> children = [];
    String? currentDate;

    for (final record in sorted) {
      final dt = _extractDateTimeFromFilename(record.originalImagePath);
      final dateStr = _dateFmt.format(dt);
      final timeStr = _timeFmt.format(dt);

      if (currentDate != dateStr) {
        currentDate = dateStr;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              dateStr,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor),
            ),
          ),
        );
      }

      final isXray = record.imageType == 'xray';
      final route =
          isXray ? '/history_xray_result_detail' : '/history_result_detail';
      final modelFilename = getModelFilename(record.originalImagePath);
      final originalImageUrl = '$imageBaseUrl${record.originalImagePath}';

      final modelUrls = isXray
          ? {
              1: '$imageBaseUrl/images/xmodel1/$modelFilename',
              2: '$imageBaseUrl/images/xmodel2/$modelFilename',
            }
          : {
              1: '$imageBaseUrl/images/model1/$modelFilename',
              2: '$imageBaseUrl/images/model2/$modelFilename',
              3: '$imageBaseUrl/images/model3/$modelFilename',
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
            };
      final statusText = _getStatusText(record);
      final statusColor = _getStatusColor(record);

      children.add(
        InkWell(
          onTap: () {
            context.push(
              route,
              extra: {
                'originalImageUrl': originalImageUrl,
                'processedImageUrls': modelUrls,
                'modelInfos': modelData,
                'userId': record.userId,
                'inferenceResultId': record.id,
                'baseUrl': widget.baseUrl,
                'isRequested': record.isRequested,
                'isReplied': record.isReplied,
              },
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    originalImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return SizedBox(
                        width: 80,
                        height: 80,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(
                        width: 80,
                        height: 80,
                        child: Icon(Icons.broken_image,
                            color: subtitleColor, size: 50),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '진단 이미지 (${isXray ? 'X-ray' : '일반'})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                            fontSize: 14, color: subtitleColor),
                      ),
                      const SizedBox(height: 8),
                      if (statusText == '응답 완료')
                        Text(
                          _getSummaryResult(record),
                          style: const TextStyle(
                              fontSize: 14, color: textColor),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('기록 삭제'),
                          content: const Text('정말 이 기록을 삭제하시겠습니까?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('취소', style: TextStyle(color: subtitleColor)),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('삭제', style: TextStyle(color: Colors.red)),
                              onPressed: () async {
                                // TODO: 삭제 로직 구현
                                print('기록 ID ${record.id} 삭제 요청');
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 24, color: subtitleColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }

  String _getStatusText(HistoryRecord record) {
    if (record.isRequested == 'Y' && record.isReplied == 'Y') {
      return '응답 완료';
    } else if (record.isRequested == 'Y' && record.isReplied == 'N') {
      return '응답 대기중';
    } else {
      return '신청 안함';
    }
  }

  Color _getStatusColor(HistoryRecord record) {
    if (record.isRequested == 'Y' && record.isReplied == 'Y') {
      return completedColor;
    } else if (record.isRequested == 'Y' && record.isReplied == 'N') {
      return pendingColor;
    } else {
      return notRequestedColor;
    }
  }

  // ✅ 추가된 요약 결과 생성 메서드
  String _getSummaryResult(HistoryRecord record) {
    // 엑스레이 로직 제거, 오직 치아 관련 로직만 남김
    final m1 = record.model1InferenceResult ?? {};
    final m2 = record.model2InferenceResult ?? {};
    final m3 = record.model3InferenceResult ?? {};

    final results = <String>[];
    
    if (m1['result'] != null && m1['result'] != '정상') {
      results.add('충치: ${m1['result']}');
    }
    
    if (m2['result'] != null && m2['result'] != '정상') {
      results.add('치아상태: ${m2['result']}');
    }
    
    if (m3['result'] != null && m3['result'] != '정상') {
      results.add('치아교정: ${m3['result']}');
    }

    return results.isEmpty ? '정상' : results.join(', ');
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