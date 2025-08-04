import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import 'dart:convert'; // ✅ utf8 사용을 위한 import

class RegisterScreen extends StatefulWidget {
  final String baseUrl;

  const RegisterScreen({super.key, required this.baseUrl});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _selectedGender = 'M';
  String _selectedRole = 'P';
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  List<int> _years = List.generate(141, (index) => DateTime.now().year - index);
  List<int> _months = List.generate(12, (index) => index + 1);

  bool _isDuplicate = true;
  bool _isIdChecked = false;

  static const Color primaryBlue = Color(0xFF5F97F7);
  static const Color lightBlueBackground = Color(0xFFB4D4FF);

  @override
  void dispose() {
    _nameController.dispose();
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
    String? _validateBirth() {
      if (_selectedYear == null || _selectedMonth == null || _selectedDay == null) {
        return '생년월일을 모두 선택해주세요';
      }
      final birthDate = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
      final now = DateTime.now();
      final oldest = DateTime(now.year - 125, now.month, now.day);
      if (birthDate.isBefore(oldest) || birthDate.isAfter(now)) {
        return '유효한 생년월일을 입력해주세요';
      }
      return null;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnack('모든 필드를 올바르게 입력해주세요.');
      return;
    }
    final birthError = _validateBirth();
      if (birthError != null) {
        _showSnack(birthError);
        return;
      }
    if (!_isIdChecked || _isDuplicate) {
      _showSnack('아이디 중복 확인을 완료해주세요.');
      return;
    }

    final userData = {
      'register_id': _registerIdController.text.trim(), // ✅ 아이디
      'password': _passwordController.text.trim(),      // ✅ 비밀번호
      'name': _nameController.text.trim(),              // ✅ 이름
      'gender': _selectedGender,
      'birth': '${_selectedYear!}-${_selectedMonth!.toString().padLeft(2, '0')}-${_selectedDay!.toString().padLeft(2, '0')}',
      'phone': _phoneController.text.trim(),
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

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedYear,
      decoration: const InputDecoration(labelText: '연도'),
      items: _years.map((year) {
        return DropdownMenuItem(value: year, child: Text('$year'));
      }).toList(),
      onChanged: (val) => setState(() => _selectedYear = val),
      validator: (val) => val == null ? '연도를 선택해주세요' : null,
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedMonth,
      decoration: const InputDecoration(labelText: '월'),
      items: _months.map((month) {
        return DropdownMenuItem(value: month, child: Text('$month'));
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedMonth = val;
          _selectedDay = null; // 월 바뀌면 일 초기화
        });
      },
      validator: (val) => val == null ? '월을 선택해주세요' : null,
    );
  }

  Widget _buildDayDropdown() {
    int maxDay = 31;
    if (_selectedYear != null && _selectedMonth != null) {
      maxDay = DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
    }
    final days = List.generate(maxDay, (index) => index + 1);

    return DropdownButtonFormField<int>(
      value: _selectedDay,
      decoration: const InputDecoration(labelText: '일'),
      items: days.map((day) {
        return DropdownMenuItem(value: day, child: Text('$day'));
      }).toList(),
      onChanged: (val) => setState(() => _selectedDay = val),
      validator: (val) => val == null ? '일을 선택해주세요' : null,
    );
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedRole = value;
                _isIdChecked = false;
                _isDuplicate = true;
                _registerIdController.clear();
                authViewModel.clearDuplicateCheckErrorMessage();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'P', child: Text('환자')),
              const PopupMenuItem(value: 'D', child: Text('의사')),
            ],
            icon: const Icon(Icons.account_circle),
            tooltip: '사용자 유형 선택',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                  _buildTextField(
                    _nameController,
                    '이름 (한글만)',
                    inputFormatters: [_NameByteLimitFormatter()],
                  ),
                  const SizedBox(height: 10),
                  _buildGenderCardSelector(),
                  Row(
                    children: [
                      Expanded(child: _buildYearDropdown()),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMonthDropdown()),
                      const SizedBox(width: 10),
                      Expanded(child: _buildDayDropdown()),
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
                  _buildTextField(_passwordController, '비밀번호 (6자 이상)', isPassword: true),
                  _buildTextField(_confirmController, '비밀번호 확인', isPassword: true),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        '회원가입 완료',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return '$label을 입력해주세요';
          if (label == '비밀번호 확인' && value != _passwordController.text) {
            return '비밀번호가 일치하지 않습니다';
          }
          if (label == '이름 (한글만)' && !RegExp(r'^[가-힣]+$').hasMatch(value)) {
            return '이름은 한글만 입력해주세요';
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
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
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

class _NameByteLimitFormatter extends TextInputFormatter {
  final int maxBytes;
  _NameByteLimitFormatter({this.maxBytes = 15});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text;
    final bytes = utf8.encode(newText);
    if (bytes.length <= maxBytes) return newValue;

    // 바이트 수 초과 시 앞에서부터 유효한 범위까지만 자르기
    int byteCount = 0;
    int cutoffIndex = 0;
    for (int i = 0; i < newText.length; i++) {
      final char = newText[i];
      final charBytes = utf8.encode(char);
      if (byteCount + charBytes.length > maxBytes) break;
      byteCount += charBytes.length;
      cutoffIndex = i + 1;
    }

    final truncated = newText.substring(0, cutoffIndex);
    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }
}

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.replaceAll('-', '');

    if (newText.length < oldValue.text.replaceAll('-', '').length) {
      // ✅ 백스페이스 동작 허용
      return newValue;
    }

    if (newText.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      if (i == 3 || i == 5) buffer.write('-');
    }

    return TextEditingValue(
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