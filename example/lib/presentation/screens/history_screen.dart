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

// ✅ 색상 팔레트 정의
const Color primaryColor = Color(0xFF3869A8);       // AppBar/헤더
const Color secondaryColor = Color(0xFFDCE7F6);     // 전체 배경
const Color cardColor = Colors.white;               // 카드 배경
const Color chipTrackColor = Color(0xFFF1F2F4);     // 칩 트랙
const Color textColor = Color(0xFF1E2741);          // 본문 텍스트
const Color subtitleColor = Color(0xFF8B92A4);      // 보조 텍스트
const Color completedColor = Color(0xFF4CAF50);     // 응답 완료 배지
const Color pendingColor = Color(0xFFFFC107);       // 응답 대기중 배지
const Color notRequestedColor = Color(0xFF2196F3);  // 신청 안함 배지

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

  // ✅ 본문
  Widget _buildMainBody(HistoryViewModel viewModel, dynamic currentUser) {
    final imageBaseUrl = widget.baseUrl.replaceAll('/api', '');

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      return Center(child: Text('오류: ${viewModel.error}', style: TextStyle(color: Colors.red.shade400)));
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
                return const Center(child: Text('기록이 없습니다.', style: TextStyle(color: subtitleColor)));
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

  Widget _buildStatusChips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 44,
      decoration: BoxDecoration(
        color: chipTrackColor,
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
    // 최신순 정렬 (파일명 안의 타임스탬프 기준)
    final sorted = [...records]..sort((a, b) {
        final at = _extractDateTimeFromFilename(a.originalImagePath);
        final bt = _extractDateTimeFromFilename(b.originalImagePath);
        return bt.compareTo(at); // desc
      });

    final List<Widget> children = [];
    String? currentDate;

    for (final record in sorted) {
      final dt = _extractDateTimeFromFilename(record.originalImagePath);
      final dateStr = _dateFmt.format(dt);
      final timeStr = _timeFmt.format(dt);

      // 날짜 헤더
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
                color: primaryColor,
              ),
            ),
          ),
        );
      }

      final isXray = record.imageType == 'xray';
      final route = isXray ? '/history_xray_result_detail' : '/history_result_detail';
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
        PressableCard(
          onTap: () {
            final isReq = record.isRequested == 'Y' ? 'Y' : 'N';
            final isRep = record.isReplied == 'Y' ? 'Y' : 'N';

            context.push(
              route,
              extra: {
                'originalImageUrl': originalImageUrl,
                'processedImageUrls': modelUrls,
                'modelInfos': modelData,
                'userId': record.userId,
                'inferenceResultId': record.id,
                'baseUrl': widget.baseUrl,
                'isRequested': isReq,
                'isReplied': isRep,
              },
            );
          },
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _AuthThumb(
                  url: originalImageUrl,        // 절대 URL
                  baseUrl: widget.baseUrl,      // 토큰 발급용
                  size: 80,
                ),
              ),
              const SizedBox(width: 16),
              // 본문
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '진단 이미지 (${isXray ? 'X-ray' : '일반'})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 14, color: subtitleColor),
                    ),
                    const SizedBox(height: 8),
                    if (statusText == '응답 완료')
                      Text(
                        _getSummaryResult(record),
                        style: const TextStyle(fontSize: 14, color: textColor),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 삭제 버튼 - 원형 클릭 영역도 딱 맞게
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: const CircleBorder(),
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
                              onPressed: () => Navigator.of(dialogContext).pop(),
                            ),
                            TextButton(
                              child: const Text('삭제', style: TextStyle(color: Colors.red)),
                              onPressed: () async {
                                // TODO: 삭제 로직
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
                      color: Colors.grey.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, size: 24, color: subtitleColor),
                  ),
                ),
              ),
            ],
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

  // ✅ 응답 완료 요약 텍스트
  String _getSummaryResult(HistoryRecord record) {
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

// -----------------------------
// 인증 썸네일 위젯
// -----------------------------
class _AuthThumb extends StatefulWidget {
  final String url;      // 절대 URL (imageBaseUrl + path)
  final String baseUrl;  // api base
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
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : (_bytes != null
              ? Image.memory(_bytes!, fit: BoxFit.cover)
              : const Icon(Icons.image_not_supported, size: 20, color: Colors.grey)),
    );
  }
}

// -----------------------------
// 눌림 애니메이션 카드 (라운드 모양과 클릭 범위 일치)
// -----------------------------
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color background;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.background = cardColor,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final r = widget.borderRadius as BorderRadius? ?? BorderRadius.circular(16);

    // 바깥에서만 그림자 (여긴 히트테스트 없음)
    final shadow = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          // 아래쪽 부드러운 그림자
          BoxShadow(
            color: const Color(0x2A000000),
            blurRadius: _pressed ? 10 : (_hovered ? 20 : 16),
            spreadRadius: _pressed ? 0.5 : 1.2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _innerMaterial(r),
    );

    return Padding(
      padding: widget.margin,
      child: shadow,
    );
  }

  // 실제 클릭 가능한 재질 레이어
  Widget _innerMaterial(BorderRadius r) {
    final shape = RoundedRectangleBorder(borderRadius: r);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(0.0, _pressed ? 2.0 : 0.0)
        ..scale(_pressed ? 0.985 : 1.0, _pressed ? 0.985 : 1.0),
      child: Material(
        color: widget.background,
        elevation: 0, // 그림자는 바깥 컨테이너에서 처리
        shape: shape,
        clipBehavior: Clip.antiAlias, // ✅ 코너/리플 완전 클립
        child: InkWell(
          // ✅ 둥근 모양에 맞춘 클릭/리플/히트테스트
          customBorder: shape,
          onTap: widget.onTap,
          onHighlightChanged: (v) => _setPressed(v),
          onHover: (v) => _setHovered(v),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
