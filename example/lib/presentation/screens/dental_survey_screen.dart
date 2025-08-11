import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SurveyQuestion {
  final String category;
  final String question;
  int response;

  SurveyQuestion({
    required this.category,
    required this.question,
    this.response = 3,
  });
}

class DentalSurveyScreen extends StatefulWidget {
  final String baseUrl;
  const DentalSurveyScreen({super.key, required this.baseUrl});

  @override
  State<DentalSurveyScreen> createState() => _DentalSurveyScreenState();
}

class _DentalSurveyScreenState extends State<DentalSurveyScreen> {
  final List<String> categories = [
    '통증 및 불편감',
    '구강 위생 상태',
    '기존 질환 및 치료 경험',
    '생활 습관 및 관련 요인',
    '치료 의향 및 인식',
  ];

  final List<SurveyQuestion> questions = [
    SurveyQuestion(category: '통증 및 불편감', question: '최근 1주일간 치아 통증을 느낀 적이 있다.'),
    SurveyQuestion(category: '통증 및 불편감', question: '음식을 씹을 때 불편하거나 아픈 부분이 있다.'),
    SurveyQuestion(category: '통증 및 불편감', question: '찬물 또는 뜨거운 음식을 먹을 때 이가 시리다.'),
    SurveyQuestion(category: '통증 및 불편감', question: '잇몸이 붓거나 피가 난 적이 있다.'),
    SurveyQuestion(category: '구강 위생 상태', question: '하루 2회 이상 양치질을 한다.'),
    SurveyQuestion(category: '구강 위생 상태', question: '정기적으로 치실이나 구강 세정제를 사용한다.'),
    SurveyQuestion(category: '구강 위생 상태', question: '양치 후에도 입안이 개운하지 않다고 느낀다.'),
    SurveyQuestion(category: '구강 위생 상태', question: '구취(입 냄새)를 자주 느낀다.'),
    SurveyQuestion(category: '기존 질환 및 치료 경험', question: '최근 6개월 이내 치과 치료를 받은 적이 있다.'),
    SurveyQuestion(category: '기존 질환 및 치료 경험', question: '충치나 잇몸질환 진단을 받은 적이 있다.'),
    SurveyQuestion(category: '기존 질환 및 치료 경험', question: '스케일링이나 기타 정기검진을 받은 적이 있다.'),
    SurveyQuestion(category: '기존 질환 및 치료 경험', question: '과거 치아 외상 또는 수술 경험이 있다.'),
    SurveyQuestion(category: '생활 습관 및 관련 요인', question: '자주 단 음식을 섭취한다.'),
    SurveyQuestion(category: '생활 습관 및 관련 요인', question: '탄산음료나 커피를 자주 마신다.'),
    SurveyQuestion(category: '생활 습관 및 관련 요인', question: '흡연을 하거나 했던 경험이 있다.'),
    SurveyQuestion(category: '생활 습관 및 관련 요인', question: '스트레스를 많이 받는 편이다.'),
    SurveyQuestion(category: '치료 의향 및 인식', question: '정기적인 치과 검진이 필요하다고 생각한다.'),
    SurveyQuestion(category: '치료 의향 및 인식', question: '치료 비용이 부담되어 진료를 미룬 적이 있다.'),
    SurveyQuestion(category: '치료 의향 및 인식', question: '구강 건강은 전신 건강과 밀접한 관련이 있다고 생각한다.'),
    SurveyQuestion(category: '치료 의향 및 인식', question: '필요시 비대면 진료나 AI 기반 진단도 고려할 수 있다.'),
  ];

  late final Map<String, List<SurveyQuestion>> categorizedQuestions;
  final Map<String, bool> _isExpanded = {};

  @override
  void initState() {
    super.initState();
    categorizedQuestions = {
      for (var category in categories)
        category: questions.where((q) => q.category == category).toList(),
    };
    for (var category in categories) {
      _isExpanded[category] = false;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '통증 및 불편감':
        return Icons.sick_outlined;
      case '구강 위생 상태':
        return Icons.brush_outlined;
      case '기존 질환 및 치료 경험':
        return Icons.healing_outlined;
      case '생활 습관 및 관련 요인':
        return Icons.directions_run_outlined;
      case '치료 의향 및 인식':
        return Icons.lightbulb_outline;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA9C9F5),
      appBar: AppBar(
        title: const Text('치과 문진', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF3869A8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: categories
                  .map((category) => _buildCategoryTile(
                        category,
                        categorizedQuestions[category] ?? [],
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitSurvey,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3869A8),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('다음 페이지로 이동', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String category, List<SurveyQuestion> questions) {
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
        key: PageStorageKey(category),
        initiallyExpanded: _isExpanded[category] ?? false,
        onExpansionChanged: (isExpanded) {
          setState(() {
            _isExpanded[category] = isExpanded;
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(_getCategoryIcon(category), color: const Color(0xFF3869A8), size: 30),
        title: Text(
          category,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        collapsedIconColor: Colors.grey[600],
        iconColor: const Color(0xFF3869A8),
        children: questions.map((q) => _buildQuestionCard(q)).toList(),
      ),
    );
  }

  Widget _buildLikertSlider(SurveyQuestion question) {
    final outerSizes = [28.0, 24.0, 20.0, 24.0, 28.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            // ← 왼쪽: 그렇지 않다 / 오른쪽: 그렇다
            Text('그렇지 않다', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            Text('그렇다', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  // 그라데이션도 좌→우 = 초록 → 노랑
                  painter: _GradientLinePainter(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final value = index + 1; // 왼쪽 1 → 오른쪽 5
                  final isSelected = question.response == value;
                  // 색상도 초록→노랑으로 진행
                  final color = Color.lerp(Colors.green, Colors.amber, index / 4)!;
                  final size = outerSizes[index];

                  return GestureDetector(
                    onTap: () => setState(() => question.response = value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: isSelected ? size + 6 : size,
                      height: isSelected ? size + 6 : size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? color : Colors.white,
                        border: Border.all(
                          color: isSelected ? color.darken(0.25) : color.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(SurveyQuestion question) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.question, style: const TextStyle(fontSize: 16, color: Color(0xFF555555))),
            const SizedBox(height: 12),
            _buildLikertSlider(question),
          ],
        ),
      ),
    );
  }

  void _submitSurvey() {
    final surveyResponses = {
      for (final q in questions) q.question: q.response,
    };

    context.push(
      '/upload',
      extra: {
        'baseUrl': widget.baseUrl,
        'survey': surveyResponses,
      },
    );
  }
}

class _GradientLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(colors: [Colors.green, Colors.amber])
          .createShader(Rect.fromLTWH(0, 0, size.width, 0))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // ✅ 중앙 한 줄만 그림
    final y = size.height / 2;
    canvas.drawLine(Offset(14, y), Offset(size.width - 14, y), paint);
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
