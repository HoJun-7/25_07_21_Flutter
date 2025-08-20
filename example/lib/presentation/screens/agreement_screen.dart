import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';

class AgreementScreen extends StatefulWidget {
  final String baseUrl;

  const AgreementScreen({super.key, required this.baseUrl});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String termsHtmlContent = '';
  String appendixHtmlContent = '';

  bool isTermsChecked = false;
  bool isPrivacyChecked = false;

  bool get isAllAgreed => isTermsChecked && isPrivacyChecked;

  // ▼ 첫 번째 UI와 동일 톤
  static const Color primaryBlue = Color(0xFF3869A8);
  static const Color lightBlueBackground = Color(0xFFB4D4FF);
  static const Color cardTopBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHtmlContents();
  }

  Future<void> _loadHtmlContents() async {
    final terms = await rootBundle.loadString('assets/html/toothai_terms_full.html');
    final appendix = await rootBundle.loadString('assets/html/toothai_terms_appendix1.html');

    setState(() {
      termsHtmlContent = terms;
      appendixHtmlContent = appendix;
    });
  }

  void _goToRegister() {
    if (isAllAgreed) {
      context.push('/register');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCheckboxTile({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: primaryBlue, // ▶ 체크 색상 통일
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlueBackground, // ▶ 배경 컬러 통일
      appBar: AppBar(
        backgroundColor: primaryBlue, // ▶ 상단 바 컬러 통일
        title: const Text('약관 동의'),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            final maxWidth = kIsWeb ? 450.0 : double.infinity;

            // 화면 높이에 비례한 카드 높이 (너무 크거나 작지 않게 클램프)
            final double cardHeight =
                (constraints.maxHeight * 0.55).clamp(320.0, 560.0);

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 16 + bottomInset),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    // 화면보다 내용이 적을 때는 화면 높이에 맞추고,
                    // 많을 때는 SingleChildScrollView로 스크롤
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // ▼ 카드 영역: Expanded 제거 → 고정/가변 높이 SizedBox로 변경
                        SizedBox(
                          height: cardHeight,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                // ▶ 카드 상단은 흰색 + Tab 스타일만 파란톤 (기존과 동일)
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    labelColor: primaryBlue,
                                    unselectedLabelColor: Colors.grey,
                                    labelStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    indicatorColor: primaryBlue,
                                    indicatorWeight: 3,
                                    tabs: const [
                                      Tab(text: '이용약관'),
                                      Tab(text: '개인정보 수집·이용'),
                                    ],
                                  ),
                                ),

                                // ▼ 카드 내부는 기존처럼 TabBarView + 본문 스크롤 유지
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      termsHtmlContent.isEmpty
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: SingleChildScrollView(
                                                child: Html(
                                                    data: termsHtmlContent),
                                              ),
                                            ),
                                      appendixHtmlContent.isEmpty
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: SingleChildScrollView(
                                                child: Html(
                                                    data: appendixHtmlContent),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ▼ 체크박스/버튼 영역 (그대로)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              _buildCheckboxTile(
                                label: '이용약관에 동의합니다.',
                                value: isTermsChecked,
                                onChanged: (val) => setState(
                                    () => isTermsChecked = val ?? false),
                              ),
                              _buildCheckboxTile(
                                label: '개인정보 수집 및 이용에 동의합니다.',
                                value: isPrivacyChecked,
                                onChanged: (val) => setState(
                                    () => isPrivacyChecked = val ?? false),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: isAllAgreed ? _goToRegister : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isAllAgreed
                                        ? primaryBlue
                                        : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: isAllAgreed ? 2 : 0,
                                  ),
                                  child: const Text('다음'),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
