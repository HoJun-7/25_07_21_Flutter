import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/find_password_viewmodel.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB4D4FF), Color(0xFFA0C5FF)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              '비밀번호 찾기',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 24,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Color.fromARGB(100, 0, 0, 0),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/tooth_character.png', height: 150),
                  const SizedBox(height: 40),

                  _buildInputField(
                    context,
                    controller: nameController,
                    labelText: '이름',
                    keyboardType: TextInputType.text,
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 25),
                  _buildInputField(
                    context,
                    controller: phoneController,
                    labelText: '전화번호',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 50),

                  if (viewModel.isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.white))
                  else
                    _GradientButton(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6a9ce7), Color(0xFF4a7fd6)],
                      ),
                      onPressed: () async {
                        final success = await viewModel.findPassword(
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                        );
                        if (success && context.mounted) {
                          context.go('/find-password-result');
                        }
                      },
                      child: const Text(
                        '비밀번호 찾기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: (viewModel.successMessage != null)
                        ? Text(
                            key: const ValueKey('successMessage'),
                            viewModel.successMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF70FF70),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              shadows: [
                                Shadow(
                                  offset: Offset(1.0, 1.0),
                                  blurRadius: 2.0,
                                  color: Color.fromARGB(100, 0, 0, 0),
                                ),
                              ],
                            ),
                          )
                        : (viewModel.errorMessage != null)
                            ? Text(
                                key: const ValueKey('errorMessage'),
                                viewModel.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFF7070),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 60),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      overlayColor: Colors.white.withOpacity(0.15),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    child: const Text(
                      '로그인 화면으로 돌아가기',
                      style: TextStyle(
                        color: Color(0xFF3060C0),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF3060C0),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            spreadRadius: -2,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 18),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white70) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: const BorderSide(color: Colors.white, width: 3.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        ),
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 19),
        cursorColor: Colors.white,
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final Gradient gradient;
  final VoidCallback onPressed;
  final Widget child;

  const _GradientButton({
    Key? key,
    required this.gradient,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30.0),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
