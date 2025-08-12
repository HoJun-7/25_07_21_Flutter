// lib/widgets/chat_bubble.dart
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final Color bubbleColor;
  final Color borderColor;
  final TextStyle? textStyle;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.bubbleColor,
    required this.borderColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle defaultTextStyle = const TextStyle(fontSize: 15, color: Colors.black);

    // 말풍선 본문 위젯을 정의합니다.
    Widget bubbleContent = Text(
      message,
      style: textStyle ?? defaultTextStyle,
    );

    if (isUser) {
      // 사용자 말풍선: CustomPaint를 사용하여 오른쪽 상단에 꼬리 그리기
      bubbleContent = CustomPaint(
        painter: ChatBubblePainter(
          bubbleColor: bubbleColor,
          borderColor: borderColor,
          isUser: true, // 사용자 말풍선임을 알림
        ),
        child: Container(
          // 오른쪽 정렬에 맞춰 왼쪽 마진은 0, 오른쪽 마진은 12.0으로 설정합니다.
          margin: const EdgeInsets.fromLTRB(0, 8.0, 12.0, 0),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
          child: bubbleContent,
        ),
      );
    } else {
      // 덴티봇 말풍선: CustomPaint를 사용하여 왼쪽 상단에 꼬리 그리기
      bubbleContent = CustomPaint(
        painter: ChatBubblePainter(
          bubbleColor: bubbleColor,
          borderColor: borderColor,
          isUser: false, // 챗봇 말풍선임을 알림
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12.0, 8.0, 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
          child: bubbleContent,
        ),
      );
    }

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.4,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: bubbleContent,
          ),
        ),
      ],
    );
  }
}

// 말풍선 꼬리를 그리는 CustomPainter
class ChatBubblePainter extends CustomPainter {
  final Color bubbleColor;
  final Color borderColor;
  final bool isUser; // 사용자/챗봇 말풍선 구별용

  ChatBubblePainter({
    required this.bubbleColor,
    required this.borderColor,
    required this.isUser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double tailWidth = 12;
    const double tailHeight = 10;
    const double borderRadius = 14;
    const double bodyTopY = 8.0;

    final Path path = Path();

    if (isUser) {
      // 사용자 말풍선: 꼬리가 오른쪽 상단에 위치하도록 로직 수정
      path.moveTo(size.width, bodyTopY + tailHeight / 2);
      path.quadraticBezierTo(
        size.width - tailWidth * 0.5, bodyTopY,
        size.width - tailWidth, bodyTopY,
      );

      path.lineTo(borderRadius, bodyTopY);
      path.arcToPoint(Offset(0, bodyTopY + borderRadius),
          radius: const Radius.circular(borderRadius), clockwise: false);

      path.lineTo(0, size.height - borderRadius);
      path.arcToPoint(Offset(borderRadius, size.height),
          radius: const Radius.circular(borderRadius), clockwise: false);

      path.lineTo(size.width - tailWidth - borderRadius, size.height);
      path.arcToPoint(Offset(size.width - tailWidth, size.height - borderRadius),
          radius: const Radius.circular(borderRadius), clockwise: false);

      path.lineTo(size.width - tailWidth, bodyTopY + tailHeight);
      path.quadraticBezierTo(
        size.width - tailWidth * 0.5, bodyTopY + tailHeight * 0.5,
        size.width, bodyTopY + tailHeight / 2,
      );
          
    } else {
      // 챗봇 말풍선: 꼬리가 왼쪽 상단에 위치 (기존 코드와 동일)
      path.moveTo(0, bodyTopY + tailHeight / 2);
      path.quadraticBezierTo(
        tailWidth * 0.5, bodyTopY,
        tailWidth, bodyTopY,
      );

      path.lineTo(size.width - borderRadius, bodyTopY);
      path.arcToPoint(Offset(size.width, bodyTopY + borderRadius),
          radius: const Radius.circular(borderRadius), clockwise: true);

      path.lineTo(size.width, size.height - borderRadius);
      path.arcToPoint(Offset(size.width - borderRadius, size.height),
          radius: const Radius.circular(borderRadius), clockwise: true);

      path.lineTo(tailWidth + borderRadius, size.height);
      path.arcToPoint(Offset(tailWidth, size.height - borderRadius),
          radius: const Radius.circular(borderRadius), clockwise: true);

      path.lineTo(tailWidth, bodyTopY + tailHeight);
      path.quadraticBezierTo(
        tailWidth * 0.5, bodyTopY + tailHeight * 0.5,
        0, bodyTopY + tailHeight / 2,
      );
    }

    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is ChatBubblePainter &&
        (oldDelegate.bubbleColor != bubbleColor ||
            oldDelegate.borderColor != borderColor ||
            oldDelegate.isUser != isUser);
  }
}