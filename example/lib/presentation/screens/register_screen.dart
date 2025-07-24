import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
<<<<<<< HEAD
  final String baseUrl;

  const RegisterScreen({super.key, required this.baseUrl});
=======
  const RegisterScreen({super.key});
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
<<<<<<< HEAD

  final _nameController = TextEditingController();
=======
  final _nameController = TextEditingController();
  String _selectedGender = 'M';
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
  final _birthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
<<<<<<< HEAD

  String _selectedGender = 'M';
  String _selectedRole = 'P';
  bool _isIdChecked = false;
  bool _isDuplicate = true; // 초기값 설정 (중복으로 간주)
  String? _duplicateCheckErrorMessage;
=======
  String _selectedRole = 'P';

  bool _isDuplicate = true;
  bool _isIdChecked = false;
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4

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
<<<<<<< HEAD
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = _registerIdController.text.trim();
    if (userId.length < 4) {
      setState(() {
        _duplicateCheckErrorMessage = '아이디는 4자 이상 입력해주세요.';
        _isIdChecked = false;
=======
    final viewModel = context.read<AuthViewModel>();
    final id = _registerIdController.text.trim();

    if (id.length < 4) {
      _showSnack('아이디는 최소 4자 이상이어야 합니다');
      setState(() {
        _isIdChecked = false;
        _isDuplicate = true;
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
      });
      return;
    }

<<<<<<< HEAD
    setState(() {
      _duplicateCheckErrorMessage = null;
    });

    final isDuplicate = await authViewModel.checkUserIdDuplicate(userId, _selectedRole);
    setState(() {
      _isIdChecked = true;
      // 'bool?' 타입의 isDuplicate를 'bool' 타입의 _isDuplicate에 할당하기 위해
      // null 병합 연산자(??)를 사용하여 isDuplicate가 null일 경우 true(중복)로 처리합니다.
      _isDuplicate = isDuplicate ?? true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isIdChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디 중복확인을 해주세요.')),
      );
      return;
    }

    if (_isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 사용 중인 아이디입니다.')),
      );
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userData = {
      "register_id": _registerIdController.text.trim(),
      "password": _passwordController.text,
      "name": _nameController.text.trim(),
      "birth": _birthController.text.trim(),
      "phone": _phoneController.text.trim(),
      "gender": _selectedGender,
      "role": _selectedRole,
    };

    final error = await authViewModel.registerUser(userData);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공!')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int minLength = 0,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: Colors.grey[50],
          filled: true,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '필수 입력 항목입니다.';
          if (minLength > 0 && value.length < minLength) return '$minLength자 이상 입력해주세요.';
          if (label.contains('비밀번호 확인') && value != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
          return null;
        },
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildGenderSelector(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Text('성별:'),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('남자'),
            selected: _selectedGender == 'M',
            onSelected: (selected) {
              setState(() {
                _selectedGender = 'M';
              });
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('여자'),
            selected: _selectedGender == 'F',
            onSelected: (selected) {
              setState(() {
                _selectedGender = 'F';
              });
            },
          ),
        ],
      ),
    );
=======
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
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
<<<<<<< HEAD
      backgroundColor: const Color(0xFFB4D4FF),
      appBar: AppBar(
        title: Text('회원가입', style: textTheme.headlineLarge),
        backgroundColor: const Color(0xFF5F97F7),
        foregroundColor: Colors.white,
=======
      appBar: AppBar(
        title: Text('회원가입', style: textTheme.headlineLarge),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedRole = value;
                _isIdChecked = false;
<<<<<<< HEAD
                _isDuplicate = true; // 역할 변경 시 중복 확인 초기화
                _registerIdController.clear();
                _duplicateCheckErrorMessage = null;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'P', child: Text('환자')),
              PopupMenuItem(value: 'D', child: Text('의사')),
=======
                _isDuplicate = true;
                _registerIdController.clear();
                authViewModel.clearDuplicateCheckErrorMessage();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'P', child: Text('환자')),
              const PopupMenuItem(value: 'D', child: Text('의사')),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
            ],
            icon: const Icon(Icons.account_circle),
            tooltip: '사용자 유형 선택',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
<<<<<<< HEAD
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildTextField(_nameController, '이름 (한글만)', keyboardType: TextInputType.name),
                _buildGenderSelector(textTheme),
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
                        minLength: 4,
                        onChanged: (_) {
                          setState(() {
                            _isIdChecked = false;
                            _isDuplicate = true; // 아이디 변경 시 중복 확인 초기화
                            _duplicateCheckErrorMessage = null;
                          });
                        },
                        errorText: _duplicateCheckErrorMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: authViewModel.isCheckingUserId ? null : _checkDuplicateId,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F97F7),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authViewModel.isCheckingUserId
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isIdChecked
                                  ? (_isDuplicate ? '사용 불가' : '사용 가능')
                                  : '중복확인',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
                _buildTextField(_passwordController, '비밀번호 (6자 이상)', isPassword: true, minLength: 6),
                _buildTextField(_confirmController, '비밀번호 확인', isPassword: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F97F7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '회원가입 완료',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
=======
          child: ListView(
            children: [
              _buildTextField(_nameController, '이름 (한글만)', keyboardType: TextInputType.name),
              _buildGenderSelector(textTheme),
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
                      minLength: 4,
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
                  ElevatedButton(
                    onPressed: authViewModel.isCheckingUserId ? null : _checkDuplicateId,
                    child: authViewModel.isCheckingUserId
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('중복확인'),
                  ),
                ],
              ),
              _buildTextField(_passwordController, '비밀번호 (6자 이상)', isPassword: true, minLength: 6),
              _buildTextField(_confirmController, '비밀번호 확인', isPassword: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('회원가입 완료'),
                ),
              ),
            ],
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    if (digitsOnly.length >= 4) {
      formatted += digitsOnly.substring(0, 4);
    } else {
      formatted += digitsOnly;
    }
    if (digitsOnly.length >= 6) {
      formatted += '-' + digitsOnly.substring(4, 6);
    } else if (digitsOnly.length > 4) {
      formatted += '-' + digitsOnly.substring(4);
    }
    if (digitsOnly.length >= 8) {
      formatted += '-' + digitsOnly.substring(6, 8);
    } else if (digitsOnly.length > 6) {
      formatted += '-' + digitsOnly.substring(6);
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
=======

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
    int? minLength,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return '$label을 입력해주세요';
          if (minLength != null && value.trim().length < minLength) {
            return '$label은 ${minLength}자 이상이어야 합니다';
          }
          if (label == '비밀번호 확인' && value != _passwordController.text) {
            return '비밀번호가 일치하지 않습니다';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderSelector(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('성별', style: textTheme.bodyMedium),
          const SizedBox(width: 16),
          Expanded(
            child: RadioListTile<String>(
              title: Text('남', style: textTheme.labelLarge),
              value: 'M',
              groupValue: _selectedGender,
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: Text('여', style: textTheme.labelLarge),
              value: 'F',
              groupValue: _selectedGender,
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
          ),
        ],
      ),
    );
  }
}

// 생년월일 자동 포맷
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
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
    );
  }
}

<<<<<<< HEAD
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = digits;
    if (digits.length >= 11) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, 11)}';
    } else if (digits.length >= 7) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    } else if (digits.length >= 4) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
=======
// 전화번호 자동 포맷
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
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
