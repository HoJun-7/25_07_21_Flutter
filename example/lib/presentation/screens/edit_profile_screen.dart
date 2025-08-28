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

  bool _showPassword = false;
  bool _saving = false;

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

    setState(() => _saving = true);
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
    setState(() => _saving = false);

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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final cutoff = DateTime(now.year - 110, now.month, now.day);

    final parsed = DateTime.tryParse(_birthController.text) ?? DateTime(1995, 1, 1);
    final initial = parsed.isBefore(cutoff)
        ? cutoff
        : (parsed.isAfter(now) ? now : parsed);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: cutoff, // ✅ 오늘 기준 110년 이전 선택 불가
      lastDate: now,     // ✅ 미래 선택 불가
      helpText: '생년월일 선택',
      confirmText: '확인',
      cancelText: '취소',
    );
    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      _birthController.text = '$y-$m-$d';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEAF4FF);
    const primary = Color(0xFF3869A8);
    const cardRadius = 24.0;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('개인 정보 변경'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05), // ⚙️ withOpacity -> withValues
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: bg,
                                child: Icon(Icons.person, size: 28, color: Colors.black54),
                              ),
                              const SizedBox(width: 12),
                              const Text('내 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildLabeledField(
                            label: '이름',
                            child: _buildRoundedField(
                              _nameController,
                              '이름 (한글만)',
                              keyboardType: TextInputType.name,
                            ),
                          ),

                          _buildLabeledField(
                            label: '성별',
                            child: _buildGenderButtons(),
                          ),

                          _buildLabeledField(
                            label: '비밀번호',
                            helper: '6자 이상 • 영문,숫자,특수기호 사용가능합니다',
                            child: _buildRoundedField(
                              _passwordController,
                              '비밀번호 (6자 이상)',
                              isPassword: true,
                              minLength: 6,
                            ),
                          ),

                          _buildLabeledField(
                            label: '생년월일',
                            child: _buildRoundedField(
                              _birthController,
                              '생년월일 (YYYY-MM-DD)',
                              maxLength: 10,
                              keyboardType: TextInputType.datetime,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(10),
                                const DateHyphenFormatter(), // ⚙️ 리스트에서 const 삭제, 생성자는 const 아님 → 여기 const 제거해도 OK
                              ],
                              suffix: IconButton(
                                icon: const Icon(Icons.calendar_today_outlined),
                                onPressed: _pickBirthDate,
                                tooltip: '달력에서 선택',
                              ),
                            ),
                          ),

                          _buildLabeledField(
                            label: '전화번호',
                            child: _buildRoundedField(
                              _phoneController,
                              '전화번호',
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                                _PhoneNumberFormatter(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                          const Divider(height: 24),
                          const SizedBox(height: 8),

                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: primary.withValues(alpha: 0.5), // ⚙️ withOpacity -> withValues
                                disabledForegroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                    )
                                  : const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 라벨 + 필드 묶음
  Widget _buildLabeledField({required String label, String? helper, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          if (helper != null) ...[
            const SizedBox(height: 2),
            Text(helper, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
          ],
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildRoundedField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
    int? maxLength,
    int? minLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_showPassword,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF5F8FC),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        counterText: '',
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              )
            : suffix,
      ),
      validator: (value) {
        final v = value?.trim() ?? '';

        // ✅ 생년월일은 전용 검증기 사용
        if (label.contains('생년월일')) {
          return DobValidator.validate(v);
        }

        if ((v.isEmpty) && !isPassword) return '$label을 입력해주세요';
        if (isPassword && v.isNotEmpty && minLength != null && v.length < minLength) {
          return '$label은 ${minLength}자 이상이어야 합니다';
        }
        if (label.contains('이름') && v.isNotEmpty && !RegExp(r'^[가-힣]+$').hasMatch(v)) {
          return '이름은 한글만 입력 가능합니다';
        }
        if (label == '전화번호' && !RegExp(r'^\d{3}-\d{3,4}-\d{4}$').hasMatch(v)) {
          return '전화번호 형식이 올바르지 않습니다';
        }
        return null;
      },
    );
  }

  Widget _buildGenderButtons() {
    const maleColor = Color(0xFF3F8CD4);
    const femaleColor = Color(0xFFE53935);
    const unselectedBg = Color(0xFFE9EDF3);

    Widget genderChip(String label, String value, Color activeColor) {
      final selected = _selectedGender == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedGender = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? activeColor : unselectedBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) const Icon(Icons.check, color: Colors.white, size: 18),
                if (selected) const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        genderChip('남', 'M', maleColor),
        const SizedBox(width: 12),
        genderChip('여', 'F', femaleColor),
      ],
    );
  }
}

/// ✅ 생년월일 자동 포맷터 (YYYY-MM-DD)
/// - 숫자만 허용 후 하이픈 자동 삽입
/// - 하이픈 위치에서 백스페이스 정상 동작 (커서 보정)
/// - 월을 01..12로 자동 보정
/// - 일을 해당 달 마지막 날로 자동 보정(윤년 포함)
class DateHyphenFormatter extends TextInputFormatter {
  const DateHyphenFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 새 값에서 커서 앞까지의 숫자 개수
    final digitCursor = _countDigitsBefore(newValue.text, newValue.selection.baseOffset);

    // 숫자만 추출
    final digits = StringBuffer();
    for (int i = 0; i < newValue.text.length; i++) {
      final c = newValue.text[i];
      if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
        digits.write(c);
      }
    }
    var d = digits.toString();

    // 월 보정
    if (d.length >= 6) {
      final year = int.tryParse(d.substring(0, 4)) ?? 0;
      var month = int.tryParse(d.substring(4, 6)) ?? 0;
      if (month <= 0) month = 1;
      if (month > 12) month = 12;
      d = d.replaceRange(4, 6, month.toString().padLeft(2, '0'));

      // 일 보정
      if (d.length >= 8) {
        var day = int.tryParse(d.substring(6, 8)) ?? 0;
        final maxDay = _daysInMonth(year, month);
        if (day <= 0) day = 1;
        if (day > maxDay) day = maxDay;
        d = d.replaceRange(6, 8, day.toString().padLeft(2, '0'));
      }
    }

    // 하이픈 삽입: YYYY-MM-DD
    final buf = StringBuffer();
    var writtenDigits = 0;
    for (int i = 0; i < d.length && i < 8; i++) {
      buf.write(d[i]);
      writtenDigits++;
      if (writtenDigits == 4 || writtenDigits == 6) {
        buf.write('-');
      }
    }
    var formatted = buf.toString();
    if (formatted.endsWith('-')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    // 커서 위치 복원
    final caret = _caretOffsetFromDigitIndex(formatted, digitCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: caret),
      composing: TextRange.empty,
    );
  }

  int _countDigitsBefore(String text, int rawIndex) {
    var cnt = 0;
    final idx = rawIndex.clamp(0, text.length);
    for (int i = 0; i < idx; i++) {
      final c = text[i];
      if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) cnt++;
    }
    return cnt;
  }

  int _caretOffsetFromDigitIndex(String formatted, int digitIdx) {
    if (digitIdx <= 0) return 0;
    var count = 0;
    for (int i = 0; i < formatted.length; i++) {
      final c = formatted[i];
      if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
        count++;
        if (count == digitIdx) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }

  int _daysInMonth(int year, int month) {
    if (month < 1 || month > 12) return 31;
    final last = DateTime(year, month + 1, 0); // 다음 달 0일 = 해당 달 마지막 날
    return last.day;
  }
}

/// ✅ 생년월일 검증기
/// - 형식: YYYY-MM-DD
/// - 월: 1..12
/// - 일: 1..해당 달 마지막 날(윤년 반영)
/// - 오늘 기준 110년 이전 금지
/// - 미래 날짜 금지
class DobValidator {
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '생년월일을 입력해 주세요 (예: 1990-03-15)';
    }
    final s = value.trim();
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(s)) {
      return '생년월일을 YYYY-MM-DD 형식으로 입력하세요';
    }

    final year = int.tryParse(s.substring(0, 4));
    final month = int.tryParse(s.substring(5, 7));
    final day = int.tryParse(s.substring(8, 10));

    if (year == null || month == null || day == null) {
      return '올바른 생년월일이 아닙니다';
    }
    if (month < 1 || month > 12) {
      return '달은 1~12 사이여야 합니다';
    }

    final maxDay = _daysInMonth(year, month);
    if (day < 1 || day > maxDay) {
      return '해당 달의 마지막 날(${maxDay}일)을 초과했습니다';
    }

    DateTime dob;
    try {
      dob = DateTime(year, month, day);
    } catch (_) {
      return '올바른 생년월일이 아닙니다';
    }

    final now = DateTime.now();
    final cutoff = DateTime(now.year - 110, now.month, now.day);
    if (dob.isBefore(cutoff)) {
      return '오늘 기준 110년 이전 생년월일은 등록할 수 없습니다';
    }
    if (dob.isAfter(now)) {
      return '미래 날짜는 등록할 수 없습니다';
    }

    return null;
  }

  static int _daysInMonth(int year, int month) {
    final last = DateTime(year, month + 1, 0);
    return last.day;
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