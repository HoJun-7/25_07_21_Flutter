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
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('앱 종료'),
            content: const Text('앱을 종료하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('종료'),
              ),
            ],
          ),
        );
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
            ),
          ],
        ),
        body: Container(
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
              ),
            ),
          ),
        ),
      ),
    );
  }

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
