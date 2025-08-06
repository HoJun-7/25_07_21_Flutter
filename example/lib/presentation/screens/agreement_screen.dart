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
      context.go('/register'); // router.dart의 register 경로로 이동
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
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 16)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약관 동의'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '이용약관'),
            Tab(text: '개인정보 수집·이용'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                termsHtmlContent.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(child: Html(data: termsHtmlContent)),
                appendixHtmlContent.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(child: Html(data: appendixHtmlContent)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
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
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isAllAgreed ? _goToRegister : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: isAllAgreed ? Colors.blue : Colors.grey,
                  ),
                  child: const Text('다음'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

