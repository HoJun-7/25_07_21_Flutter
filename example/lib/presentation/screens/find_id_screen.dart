import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '/presentation/viewmodel/find_id_viewmodel.dart';

/// 한국형 전화번호 하이픈 자동 포맷터
class KoreanPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // 숫자만 추출
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String f = '';

    if (digits.startsWith('02')) {
      // 서울 국번
      if (digits.length <= 2) {
        f = digits;
      } else if (digits.length <= 5) {
        f = '${digits.substring(0, 2)}-${digits.substring(2)}';
      } else {
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

class FindIdScreen extends StatelessWidget {
  final String baseUrl;

  const FindIdScreen({Key? key, required this.baseUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<FindIdViewModel>(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final dpr = MediaQuery.of(context).devicePixelRatio;
    const double logoSize = 150.0;

    return Scaffold(
      backgroundColor: const Color(0xFFB4D4FF),
      appBar: AppBar(
        title: const Text('아이디 찾기', style: TextStyle(color: Colors.white)),
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
              constraints: kIsWeb
                  ? const BoxConstraints(maxWidth: 450)
                  : const BoxConstraints(),
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
                            await viewModel.findId(
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(), // 하이픈 포함 그대로 전송
                            );
                            if (viewModel.foundId != null && context.mounted) {
                              context.push('/find-id-result', extra: viewModel.foundId);
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
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          child: const Text(
                            '아이디 찾기',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    if (viewModel.errorMessage != null)
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
    List<TextInputFormatter>? inputFormatters,
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
