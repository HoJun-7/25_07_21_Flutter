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

  Widget _buildMainBody(HistoryViewModel viewModel, dynamic currentUser) {
    final imageBaseUrl = widget.baseUrl.replaceAll('/api', '');

    return viewModel.isLoading
        ? const Center(child: CircularProgressIndicator())
        : viewModel.error != null
            ? Center(child: Text('오류: ${viewModel.error}'))
            : currentUser == null
                ? const Center(child: Text('로그인이 필요합니다.'))
                : Column(
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3869A8)),
            ),
          ),
        );
      }

      final isXray = record.imageType == 'xray';
      final route = isXray ? '/history_xray_result_detail' : '/history_result_detail';

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

      // 참고용으로 matchedResults도 넘김(상세 화면에서 bbox 매칭 폴백 있음)
      final List<dynamic> matchedResults = [];
      if (record.model1InferenceResult != null) {
        matchedResults.addAll(record.model1InferenceResult!['detected_labels'] as List? ?? []);
      }
      if (record.model2InferenceResult != null) {
        matchedResults.addAll(record.model2InferenceResult!['detected_labels'] as List? ?? []);
      }

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
                'matchedResults': matchedResults,
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
                SizedBox(
                  width: 50,
                  child: Text(
                    timeStr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 16),
                _AuthThumb(
                  url: '$imageBaseUrl${record.originalImagePath}',
                  baseUrl: widget.baseUrl,
                  size: 64,
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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

class _AuthThumb extends StatefulWidget {
  final String url;
  final String baseUrl;
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
