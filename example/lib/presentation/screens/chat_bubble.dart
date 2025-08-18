// lib/widgets/chat_bubble.dart
import 'package:flutter/material.dart';

// 말풍선 모양과 텍스트를 담고 있는 위젯
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
    // 텍스트에 적용될 기본 스타일을 정의합니다.
    final TextStyle defaultTextStyle = const TextStyle(fontSize: 15, color: Colors.black);

    // 말풍선 본문 위젯 (텍스트)을 정의합니다.
    final Widget bubbleContent = Text(
      message,
      style: textStyle ?? defaultTextStyle,
    );

    // CustomPaint를 사용하여 꼬리 모양을 그리는 말풍선 위젯을 정의합니다.
    final Widget bubbleWithTail = CustomPaint(
      painter: ChatBubblePainter(
        bubbleColor: bubbleColor,
        borderColor: borderColor,
        isUser: isUser,
      ),
      child: Container(
        // 사용자/챗봇에 따라 마진을 다르게 설정하여 위치를 조정합니다.
        margin: EdgeInsets.fromLTRB(
          isUser ? 0 : 12.0,
          8.0,
          isUser ? 12.0 : 0,
          0,
        ),
        // 텍스트와 말풍선 경계선 사이의 패딩을 설정합니다.
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        child: bubbleContent,
      ),
    );

    return Align(
      // 말풍선이 화면의 끝에 정렬되도록 합니다.
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        // 말풍선의 최대 너비를 화면 너비의 75%로 제한하여 오버플로를 방지합니다.
        constraints: BoxConstraints(
          maxWidth:  MediaQuery.of(context).size.width * (isUser ? 0.2 : 0.3),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: bubbleWithTail,
        ),
      ),
    );
  }
}

// 말풍선 꼬리를 그리는 CustomPainter
class ChatBubblePainter extends CustomPainter {
  final Color bubbleColor;
  final Color borderColor;
  final bool isUser;

  ChatBubblePainter({
    required this.bubbleColor,
    required this.borderColor,
    required this.isUser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 말풍선 채우기 색상과 테두리 색상을 정의합니다.
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 꼬리, 모서리, 본문의 크기 및 위치를 정의합니다.
    const double tailWidth = 12;
    const double tailHeight = 10;
    const double borderRadius = 14;
    const double bodyTopY = 8.0;

    final Path path = Path();

    if (isUser) {
      // 사용자 말풍선: 꼬리가 오른쪽 상단에 위치하도록 경로를 그립니다.
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
      // 챗봇 말풍선: 꼬리가 왼쪽 상단에 위치하도록 경로를 그립니다.
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
    // 위젯의 속성이 변경될 때만 다시 그리도록 최적화합니다.
    return oldDelegate is ChatBubblePainter &&
        (oldDelegate.bubbleColor != bubbleColor ||
            oldDelegate.borderColor != borderColor ||
            oldDelegate.isUser != isUser);
  }
} 