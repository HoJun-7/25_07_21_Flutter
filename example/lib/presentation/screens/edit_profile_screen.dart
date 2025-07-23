import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app/presentation/model/user.dart'; // User 모델 경로 확인 및 수정
import 'package:app/presentation/viewmodel/userinfo_viewmodel.dart'; // UserInfoViewModel 경로 확인 및 수정
import 'package:app/presentation/screens/register_screen.dart'; // DateInputFormatter 경로 확인 및 수정

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
  late TextEditingController _usernameController; // userId 대신 username 사용
  late TextEditingController _addressController; // 주소 필드 추가

  @override
  void initState() {
    super.initState();
    final userInfoViewModel = Provider.of<UserInfoViewModel>(context, listen: false);
    final User? user = userInfoViewModel.user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _selectedGender = user?.gender ?? 'M'; // 기본값 설정
    _birthController = TextEditingController(text: user?.birth ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// 프로필 업데이트를 서버에 요청하고 결과를 처리하는 함수
  Future<void> _submit() async {
    // 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('모든 필드를 올바르게 입력해주세요.');
      return;
    }

    final userInfoViewModel = context.read<UserInfoViewModel>();
    final User? currentUser = userInfoViewModel.user;

    // 현재 로그인된 사용자 정보가 없는 경우
    if (currentUser == null) {
      _showSnackBar('로그인 정보가 없습니다. 다시 로그인해주세요.');
      return;
    }

    // 업데이트할 데이터 맵 생성
    final updatedData = {
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      'birth': _birthController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      // 'username'은 읽기 전용이므로 업데이트 데이터에 포함하지 않음
    };

    // 사용자 프로필 업데이트 요청
    final error = await userInfoViewModel.updateUserProfile(currentUser.id, updatedData);

    if (error == null) {
      // 성공 시 스낵바 메시지 표시 후 이전 화면으로 이동
      _showSnackBar('프로필이 성공적으로 업데이트되었습니다!');
      context.pop();
    } else {
      // 실패 시 에러 메시지 표시
      _showSnackBar(error);
    }
  }

  /// 사용자에게 스낵바 메시지를 보여주는 헬퍼 함수
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // 요청하신 #B4D4FF 색상 정의
    const Color customBackgroundColor = Color(0xFFB4D4FF);

    return Scaffold(
      // ✅ Scaffold의 배경색을 #B4D4FF로 설정
      backgroundColor: customBackgroundColor,
      appBar: AppBar(
        title: const Text('프로필 수정'),
        centerTitle: true, // 제목 중앙 정렬
        // ✅ AppBar 배경색을 투명하게 설정하여 뒤의 Scaffold 배경색이 보이도록
        backgroundColor: Colors.transparent,
        // ✅ AppBar 그림자 제거
        elevation: 0,
      ),
      body: Container( // ✅ Container로 body를 감싸서 흰색 배경을 추가합니다.
        // Container의 상단 마진을 주어 AppBar와 간격을 둡니다.
        margin: const EdgeInsets.only(top: 20.0), // 적절한 값으로 조절
        // 가로로 최대한 확장
        width: double.infinity,
        // 데모 이미지와 유사하게 박스 모양을 만듭니다.
        decoration: BoxDecoration(
          color: Colors.white, // ✅ Container의 배경색을 흰색으로 설정
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), // 상단 왼쪽 모서리 둥글게
            topRight: Radius.circular(20), // 상단 오른쪽 모서리 둥글게
          ),
          boxShadow: [ // 그림자 추가 (선택 사항)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 전체 패딩
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction, // 사용자 입력 시 자동 유효성 검사
            child: ListView(
              children: [
                // 이름 입력 필드
                _buildTextField(
                  _nameController,
                  '이름 (한글만)',
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이름을 입력해주세요.';
                    }
                    if (!RegExp(r'^[가-힣]+$').hasMatch(value)) {
                      return '이름은 한글만 입력 가능합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16), // 간격 추가

                // 성별 선택 라디오 버튼
                _buildGenderSelector(),
                const SizedBox(height: 16), // 간격 추가

                // 생년월일 입력 필드
                _buildTextField(
                  _birthController,
                  '생년월일 (YYYY-MM-DD)',
                  maxLength: 10,
                  keyboardType: TextInputType.number,
                  inputFormatters: [DateInputFormatter()], // 날짜 형식 자동 입력
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '생년월일을 입력해주세요.';
                    }
                    final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                    if (!dateRegex.hasMatch(value)) {
                      return '올바른 생년월일 형식(YYYY-MM-DD)으로 입력하세요.';
                    }
                    try {
                      final DateTime birthDate = DateTime.parse(value);
                      final DateTime now = DateTime.now();
                      if (birthDate.isAfter(now)) {
                        return '생년월일은 미래 날짜일 수 없습니다.';
                      }
                    } catch (e) {
                      return '유효하지 않은 날짜입니다 (예: 2023-02-30).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16), // 간격 추가

                // 전화번호 입력 필드
                _buildTextField(
                  _phoneController,
                  '전화번호 (숫자만)',
                  maxLength: 11,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 숫자만 입력 허용
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '전화번호를 입력해주세요.';
                    }
                    if (!RegExp(r'^\d{10,11}$').hasMatch(value)) {
                      return '유효한 전화번호를 입력하세요 (숫자 10-11자리).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16), // 간격 추가

                // 아이디 입력 필드 (읽기 전용)
                _buildTextField(
                  _usernameController,
                  '아이디',
                  readOnly: true, // 읽기 전용 설정
                  validator: (value) => null, // 읽기 전용 필드는 유효성 검사 필요 없음
                ),
                const SizedBox(height: 16), // 간격 추가

                // 주소 입력 필드
                _buildTextField(
                  _addressController,
                  '주소',
                  keyboardType: TextInputType.streetAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '주소를 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32), // 하단 버튼과의 간격

                // 저장 버튼
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15), // 버튼 패딩
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 버튼 모서리 둥글게
                    ),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(fontSize: 18), // 텍스트 크기
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 일반 텍스트 입력 필드를 생성하는 헬퍼 함수
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
    int? maxLength,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    String? Function(String?)? validator, // 유효성 검사 함수를 직접 받을 수 있도록 추가
  }) {
    return TextFormField(
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
        counterText: '', // maxLength 사용 시 하단 카운터 텍스트 숨김
      ),
      validator: validator, // 외부에서 받은 validator 함수 사용
    );
  }

  /// 성별 선택 라디오 버튼 그룹을 생성하는 헬퍼 함수
  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성별',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black87), // 일반 텍스트 필드와 유사한 스타일
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('남'),
                value: 'M',
                groupValue: _selectedGender,
                onChanged: (value) => setState(() => _selectedGender = value!),
                activeColor: Colors.blue, // 예시 색상, 원하는 색상으로 변경 가능
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('여'),
                value: 'F',
                groupValue: _selectedGender,
                onChanged: (value) => setState(() => _selectedGender = value!),
                activeColor: Colors.pink, // 예시 색상, 원하는 색상으로 변경 가능
              ),
            ),
          ],
        ),
      ],
    );
  }
}