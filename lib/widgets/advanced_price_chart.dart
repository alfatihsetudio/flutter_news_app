// lib/widgets/advanced_price_chart.dart
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AdvancedPriceChart extends StatefulWidget {
  const AdvancedPriceChart({
    super.key,
    required this.prices,
    required this.times,
  });

  /// Harga per titik; panjang harus sama dengan [times].
  final List<double> prices;

  /// Timestamp untuk setiap titik harga.
  final List<DateTime> times;

  @override
  State<AdvancedPriceChart> createState() => _AdvancedPriceChartState();
}

class _AdvancedPriceChartState extends State<AdvancedPriceChart> {
  // Viewport X dalam indeks data 0..N-1
  late double _xMin;
  late double _xMax;

  // Lebar kanvas plotting (tanpa padding)
  double _chartWidth = 1.0;

  // Padding area plotting (selaras dengan build)
  static const EdgeInsets _plotPadding =
      EdgeInsets.only(top: 6, right: 8, bottom: 28, left: 8);

  // Cache gesture
  double _lastScale = 1.0;
  Offset? _lastFocal;

  int get _len => widget.prices.length;
  double get _minFullX => 0.0;
  double get _maxFullX => math.max(0, _len - 1).toDouble();

  @override
  void initState() {
    super.initState();
    _fitAll();
  }

  @override
  void didUpdateWidget(covariant AdvancedPriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prices.length != oldWidget.prices.length) {
      _fitAll();
    }
  }

  void _fitAll() {
    _xMin = _minFullX;
    _xMax = _maxFullX;
    if (_xMax <= _xMin) _xMax = _xMin + 1.0;
    setState(() {});
  }

  // ----------------- Y range otomatis untuk viewport terlihat -----------------
  (double minY, double maxY) _visibleYRange() {
    if (_len == 0) return (0.0, 1.0);
    final i0 = _xMin.floor().clamp(0, _len - 1);
    final i1 = _xMax.ceil().clamp(0, _len - 1);
    double minY = double.infinity;
    double maxY = -double.infinity;
    for (int i = i0; i <= i1; i++) {
      final v = widget.prices[i];
      if (v < minY) minY = v;
      if (v > maxY) maxY = v;
    }
    if (minY == maxY) {
      minY -= 1.0;
      maxY += 1.0;
    }
    final pad = (maxY - minY) * 0.06;
    return (minY - pad, maxY + pad);
  }

  // ----------------- Segmentasi warna naik (hijau) / turun (merah) ------------
  List<LineChartBarData> _buildColoredSegments() {
    final bars = <LineChartBarData>[];
    if (_len < 2) return bars;

    List<FlSpot> current = [];
    bool? up;

    for (int i = 0; i < _len; i++) {
      final x = i.toDouble();
      final y = widget.prices[i];
      if (i == 0) {
        current.add(FlSpot(x, y));
        continue;
      }
      final prev = widget.prices[i - 1];
      final isUp = y >= prev;
      if (up != null && isUp != up) {
        bars.add(_segment(current, up!));
        current = [FlSpot((i - 1).toDouble(), prev), FlSpot(x, y)];
      } else {
        current.add(FlSpot(x, y));
      }
      up = isUp;
    }
    if (current.isNotEmpty && up != null) {
      bars.add(_segment(current, up!));
    }
    return bars;
  }

  LineChartBarData _segment(List<FlSpot> spots, bool up) {
    final color = up ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.6,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.14)),
    );
  }

  // ----------------- Interaksi ala Maps ---------------------------------------
  // Konversi global -> rasio X lokal (0..1) di area plot (tanpa padding)
  double _globalToLocalRatioX(Offset global, RenderBox box) {
    final local = box.globalToLocal(global);
    final dx = (local.dx - _plotPadding.left).clamp(0.0, _chartWidth);
    if (_chartWidth <= 0) return 0.5;
    return dx / _chartWidth;
  }

  // Zoom berporos di rasio (0..1) relatif viewport
  void _zoomAround({required double factor, required double anchorRatio}) {
    final oldLen = (_xMax - _xMin).clamp(10.0, _maxFullX - _minFullX + 1.0);
    final newLen = (oldLen / factor).clamp(10.0, (_maxFullX - _minFullX + 1.0));
    final anchorX = _xMin + anchorRatio * oldLen;

    var newMin = anchorX - anchorRatio * newLen;
    var newMax = newMin + newLen;

    if (newMin < _minFullX) {
      newMax += _minFullX - newMin;
      newMin = _minFullX;
    }
    if (newMax > _maxFullX) {
      newMin -= newMax - _maxFullX;
      newMax = _maxFullX;
    }

    setState(() {
      _xMin = newMin;
      _xMax = newMax;
    });
  }

  // Pan horizontal berdasarkan delta piksel
  void _panByPixels(double dxPixels) {
    final len = (_xMax - _xMin);
    if (_chartWidth <= 0 || len <= 0) return;

    final shift = dxPixels / _chartWidth * len;

    var newMin = (_xMin - shift).clamp(_minFullX, _maxFullX);
    var newMax = (_xMax - shift).clamp(_minFullX, _maxFullX);

    // Pertahankan panjang viewport
    if ((newMax - newMin) != len) {
      if (newMin <= _minFullX) {
        newMax = newMin + len;
      } else if (newMax >= _maxFullX) {
        newMin = newMax - len;
      }
    }

    setState(() {
      _xMin = newMin;
      _xMax = newMax;
    });
  }

  // Scroll wheel / trackpad zoom
  void _onPointerSignal(PointerSignalEvent e, RenderBox box) {
    if (e is PointerScrollEvent) {
      final ratio = _globalToLocalRatioX(e.position, box);
      final factor = e.scrollDelta.dy < 0 ? 1.18 : (1 / 1.18);
      _zoomAround(factor: factor, anchorRatio: ratio);
    }
  }

  // Toolbar helpers
  void _zoomInCenter() => _zoomAround(factor: 1.25, anchorRatio: 0.5);
  void _zoomOutCenter() => _zoomAround(factor: 1 / 1.25, anchorRatio: 0.5);

  @override
  Widget build(BuildContext context) {
    if (_len == 0) return const Center(child: Text('No data'));

    final (minY, maxY) = _visibleYRange();
    final spanY = (maxY - minY).abs();
    final yInterval = spanY <= 0 ? 1.0 : (spanY / 4.0);

    final bars = _buildColoredSegments();

    return LayoutBuilder(
      builder: (context, constraints) {
        _chartWidth =
            math.max(1.0, constraints.maxWidth - _plotPadding.horizontal);

        return Builder(
          builder: (ctx) {
            final box = ctx.findRenderObject() as RenderBox?;

            return Listener(
              onPointerSignal: (evt) {
                if (box != null) _onPointerSignal(evt, box);
              },
              child: GestureDetector(
                // Pan & pinch via scale recognizer (tidak pakai onPanUpdate)
                onScaleStart: (details) {
                  _lastScale = 1.0;
                  _lastFocal = details.focalPoint;
                },
                onScaleUpdate: (details) {
                  if (box == null) return;

                  // 1) Pan: geser mengikuti delta focal point
                  final delta = details.focalPoint -
                      (_lastFocal ?? details.focalPoint);
                  if (delta.dx != 0) {
                    _panByPixels(delta.dx);
                  }
                  _lastFocal = details.focalPoint;

                  // 2) Zoom: faktor relatif sejak update terakhir
                  final prev = _lastScale == 0 ? 1.0 : _lastScale;
                  final rel = details.scale == 0 ? 1.0 : (details.scale / prev);
                  if ((rel - 1.0).abs() > 0.01) {
                    final ratio =
                        _globalToLocalRatioX(details.focalPoint, box);
                    _zoomAround(factor: rel, anchorRatio: ratio);
                    _lastScale = details.scale == 0 ? 1.0 : details.scale;
                  }
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        Theme.of(context).colorScheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: _plotPadding,
                        child: LineChart(
                          LineChartData(
                            minX: _xMin,
                            maxX: _xMax,
                            minY: minY,
                            maxY: maxY,
                            clipData: const FlClipData.all(),

                            // Grid halus
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              verticalInterval:
                                  math.max(1.0, (_xMax - _xMin) / 6.0),
                              horizontalInterval: yInterval,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: Colors.white.withValues(alpha: 0.16),
                                strokeWidth: 0.7,
                              ),
                              getDrawingVerticalLine: (_) => FlLine(
                                color: Colors.white.withValues(alpha: 0.12),
                                strokeWidth: 0.7,
                              ),
                            ),

                            // Axis & label
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  interval: yInterval,
                                  getTitlesWidget: (v, _) => Text(
                                    v.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval:
                                      math.max(1.0, (_xMax - _xMin) / 6.0),
                                  getTitlesWidget: (value, _) {
                                    final i = value
                                        .toInt()
                                        .clamp(0, widget.times.length - 1);
                                    final t = widget.times[i];
                                    final label =
                                        '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Tooltip + crosshair
                            lineTouchData: LineTouchData(
                              handleBuiltInTouches: true,
                              getTouchedSpotIndicator: (bar, indexes) =>
                                  indexes.map((_) {
                                return TouchedSpotIndicatorData(
                                  FlLine(
                                    color: Colors.white
                                        .withValues(alpha: 0.25),
                                    strokeWidth: 1.0,
                                    dashArray: [3, 3],
                                  ),
                                  const FlDotData(show: false),
                                );
                              }).toList(),
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor:
                                    Colors.black.withValues(alpha: 0.70),
                                tooltipRoundedRadius: 10.0,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                getTooltipItems: (spots) => spots.map((s) {
                                  final i = s.x
                                      .toInt()
                                      .clamp(0, widget.times.length - 1);
                                  final t = widget.times[i];
                                  final timeStr =
                                      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
                                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                                  return LineTooltipItem(
                                    '${s.y.toStringAsFixed(0)}\n$timeStr',
                                    const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            lineBarsData: bars,
                          ),
                        ),
                      ),

                      // Toolbar
                      Positioned(
                        right: 8,
                        top: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Fit',
                                onPressed: _fitAll,
                                icon: const Icon(Icons.fit_screen),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Zoom out',
                                onPressed: _zoomOutCenter,
                                icon: const Icon(Icons.zoom_out),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Zoom in',
                                onPressed: _zoomInCenter,
                                icon: const Icon(Icons.zoom_in),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
