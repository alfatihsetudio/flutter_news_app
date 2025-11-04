// lib/screens/menu_screen.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

// ========== FITUR YANG SUDAH ADA DI PROJEK ==========
import 'home_screen.dart';
import 'screen_tugas_maps.dart';
import 'screen_game.dart';
import 'screen_stocks.dart';
import 'screen_auth_hub.dart';



class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgCtl;

  @override
  void initState() {
    super.initState();
    _bgCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features = <_Feature>[
      _Feature(
        title: '📰 Aplikasi Berita',
        subtitle: 'Menampilkan berita dari NewsAPI',
        icon: Icons.article_outlined,
        page: const HomeScreen(),
      ),
      // di list features pada MenuScreen
      _Feature(
        title: '🔐 Auth Hub',
        subtitle: 'Login • Register • Profile',
        icon: Icons.verified_user_outlined,
        page: const ScreenAuthHub(),
      ),

      _Feature(
        title: '📍 Tugas 2 - Maps',
        subtitle: 'Peta interaktif OSM + lokasi + search',
        icon: Icons.map_outlined,
        page: const ScreenTugasMaps(),
      ),
      _Feature(
        title: '🎮 Game',
        subtitle: 'Snake mini-game',
        icon: Icons.sports_esports_outlined,
        page: const ScreenGame(),
      ),
      _Feature(
        title: '📊 Crypto Watch',
        subtitle: 'Pantau harga real-time',
        icon: Icons.show_chart,
        page: const ScreenStocks(),
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Flutter Experimental Hub'),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== Background dinamis (gradient + blobs + noise) =====
          _AnimatedBackground(controller: _bgCtl),

          // ===== Konten utama dengan glass sheet =====
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final cross = w < 640
                      ? 2
                      : (w < 980)
                          ? 3
                          : 4;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 24,
                                spreadRadius: -6,
                                offset: Offset(0, 12),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header kecil di atas grid
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 18, 18, 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.dashboard_customize,
                                        size: 22, color: Colors.white),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Menu Fitur Percobaan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const Spacer(),
                                    _GlassPill(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.flash_on_rounded, size: 16),
                                          SizedBox(width: 6),
                                          Text('Dynamic • Blur • Animations'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(18),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cross,
                                    mainAxisSpacing: 18,
                                    crossAxisSpacing: 18,
                                    childAspectRatio: 1.08,
                                  ),
                                  itemCount: features.length,
                                  itemBuilder: (_, i) =>
                                      _FeatureCard(feature: features[i]),
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
        ],
      ),
    );
  }
}

/* =========================
   Komponen: Feature & Card
   ========================= */

class _Feature {
  const _Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 420),
              pageBuilder: (_, a, __) => FadeTransition(
                opacity: a,
                child: f.page,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: _pressed
              ? 0.98
              : _hover
                  ? 1.03
                  : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(_hover ? 0.32 : 0.18),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(_hover ? 0.22 : 0.14),
                      Colors.white.withOpacity(_hover ? 0.08 : 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_hover ? 0.24 : 0.14),
                      blurRadius: _hover ? 26 : 16,
                      spreadRadius: -6,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IconAura(icon: f.icon, active: _hover),
                    const SizedBox(height: 12),
                    Text(
                      f.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      f.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* =========================
   Komponen: Icon dengan aura
   ========================= */
class _IconAura extends StatelessWidget {
  const _IconAura({required this.icon, required this.active});
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.indigoAccent.withOpacity(active ? 0.75 : 0.55),
            Colors.indigo.withOpacity(active ? 0.25 : 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 34,
          color: Colors.white,
        ),
      ),
    );
  }
}

/* =========================
   Komponen: Badge kecil kaca
   ========================= */
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.26)),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/* =========================
   Background dinamis
   ========================= */
class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = [
      scheme.primary.withOpacity(0.75),
      Colors.pinkAccent.withOpacity(0.65),
      Colors.amber.withOpacity(0.55),
      Colors.cyanAccent.withOpacity(0.55),
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * math.pi;

        // Blob positions
        final a = Alignment(math.sin(t) * 0.7, math.cos(t) * 0.7);
        final b = Alignment(math.cos(t * 0.8) * -0.8, math.sin(t * 0.8) * 0.8);
        final c = Alignment(math.sin(t * 1.2) * 0.6, math.cos(t * 1.2) * -0.6);

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F1023), Color(0xFF1B1E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              _Blob(alignment: a, color: colors[0], size: 420),
              _Blob(alignment: b, color: colors[1], size: 360),
              _Blob(alignment: c, color: colors[2], size: 460),
              // Lapisan halus di atas
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.02),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // glow lembut
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 180,
              spreadRadius: 60,
            )
          ],
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.55),
              color.withOpacity(0.18),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}
