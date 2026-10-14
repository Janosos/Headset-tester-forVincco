import 'package:flutter/material.dart';

/// Componente visual tipo VU meter / barras de audio que reaccionan
/// dinámicamente al nivel del micrófono o de la bocina.
class AudioVisualizerBars extends StatelessWidget {
  final Stream<List<double>> barsStream;
  final Stream<double> levelStream;
  final List<Color> gradientColors;
  final Color activeGlowColor;
  final String label;

  const AudioVisualizerBars({
    super.key,
    required this.barsStream,
    required this.levelStream,
    required this.gradientColors,
    required this.activeGlowColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
              StreamBuilder<double>(
                stream: levelStream,
                initialData: 0.0,
                builder: (context, snapshot) {
                  final level = (snapshot.data ?? 0.0).clamp(0.0, 1.0);
                  final pct = (level * 100).toInt();
                  final isActive = level > 0.03;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? activeGlowColor.withOpacity(0.18)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive
                            ? activeGlowColor.withOpacity(0.5)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isActive ? '$pct% ACTIVO' : 'EN ESPERA',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isActive ? activeGlowColor : const Color(0xFF64748B),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Barras del ecualizador
          SizedBox(
            height: 38,
            child: StreamBuilder<List<double>>(
              stream: barsStream,
              initialData: List.filled(12, 0.06),
              builder: (context, snapshot) {
                final bars = snapshot.data ?? List.filled(12, 0.06);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(bars.length, (index) {
                    final normalizedHeight = (bars[index]).clamp(0.06, 1.0);

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 30),
                          curve: Curves.easeOutQuad,
                          height: 38 * normalizedHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: normalizedHeight > 0.25
                                ? [
                                    BoxShadow(
                                      color: activeGlowColor.withOpacity(
                                        (normalizedHeight * 0.4).clamp(0.1, 0.5),
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, -1),
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
