// lib/presentation/widgets/national_weather_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/national_weather_service.dart';

/// 대시보드(닥터 리얼 홈) 안 '날씨 칸'에 넣어 쓰는 카드 위젯
class NationalWeatherCard extends StatelessWidget {
  /// 카드 고정 높이 (대시보드 타일 높이에 맞춰 조절)
  final double height;
  /// 카드 외부 패딩(부모 그리드에 이미 패딩 있으면 EdgeInsets.zero 권장)
  final EdgeInsets margin;

  const NationalWeatherCard({
    super.key,
    this.height = 72,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<NationalWeatherService?>();
    if (svc == null) {
      return SizedBox(height: height); // Provider 없으면 빈 칸
    }

    final c = svc.currentCity;
    final cw = svc.currentCityWeather;

    // 카드 전체 텍스트에 밑줄/장식 강제 차단
    final baseText = const TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
      height: 1.1,
    );

    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F8DDA), Color(0xFF2E67A8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(blurRadius: 8, offset: Offset(0, 3), color: Colors.black26)
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: DefaultTextStyle.merge(
        style: baseText,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 날씨 아이콘: WMO 코드에 따라 변경
            Icon(_iconForWmo(cw?.weatherCode), color: Colors.white, size: 22),
            const SizedBox(width: 10),

            // ── 왼쪽: 시간(윗줄) / 위치(둘째줄) / 상태(아주 작게) ───
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1줄: 실시간 시계
                  ValueListenableBuilder<DateTime>(
                    valueListenable: svc.now,
                    builder: (_, now, __) {
                      String two(int v) => v.toString().padLeft(2, '0');
                      final ts =
                          '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          ts,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),

                  // 2줄: 위치
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 3줄: 상태(아주 작게, 공간 없으면 말줄임)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      cw == null
                          ? '—'
                          : NationalWeatherService.wmoToKo(cw.weatherCode),
                      key: ValueKey(
                          '${c.name}_${cw?.fetchedAt.millisecondsSinceEpoch ?? 0}_desc'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── 오른쪽: 온도 (살짝 축소 + FittedBox로 오버플로우 방지)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    cw == null ? '—℃' : '${cw.tempC.toStringAsFixed(0)}℃',
                    key: ValueKey(
                        '${c.name}_${cw?.fetchedAt.millisecondsSinceEpoch ?? 0}_temp'),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 24, // 28 → 24 로 살짝 축소
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// WMO 코드 → 머티리얼 아이콘 매핑
IconData _iconForWmo(int? code) {
  if (code == null) return Icons.cloud;
  switch (code) {
    case 0: // 맑음
      return Icons.wb_sunny;
    case 1: // 대체로 맑음
    case 2:
      return Icons.wb_sunny_outlined;
    case 3: // 흐림
      return Icons.wb_cloudy;
    case 45: // 안개
    case 48:
      return Icons.air;
    case 51: // 이슬비
    case 53:
    case 55:
      return Icons.grain;
    case 61: // 비/소나기 계열
    case 63:
    case 65:
    case 80:
    case 81:
    case 82:
      return Icons.water_drop;
    case 66: // 어는 비
    case 67:
      return Icons.ac_unit;
    case 71: // 눈/소낙눈
    case 73:
    case 75:
    case 85:
    case 86:
      return Icons.ac_unit;
    case 95: // 뇌우
    case 96:
    case 99:
      return Icons.thunderstorm;
    default:
      return Icons.cloud;
  }
}