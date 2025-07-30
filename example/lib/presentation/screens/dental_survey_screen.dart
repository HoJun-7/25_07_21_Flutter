import 'package:flutter/material.dart';

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
  const DentalSurveyScreen({super.key});

  @override
  State<DentalSurveyScreen> createState() => _DentalSurveyScreenState();
}

class _DentalSurveyScreenState extends State<DentalSurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
    SurveyQuestion(category: '통증 및 불편감', question: '찬물, 뜨거운 음식을 먹을 때 이가 시리다.'),
    SurveyQuestion(category: '통증 및 불편감', question: '잇몸에서 피가 난 적이 있다.'),
    SurveyQuestion(category: '구강 위생 상태', question: '하루 2회 이상 칫솔질을 한다.'),
    SurveyQuestion(category: '구강 위생 상태', question: '치실이나 치간 칫솔을 정기적으로 사용한다.'),
    SurveyQuestion(category: '구강 위생 상태', question: '구강 청결에 대한 스스로의 관리가 잘 되고 있다고 생각한다.'),
    SurveyQuestion(category: '구강 위생 상태', question: '입 냄새(구취)가 신경 쓰일 때가 있다.'),
    SurveyQuestion(category: '기존 질환 및 치료 경험', question: '충치나 잇몸질환을 지적받은 적이 있다.'),
    SurveyQuestion(category: '기존 질환 및 치료 경험', question: '현재 보철물(임플란트, 크라운 등)을 사용 중이다.'),
    SurveyQuestion(category: '기존 질환 및 치료 경험', question: '최근 1년 내에 치과 치료를 받은 적이 있다.'),
    SurveyQuestion(category: '기존 질환 및 치료 경험', question: '정기적인 구강 검진을 받고 있다.'),
    SurveyQuestion(category: '생활 습관 및 관련 요인', question: '단 음식(과자, 음료 등)을 자주 섭취한다.'),
    SurveyQuestion(category: '생활 습관 및 관련 요인', question: '흡연을 하고 있다.'),
    SurveyQuestion(category: '생활 습관 및 관련 요인', question: '스트레스를 자주 받는다.'),
    SurveyQuestion(category: '생활 습관 및 관련 요인', question: '구강건강이 전신 건강에 영향을 준다고 생각한다.'),
    SurveyQuestion(category: '치료 의향 및 인식', question: '치과 진료가 필요하다고 느낀다.'),
    SurveyQuestion(category: '치료 의향 및 인식', question: '지금 증상이 심각하다고 느낀다.'),
    SurveyQuestion(category: '치료 의향 및 인식', question: '진료를 미루는 이유는 시간/비용/공포 때문이다.'),
    SurveyQuestion(category: '치료 의향 및 인식', question: 'AI 기반 진단 결과를 신뢰할 수 있다고 느낀다.'),
  ];

  @override
  Widget build(BuildContext context) {
    final questionsByCategory = categories.map((category) {
      return questions.where((q) => q.category == category).toList();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('치과 문진'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3869A8),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: categories.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categories[index],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: questionsByCategory[index].map((q) => _buildQuestionCard(q)).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  ElevatedButton(
                    onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: const Text('이전'),
                  ),
                if (_currentPage < categories.length - 1)
                  ElevatedButton(
                    onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: const Text('다음'),
                  ),
                if (_currentPage == categories.length - 1)
                  ElevatedButton(
                    onPressed: _submitSurvey,
                    child: const Text('제출'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(SurveyQuestion question) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.question, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final value = index + 1;
                return Expanded(
                  child: RadioListTile<int>(
                    dense: true,
                    value: value,
                    groupValue: question.response,
                    onChanged: (val) => setState(() => question.response = val!),
                    title: Text('$value', textAlign: TextAlign.center),
                  ),
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  void _submitSurvey() {
    for (final q in questions) {
      debugPrint('Q: ${q.question} => ${q.response}');
    }
    // TODO: 서버 전송 로직 추가
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('문진 응답이 제출되었습니다.')),
    );
  }
}
