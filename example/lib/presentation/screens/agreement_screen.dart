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

  // 컬러 톤
  static const Color primaryBlue = Color(0xFF3869A8);
  static const Color lightBlueBackground = Color(0xFFB4D4FF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHtmlContents();
  }

  Future<void> _loadHtmlContents() async {
    final terms =
        await rootBundle.loadString('assets/html/toothai_terms_full.html');
    final appendix =
        await rootBundle.loadString('assets/html/toothai_terms_appendix1.html');

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
          activeColor: primaryBlue,
        ),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlueBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('약관 동의'),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            final bool isWideWeb = kIsWeb && constraints.maxWidth >= 768;
            final double maxWidth = isWideWeb ? 560.0 : (kIsWeb ? 520.0 : double.infinity);

            // 카드 높이를 더 크게 (웹 72%, 모바일 62%), 상/하 한계값도 상향
            final double factor = kIsWeb ? 0.72 : 0.62;
            final double minH = kIsWeb ? 420.0 : 380.0;
            final double maxH = kIsWeb ? 760.0 : 680.0;
            final double cardHeight =
                (constraints.maxHeight * factor).clamp(minH, maxH);

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 16 + bottomInset),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight: constraints.maxHeight, // 화면 높이 채워 자연스러운 배치
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28), // 상단 여백 약간 키움

                        // ▶ 더 커진 카드
                        SizedBox(
                          height: cardHeight,
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(14),
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
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      termsHtmlContent.isEmpty
                                          ? const Center(
                                              child: CircularProgressIndicator(),
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: SingleChildScrollView(
                                                child: Html(data: termsHtmlContent),
                                              ),
                                            ),
                                      appendixHtmlContent.isEmpty
                                          ? const Center(
                                              child: CircularProgressIndicator(),
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: SingleChildScrollView(
                                                child:
                                                    Html(data: appendixHtmlContent),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20), // 카드와 체크 사이 간격 살짝 키움

                        // 체크박스/버튼
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              _buildCheckboxTile(
                                label: '이용약관에 동의합니다.',
                                value: isTermsChecked,
                                onChanged: (val) =>
                                    setState(() => isTermsChecked = val ?? false),
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
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isAllAgreed ? _goToRegister : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isAllAgreed
                                        ? primaryBlue
                                        : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: isAllAgreed ? 2 : 0,
                                  ),
                                  child: const Text('다음'),
                                ),
                              ),
                              const SizedBox(height: 28),
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
