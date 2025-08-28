import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/national_weather_service.dart';

/// 닥터 리얼 홈 TopBar 우측 "날씨 카드" 자리에 넣는 위젯
class NationalWeatherMiniCard extends StatelessWidget {
  final double height;
  final double width;
  const NationalWeatherMiniCard({super.key, this.height = 80, this.width = 200});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<NationalWeatherService?>();
    if (svc == null) {
      // Provider 미설정 시에도 UI가 무너지지 않도록 더미 출력
      return _frame(
        child: const Center(
          child: Text('—℃', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final city = svc.currentCity;
    final cw = svc.currentCityWeather;

    return _frame(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.cloud, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 13),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        city.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('·', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 6),
                    ValueListenableBuilder<DateTime>(
                      valueListenable: svc.now,
                      builder: (_, now, __) {
                        String two(int v) => v.toString().padLeft(2, '0');
                        final ts =
                            '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
                        return Text(
                          ts,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    cw == null
                        ? '—'
                        : NationalWeatherService.wmoToKo(cw.weatherCode),
                    key: ValueKey(
                      '${city.name}_${cw?.fetchedAt.millisecondsSinceEpoch ?? 0}_desc',
                    ),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              cw == null ? '—℃' : '${cw.tempC.toStringAsFixed(0)}℃',
              key: ValueKey(
                '${city.name}_${cw?.fetchedAt.millisecondsSinceEpoch ?? 0}_temp',
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _frame({required Widget child}) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient:
              const LinearGradient(colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: child,
      ),
    );
  }
}

/// (호환용) 예전에 main.dart에서 호출하던 오버레이 이름을 그대로 유지하기 위한 더미.
/// 이제는 DRealHome 내부 카드로만 사용하므로, 화면에는 아무것도 그리지 않음.
/// ─ main.dart 에서 NationalWeatherTickerHUD(...) 호출이 남아 있어도 컴파일/런타임 에러 방지.
class NationalWeatherTickerHUD extends StatelessWidget {
  final EdgeInsets contentInsets;
  final bool desktopOnly;

  const NationalWeatherTickerHUD({
    super.key,
    this.contentInsets = EdgeInsets.zero,
    this.desktopOnly = true,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}