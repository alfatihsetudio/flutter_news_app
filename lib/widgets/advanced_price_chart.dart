// lib/widgets/advanced_price_chart.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Grafik harga interaktif:
/// - Pinch zoom (horizontal) + drag pan (seperti Maps)
/// - Double-tap untuk reset
/// - Crosshair + tooltip mini saat tap/drag
/// - Grid, label waktu & harga yang rapi
/// - Area gradient + segmen garis hijau/merah sesuai naik/turun
/// - Toolbar mengambang (Reset, Fit, 1D/3D/7D)
///
/// Gunakan: AdvancedPriceChart(prices: [...], times: [...])
class AdvancedPriceChart extends StatefulWidget {
  const AdvancedPriceChart({
    super.key,
    required this.prices,
    required this.times,
    this.minViewportPoints = 30,
    this.maxViewportPoints = 400,
  }) : assert(prices.length == times.length && prices.length > 1);

  final List<double> prices;
  final List<DateTime> times;

  /// Batas zoom: jumlah titik minimum & maksimum dalam viewport
  final int minViewportPoints;
  final int maxViewportPoints;

  @override
  State<AdvancedPriceChart> createState() => _AdvancedPriceChartState();
}

class _AdvancedPriceChartState extends State<AdvancedPriceChart> {
  late int _start; // index pertama yang terlihat
  late int _end;   // index terakhir (inklusif)
  Offset? _cursor; // posisi pointer untuk crosshair
  int? _cursorIndex;

  // Untuk gesture scale
  double _lastScale = 1.0;
  int _lastFocalIndex = 0;

  @override
  void initState() {
    super.initState();
    _fitAll();
  }

  void _fitAll() {
    _start = 0;
    _end = widget.prices.length - 1;
    _cursor = null;
    _cursorIndex = null;
  }

  void _fitRange(int points) {
  final n = widget.prices.length;
  final p = points
      .clamp(widget.minViewportPoints, n)
      .toInt(); // ← penting: cast ke int

  _start = math.max(0, n - p);
  _end = n - 1;
  _cursor = null;
  _cursorIndex = null;
}


  int get _count => _end - _start + 1;

  // Mengubah index visible sesuai pan/zoom
  void _panBy(int deltaPoints) {
  if (deltaPoints == 0) return;
  final n = widget.prices.length;

  final s = (_start + deltaPoints)
      .clamp(0, math.max(0, n - _count))
      .toInt(); // ← cast ke int

  _start = s;
  _end = (_start + _count - 1)
      .clamp(_start, n - 1)
      .toInt(); // ← cast ke int

  setState(() {});
}


  void _zoomAround(int anchorIndex, double scale) {
  if (scale == 1) return;
  final n = widget.prices.length;

  final target = (_count / scale)
      .round()
      .clamp(widget.minViewportPoints, widget.maxViewportPoints)
      .clamp(widget.minViewportPoints, n)
      .toInt(); // ← cast ke int

  if (target == _count) return;

  final ratio = (_count == 0) ? 0.5 : (anchorIndex - _start) / _count;
  var newStart = (anchorIndex - (ratio * target)).round();
  newStart = newStart
      .clamp(0, math.max(0, n - target))
      .toInt(); // ← cast ke int

  _start = newStart;
  _end = (_start + target - 1)
      .clamp(_start, n - 1)
      .toInt(); // ← cast ke int

  setState(() {});
}


  // Hitung min/max Y hanya untuk data visible agar autoscale vertikal
  (double minY, double maxY) _minMaxVisible() {
    var minY = double.infinity, maxY = -double.infinity;
    for (int i = _start; i <= _end; i++) {
      final v = widget.prices[i];
      if (v < minY) minY = v;
      if (v > maxY) maxY = v;
    }
    if (minY == maxY) {
      // hindari div zero
      minY -= 1;
      maxY += 1;
    }
    final pad = (maxY - minY) * 0.08;
    return (minY - pad, maxY + pad);
  }

  // Konversi koordinat
  double _xToIndex(double x, double chartWidth, EdgeInsets pad) {
    final w = math.max(1.0, chartWidth - pad.left - pad.right);
    final t = ((x - pad.left) / w).clamp(0.0, 1.0);
    return _start + t * (_count - 1);
  }

  double _indexToX(int i, double chartWidth, EdgeInsets pad) {
    final w = math.max(1.0, chartWidth - pad.left - pad.right);
    final t = (_count == 1) ? 0.0 : (i - _start) / (_count - 1);
    return pad.left + t * w;
    }

  double _yToCanvas(double y, double h, EdgeInsets pad, double minY, double maxY) {
    final hh = math.max(1.0, h - pad.top - pad.bottom);
    final t = ((y - minY) / (maxY - minY)).clamp(0.0, 1.0);
    return pad.top + (1 - t) * hh;
  }

  @override
  Widget build(BuildContext context) {
    const pad = EdgeInsets.fromLTRB(64, 16, 16, 32); // ruang sumbu kiri & bawah
    final (minY, maxY) = _minMaxVisible();

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Gesture: pakai onScale* agar pan+pinch tidak konflik.
              GestureDetector(
                onDoubleTap: () => setState(_fitAll),
                onScaleStart: (d) {
                  _lastScale = 1.0;
                  _lastFocalIndex =
                      _xToIndex(d.localFocalPoint.dx, w, pad).round();
                },
                onScaleUpdate: (d) {
                  // Zoom
                  final s = d.scale;
                  if ((s - _lastScale).abs() > 0.01) {
                    _zoomAround(_lastFocalIndex, s / _lastScale);
                    _lastScale = s;
                  }

                  // Pan (pakai pergeseran fokus)
                  if (d.pointerCount == 1) {
                    // drag satu jari: geser index berdasarkan deltaX
                    final prevIndex = _xToIndex(
                      d.localFocalPoint.dx - d.focalPointDelta.dx,
                      w,
                      pad,
                    );
                    final nowIndex =
                        _xToIndex(d.localFocalPoint.dx, w, pad);
                    final di = (prevIndex - nowIndex).round();
                    if (di != 0) _panBy(di);
                  }
                },
                onTapDown: (d) {
                  setState(() {
                    _cursor = d.localPosition;
                    _cursorIndex =
                        _xToIndex(d.localPosition.dx, w, pad).round()
                            .clamp(_start, _end);
                  });
                },
                onLongPressMoveUpdate: (d) {
                  setState(() {
                    _cursor = d.localPosition;
                    _cursorIndex =
                        _xToIndex(d.localPosition.dx, w, pad).round()
                            .clamp(_start, _end);
                  });
                },
                onTapUp: (_) => setState(() {
                  // sembunyikan crosshair setelah tap singkat
                  _cursor = null;
                  _cursorIndex = null;
                }),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ChartPainter(
                    prices: widget.prices,
                    times: widget.times,
                    start: _start,
                    end: _end,
                    minY: minY,
                    maxY: maxY,
                    pad: pad,
                    cursorIndex: _cursorIndex,
                    theme: _ChartTheme.of(context),
                  ),
                ),
              ),

              // Toolbar mengambang
              Positioned(
                top: 8,
                right: 8,
                child: _Toolbar(
                  onReset: () => setState(_fitAll),
                  onFit1D: () => setState(() => _fitRange(48)),
                  onFit3D: () => setState(() => _fitRange(48 * 3)),
                  onFit7D: () => setState(() => _fitRange(48 * 7)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ========================= Painter & Theme ========================= */

class _ChartTheme {
  final Color grid = const Color(0x22FFFFFF);
  final Color axis = const Color(0x99FFFFFF);
  final Color up = const Color(0xFF4CAF50);
  final Color upFillA = const Color(0x334CAF50);
  final Color upFillB = const Color(0x114CAF50);
  final Color down = const Color(0xFFE53935);
  final Color downFillA = const Color(0x33E53935);
  final Color downFillB = const Color(0x11E53935);
  final Color bandA = const Color(0x10FFFFFF);
  final Color bandB = const Color(0x04000000);
  final TextStyle label = const TextStyle(
    color: Color(0xCCFFFFFF),
    fontSize: 11,
    height: 1,
  );

  static _ChartTheme of(BuildContext _) => _ChartTheme();
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.prices,
    required this.times,
    required this.start,
    required this.end,
    required this.minY,
    required this.maxY,
    required this.pad,
    required this.theme,
    this.cursorIndex,
  });

  final List<double> prices;
  final List<DateTime> times;
  final int start, end;
  final double minY, maxY;
  final EdgeInsets pad;
  final _ChartTheme theme;

  final int? cursorIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // grid + bands
    _drawBands(canvas, size);
    _drawGrid(canvas, size);

    // garis + area
    _drawSeries(canvas, size);

    // axis labels
    _drawAxes(canvas, size);

    // crosshair + tooltip
    if (cursorIndex != null) {
      _drawCrosshair(canvas, size, cursorIndex!);
    }

    // border
    final border = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(18),
      ),
      border,
    );
  }

  /* ---------- helpers ---------- */

  double _indexToX(int i, Size s) {
    final w = math.max(1.0, s.width - pad.left - pad.right);
    final t = (end == start) ? 0.0 : (i - start) / (end - start);
    return pad.left + t * w;
  }

  double _yToCanvas(double y, Size s) {
    final hh = math.max(1.0, s.height - pad.top - pad.bottom);
    final t = ((y - minY) / (maxY - minY)).clamp(0.0, 1.0);
    return pad.top + (1 - t) * hh;
  }

  void _drawBands(Canvas c, Size s) {
    // pita vertikal selang-seling supaya tidak monoton
    final bandPaintA = Paint()..color = theme.bandA;
    final bandPaintB = Paint()..color = theme.bandB;
    for (int i = start; i <= end; i++) {
      final x0 = _indexToX(i, s);
      final x1 = _indexToX((i + 1).clamp(start, end), s);
      final r = Rect.fromLTWH(x0, pad.top, (x1 - x0), s.height - pad.top - pad.bottom);
      c.drawRect(r, (i.isEven) ? bandPaintA : bandPaintB);
    }
  }

  void _drawGrid(Canvas c, Size s) {
    final p = Paint()
      ..color = theme.grid
      ..strokeWidth = 1;

    // horizontal ticks
    final nH = 4;
    for (int i = 0; i <= nH; i++) {
      final y = pad.top +
          (s.height - pad.top - pad.bottom) * (i / nH);
      c.drawLine(Offset(pad.left, y), Offset(s.width - pad.right, y), p);
    }

    // vertical ticks
    final nV = 6;
    for (int i = 0; i <= nV; i++) {
      final x = pad.left +
          (s.width - pad.left - pad.right) * (i / nV);
      c.drawLine(Offset(x, pad.top), Offset(x, s.height - pad.bottom), p);
    }
  }

  void _drawSeries(Canvas c, Size s) {
    // garis diwarnai naik/turun per segmen + fill dengan gradient
    final upPaint = Paint()
      ..color = theme.up
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final downPaint = Paint()
      ..color = theme.down
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final pathUp = Path();
    final pathDown = Path();
    final fillUp = Path();
    final fillDown = Path();

    // start path
    final firstX = _indexToX(start, s);
    final firstY = _yToCanvas(prices[start], s);
    pathUp.moveTo(firstX, firstY);
    pathDown.moveTo(firstX, firstY);
    fillUp.moveTo(firstX, s.height - pad.bottom);
    fillUp.lineTo(firstX, firstY);
    fillDown.moveTo(firstX, s.height - pad.bottom);
    fillDown.lineTo(firstX, firstY);

    for (int i = start + 1; i <= end; i++) {
      final x = _indexToX(i, s);
      final y = _yToCanvas(prices[i], s);
      final prevY = _yToCanvas(prices[i - 1], s);
      final up = prices[i] >= prices[i - 1];

      if (up) {
        pathUp.lineTo(x, y);
        pathDown.moveTo(x, y);
      } else {
        pathDown.lineTo(x, y);
        pathUp.moveTo(x, y);
      }
      (up ? fillUp : fillDown).lineTo(x, y);
    }

    // tutup fill
    fillUp
      ..lineTo(_indexToX(end, s), s.height - pad.bottom)
      ..close();
    fillDown
      ..lineTo(_indexToX(end, s), s.height - pad.bottom)
      ..close();

    // gambar fill gradient
    final upShader = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [theme.upFillA, theme.upFillB],
      ).createShader(Rect.fromLTWH(
          pad.left, pad.top, s.width - pad.left - pad.right, s.height - pad.top - pad.bottom));
    final downShader = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [theme.downFillA, theme.downFillB],
      ).createShader(Rect.fromLTWH(
          pad.left, pad.top, s.width - pad.left - pad.right, s.height - pad.top - pad.bottom));

    c.drawPath(fillUp, upShader);
    c.drawPath(fillDown, downShader);

    // garis
    c.drawPath(pathUp, upPaint);
    c.drawPath(pathDown, downPaint);
  }

  void _drawAxes(Canvas c, Size s) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    // Y labels (kiri)
    const yTicks = 4;
    for (int i = 0; i <= yTicks; i++) {
      final v = minY + (maxY - minY) * (i / yTicks);
      final y = _yToCanvas(v, s);
      tp.text = TextSpan(text: _fmtPrice(v), style: theme.label);
      tp.layout();
      tp.paint(c, Offset(pad.left - tp.width - 6, y - tp.height / 2));
    }

    // X labels (bawah): 6 label
    const xTicks = 6;
    for (int i = 0; i <= xTicks; i++) {
      final idx = (start + (end - start) * (i / xTicks)).round();
      final x = _indexToX(idx, s);
      final t = times[idx];
      tp.text = TextSpan(text: _fmtTime(t), style: theme.label);
      tp.layout();
      tp.paint(c, Offset(x - tp.width / 2, s.height - pad.bottom + 6));
    }
  }

  void _drawCrosshair(Canvas c, Size s, int idx) {
    final x = _indexToX(idx, s);
    final y = _yToCanvas(prices[idx], s);

    final cross = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1;

    // garis vertikal & horizontal
    c.drawLine(Offset(x, pad.top), Offset(x, s.height - pad.bottom), cross);
    c.drawLine(Offset(pad.left, y), Offset(s.width - pad.right, y), cross);

    // titik
    c.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white);

    // tooltip sederhana
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final text =
        '${_fmtTime(times[idx])}\n${_fmtPrice(prices[idx])}';
    tp.text = TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 11));
    tp.layout();

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (x + 8 + tp.width > s.width - pad.right)
            ? x - 8 - tp.width
            : x + 8,
        (y - 8 - tp.height < pad.top)
            ? y + 8
            : y - 8 - tp.height,
        tp.width + 10,
        tp.height + 8,
      ),
      const Radius.circular(8),
    );

    c.drawRRect(rect, Paint()..color = const Color(0xCC222733));
    tp.paint(c, Offset(rect.left + 5, rect.top + 4));
  }

  String _fmtPrice(double v) {
    if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtTime(DateTime t) {
    // tampilkan “MM/dd HH” (ringkas & universal)
    return '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) {
    return start != old.start ||
        end != old.end ||
        minY != old.minY ||
        maxY != old.maxY ||
        cursorIndex != old.cursorIndex ||
        prices != old.prices;
  }
}

/* ========================= Toolbar kecil ========================= */

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onReset,
    required this.onFit1D,
    required this.onFit3D,
    required this.onFit7D,
  });

  final VoidCallback onReset, onFit1D, onFit3D, onFit7D;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC1E2537),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tbBtn(Icons.center_focus_strong, 'Reset', onReset),
          _tbBtn(Icons.calendar_view_day, '1D', onFit1D),
          _tbBtn(Icons.event, '3D', onFit3D),
          _tbBtn(Icons.date_range, '7D', onFit7D),
        ],
      ),
    );
  }

  Widget _tbBtn(IconData i, String tt, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Tooltip(message: tt, child: Icon(i, color: Colors.white, size: 18)),
      ),
    );
  }
}
