import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScreenGame extends StatefulWidget {
  const ScreenGame({super.key});

  @override
  State<ScreenGame> createState() => _ScreenGameState();
}

enum _Dir { up, down, left, right }

class _ScreenGameState extends State<ScreenGame> {
  // ====== Konfigurasi papan ======
  static const int _rows = 22;
  static const int _cols = 22;
  static const double _cellGap = 3.0; // jarak antar sel
  static const Duration _tickStart = Duration(milliseconds: 180); // awal game
  static const Duration _tickMin = Duration(milliseconds: 70);    // batas cepat

  // ====== State game ======
  final Random _rng = Random();
  Timer? _timer;
  List<Point<int>> _snake = [];
  Set<Point<int>> _snakeSet = {};
  late Point<int> _food;
  _Dir _dir = _Dir.right;
  _Dir _pendingDir = _Dir.right; // supaya input tidak langsung reverse
  bool _running = false;
  int _score = 0;
  int _highScore = 0;
  Duration _tick = _tickStart;

  // untuk gesture swipe
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _resetBoard();
  }

  Future<void> _loadHighScore() async {
    try {
      final sp = await SharedPreferences.getInstance();
      setState(() {
        _highScore = sp.getInt('snake_highscore') ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _saveHighScore() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('snake_highscore', _highScore);
    } catch (_) {}
  }

  void _resetBoard() {
    _timer?.cancel();
    // posisi awal: cacing 4 segmen di tengah agak kiri
    final cx = (_cols / 2).floor();
    final cy = (_rows / 2).floor();
    _snake = [
      Point(cx - 2, cy),
      Point(cx - 1, cy),
      Point(cx, cy),
      Point(cx + 1, cy),
    ];
    _snakeSet = _snake.toSet();
    _dir = _Dir.right;
    _pendingDir = _Dir.right;
    _score = 0;
    _tick = _tickStart;
    _spawnFood();
    setState(() {});
  }

  void _start() {
    if (_running) return;
    setState(() {
      _running = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _step());
  }

  void _pause() {
    if (!_running) return;
    setState(() {
      _running = false;
    });
    _timer?.cancel();
  }

  void _restart() {
    _pause();
    _resetBoard();
    _start();
  }

  void _faster() {
    // percepat sedikit
    final next = _tick - const Duration(milliseconds: 10);
    _tick = next > _tickMin ? next : _tickMin;
    if (_running) {
      _timer?.cancel();
      _timer = Timer.periodic(_tick, (_) => _step());
    }
  }

  void _spawnFood() {
    while (true) {
      final p = Point(_rng.nextInt(_cols), _rng.nextInt(_rows));
      if (!_snakeSet.contains(p)) {
        _food = p;
        break;
      }
    }
  }

  bool _isOpposite(_Dir a, _Dir b) {
    return (a == _Dir.up && b == _Dir.down) ||
        (a == _Dir.down && b == _Dir.up) ||
        (a == _Dir.left && b == _Dir.right) ||
        (a == _Dir.right && b == _Dir.left);
  }

  void _queueDirection(_Dir d) {
    // Hindari reverse langsung (nabrak diri sendiri)
    if (_isOpposite(_dir, d)) return;
    _pendingDir = d;
  }

  void _step() {
    // apply input terbaru
    _dir = _pendingDir;

    final head = _snake.last;
    Point<int> next;
    switch (_dir) {
      case _Dir.up:
        next = Point(head.x, (head.y - 1 + _rows) % _rows); // wrap tembok
        break;
      case _Dir.down:
        next = Point(head.x, (head.y + 1) % _rows);
        break;
      case _Dir.left:
        next = Point((head.x - 1 + _cols) % _cols, head.y);
        break;
      case _Dir.right:
        next = Point((head.x + 1) % _cols, head.y);
        break;
    }

    // tabrak diri sendiri?
    final willBiteTail = _snakeSet.contains(next) && next != _snake.first;
    if (willBiteTail) {
      _gameOver();
      return;
    }

    // gerak
    _snake.add(next);
    _snakeSet.add(next);

    // makan?
    if (next == _food) {
      _score += 1;
      if (_score > _highScore) {
        _highScore = _score;
        _saveHighScore();
      }
      _spawnFood();
      if (_score % 3 == 0) _faster(); // percepat tiap 3 poin
      HapticFeedback.selectionClick();
    } else {
      // buang ekor (jalan normal)
      final tail = _snake.removeAt(0);
      _snakeSet.remove(tail);
    }

    if (mounted) setState(() {});
  }

  Future<void> _gameOver() async {
    _pause();
    HapticFeedback.vibrate();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Skor: $_score\nHigh Score: $_highScore'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    _resetBoard();
    setState(() {});
  }

  // Gestur swipe untuk kontrol arah
  void _onPanStart(DragStartDetails d) => _dragStart = d.localPosition;
  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragStart == null) return;
    final delta = d.localPosition - _dragStart!;
    if (delta.distance < 18) return;
    if (delta.dx.abs() > delta.dy.abs()) {
      _queueDirection(delta.dx > 0 ? _Dir.right : _Dir.left);
    } else {
      _queueDirection(delta.dy > 0 ? _Dir.down : _Dir.up);
    }
    _dragStart = d.localPosition; // agar bisa swipe bertahap
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Snake — Cacing Ceria'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          // latar gradient cerah
          gradient: LinearGradient(
            colors: [Color(0xFF7AE9FF), Color(0xFF88F7A0), Color(0xFFFFF59D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Header skor
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _StatPill(
                      icon: Icons.stars_rounded,
                      label: 'Skor',
                      value: '$_score',
                      color: const Color(0xFF4E9BFF),
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
                      icon: Icons.emoji_events_outlined,
                      label: 'High',
                      value: '$_highScore',
                      color: const Color(0xFFFF7AC8),
                    ),
                    const Spacer(),
                    // Play/Pause kecil
                    IconButton.filledTonal(
                      onPressed: _running ? _pause : _start,
                      icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      onPressed: _restart,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Papan permainan (square)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _cols / _rows,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final cellSizeW = (c.maxWidth - (_cols - 1) * _cellGap) / _cols;
                        final cellSizeH = (c.maxHeight - (_rows - 1) * _cellGap) / _rows;
                        final cellSize = min(cellSizeW, cellSizeH);

                        // agar papan tetap center kalau ada sisa ruang
                        final boardW = cellSize * _cols + _cellGap * (_cols - 1);
                        final boardH = cellSize * _rows + _cellGap * (_rows - 1);

                        return Center(
                          child: SizedBox(
                            width: boardW,
                            height: boardH,
                            child: GestureDetector(
                              onPanStart: _onPanStart,
                              onPanUpdate: _onPanUpdate,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  children: [
                                    // grid background (checker subtle)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _BoardPainter(
                                          rows: _rows,
                                          cols: _cols,
                                          gap: _cellGap,
                                          cell: cellSize,
                                        ),
                                      ),
                                    ),
                                    // Makanan
                                    Positioned(
                                      left: _food.x * (cellSize + _cellGap),
                                      top: _food.y * (cellSize + _cellGap),
                                      child: _FoodCell(size: cellSize),
                                    ),
                                    // Cacing
                                    ..._snake.map((p) {
                                      final isHead = p == _snake.last;
                                      return Positioned(
                                        left: p.x * (cellSize + _cellGap),
                                        top: p.y * (cellSize + _cellGap),
                                        child: _SnakeCell(
                                          size: cellSize,
                                          head: isHead,
                                        ),
                                      );
                                    }),
                                    // Overlay hint saat tidak jalan
                                    if (!_running)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.white.withValues(alpha: 0.06),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.swipe_rounded,
                                                    size: 48,
                                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Swipe / gunakan D-Pad untuk mengarahkan.\nTekan ▶ Start.',
                                                  textAlign: TextAlign.center,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // D-Pad Kontrol
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _Dpad(
                  onUp: () => _queueDirection(_Dir.up),
                  onDown: () => _queueDirection(_Dir.down),
                  onLeft: () => _queueDirection(_Dir.left),
                  onRight: () => _queueDirection(_Dir.right),
                  onStartPause: () => _running ? _pause() : _start(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== Widget kecil ======

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            spreadRadius: 0,
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            '$label ',
            style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: t.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCell extends StatelessWidget {
  const _FoodCell({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5D6C),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: const Color(0xFFFF5D6C).withValues(alpha: 0.35),
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8AA1), Color(0xFFFF3B55)],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.35,
        height: size * 0.35,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SnakeCell extends StatelessWidget {
  const _SnakeCell({required this.size, required this.head});
  final double size;
  final bool head;

  @override
  Widget build(BuildContext context) {
    final bodyColor = head ? const Color(0xFF6A5CFF) : const Color(0xFF8D7BFF);
    final gradA = head ? const Color(0xFF8EA0FF) : const Color(0xFFA898FF);
    final gradB = head ? const Color(0xFF5A47FF) : const Color(0xFF7B68FF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradA, gradB],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: bodyColor.withValues(alpha: 0.28),
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
      ),
      child: head
          ? Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: size * 0.14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _eye(size),
                    SizedBox(width: size * 0.10),
                    _eye(size),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _eye(double s) {
    return Container(
      width: s * 0.18,
      height: s * 0.18,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: s * 0.09,
        height: s * 0.09,
        decoration: const BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.rows,
    required this.cols,
    required this.gap,
    required this.cell,
  });

  final int rows, cols;
  final double gap, cell;

  @override
  void paint(Canvas canvas, Size size) {
    final bgA = Paint()..color = const Color(0x66FFFFFF);
    final bgB = Paint()..color = const Color(0x33FFFFFF);

    // Grid checker halus
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final left = x * (cell + gap);
        final top = y * (cell + gap);
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, cell, cell),
          Radius.circular(cell * 0.22),
        );
        canvas.drawRRect((x + y).isEven ? r : r, (x + y).isEven ? bgA : bgB);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.cols != cols ||
        oldDelegate.gap != gap ||
        oldDelegate.cell != cell;
  }
}

class _Dpad extends StatelessWidget {
  const _Dpad({
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onStartPause, // dibiarkan saja untuk kompatibilitas pemanggil
  });

  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onStartPause;

  @override
  Widget build(BuildContext context) {
    // Ukuran D-Pad, bisa kamu sesuaikan (mis. 160–220)
    const double size = 200;
    const double btnPad = 20; // padding di dalam tombol
    final Color base = Colors.white.withValues(alpha: 0.92);
    final Color icon = Colors.black87;

    Widget circleBtn(IconData ic, VoidCallback onTap) => Material(
          color: base,
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(btnPad),
              child: Icon(ic, size: 36, color: icon),
            ),
          ),
        );

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hiasan diamond (belah ketupat)
            Transform.rotate(
              angle: pi / 4,
              child: Container(
                width: size * 0.72,
                height: size * 0.72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 14,
                      color: Colors.black.withValues(alpha: 0.06),
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),

            // Atas
            Positioned(
              top: 0,
              child: circleBtn(Icons.keyboard_arrow_up_rounded, onUp),
            ),
            // Bawah
            Positioned(
              bottom: 0,
              child: circleBtn(Icons.keyboard_arrow_down_rounded, onDown),
            ),
            // Kiri
            Positioned(
              left: 0,
              child: circleBtn(Icons.keyboard_arrow_left_rounded, onLeft),
            ),
            // Kanan
            Positioned(
              right: 0,
              child: circleBtn(Icons.keyboard_arrow_right_rounded, onRight),
            ),
          ],
        ),
      ),
    );
  }
}
