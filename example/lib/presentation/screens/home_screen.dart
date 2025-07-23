import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // kIsWeb import 추가

class HomeScreen extends StatelessWidget {
  final String baseUrl;
  final String userId;

  const HomeScreen({
    super.key,
    required this.baseUrl,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // 기본 배경 색상 정의: 요청하신 #B4D4FF (부드러운 하늘색)
    const Color primaryBackgroundColor = Color(0xFFB4D4FF);

    return WillPopScope(
      onWillPop: () async {
        // 사용자가 뒤로가기 버튼을 눌렀을 때 앱 종료를 확인하는 대화 상자
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('앱 종료'),
            content: const Text('앱을 종료하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // '취소' 버튼: 앱 종료하지 않음
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // '종료' 버튼: 앱 종료
                child: const Text('종료'),
              ),
            ],
          ),
        );
        return shouldExit ?? false; // 대화 상자가 닫히지 않았을 경우 (null) false 반환
      },
      child: Scaffold(
        // 배경 그라데이션이 앱바 뒤까지 확장되도록 설정
        extendBodyBehindAppBar: true,
        // 앱 상단 바 (AppBar) 디자인
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min, // Row의 크기를 자식 위젯에 맞게 최소화
            children: [
              // 앱 바에 아이콘을 사용하고 싶다면 여기에 추가
              const Text(
                'MediTooth', // 앱 이름
                style: TextStyle(
                  fontWeight: FontWeight.bold, // 폰트 굵게
                  color: Colors.white, // 텍스트 색상 흰색
                  fontSize: 20, // ✅ 폰트 크기 약간 줄임
                ),
              ),
            ],
          ),
          centerTitle: true, // 제목을 앱 바 중앙에 배치
          backgroundColor: Colors.transparent, // 앱 바 배경색을 투명하게
          elevation: 0, // 앱 바 아래 그림자 제거
          actions: [
            // 마이페이지 이동 버튼을 알림 아이콘으로 변경
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white, size: 26), // ✅ 알림 아이콘 크기 약간 줄임
              onPressed: () {
                // TODO: 알림 화면으로 이동 또는 알림 목록 표시 기능 구현
                context.go('/mypage'); // 현재는 마이페이지로 이동 유지 (경로 변경 필요 시 수정)
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            // 메인 화면 배경 그라데이션
            gradient: LinearGradient(
              begin: Alignment.topCenter, // 상단 중앙에서 시작
              end: Alignment.bottomCenter, // 하단 중앙으로 끝남
              colors: [
                primaryBackgroundColor, // 상단은 기본 배경색
                Color(0xFFE0F2F7), // 하단은 더 밝은 파스텔톤 색상으로 부드럽게 연결
              ],
            ),
          ),
          child: SafeArea( // 상태 바 및 노치 영역을 고려하여 콘텐츠 배치
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0), // ✅ 전체 콘텐츠 수직 패딩 더 줄임
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
                  crossAxisAlignment: CrossAxisAlignment.stretch, // 가로로 최대한 확장
                  children: [
                    // --- 앱 로고 및 슬로건 섹션 (로고는 아이콘으로 대체) ---
                    Column(
                      children: [
                        // 메인 화면 중앙에 크게 표시되는 아이콘 (로고 이미지 대체)
                        const Icon(
                          Icons.medical_services, // 의료 관련 상징 아이콘
                          size: 40, // ✅ 아이콘 크기 더 줄임
                          color: Colors.white, // 아이콘 색상 흰색
                          shadows: [
                            Shadow(
                              blurRadius: 8.0,
                              color: Colors.black45,
                              offset: Offset(3.0, 3.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3), // 아이콘과 슬로건 사이 간격 유지
                        const Text(
                          '건강한 치아, MediTooth와 함께!', // 앱 슬로건
                          textAlign: TextAlign.center, // 텍스트 중앙 정렬
                          style: TextStyle(
                            fontSize: 16, // ✅ 폰트 크기 더 줄임
                            fontWeight: FontWeight.bold, // 폰트 굵게
                            color: Colors.white, // 텍스트 색상 흰색
                            shadows: [
                              Shadow(
                                blurRadius: 8.0, // 그림자 흐림 정도 증가
                                color: Colors.black45, // 그림자 색상 (더 진하게)
                                offset: Offset(3.0, 3.0), // 그림자 위치 (오른쪽 아래)
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10), // ✅ 슬로건과 기능 그리드 사이 간격 더 줄임
                      ],
                    ),

                    // --- 4개 네모 박스 기능 섹션 (GridView) ---
                    GridView.count(
                      shrinkWrap: true, // GridView가 Column 내에서 콘텐츠 크기에 맞게 줄어들도록 함
                      physics: const NeverScrollableScrollPhysics(), // GridView 자체 스크롤 비활성화 (SingleChildScrollView가 처리)
                      crossAxisCount: 2, // 한 줄에 2개의 아이템 배치
                      crossAxisSpacing: 8, // 가로 간격 8로 유지
                      mainAxisSpacing: 8, // 세로 간격 8로 유지
                      childAspectRatio: 0.7, // ✅ 아이템 비율을 0.7로 조정 (상자 높이를 더 줄여 절반에 가깝게)
                      children: [
                        // AI 진단 카드
                        _buildGridButton(
                          context,
                          label: 'AI 진단',
                          icon: Icons.lightbulb_outline, // AI 관련 아이콘
                          onPressed: () => context.push('/upload'),
                          cardColor: const Color(0xFF6A9EEB), // 부드러운 파란색
                        ),
                        // 실시간 예측하기 카드
                        Tooltip(
                          message: kIsWeb ? '웹에서는 이용할 수 없습니다.' : '',
                          triggerMode: kIsWeb ? TooltipTriggerMode.longPress : TooltipTriggerMode.manual,
                          child: _buildGridButton(
                            context,
                            label: '실시간 예측', // 텍스트 간결하게 변경
                            icon: Icons.videocam_outlined, // 카메라/비디오 관련 아이콘
                            onPressed: kIsWeb
                                ? null
                                : () => GoRouter.of(context).push(
                                      '/diagnosis/realtime',
                                      extra: {
                                        'baseUrl': baseUrl,
                                        'userId': userId,
                                      },
                                    ),
                            cardColor: kIsWeb ? const Color(0xFFD0D0D0) : const Color(0xFF82C8A0), // 웹일 경우 회색, 아니면 부드러운 녹색
                            iconColor: kIsWeb ? Colors.black54 : Colors.white,
                            textColor: kIsWeb ? Colors.black54 : Colors.white,
                          ),
                        ),
                        // 이전 결과 보기 카드
                        _buildGridButton(
                          context,
                          label: '이전 결과', // 텍스트 간결하게 변경
                          icon: Icons.history, // 기록/히스토리 관련 아이콘
                          onPressed: () => context.push('/history'),
                          cardColor: const Color(0xFFFFB380), // 부드러운 오렌지색
                        ),
                        // 주변 치과 찾기 카드
                        _buildGridButton(
                          context,
                          label: '치과 찾기', // 텍스트 간결하게 변경
                          icon: Icons.local_hospital_outlined, // 병원/치과 관련 아이콘
                          onPressed: () => context.push('/clinics'),
                          cardColor: const Color(0xFFC2A8FF), // 부드러운 보라색
                        ),
                      ],
                    ),
                    const SizedBox(height: 0), // ✅ 그리드뷰 아래 여백 최소화
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 아이콘 중심의 카드형 버튼 위젯을 생성하는 헬퍼 함수 (그리드용)
  Widget _buildGridButton(
    BuildContext context, {
    required String label, // 버튼에 표시될 텍스트
    required IconData icon, // 버튼에 표시될 아이콘 데이터
    required VoidCallback? onPressed, // 버튼 클릭 시 실행될 함수
    required Color cardColor, // 카드 배경색
    Color iconColor = Colors.white, // 아이콘 색상 (기본값 흰색)
    Color textColor = Colors.white, // 텍스트 색상 (기본값 흰색)
  }) {
    return Card(
      color: onPressed == null ? Colors.grey[300] : cardColor, // 비활성화 시 회색 배경
      elevation: 3, // 카드 그림자 강도 유지
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // 카드 모서리 유지
      ),
      child: InkWell( // 터치 피드백을 위한 InkWell 사용
        onTap: onPressed, // 클릭 이벤트 핸들러
        borderRadius: BorderRadius.circular(15), // InkWell의 둥근 모서리 설정
        child: Padding(
          padding: const EdgeInsets.all(4.0), // ✅ 내부 패딩을 4.0으로 조정
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
            children: [
              Icon(
                icon,
                size: 35, // ✅ 아이콘 크기를 35로 조정
                color: iconColor, // 아이콘 색상
              ),
              const SizedBox(height: 3), // 아이콘과 텍스트 사이 간격 유지
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, // ✅ 폰트 크기를 14로 조정
                  fontWeight: FontWeight.w500, // 폰트 굵기를 w500으로 유지
                  color: textColor, // 텍스트 색상
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
