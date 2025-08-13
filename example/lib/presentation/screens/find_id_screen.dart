import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '/presentation/viewmodel/find_id_viewmodel.dart';

class FindIdScreen extends StatelessWidget {
  final String baseUrl;

  const FindIdScreen({Key? key, required this.baseUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<FindIdViewModel>(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    // DPR 반영해서 로고를 선명하게 디코딩
    final dpr = MediaQuery.of(context).devicePixelRatio;
    const double logoSize = 150.0;

    return Scaffold(
      backgroundColor: const Color(0xFFB4D4FF),
      appBar: AppBar(
        title: const Text('아이디 찾기', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5F97F7),
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
                      context,
                      controller: nameController,
                      labelText: '이름',
                      keyboardType: TextInputType.text,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      context,
                      controller: phoneController,
                      labelText: '전화번호',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
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
                              phone: phoneController.text.trim(),
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
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
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
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      cursorColor: Colors.blue,
    );
  }
}
