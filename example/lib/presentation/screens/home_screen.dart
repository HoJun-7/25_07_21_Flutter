import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
<<<<<<< HEAD
    // 기본 배경 색상 정의: 요청하신 #B4D4FF (부드러운 하늘색)
    const Color primaryBackgroundColor = Color(0xFFB4D4FF);

    return WillPopScope(
      onWillPop: () async {
        // 사용자가 뒤로가기 버튼을 눌렀을 때 앱 종료를 확인하는 대화 상자
=======
    return WillPopScope(
      onWillPop: () async {
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('앱 종료'),
            content: const Text('앱을 종료하시겠습니까?'),
            actions: [
              TextButton(
<<<<<<< HEAD
                onPressed: () => Navigator.of(context).pop(false), // '취소' 버튼: 앱 종료하지 않음
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // '종료' 버튼: 앱 종료
=======
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
                child: const Text('종료'),
              ),
            ],
          ),
        );
<<<<<<< HEAD
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
              // MediTooth 로고 이미지 (앱 바 타이틀 옆)
              Image.asset(
                'assets/images/meditooth_logo.png', // 로고 이미지 경로
                height: 30, // 로고 높이 조정
              ),
              const SizedBox(width: 8), // 로고와 텍스트 사이 간격
              const Text(
                'MediTooth', // 앱 이름
                style: TextStyle(
                  fontWeight: FontWeight.bold, // 폰트 굵게
                  color: Colors.white, // 텍스트 색상 흰색
                  fontSize: 22, // 폰트 크기
                ),
              ),
            ],
          ),
          centerTitle: true, // 제목을 앱 바 중앙에 배치
          backgroundColor: Colors.transparent, // 앱 바 배경색을 투명하게
          elevation: 0, // 앱 바 아래 그림자 제거
          actions: [
            // 마이페이지 이동 버튼
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white, size: 28), // 사람 아이콘, 흰색, 크기 조정
              onPressed: () => context.go('/mypage'), // '/mypage' 경로로 이동
=======
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'MediTooth',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => context.go('/mypage'),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
            ),
          ],
        ),
        body: Container(
<<<<<<< HEAD
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0), // 전체 콘텐츠에 패딩 적용
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
                  crossAxisAlignment: CrossAxisAlignment.stretch, // 가로로 최대한 확장
                  children: [
                    // --- 앱 로고 및 슬로건 섹션 ---
                    Column(
                      children: [
                        // 메인 화면 중앙에 크게 표시되는 로고 이미지
                        Image.asset(
                          'assets/images/meditooth_logo.png', // 로고 이미지 경로
                          height: 120, // 로고 높이 증가
                          color: Colors.white, // 로고 색상 흰색 (배경과 대비되도록)
                        ),
                        const SizedBox(height: 20), // 로고와 슬로건 사이 간격
                        const Text(
                          '건강한 치아, MediTooth와 함께!', // 앱 슬로건
                          textAlign: TextAlign.center, // 텍스트 중앙 정렬
                          style: TextStyle(
                            fontSize: 28, // 폰트 크기 증가
                            fontWeight: FontWeight.bold, // 폰트 굵게
                            color: Colors.white, // 텍스트 색상 흰색
                            shadows: [
                              Shadow(
                                blurRadius: 10.0, // 그림자 흐림 정도 증가
                                color: Colors.black45, // 그림자 색상 (더 진하게)
                                offset: Offset(3.0, 3.0), // 그림자 위치 (오른쪽 아래)
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60), // 슬로건과 기능 그리드 사이 간격 증가
                      ],
                    ),

                    // --- 4개 네모 박스 기능 섹션 (GridView) ---
                    GridView.count(
                      shrinkWrap: true, // GridView가 Column 내에서 콘텐츠 크기에 맞게 줄어들도록 함
                      physics: const NeverScrollableScrollPhysics(), // GridView 자체 스크롤 비활성화 (SingleChildScrollView가 처리)
                      crossAxisCount: 2, // 한 줄에 2개의 아이템 배치
                      crossAxisSpacing: 15, // 가로 간격
                      mainAxisSpacing: 15, // 세로 간격
                      childAspectRatio: 1.0, // 아이템 비율 (정사각형)
                      children: [
                        // AI 진단 카드 (아이콘 사용)
                        _buildIconCardButton(
                          context,
                          label: 'AI 진단',
                          icon: Icons.camera_alt_rounded, // 카메라 아이콘
                          onPressed: () => context.push('/upload'),
                          cardColor: const Color(0xFF6A9EEB), // 부드러운 파란색
                        ),
                        // 실시간 예측하기 카드 (아이콘 사용, 웹에서는 비활성화)
                        Tooltip(
                          message: kIsWeb ? '웹에서는 이용할 수 없습니다.' : '',
                          triggerMode: kIsWeb ? TooltipTriggerMode.longPress : TooltipTriggerMode.manual,
                          child: _buildIconCardButton(
                            context,
                            label: '실시간 예측하기',
                            icon: Icons.videocam_rounded, // 비디오 카메라 아이콘
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
                            textColor: kIsWeb ? Colors.black54 : Colors.white,
                            iconColor: kIsWeb ? Colors.black54 : Colors.white,
                          ),
                        ),
                        // 이전 결과 보기 카드 (아이콘 사용)
                        _buildIconCardButton(
                          context,
                          label: '이전 결과 보기',
                          icon: Icons.history_edu_rounded, // 기록/히스토리 아이콘
                          onPressed: () => context.push('/history'),
                          cardColor: const Color(0xFFFFB380), // 부드러운 오렌지색
                        ),
                        // 주변 치과 찾기 카드 (아이콘 사용)
                        _buildIconCardButton(
                          context,
                          label: '주변 치과 찾기',
                          icon: Icons.location_on_rounded, // 위치 아이콘
                          onPressed: () => context.push('/clinics'),
                          cardColor: const Color(0xFFC2A8FF), // 부드러운 보라색
                        ),
                      ],
                    ),
                    const SizedBox(height: 30), // 그리드뷰 아래 여백
                  ],
                ),
=======
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.8),
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.health_and_safety, size: 80, color: Colors.white),
                      const SizedBox(height: 10),
                      const Text(
                        '건강한 치아, MediTooth와 함께!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 5.0,
                              color: Colors.black26,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                  _buildActionButton(
                    context,
                    label: '사진으로 예측하기',
                    icon: Icons.photo_camera,
                    onPressed: () => context.push('/upload'),
                    buttonColor: Colors.blueAccent,
                  ),
                  const SizedBox(height: 20),
                  Tooltip(
                    message: kIsWeb ? '웹에서는 이용할 수 없습니다.' : '',
                    triggerMode: kIsWeb ? TooltipTriggerMode.longPress : TooltipTriggerMode.manual,
                    child: _buildActionButton(
                      context,
                      label: '실시간 예측하기',
                      icon: Icons.videocam,
                      onPressed: kIsWeb
                          ? null
                          : () => GoRouter.of(context).push(
                                '/diagnosis/realtime',
                                extra: {
                                  'baseUrl': baseUrl,
                                  'userId': userId,
                                },
                              ),
                      buttonColor: kIsWeb ? Colors.grey[400]! : Colors.greenAccent,
                      textColor: kIsWeb ? Colors.black54 : Colors.white,
                      iconColor: kIsWeb ? Colors.black54 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    context,
                    label: '이전결과 보기',
                    icon: Icons.history,
                    onPressed: () => context.push('/history'),
                    buttonColor: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    context,
                    label: '주변 치과',
                    icon: Icons.local_hospital,
                    onPressed: () => context.push('/clinics'),
                    buttonColor: Colors.purpleAccent,
                  ),
                  const SizedBox(height: 20),
                ],
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
              ),
            ),
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  // 아이콘 중심의 카드형 버튼 위젯을 생성하는 헬퍼 함수
  Widget _buildIconCardButton(
    BuildContext context, {
    required String label, // 버튼에 표시될 텍스트
    required IconData icon, // 버튼에 표시될 아이콘
    required VoidCallback? onPressed, // 버튼 클릭 시 실행될 함수
    required Color cardColor, // 카드 배경색
    Color textColor = Colors.white, // 텍스트 색상 (기본값 흰색)
    Color iconColor = Colors.white, // 아이콘 색상 (기본값 흰색)
  }) {
    return Card(
      color: onPressed == null ? Colors.grey[300] : cardColor, // 비활성화 시 회색 배경
      elevation: 8, // 카드 그림자 강도 증가
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25), // 카드 모서리를 더 둥글게
      ),
      child: InkWell( // 터치 피드백을 위한 InkWell 사용
        onTap: onPressed, // 클릭 이벤트 핸들러
        borderRadius: BorderRadius.circular(25), // InkWell의 둥근 모서리 설정
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
            children: [
              Icon(
                icon,
                size: 70, // 아이콘 크기
                color: iconColor, // 아이콘 색상
              ),
              const SizedBox(height: 10), // 아이콘과 텍스트 사이 간격
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, // 폰트 크기
                  fontWeight: FontWeight.bold, // 폰트 굵게
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
=======
  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color buttonColor,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28, color: iconColor),
      label: Text(
        label,
        style: TextStyle(fontSize: 20, color: textColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 8,
        shadowColor: buttonColor.withOpacity(0.5),
      ),
    );
  }
}
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
