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
    final mainContent = Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.black,
                      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      unselectedLabelColor: Colors.grey,
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
                            ? const Center(child: CircularProgressIndicator())
                            : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SingleChildScrollView(
                                  child: Html(data: termsHtmlContent),
                                ),
                              ),
                        appendixHtmlContent.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SingleChildScrollView(
                                  child: Html(data: appendixHtmlContent),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              _buildCheckboxTile(
                label: '이용약관에 동의합니다.',
                value: isTermsChecked,
                onChanged: (val) => setState(() => isTermsChecked = val ?? false),
              ),
              _buildCheckboxTile(
                label: '개인정보 수집 및 이용에 동의합니다.',
                value: isPrivacyChecked,
                onChanged: (val) => setState(() => isPrivacyChecked = val ?? false),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isAllAgreed ? _goToRegister : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAllAgreed ? const Color(0xFF42A5F5) : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('다음'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF90CAF9),
        title: const Text('약관 동의'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: kIsWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: mainContent,
                ),
              )
            : mainContent,
      ),
    );
  }
}
