import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ 웹 감지를 위해 추가
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

const kPrimary = Color(0xFF3869A8);

// 공통 규격
const double kAnswerHeight = 44;
const double kAnswerSideInset = 12;

// 알약(세그먼트) 스타일
const double kSegHeight  = 36;   // 버튼 높이
const double kSegHPad    = 16;   // 좌우 패딩
const double kSegDivider = 1.0;  // 구분선 두께
const double kSegRadius  = 22.0; // 모서리 반경

// 점-스케일 라벨 텍스트
const kScaleHint = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: Color(0xFF6B7280),
);

enum SurveyType { yesNo, yesNoDontKnow, singleChoice, numeric, text }

class SurveyQuestion {
  final String category;
  final String question;
  final SurveyType type;
  final List<String>? options;

  int? selectedIndex; // choice 계열
  int? numberValue;   // numeric
  String? textValue;  // text

  SurveyQuestion({
    required this.category,
    required this.question,
    required this.type,
    this.options,
    this.selectedIndex,
    this.numberValue,
    this.textValue,
  });
}

class DentalSurveyScreen extends StatefulWidget {
  final String baseUrl;
  const DentalSurveyScreen({super.key, required this.baseUrl});

  @override
  State<DentalSurveyScreen> createState() => _DentalSurveyScreenState();
}

class _DentalSurveyScreenState extends State<DentalSurveyScreen> {
  final List<String> categories = const [
    '(치과)병력과 증상',
    '구강건강 삶의 질과 인식',
    '흡연',
    '구강위생관리',
    '불소이용',
    '식습관',
    '기타(자유기술)',
  ];

  late final List<SurveyQuestion> questions;
  late final Map<String, List<SurveyQuestion>> categorizedQuestions;
  final Map<String, bool> _isExpanded = {};

  // numeric 컨트롤러
  final Map<String, TextEditingController> _numControllers = {};

  @override
  void initState() {
    super.initState();

    // 0~7회 (8개 점) 라벨
    final eightLabels = List<String>.generate(8, (i) => '${i}회');

    questions = [
      // (치과)병력과 증상
      SurveyQuestion(
        category: '(치과)병력과 증상',
        question: '최근 1년간 구강검진을 받거나 예방·관리 목적으로 치과병(의)원에 간 적이 있습니까?',
        type: SurveyType.yesNo,
        options: const ['예', '아니요'],
      ),
      SurveyQuestion(
        category: '(치과)병력과 증상',
        question: '현재 당뇨병을 앓고 계십니까?',
        type: SurveyType.yesNoDontKnow,
        options: const ['예', '아니요', '모르겠다'],
      ),
      SurveyQuestion(
        category: '(치과)병력과 증상',
        question: '현재 심혈관건강문제를 겪고 계십니까? (예: 고혈압, 고지혈증, 동맥경화증 등)',
        type: SurveyType.yesNoDontKnow,
        options: const ['예', '아니요', '모르겠다'],
      ),
      SurveyQuestion(
        category: '(치과)병력과 증상',
        question: '최근 3개월 동안, 치아가 쑤시거나 욱신거리거나 아픈 적 있습니까?',
        type: SurveyType.yesNo,
        options: const ['예', '아니요'],
      ),
      SurveyQuestion(
        category: '(치과)병력과 증상',
        question: '최근 3개월 동안, 잇몸이 아프거나 피가 난 적 있습니까?',
        type: SurveyType.yesNo,
        options: const ['예', '아니요'],
      ),

      // 구강건강 삶의 질과 인식
      SurveyQuestion(
        category: '구강건강 삶의 질과 인식',
        question: '최근 3개월 동안, 치아나 입안의 문제로 혹은 틀니 때문에 음식을 씹는 데에 불편감을 느낀 적이 있습니까?',
        type: SurveyType.yesNo,
        options: const ['예', '아니요'],
      ),
      SurveyQuestion(
        category: '구강건강 삶의 질과 인식',
        question: '스스로 생각할 때, 자신의 구강건강은 어떤 편이라고 생각합니까?',
        type: SurveyType.singleChoice,
        options: const ['매우 좋다', '좋다', '보통이다', '나쁘다', '매우 나쁘다'],
      ),

      // 흡연
      SurveyQuestion(
        category: '흡연',
        question: '담배를 피웁니까?',
        type: SurveyType.yesNo,
        options: const ['예', '아니요'],
      ),

      // 구강위생관리
      SurveyQuestion(
        category: '구강위생관리',
        question: '최근 일주일 동안, 하루 평균 치아를 몇 번 닦았습니까?',
        type: SurveyType.numeric,
      ),
      SurveyQuestion(
        category: '구강위생관리',
        question: '최근 일주일 동안, 잠자기 직전에 칫솔질을 몇 회 하였습니까?',
        type: SurveyType.singleChoice,
        options: eightLabels, // 0~7회
      ),
      SurveyQuestion(
        category: '구강위생관리',
        question: '최근 일주일 동안, 치아를 닦을 때 치실 혹은 치간칫솔을 사용하였습니까?',
        type: SurveyType.yesNo,
        options: const ['예', '아니요'],
      ),

      // 불소이용
      SurveyQuestion(
        category: '불소이용',
        question: '현재 사용 중인 치약에 불소가 들어 있습니까?',
        type: SurveyType.yesNo,
        options: const ['예', '아니요'],
      ),

      // 식습관
      SurveyQuestion(
        category: '식습관',
        question: '하루에 달거나 끈적한 간식(과자, 사탕, 케이크 등)을 얼마나 먹습니까?',
        type: SurveyType.singleChoice,
        options: const ['먹지 않는다', '1번', '2번', '3번', '4번 이상'],
      ),
      SurveyQuestion(
        category: '식습관',
        question: '하루에 과일주스나 당분이 첨가된 음료(탄산음료, 스포츠음료 등)를 얼마나 먹습니까?',
        type: SurveyType.singleChoice,
        options: const ['먹지 않는다', '1번', '2번', '3번', '4번 이상'],
      ),

      // 기타
      SurveyQuestion(
        category: '기타',
        question: '특별한 증상 혹은 치과의사에게 묻고 싶은 말을 자유롭게 적어주세요.',
        type: SurveyType.text,
      ),
    ];

    categorizedQuestions = {
      for (final c in categories) c: questions.where((q) => q.category == c).toList(),
    };
    for (final c in categories) {
      _isExpanded[c] = false;
    }
  }

  @override
  void dispose() {
    for (final c in _numControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA9C9F5),
      appBar: AppBar(
        title: const Text('치과 문진', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: kPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        // ✅ 웹이면 폭을 고정(예: 520px)하고 가운데 정렬
        child: kIsWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildMainBody(),
                ),
              )
            : _buildMainBody(),
      ),
    );
  }

  // ✅ 본문을 분리하여 웹/모바일에서 공통 사용
  Widget _buildMainBody() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: categories
                .map((category) => _buildCategoryTile(
                      category,
                      categorizedQuestions[category] ?? const [],
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _submitSurvey,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('다음 페이지로 이동', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(String category, List<SurveyQuestion> qs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        key: ValueKey('cat-$category'), // GlobalKey 사용 안 함
        initiallyExpanded: _isExpanded[category] ?? false,
        onExpansionChanged: (isExpanded) => setState(() => _isExpanded[category] = isExpanded),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(_getCategoryIcon(category), color: kPrimary, size: 30),
        title: Text(
          category,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
        collapsedIconColor: Colors.grey[600],
        iconColor: kPrimary,
        children: qs.map(_buildQuestionCard).toList(),
      ),
    );
  }

  Widget _buildQuestionCard(SurveyQuestion q) {
    return Card(
      key: ValueKey('q-${q.question}'),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.question, style: const TextStyle(fontSize: 16, color: Color(0xFF555555))),
            const SizedBox(height: 12),
            _buildAnswerControl(q),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerControl(SurveyQuestion q) {
    switch (q.type) {
      case SurveyType.yesNo:
      case SurveyType.yesNoDontKnow:
        return _segmentedChoice(
          items: q.options ?? const [],
          selectedIndex: q.selectedIndex,
          onSelect: (i) => setState(() => q.selectedIndex = i),
        );

      case SurveyType.singleChoice:
        return _dotScaleCompact(
          labels: q.options ?? const [],
          selectedIndex: q.selectedIndex,
          onSelect: (i) => setState(() => q.selectedIndex = i),
        );

      case SurveyType.numeric:
        // 숫자 입력 + 스테퍼
        final controller = _numControllers.putIfAbsent(
          q.question,
          () => TextEditingController(text: '${q.numberValue ?? 0}'),
        );

        void setNum(int v) {
          final nv = v.clamp(0, 99);
          q.numberValue = nv;
          final s = nv.toString();
          controller.value = TextEditingValue(
            text: s,
            selection: TextSelection.collapsed(offset: s.length),
          );
          setState(() {});
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kAnswerSideInset),
          child: SizedBox(
            height: kAnswerHeight,
            width: double.infinity,
            child: Row(
              children: [
                IconButton(
                  tooltip: '감소',
                  onPressed: () => setNum((q.numberValue ?? 0) - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 78,
                  height: 36,
                  child: TextField(
                    key: ValueKey('num-${q.question}'),
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(),
                      suffixText: '회',
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      q.numberValue = (n ?? 0).clamp(0, 99);
                      setState(() {});
                    },
                    onEditingComplete: () {
                      final n = int.tryParse(controller.text) ?? 0;
                      setNum(n);
                    },
                  ),
                ),
                IconButton(
                  tooltip: '증가',
                  onPressed: () => setNum((q.numberValue ?? 0) + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
        );

      case SurveyType.text:
        return TextFormField(
          key: ValueKey('text-${q.question}'),
          initialValue: q.textValue ?? '',
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '내용을 입력하세요',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => q.textValue = v,
        );
    }
  }

  /// 왼쪽 정렬 + 동일 너비 알약(세그먼트)
  Widget _segmentedChoice({
    required List<String> items,
    required int? selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    final borderColor = const Color(0xFFE1E6EF);
    final baseStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    double _measureTextWidth(String s) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: baseStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      return tp.width;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kAnswerSideInset),
      child: Align(
        alignment: Alignment.centerLeft,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 자연 너비 = 가장 긴 텍스트 + 패딩
            final maxTextW = items.isEmpty ? 0.0 : items.map(_measureTextWidth).reduce(math.max);
            double pillW = maxTextW + kSegHPad * 2;

            // 화면을 넘기면 가용 폭에 맞춰 균등 분배
            final totalSeparatorsW = (items.length - 1) * kSegDivider;
            final maxAvail = constraints.maxWidth;
            final naturalGroupW = pillW * items.length + totalSeparatorsW;

            if (naturalGroupW > maxAvail) {
              pillW = (maxAvail - totalSeparatorsW) / items.length;
              pillW = pillW.clamp(68.0, 9999.0); // 최소 너비
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(kSegRadius),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: borderColor, width: 1.2),
                  borderRadius: BorderRadius.circular(kSegRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(items.length * 2 - 1, (j) {
                    if (j.isOdd) {
                      return Container(
                        width: kSegDivider,
                        height: kSegHeight - 8,
                        color: borderColor,
                      );
                    }
                    final i = j ~/ 2;
                    final selected = selectedIndex == i;

                    return InkWell(
                      onTap: () => onSelect(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: pillW,
                        height: kSegHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? kPrimary.withOpacity(.08) : Colors.white,
                          borderRadius: BorderRadius.horizontal(
                            left: i == 0 ? const Radius.circular(kSegRadius) : Radius.zero,
                            right: i == items.length - 1
                                ? const Radius.circular(kSegRadius)
                                : Radius.zero,
                          ),
                        ),
                        child: Text(
                          items[i],
                          style: baseStyle.copyWith(
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? kPrimary : const Color(0xFF333333),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 점-스케일 – 끝점 정렬 + 하단 라벨
  Widget _dotScaleCompact({
    required List<String> labels,
    required int? selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    final count = labels.isNotEmpty ? labels.length : 3;
    final baseSizes = (count == 5)
        ? [16.0, 14.0, 12.0, 14.0, 16.0]
        : List<double>.filled(count, 14.0);

    const double boost = 5.0; // 선택 시 확대
    final double maxDot = baseSizes.fold<double>(0, (p, e) => math.max(p, e)) + boost;
    final double safeInset = math.max(8.0, maxDot / 2 + 2); // 좌우 여유

    const double lineTop = 8.0;
    const double lineBottom = 18.0;
    final double hitHeight = kAnswerHeight - lineTop - lineBottom;

    final leftText = labels.isNotEmpty ? labels.first : '';
    final rightText = labels.length > 1 ? labels.last : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kAnswerSideInset),
      child: SizedBox(
        height: kAnswerHeight,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final usableW = width - safeInset * 2;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 라인
                Positioned.fill(
                  top: lineTop,
                  bottom: lineBottom,
                  child: CustomPaint(
                    painter: _GradientLinePainter(inset: safeInset, thickness: 3),
                  ),
                ),

                // 점들
                ...List.generate(count, (i) {
                  final t = count == 1 ? 0.0 : i / (count - 1);
                  final cx = safeInset + t * usableW;
                  final isSelected = selectedIndex == i;
                  final color = Color.lerp(Colors.amber, Colors.green, t)!;
                  final size = isSelected ? baseSizes[i] + boost : baseSizes[i];

                  return Positioned(
                    left: cx - 18,
                    top: lineTop,
                    width: 36,
                    height: hitHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => onSelect(i),
                      child: Center(
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? color : Colors.white,
                            border: Border.all(
                              color: isSelected ? color.darken(0.25) : color.withOpacity(0.35),
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // 하단 좌/우 라벨
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text(leftText, style: kScaleHint, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            rightText,
                            style: kScaleHint,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '(치과)병력과 증상':
        return Icons.healing_outlined;
      case '구강건강 삶의 질과 인식':
        return Icons.sentiment_satisfied_alt_outlined;
      case '흡연':
        return Icons.smoking_rooms_outlined;
      case '구강위생관리':
        return Icons.brush_outlined;
      case '불소이용':
        return Icons.water_drop_outlined;
      case '식습관':
        return Icons.restaurant_outlined;
      case '기타(자유기술)':
        return Icons.notes_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  void _submitSurvey() {
    final Map<String, dynamic> surveyResponses = {};
    for (final q in questions) {
      dynamic value;
      switch (q.type) {
        case SurveyType.yesNo:
        case SurveyType.yesNoDontKnow:
        case SurveyType.singleChoice:
          if (q.selectedIndex != null &&
              q.options != null &&
              q.selectedIndex! >= 0 &&
              q.selectedIndex! < q.options!.length) {
            value = q.options![q.selectedIndex!];
          }
          break;
        case SurveyType.numeric:
          value = q.numberValue ?? 0;
          break;
        case SurveyType.text:
          value = q.textValue ?? '';
          break;
      }
      surveyResponses[q.question] = value;
    }

    context.push('/upload', extra: {'baseUrl': widget.baseUrl, 'survey': surveyResponses});
  }
}

/// 그라데이션 라인
class _GradientLinePainter extends CustomPainter {
  final double inset;
  final double thickness;
  const _GradientLinePainter({this.inset = 0, this.thickness = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(colors: [Colors.amber, Colors.green])
          .createShader(Rect.fromLTWH(inset, 0, size.width - inset * 2, 0))
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(inset, size.height / 2),
      Offset(size.width - inset, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
