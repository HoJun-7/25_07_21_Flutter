// 생략된 import 유지
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RegisterScreen extends StatefulWidget {
  final String baseUrl;

  const RegisterScreen({super.key, required this.baseUrl});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _selectedGender = 'M';
  String _selectedRole = 'P';

  bool _isDuplicate = true;
  bool _isIdChecked = false;

  static const Color primaryBlue = Color(0xFF5F97F7);
  static const Color lightBlueBackground = Color(0xFFB4D4FF);

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    _phoneController.dispose();
    _registerIdController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _checkDuplicateId() async {
    final viewModel = context.read<AuthViewModel>();
    final id = _registerIdController.text.trim();

    if (id.length < 4) {
      _showSnack('아이디는 최소 4자 이상이어야 합니다');
      setState(() {
        _isIdChecked = false;
        _isDuplicate = true;
      });
      return;
    }

    final exists = await viewModel.checkUserIdDuplicate(id, _selectedRole);
    setState(() {
      _isIdChecked = true;
      _isDuplicate = (exists ?? true);
    });

    if (viewModel.duplicateCheckErrorMessage != null) {
      _showSnack(viewModel.duplicateCheckErrorMessage!);
    } else if (exists == false) {
      _showSnack('사용 가능한 아이디입니다');
    } else {
      _showSnack('이미 사용 중인 아이디입니다');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('모든 필드를 올바르게 입력해주세요.');
      return;
    }

    if (!_isIdChecked || _isDuplicate) {
      _showSnack('아이디 중복 확인을 완료해주세요.');
      return;
    }

    final userData = {
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      'birth': _birthController.text.trim(),
      'phone': _phoneController.text.trim(),
      'username': _registerIdController.text.trim(),
      'password': _passwordController.text.trim(),
      'role': _selectedRole,
    };

    final viewModel = context.read<AuthViewModel>();
    final error = await viewModel.registerUser(userData);

    if (error == null) {
      _showSnack('회원가입 성공!');
      context.go('/login');
    } else {
      _showSnack(error);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: lightBlueBackground,
      appBar: AppBar(
        title: const Text('회원가입', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
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
                  ? const BoxConstraints(maxWidth: 450) // ✅ 웹에서 폭 제한
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFolderRoleSelector(),
                      const SizedBox(height: 20),
                      _buildTextField(_nameController, '이름 (한글만)'),
                      const SizedBox(height: 10),
                      _buildGenderCardSelector(),
                      _buildTextField(
                        _birthController,
                        '생년월일 (YYYY-MM-DD)',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                          LengthLimitingTextInputFormatter(10),
                          _DateFormatter(),
                        ],
                      ),
                      _buildTextField(
                        _phoneController,
                        '전화번호',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                          _PhoneNumberFormatter(),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _registerIdController,
                              '아이디 (4자 이상)',
                              onChanged: (_) {
                                setState(() {
                                  _isIdChecked = false;
                                  _isDuplicate = true;
                                  authViewModel.clearDuplicateCheckErrorMessage();
                                });
                              },
                              errorText: authViewModel.duplicateCheckErrorMessage,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 56, // ✅ 아이디 입력창 높이에 맞춤
                            child: ElevatedButton(
                              onPressed: authViewModel.isCheckingUserId ? null : _checkDuplicateId,
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.pressed)) return Colors.white;
                                  return primaryBlue;
                                }),
                                foregroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.pressed)) return primaryBlue;
                                  return Colors.white;
                                }),
                                elevation: WidgetStateProperty.all(2),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(horizontal: 16), // ✅ vertical padding 제거
                                ),
                              ),
                              child: authViewModel.isCheckingUserId
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primaryBlue,
                                      ),
                                    )
                                  : const Text('중복확인'),
                            ),
                          ),
                        ],
                      ),
                      _buildTextField(_passwordController, '비밀번호 (6자 이상)', isPassword: true),
                      _buildTextField(_confirmController, '비밀번호 확인', isPassword: true),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.pressed)) return Colors.white;
                              return primaryBlue;
                            }),
                            foregroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.pressed)) return primaryBlue;
                              return Colors.white;
                            }),
                            elevation: WidgetStateProperty.all(2),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          child: const Text(
                            '회원가입 완료',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ); // ✅ 닫는 괄호 정리
  }


  Widget _buildFolderRoleSelector() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            Expanded(child: _folderTab('환자', 'P', isLeft: true)),
            Expanded(child: _folderTab('의사', 'D', isLeft: false)),
          ],
        ),
      ),
    );
  }

  Widget _folderTab(String label, String value, {required bool isLeft}) {
    final isSelected = _selectedRole == value;

    final backgroundColor = isSelected
        ? (value == 'P'
            ? const Color(0xFFFFFF99)
            : const Color(0xFF66BB6A))
        : Colors.transparent;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
          _isIdChecked = false;
          _isDuplicate = true;
          _registerIdController.clear();
          context.read<AuthViewModel>().clearDuplicateCheckErrorMessage();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isLeft ? 24 : 0),
            topRight: Radius.circular(!isLeft ? 24 : 0),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          filled: true,
          fillColor: Colors.grey[100],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none, // 평소에는 외곽선 없음
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color(0xFF5F97F7), // ✅ primaryBlue 색상
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return '$label을 입력해주세요';
          if (label == '비밀번호 확인' && value != _passwordController.text) {
            return '비밀번호가 일치하지 않습니다';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderCardSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _genderCard('남', 'M', Colors.blue[700]!),
          const SizedBox(width: 16),
          _genderCard('여', 'F', Colors.red[400]!),
        ],
      ),
    );
  }

  Widget _genderCard(String label, String genderValue, Color color) {
    final isSelected = _selectedGender == genderValue;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = genderValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            children: [
              Icon(
                genderValue == 'M' ? Icons.male : Icons.female,
                size: 40,
                color: isSelected ? Colors.white : Colors.black54,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', '');
    if (text.length > 8) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 3 || i == 5) buffer.write('-');
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', '');
    if (text.length > 11) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 || i == 6) {
        if (text.length > i + 1) buffer.write('-');
      }
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
