// lib/widgets/chat_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // ✅ Markdown 지원
import 'package:flutter/foundation.dart' show kIsWeb;    // ✅ 웹 분기
import 'dart:math' as math;

/// 말풍선 위젯 (기본: Text, 옵션: Markdown)
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final Color bubbleColor;
  final Color borderColor;
  final TextStyle? textStyle;

  /// ✅ 마크다운 렌더링 여부 (기본 false → 기존 동작 유지)
  final bool renderMarkdown;

  /// ✅ 마크다운 스타일 커스터마이즈(선택)
  final MarkdownStyleSheet? markdownStyle;

  /// ✅ 마크다운 링크 탭 핸들러(선택)
  final void Function(String text, String? href, String? title)? onTapLink;

  /// ✅ 마크다운 선택 가능 여부(복사/드래그)
  final bool selectableMarkdown;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.bubbleColor,
    required this.borderColor,
    this.textStyle,
    this.renderMarkdown = false,
    this.markdownStyle,
    this.onTapLink,
    this.selectableMarkdown = true,
  });

  @override
  Widget build(BuildContext context) {
    // 기본 텍스트 스타일(라인 높이 포함)
    final TextStyle baseStyle =
        (textStyle ?? const TextStyle(fontSize: 15, color: Colors.black))
            .copyWith(height: 1.5);

    // 1) 본문: Markdown or Text (기존 레이아웃 유지)
    final Widget bubbleContent = renderMarkdown
        ? MarkdownBody(
            data: message,
            selectable: selectableMarkdown,
            onTapLink: onTapLink,
            styleSheet: (markdownStyle ??
                    MarkdownStyleSheet.fromTheme(Theme.of(context)))
                .copyWith(
              p: baseStyle,
              strong: baseStyle.copyWith(fontWeight: FontWeight.bold),
              h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              listBullet: baseStyle,
              blockquote:
                  const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          )
        : Text(
            message,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: baseStyle,
          );

    // 2) 꼬리 달린 말풍선
    final Widget bubbleWithTail = CustomPaint(
      painter: ChatBubblePainter(
        bubbleColor: bubbleColor,
        borderColor: borderColor,
        isUser: isUser,
      ),
      child: Container(
        margin: EdgeInsets.fromLTRB(
          isUser ? 0 : 12.0,
          8.0,
          isUser ? 12.0 : 0,
          0,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        child: bubbleContent,
      ),
    );

    // 3) 정렬 + (웹에서만) 반응형 가로 폭 제한
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: kIsWeb
          ? LayoutBuilder(
              builder: (context, constraints) {
                final double colWidth = constraints.maxWidth; // 채팅 컬럼 가용폭

                // 화면군별 상한(px) — 네가 올린 로직 유지
                double capPx;
                if (colWidth >= 1200) {
                  capPx = 420; // 큰 데스크톱
                } else if (colWidth >= 900) {
                  capPx = 380; // 데스크톱/대형 태블릿
                } else if (colWidth >= 600) {
                  capPx = 340; // 태블릿
                } else {
                  capPx = double.infinity; // 모바일(웹 좁은 폭)에서는 비율만 적용
                }

                // 비율 기반 목표 폭 (웹에서만 적용)
                final double wanted = colWidth * 0.43;
                final double maxBubbleWidth = math.min(wanted, capPx);

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: SizedBox.shrink(), // placeholder, 아래 Builder에서 대체
                  ),
                )._replaceChild(
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: bubbleWithTail,
                  ),
                );
              },
            )
          : Padding(
              // ✅ 앱(모바일/데스크톱): 별도 최대폭 제한 없음
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: bubbleWithTail,
            ),
    );
  }
}

/// ConstrainedBox child 교체용 확장 (가독성 보조)
extension _ChildReplace on ConstrainedBox {
  ConstrainedBox _replaceChild(Widget child) => ConstrainedBox(
        constraints: constraints,
        child: child,
      );
}

/// 말풍선 꼬리를 그리는 페인터 (원본 그대로)
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
      // 사용자: 꼬리 오른쪽
      path.moveTo(size.width, bodyTopY + tailHeight / 2);
      path.quadraticBezierTo(
        size.width - tailWidth * 0.5,
        bodyTopY,
        size.width - tailWidth,
        bodyTopY,
      );

      path.lineTo(borderRadius, bodyTopY);
      path.arcToPoint(
        Offset(0, bodyTopY + borderRadius),
        radius: const Radius.circular(borderRadius),
        clockwise: false,
      );

      path.lineTo(0, size.height - borderRadius);
      path.arcToPoint(
        Offset(borderRadius, size.height),
        radius: const Radius.circular(borderRadius),
        clockwise: false,
      );

      path.lineTo(size.width - tailWidth - borderRadius, size.height);
      path.arcToPoint(
        Offset(size.width - tailWidth, size.height - borderRadius),
        radius: const Radius.circular(borderRadius),
        clockwise: false,
      );

      path.lineTo(size.width - tailWidth, bodyTopY + tailHeight);
      path.quadraticBezierTo(
        size.width - tailWidth * 0.5,
        bodyTopY + tailHeight * 0.5,
        size.width,
        bodyTopY + tailHeight / 2,
      );
    } else {
      // 챗봇: 꼬리 왼쪽
      path.moveTo(0, bodyTopY + tailHeight / 2);
      path.quadraticBezierTo(
        tailWidth * 0.5,
        bodyTopY,
        tailWidth,
        bodyTopY,
      );

      path.lineTo(size.width - borderRadius, bodyTopY);
      path.arcToPoint(
        Offset(size.width, bodyTopY + borderRadius),
        radius: const Radius.circular(borderRadius),
        clockwise: true,
      );

      path.lineTo(size.width, size.height - borderRadius);
      path.arcToPoint(
        Offset(size.width - borderRadius, size.height),
        radius: const Radius.circular(borderRadius),
        clockwise: true,
      );

      path.lineTo(tailWidth + borderRadius, size.height);
      path.arcToPoint(
        Offset(tailWidth, size.height - borderRadius),
        radius: const Radius.circular(borderRadius),
        clockwise: true,
      );

      path.lineTo(tailWidth, bodyTopY + tailHeight);
      path.quadraticBezierTo(
        tailWidth * 0.5,
        bodyTopY + tailHeight * 0.5,
        0,
        bodyTopY + tailHeight / 2,
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