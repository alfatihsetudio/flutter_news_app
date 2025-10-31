// lib/screens/menu_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart'; // News App feature (already exists)
import 'screen_tugas_login.dart';
import 'screen_tugas_maps.dart';
import 'screen_game.dart';





class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': '📰 Aplikasi Berita',
        'subtitle': 'Menampilkan berita dari NewsAPI',
        'icon': Icons.article_outlined,
        'page': const HomeScreen(),
      },
      {
  'title': '🧩 Tugas 1',
  'subtitle': 'Login & Register (mock)',
  'icon': Icons.task_outlined,
  'page': const ScreenTugasLogin(),
},

      {
  'title': '📍 Tugas 2 - Maps',
  'subtitle': 'Menampilkan peta interaktif OSM + lokasi + pencarian',
  'icon': Icons.map_outlined,
  'page': const ScreenTugasMaps(),
},

      {
  'title': '🧮 game ',
  'subtitle': 'game sederhana',
  'icon': Icons.calculate_outlined,
  'page': const ScreenGame(),
},

      {
        'title': '🧠 Tugas 4',
        'subtitle': 'Percobaan keempat',
        'icon': Icons.psychology_alt_outlined,
        'page': const PlaceholderScreen(title: 'Tugas 4'),
      },
      {
        'title': '🚀 Tugas 5',
        'subtitle': 'Percobaan kelima',
        'icon': Icons.science_outlined,
        'page': const PlaceholderScreen(title: 'Tugas 5'),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('📂 Menu Fitur Percobaan'),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.indigo.shade600,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 kolom di web / mobile landscape
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final item = features[index];
            return _FeatureCard(
              title: item['title'] as String,
              subtitle: item['subtitle'] as String,
              icon: item['icon'] as IconData,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item['page'] as Widget),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Widget kartu fitur
class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.indigo.shade700),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder screen untuk tugas percobaan
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Halaman $title\n(belum diimplementasikan)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
