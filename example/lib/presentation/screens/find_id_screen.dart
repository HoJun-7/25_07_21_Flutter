import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/find_id_viewmodel.dart';
import 'package:go_router/go_router.dart';

// Custom Gradient Button Widget (재사용성을 위해 별도 위젯으로 분리)
// 이 위젯은 이제 find_id_screen.dart와 find_password_screen.dart 모두에서 접근 가능합니다.
class _GradientButton extends StatefulWidget {
  final Widget child;
  final Gradient gradient;
  final VoidCallback onPressed;
  final double height;
  final double borderRadius;

  const _GradientButton({
    required this.child,
    required this.gradient,
    required this.onPressed,
    this.height = 55,
    this.borderRadius = 12.0,
  });

  @override
  _GradientButtonState createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // 애니메이션 지속 시간
      lowerBound: 0.95, // 버튼이 눌렸을 때 약간 작아지도록 설정
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate( // 실제 스케일 변화 범위
      CurvedAnimation(parent: _controller, curve: Curves.easeOut), // 부드러운 애니메이션 곡선
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 탭 다운 시 애니메이션 역방향 실행 (작아짐)
  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  // 탭 업 시 애니메이션 정방향 실행 (원래 크기로 돌아옴)
  void _onTapUp(TapUpDetails details) {
    _controller.forward();
  }

  // 탭 취소 시 애니메이션 정방향 실행
  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed, // 실제 버튼 동작
      child: ScaleTransition(
        scale: _scaleAnimation, // 스케일 애니메이션 적용
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.gradient, // 그라데이션 배경
            borderRadius: BorderRadius.circular(widget.borderRadius), // 둥근 모서리
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25), // 그림자 색상 및 투명도
                spreadRadius: 2, // 그림자 확산 반경
                blurRadius: 15, // 그림자 흐림 정도
                offset: const Offset(0, 8), // 그림자 오프셋 (아래로 더 길게)
              ),
            ],
          ),
          child: Center(child: widget.child), // 버튼 텍스트 또는 위젯
        ),
      ),
    );
  }
}

class FindIdScreen extends StatelessWidget {
  final String baseUrl;

  const FindIdScreen({Key? key, required this.baseUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<FindIdViewModel>(context);

    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB4D4FF), // 시작 색상 (기존 배경색)
              Color(0xFFA0C5FF), // 끝 색상 (약간 더 어두운/밝은 파란색 계열)
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent, // Scaffold 배경을 투명하게 설정하여 Container의 그라데이션이 보이도록 함
          appBar: AppBar(
            title: const Text(
              '아이디 찾기',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 24, // 제목 글꼴 크기 더 키우기
                shadows: [ // 텍스트 그림자 추가
                  Shadow(
                    offset: Offset(1.0, 1.0), // 그림자 오프셋
                    blurRadius: 3.0, // 그림자 흐림 정도
                    color: Color.fromARGB(100, 0, 0, 0), // 그림자 색상 (검정색에 투명도)
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent, // AppBar 배경을 투명하게 설정
            elevation: 0, // AppBar 그림자 제거
            iconTheme: const IconThemeData(color: Colors.white), // 뒤로가기 버튼 색상
            centerTitle: true, // 제목 중앙 정렬
          ),
          body: Center( // Column을 Center로 감싸서 전체 내용을 중앙 정렬
            child: SingleChildScrollView( // 키보드 올라올 때 오버플로우 방지
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0), // 좌우 패딩 유지, 상하 패딩 증가
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // 너비를 최대로
                children: [
                  // TODO: 여기에 이미지 위젯 추가
                  Image.asset(
                    'assets/images/tooth_character.png',
                    height: 150, // 이미지 높이 설정
                    // fit: BoxFit.contain, // 이미지가 컨테이너에 맞춰지도록
                  ),
                  const SizedBox(height: 40), // 이미지와 첫 번째 입력 필드 사이 간격

                  // 이름 입력 필드
                  _buildInputField(
                    context,
                    controller: nameController,
                    labelText: '이름',
                    keyboardType: TextInputType.text,
                    prefixIcon: Icons.person_outline, // 아이콘 추가
                  ),
                  const SizedBox(height: 25), // 간격 조정
                  // 전화번호 입력 필드
                  _buildInputField(
                    context,
                    controller: phoneController,
                    labelText: '전화번호',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined, // 아이콘 추가
                  ),
                  const SizedBox(height: 50), // 버튼 위 간격 증가

                  // 아이디 찾기 버튼
                  if (viewModel.isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white), // 로딩 인디케이터 색상
                    )
                  else
                    _GradientButton(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6a9ce7), // 시작 색상
                          Color(0xFF4a7fd6), // 끝 색상
                        ],
                      ),
                      onPressed: () {
                        viewModel.findId(
                          name: nameController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                        );
                      },
                      child: const Text(
                        '아이디 찾기',
                        style: TextStyle(
                          fontSize: 20, // 버튼 텍스트 크기 증가
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // 텍스트 색상 흰색
                        ),
                      ),
                    ),
                  const SizedBox(height: 30), // 결과/에러 메시지 위 간격

                  // 결과/에러 메시지 (애니메이션 추가)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300), // 애니메이션 지속 시간
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child); // 페이드 애니메이션
                    },
                    child: (viewModel.foundId != null)
                        ? Text(
                            key: const ValueKey('foundId'), // AnimatedSwitcher를 위한 고유 키
                            '아이디: ${viewModel.foundId}',
                            textAlign: TextAlign.center, // 중앙 정렬
                            style: const TextStyle(
                              fontSize: 22, // 폰트 크기 증가
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [ // 텍스트 그림자 추가
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
                                key: const ValueKey('errorMessage'), // AnimatedSwitcher를 위한 고유 키
                                viewModel.errorMessage!,
                                textAlign: TextAlign.center, // 중앙 정렬
                                style: const TextStyle(
                                  color: Color(0xFFFF7070), // 더 눈에 띄는 빨간색 계열
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18, // 폰트 크기 증가
                                ),
                              )
                            : const SizedBox.shrink(), // 메시지가 없으면 아무것도 표시하지 않음
                  ),

                  const SizedBox(height: 60), // 로그인 화면 링크 위 간격 증가
                  // 로그인 화면으로 돌아가기 링크
                  TextButton(
                    onPressed: () => context.go('/login'), // 로그인 화면으로 이동
                    style: TextButton.styleFrom(
                      overlayColor: Colors.white.withOpacity(0.15), // 클릭 시 오버레이 색상
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // 패딩 추가
                    ),
                    child: const Text(
                      '로그인 화면으로 돌아가기',
                      style: TextStyle(
                        color: Color(0xFF3060C0), // 진한 파란색 유지
                        decoration: TextDecoration.underline, // 밑줄
                        decorationColor: Color(0xFF3060C0), // 밑줄 색상도 동일하게
                        fontSize: 18, // 폰트 크기 증가
                        fontWeight: FontWeight.w800, // 더 굵게
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

  // TextField 위젯을 빌드하는 헬퍼 함수
  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon, // prefixIcon 파라미터 추가
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0), // 모서리 더 둥글게
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // 외부 그림자
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5), // 그림자 위치 조정
          ),
          // 내부 그림자 효과 (Flutter에서 직접적인 'inset' shadow는 지원하지 않으므로,
          // 유사한 시각적 효과를 위해 다른 방향의 그림자를 추가하거나,
          // 더 복잡한 효과를 원하면 CustomPainter를 고려해야 합니다.
          // 여기서는 미묘한 강조를 위해 다른 방향의 그림자를 추가합니다.)
          BoxShadow(
            color: Colors.white.withOpacity(0.1), // 밝은 색상의 그림자
            spreadRadius: -2, // 안쪽으로 확산
            blurRadius: 5,
            offset: const Offset(0, -2), // 위쪽으로 오프셋
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 18), // 라벨 폰트 크기
          filled: true,
          fillColor: Colors.white.withOpacity(0.2), // 입력 필드 배경 투명도 조정 (더 투명하게)
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white70) : null, // 아이콘 적용
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0), // 모서리 더 둥글게
            borderSide: BorderSide.none, // 기본 테두리 없음
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5), // 옅은 테두리 두께 조정
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: const BorderSide(color: Colors.white, width: 3.0), // 포커스 시 강조 두께 조정
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0), // 패딩 조정
        ),
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 19), // 입력 텍스트 색상 및 크기
        cursorColor: Colors.white, // 커서 색상
      ),
    );
  }
}