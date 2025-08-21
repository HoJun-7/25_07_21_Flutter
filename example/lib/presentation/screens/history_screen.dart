import 'package:flutter/foundation.dart' show kIsWeb; // ✅ 웹 화면 고정용
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

class HistoryScreen extends StatefulWidget {
  final String baseUrl;

  const HistoryScreen({super.key, required this.baseUrl});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<String> statuses = ['ALL', '신청 안함', '응답 대기중', '응답 완료'];

  final _dateFmt = DateFormat('yyyy-MM-dd');
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
        // ✅ 키보드 등장 시 자동 회피
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('진료 기록'),
          centerTitle: true,
          backgroundColor: const Color(0xFF3869A8),
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFFDCE7F6),
        body: SafeArea(
          child: kIsWeb
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _buildMainBody(viewModel, currentUser),
                  ),
                )
              : _buildMainBody(viewModel, currentUser),
        ),
      ),
    );
  }

  // ✅ CustomScrollView + Sliver 로 변경 (Column 제거)
  Widget _buildMainBody(HistoryViewModel viewModel, dynamic currentUser) {
    final imageBaseUrl = widget.baseUrl.replaceAll('/api', '');

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      return Center(child: Text('오류: ${viewModel.error}'));
    }
    if (currentUser == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return CustomScrollView(
      slivers: [
        // 상단 상태 칩 (얇게 조정)
        SliverToBoxAdapter(child: _buildStatusChips()),
        // 남은 공간은 PageView가 차지 (작은 높이여도 오버플로우 없음)
        SliverFillRemaining(
          hasScrollBody: true,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
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
                return _buildRecordList(filtered, imageBaseUrl);
              },
            ),
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
        return Colors.red;
      case '신청 안함':
        return Colors.blue;
      case '응답 대기중':
        return Colors.yellow;
      case '응답 완료':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ✅ 더 얇게: height 36, padding 축소
  Widget _buildStatusChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: SizedBox(
        height: 36,
        child: DecoratedBox(
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
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: _getChipColor(statuses[_selectedIndex]),
                        borderRadius: BorderRadius.circular(18),
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
                                fontSize: 13,
                                color: _selectedIndex == index
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  Widget _buildRecordList(List<HistoryRecord> records, String imageBaseUrl) {
    // 1) 최신순 정렬 (파일명 안의 타임스탬프 기준)
    final sorted = [...records]..sort((a, b) {
        final at = _extractDateTimeFromFilename(a.originalImagePath);
        final bt = _extractDateTimeFromFilename(b.originalImagePath);
        return bt.compareTo(at); // desc
      });

    // 2) 날짜 헤더 + 아이템을 순서대로 플랫하게 만든다
    final List<Widget> children = [];
    String? currentDate;

    for (final record in sorted) {
      final dt = _extractDateTimeFromFilename(record.originalImagePath);
      final dateStr = _dateFmt.format(dt);
      final timeStr = _timeFmt.format(dt);

      // 날짜가 바뀌면 헤더 추가
      if (currentDate != dateStr) {
        currentDate = dateStr;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              dateStr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3869A8),
              ),
            ),
          ),
        );
      }

      final isXray = record.imageType == 'xray';
      final route =
          isXray ? '/history_xray_result_detail' : '/history_result_detail';

      final modelFilename = getModelFilename(record.originalImagePath);
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

      // 3) 더 단순하고 보기 편하게 수정된 목록 항목
      children.add(
        InkWell(
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
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 시간
                SizedBox(
                  width: 50,
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 썸네일(원본)
                _AuthThumb(
                  url: '$imageBaseUrl${record.originalImagePath}',
                  baseUrl: widget.baseUrl,
                  size: 64, // 썸네일 크기 조정
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ PageView 안의 보조 스크롤(오버플로우 방지 핵심 유지)
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
      primary: false,
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
    );
  }

  DateTime _extractDateTimeFromFilename(String imagePath) {
    final filename = imagePath.split('/').last;
    final parts = filename.split('_');
    final timePart = parts[1];
    return DateTime.parse(
      '${timePart.substring(0, 4)}-'
      '${timePart.substring(4, 6)}-'
      '${timePart.substring(6, 8)}T'
      '${timePart.substring(8, 10)}:'
      '${timePart.substring(10, 12)}:'
      '${timePart.substring(12, 14)}',
    );
  }

  String getModelFilename(String path) {
    return path.split('/').last;
  }
}

class _AuthThumb extends StatefulWidget {
  final String url; // 절대 URL (imageBaseUrl + path)
  final String baseUrl; // api base
  final double size;

  const _AuthThumb({
    super.key,
    required this.url,
    required this.baseUrl,
    this.size = 56,
  });

  @override
  State<_AuthThumb> createState() => _AuthThumbState();
}

class _AuthThumbState extends State<_AuthThumb> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _AuthThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _bytes = null;
    });
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (!mounted) return;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(widget.url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      setState(() {
        _bytes = res.statusCode == 200 ? res.bodyBytes : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: _loading
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : (_bytes != null
              ? Image.memory(_bytes!, fit: BoxFit.cover)
              : const Icon(Icons.image_not_supported, size: 20, color: Colors.grey)),
    );
  }
}
