import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/presentation/model/user.dart';
import '/presentation/viewmodel/userinfo_viewmodel.dart';
import '/presentation/screens/register_screen.dart'; // DateInputFormatter를 위해 임포트

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedGender;
  late TextEditingController _birthController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController; // ✅ userId 대신 username 사용
  late TextEditingController _addressController; // 주소 필드 추가

  @override
  void initState() {
    super.initState();
    final userInfoViewModel = Provider.of<UserInfoViewModel>(context, listen: false);
    final User? user = userInfoViewModel.user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _selectedGender = user?.gender ?? 'M';
    _birthController = TextEditingController(text: user?.birth ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _usernameController = TextEditingController(text: user?.username ?? ''); // ✅ userId 대신 username 사용
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    _phoneController.dispose();
    _usernameController.dispose(); // ✅ _userIdController 대신 _usernameController 사용
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('모든 필드를 올바르게 입력해주세요.');
      return;
    }

    final userInfoViewModel = context.read<UserInfoViewModel>();
    final User? currentUser = userInfoViewModel.user;

    if (currentUser == null) {
      _showSnack('로그인 정보가 없습니다.');
      return;
    }

    final updatedData = {
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      'birth': _birthController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    final error = await userInfoViewModel.updateUserProfile(currentUser.id, updatedData);

    if (error == null) {
      _showSnack('프로필이 성공적으로 업데이트되었습니다!');
      context.pop();
    } else {
      _showSnack(error);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              _buildTextField(
                _nameController,
                '이름 (한글만)',
                keyboardType: TextInputType.name,
              ),
              _buildGenderSelector(),
              _buildTextField(
                _birthController,
                '생년월일 (YYYY-MM-DD)',
                maxLength: 10,
                keyboardType: TextInputType.number,
                inputFormatters: [DateInputFormatter()],
              ),
              _buildTextField(
                _phoneController,
                '전화번호 (숫자만)',
                maxLength: 11,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _buildTextField(
                _usernameController, // ✅ _userIdController 대신 _usernameController 사용
                '아이디',
                readOnly: true,
              ),
              _buildTextField(
                _addressController,
                '주소',
                keyboardType: TextInputType.streetAddress,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('저장'),
              ),
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
          if (label == '전화번호 (숫자만)' && value != null && !RegExp(r'^\d{10,11}$').hasMatch(value)) {
            return '유효한 전화번호를 입력하세요 (숫자 10-11자리)';
          }
          if (label == '생년월일 (YYYY-MM-DD)' && value != null) {
            final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
            if (!dateRegex.hasMatch(value)) {
              return '올바른 생년월일 형식(YYYY-MM-DD)으로 입력하세요';
            }
            try {
              final DateTime birthDate = DateTime.parse(value);
              final DateTime now = DateTime.now();
              if (birthDate.isAfter(now)) {
                return '생년월일은 오늘 날짜를 넘을 수 없습니다';
              }
            } catch (e) {
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
