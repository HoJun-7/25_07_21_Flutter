import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '/presentation/viewmodel/find_password_viewmodel.dart';

/// 한국형 전화번호 하이픈 자동 포맷터
class KoreanPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // 숫자만 추출
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String f = '';

    if (digits.startsWith('02')) {
      //
      if (digits.length <= 2) {
        f = digits;
      } else if (digits.length <= 5) {
        f = '${digits.substring(0, 2)}-${digits.substring(2)}';
      } else {
        // 02-***-****
        final midLen = digits.length - 6;
        f = '${digits.substring(0, 2)}-${digits.substring(2, 2 + midLen)}-${digits.substring(2 + midLen)}';
      }
    } else {
      // 010/011/031 등
      if (digits.length <= 3) {
        f = digits;
      } else if (digits.length <= 7) {
        f = '${digits.substring(0, 3)}-${digits.substring(3)}';
      } else {
        // 010-****-****
        final midLen = digits.length - 7;
        f = '${digits.substring(0, 3)}-${digits.substring(3, 3 + midLen)}-${digits.substring(3 + midLen)}';
      }
    }

    return TextEditingValue(
      text: f,
      selection: TextSelection.collapsed(offset: f.length),
    );
  }
}

class FindPasswordScreen extends StatelessWidget {
  final String baseUrl;

  const FindPasswordScreen({Key? key, required this.baseUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FindPasswordViewModel(baseUrl: baseUrl),
      child: const _FindPasswordForm(),
    );
  }
}

class _FindPasswordForm extends StatelessWidget {
  const _FindPasswordForm({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<FindPasswordViewModel>(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    // ✅ 로고 선명도 향상용 DPR
    final dpr = MediaQuery.of(context).devicePixelRatio;
    const double logoSize = 150.0;

    return Scaffold(
      backgroundColor: const Color(0xFFB4D4FF),
      appBar: AppBar(
        title: const Text('비밀번호 찾기', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3869A8),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints:
                  kIsWeb ? const BoxConstraints(maxWidth: 450) : const BoxConstraints(),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ 로고 품질 개선: SizedBox + 고품질 리샘플링 + cacheWidth/Height
                    SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Image.asset(
                        'assets/images/tooth_character.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                        cacheWidth: (logoSize * dpr).round(),
                        cacheHeight: (logoSize * dpr).round(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildInputField(
                      controller: nameController,
                      labelText: '이름',
                      keyboardType: TextInputType.text,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: phoneController,
                      labelText: '전화번호',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      // ✅ 하이픈 자동 삽입 (서버 전송 시에도 하이픈 유지)
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        KoreanPhoneNumberFormatter(),
                      ],
                    ),
                    const SizedBox(height: 30),

                    if (viewModel.isLoading)
                      const Center(child: CircularProgressIndicator(color: Colors.blue))
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await viewModel.findPassword(
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(), // ✅ 하이픈 포함 그대로 전송
                            );
                            if (success && context.mounted) {
                              context.go('/find-password-result');
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              return states.contains(WidgetState.pressed)
                                  ? Colors.white
                                  : const Color(0xFF5F97F7);
                            }),
                            foregroundColor: WidgetStateProperty.resolveWith((states) {
                              return states.contains(WidgetState.pressed)
                                  ? const Color(0xFF5F97F7)
                                  : Colors.white;
                            }),
                            elevation: WidgetStateProperty.all(5),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          child: const Text(
                            '비밀번호 찾기',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    if (viewModel.successMessage != null)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          key: const ValueKey('successMessage'),
                          viewModel.successMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF70FF70),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      )
                    else if (viewModel.errorMessage != null)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          key: const ValueKey('errorMessage'),
                          viewModel.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFF7070),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        overlayColor: Colors.black12,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      child: const Text(
                        '로그인 화면으로 돌아가기',
                        style: TextStyle(
                          color: Color(0xFF3060C0),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF3060C0),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    List<TextInputFormatter>? inputFormatters, // ✅ 포맷터 주입 가능
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[700]) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Color(0xFF5F97F7), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      cursorColor: Colors.blue,
    );
  }
}