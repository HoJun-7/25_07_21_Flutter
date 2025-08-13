// ✅ 성별 선택 버튼 위젯 (환자/의사 선택 버튼과 유사하게 수정)
Widget _buildGenderCardSelector() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _genderSelectionButton('남', 'M', Colors.blue[700]!),
        const SizedBox(width: 10), // 환자/의사 버튼과 동일하게 간격 조정
        _genderSelectionButton('여', 'F', Colors.red[400]!),
      ],
    ),
  );
}

Widget _genderSelectionButton(String label, String genderValue, Color color) {
  final isSelected = _selectedGender == genderValue;
  return Expanded(
    child: ElevatedButton(
      onPressed: () => setState(() => _selectedGender = genderValue),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSelected) const Icon(Icons.check, size: 20),
          if (isSelected) const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}