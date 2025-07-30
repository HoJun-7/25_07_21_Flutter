// lib/widgets/chat_bubble.dart
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final Color bubbleColor;
  final Color borderColor;
  final TextStyle? textStyle; // 텍스트 스타일 파라미터 추가

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.bubbleColor,
    required this.borderColor,
    this.textStyle, // 생성자에도 textStyle 파라미터 추가
  });

  @override
  Widget build(BuildContext context) {
    // 기본 TextStyle 설정 (textStyle이 제공되지 않을 경우 사용)
    final TextStyle defaultTextStyle = const TextStyle(fontSize: 15, color: Colors.black);

    if (isUser) {
      // 사용자 말풍선: 오른쪽 하단에 꼬리가 있는 둥근 사각형
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14.0),
            bottomLeft: Radius.circular(14.0),
            topRight: Radius.circular(14.0),
            bottomRight: Radius.circular(2.0), // 사용자 말풍선 꼬리 (오른쪽 아래)
          ),
          border: Border.all(color: borderColor, width: 1.0), // 테두리 유지
        ),
        child: Text(
          message,
          style: textStyle ?? defaultTextStyle, // 제공된 textStyle 또는 기본 스타일 적용
        ),
      );
    } else {
      // 덴티봇 말풍선: CustomPaint를 사용하여 왼쪽 상단에 꼬리 그리기
      return CustomPaint(
        painter: ChatBubblePainter(
            bubbleColor: bubbleColor, borderColor: borderColor), // 색상과 테두리 색상 전달
        child: Container(
          // CustomPaint가 꼬리까지 포함한 전체 영역을 그리므로,
          // 텍스트 컨테이너는 꼬리 영역을 피해서 마진을 줘야 합니다.
          // ChatBubblePainter의 tailWidth (12)와 tailOffsetY (8)를 고려하여 마진 설정
          margin: const EdgeInsets.fromLTRB(12.0, 8.0, 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
          // maxWidth는 Flexible 위젯이 처리하므로 여기서는 제거합니다.
          child: Text(
            message,
            style: textStyle ?? defaultTextStyle, // 제공된 textStyle 또는 기본 스타일 적용
          ),
        ),
      );
    }
  }
}

// 덴티봇 말풍선 꼬리를 그리는 CustomPainter
class ChatBubblePainter extends CustomPainter {
  final Color bubbleColor;
  final Color borderColor;

  ChatBubblePainter({required this.bubbleColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill; // 말풍선 내부를 채울 페인트

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke // 테두리를 그릴 페인트
      ..strokeWidth = 1.0;

    // 꼬리와 말풍선 본체의 크기 및 모서리 둥근 정도 정의
    const double tailWidth = 12; // 꼬리 밑변의 너비
    const double tailHeight = 10; // 꼬리의 높이
    const double borderRadius = 14; // 말풍선 모서리의 둥근 정도

    // 말풍선 본체의 상단 시작 Y 좌표 (꼬리 끝보다 약간 아래에 위치)
    const double bodyTopY = 8.0;

    final Path path = Path();

    // 1. 꼬리 끝점 (가장 왼쪽 상단)에서 시작
    // 꼬리 끝점의 Y 좌표는 bodyTopY를 기준으로 tailHeight의 절반만큼 아래
    path.moveTo(0, bodyTopY + tailHeight / 2);

    // 2. 꼬리 끝점에서 말풍선 본체 상단 왼쪽 모서리로 이동 (부드러운 곡선)
    // 제어점을 사용하여 꼬리의 곡선을 자연스럽게 만듭니다.
    path.quadraticBezierTo(
      tailWidth * 0.5, bodyTopY, // 제어점 (꼬리 너비의 절반, 본체 상단 Y)
      tailWidth, bodyTopY, // 말풍선 본체의 상단 왼쪽 시작점 (x: 꼬리 너비, y: bodyTopY)
    );

    // 말풍선 본체 그리기 시작

    // 3. 상단 라인 (오른쪽으로)
    path.lineTo(size.width - borderRadius, bodyTopY);
    // 4. 상단 오른쪽 둥근 모서리
    path.arcToPoint(Offset(size.width, bodyTopY + borderRadius),
        radius: const Radius.circular(borderRadius), clockwise: true);

    // 5. 오른쪽 라인 (아래로)
    path.lineTo(size.width, size.height - borderRadius);
    // 6. 하단 오른쪽 둥근 모서리
    path.arcToPoint(Offset(size.width - borderRadius, size.height),
        radius: const Radius.circular(borderRadius), clockwise: true);

    // 7. 하단 라인 (왼쪽으로)
    path.lineTo(tailWidth + borderRadius, size.height);
    // 8. 하단 왼쪽 둥근 모서리
    path.arcToPoint(Offset(tailWidth, size.height - borderRadius),
        radius: const Radius.circular(borderRadius), clockwise: true);

    // 9. 왼쪽 라인 (위로, 꼬리가 본체에 다시 만나는 지점)
    // 꼬리가 말풍선 본체 왼쪽에서 끝나는 지점
    path.lineTo(tailWidth, bodyTopY + tailHeight);

    // 10. 꼬리 삼각형 완성 (꼬리 끝점으로 돌아가기, 부드러운 곡선)
    // 제어점을 사용하여 꼬리의 나머지 곡선을 자연스럽게 만듭니다.
    path.quadraticBezierTo(
      tailWidth * 0.5, bodyTopY + tailHeight * 0.5, // 제어점
      0, bodyTopY + tailHeight / 2, // 꼬리 끝점으로 돌아감 (moveTo와 동일한 좌표)
    );

    path.close(); // 경로 닫기

    canvas.drawPath(path, paint); // 말풍선 내부 채우기
    canvas.drawPath(path, borderPaint); // 말풍선 테두리 그리기
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // 이전 delegate와 현재 delegate의 색상 및 테두리 색상이 다르면 다시 그립니다.
    return oldDelegate is ChatBubblePainter &&
        (oldDelegate.bubbleColor != bubbleColor ||
            oldDelegate.borderColor != borderColor);
  }
}