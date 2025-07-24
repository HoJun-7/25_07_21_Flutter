import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '/presentation/model/user.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late String _selectedGender;
  late TextEditingController _birthController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final User? user = authViewModel.currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _passwordController = TextEditingController();
    _selectedGender = user?.gender ?? 'M';
    _birthController = TextEditingController(text: user?.birth ?? '');
    _phoneController = TextEditingController(text: _formatPhone(user?.phone ?? ''));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _birthController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('모든 필드를 올바르게 입력해주세요.');
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final User? currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      _showSnack('로그인 정보가 없습니다.');
      return;
    }

    final updatedData = {
      'register_id': currentUser.registerId,
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      'birth': _birthController.text.trim(),
      'phone': _phoneController.text.replaceAll('-', ''),
      'password': _passwordController.text.trim(),
      'role': currentUser.role ?? 'P',
    };

    final result = await authViewModel.updateProfile(updatedData);

    if (!mounted) return;

    context.push('/edit_profile_result', extra: {
      'isSuccess': result['isSuccess'],
      'message': result['message'],
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatPhone(String raw) {
    final onlyDigits = raw.replaceAll(RegExp(r'\D'), '');
    if (onlyDigits.length == 11) {
      return '${onlyDigits.substring(0, 3)}-${onlyDigits.substring(3, 7)}-${onlyDigits.substring(7)}';
    } else if (onlyDigits.length == 10) {
      return '${onlyDigits.substring(0, 3)}-${onlyDigits.substring(3, 6)}-${onlyDigits.substring(6)}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              _buildTextField(_nameController, '이름 (한글만)', keyboardType: TextInputType.name),
              _buildGenderSelector(),
              _buildTextField(_passwordController, '비밀번호 (6자 이상)', isPassword: true, minLength: 6),
              _buildTextField(
                _birthController,
                '생년월일 (YYYY-MM-DD)',
                maxLength: 10,
                keyboardType: TextInputType.datetime,
                inputFormatters: [DateInputFormatter()],
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
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text('저장')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
    int? maxLength,
    int? minLength,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        maxLength: maxLength,
        keyboardType: keyboardType,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: '',
        ),
        validator: (value) {
          if (!readOnly && (value == null || value.trim().isEmpty)) {
            return '$label을 입력해주세요';
          }
          if (minLength != null && value!.trim().length < minLength) {
            return '$label은 ${minLength}자 이상이어야 합니다';
          }
          if (label == '이름 (한글만)' && value != null && !RegExp(r'^[가-힣]+$').hasMatch(value)) {
            return '이름은 한글만 입력 가능합니다';
          }
          if (label == '전화번호' && value != null && !RegExp(r'^\d{3}-\d{3,4}-\d{4}$').hasMatch(value)) {
            return '유효한 전화번호를 입력하세요 (형식: 010-1234-5678)';
          }
          if (label == '생년월일 (YYYY-MM-DD)' && value != null) {
            final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
            if (!dateRegex.hasMatch(value)) return '올바른 생년월일 형식(YYYY-MM-DD)으로 입력하세요';
            try {
              final DateTime birthDate = DateTime.parse(value);
              if (birthDate.isAfter(DateTime.now())) {
                return '생년월일은 오늘 날짜를 넘을 수 없습니다';
              }
            } catch (_) {
              return '유효하지 않은 날짜입니다 (예: 2023-02-30)';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Text('성별', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: RadioListTile<String>(
              title: const Text('남'),
              value: 'M',
              groupValue: _selectedGender,
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: const Text('여'),
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

/// 생년월일 자동 포맷터 (YYYY-MM-DD)
class DateInputFormatter extends TextInputFormatter {
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

/// 전화번호 하이픈 자동 포맷터 (010-xxxx-xxxx)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', '');
    if (text.length > 11) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 || (text.length >= 10 && i == 6)) buffer.write('-');
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
