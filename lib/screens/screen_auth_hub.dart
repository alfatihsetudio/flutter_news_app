// lib/screens/screen_auth_hub.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

class ScreenAuthHub extends StatefulWidget {
  const ScreenAuthHub({super.key});

  @override
  State<ScreenAuthHub> createState() => _ScreenAuthHubState();
}

class _ScreenAuthHubState extends State<ScreenAuthHub> {
  // 0 = Login, 1 = Register, 2 = Profile
  int _tab = 0;
  bool _loading = false;

  // Session
  String? _token;
  Map<String, dynamic>? _me;

  // Controllers
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();

  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();

  final _oldPass = TextEditingController();
  final _newPass = TextEditingController();

  // Styles (hindari withOpacity -> pakai ARGB agar tak kena peringatan)
  static const Color kGlassFill = Color(0x1AFFFFFF); // ~10% putih
  static const Color kGlassStroke = Color(0x33FFFFFF); // ~20%
  static const Color kTextPrimary = Colors.white;
  static const Color kTextMuted = Color(0xCCFFFFFF); // ~80%
  static const double kRadius = 24;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPass.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPass.dispose();
    _oldPass.dispose();
    _newPass.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString('token');
    if (t == null || t.isEmpty) return;
    setState(() => _token = t);
    await _fetchProfile();
  }

  Future<void> _saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('token', token);
    setState(() => _token = token);
  }

  Future<void> _clearToken() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('token');
    setState(() {
      _token = null;
      _me = null;
    });
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _fetchProfile() async {
    if (_token == null) return;
    setState(() => _loading = true);
    try {
      final me = await AuthService.instance.profile(_token!);
      setState(() => _me = me);
    } on ApiException catch (e) {
      _showSnack(e.message, error: true);
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onLogin() async {
    final email = _loginEmail.text.trim();
    final pass = _loginPass.text;
    if (email.isEmpty || pass.isEmpty) {
      _showSnack('Email & password wajib diisi', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final token = await AuthService.instance.login(email: email, password: pass);
      await _saveToken(token);
      await _fetchProfile();
      _showSnack('Login berhasil');
      setState(() => _tab = 2);
    } on ApiException catch (e) {
      _showSnack(e.message, error: true);
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRegister() async {
    final name = _regName.text.trim();
    final email = _regEmail.text.trim();
    final pass = _regPass.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showSnack('Nama, email, dan password wajib diisi', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final token = await AuthService.instance.register(
        name: name,
        email: email,
        password: pass,
      );
      if (token.isNotEmpty) {
        await _saveToken(token);
        await _fetchProfile();
        setState(() => _tab = 2);
      }
      _showSnack('Registrasi berhasil');
    } on ApiException catch (e) {
      _showSnack(e.message, error: true);
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onChangePassword() async {
    if (_token == null) {
      _showSnack('Harus login dahulu', error: true);
      return;
    }
    final oldP = _oldPass.text;
    final newP = _newPass.text;
    if (oldP.isEmpty || newP.isEmpty) {
      _showSnack('Password lama & baru wajib diisi', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.instance.changePassword(
        token: _token!,
        oldPassword: oldP,
        newPassword: newP,
      );
      _showSnack('Password berhasil diubah');
      _oldPass.clear();
      _newPass.clear();
    } on ApiException catch (e) {
      _showSnack(e.message, error: true);
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BACKGROUND: gradient + glow circles
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0E1630),
                  Color(0xFF1D2A52),
                  Color(0xFF22345F),
                  Color(0xFF19203D),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -40,
            child: _glowBlob(220, const Color(0xFF5B8CFF)),
          ),
          Positioned(
            bottom: -60,
            right: -20,
            child: _glowBlob(260, const Color(0xFFFFB86B)),
          ),

          // CONTENT
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth > 720;
                  final width = isWide ? 640.0 : c.maxWidth - 24;
                  return SizedBox(
                    width: width,
                    child: _glassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header status
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_outlined,
                                    color: kTextPrimary),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0x334CAF50),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(color: kGlassStroke),
                                  ),
                                  child: Text(
                                    _token == null ? 'Status: Tamu' : 'Status: Masuk',
                                    style: const TextStyle(
                                      color: kTextPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (_token != null)
                                  TextButton.icon(
                                    onPressed: () async {
                                      await _clearToken();
                                      _showSnack('Anda keluar');
                                      setState(() => _tab = 0);
                                    },
                                    icon: const Icon(Icons.logout, color: kTextPrimary, size: 18),
                                    label: const Text('Logout',
                                        style: TextStyle(color: kTextPrimary)),
                                  ),
                              ],
                            ),
                          ),

                          // Tab segmented
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: _segmentedTabs(),
                          ),
                          const SizedBox(height: 8),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Padding(
                              key: ValueKey(_tab),
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                              child: switch (_tab) {
                                0 => _loginView(),
                                1 => _registerView(),
                                _ => _profileView(),
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Loading overlay
          if (_loading) ...[
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Container(color: const Color(0x33000000)),
              ),
            ),
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Small widgets ----------

  Widget _segmentedTabs() {
    final entries = <(String, IconData)>[
      ('Login', Icons.login_rounded),
      ('Register', Icons.person_add_alt_1_rounded),
      ('Profile', Icons.account_circle_outlined),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kGlassFill,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: kGlassStroke),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: List.generate(entries.length, (i) {
          final selected = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0x334E9BFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  border: selected ? Border.all(color: kGlassStroke) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(entries[i].$2,
                        size: 18,
                        color: selected ? Colors.white : kTextMuted),
                    const SizedBox(width: 8),
                    Text(
                      entries[i].$1,
                      style: TextStyle(
                        color: selected ? Colors.white : kTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _loginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textField(
          controller: _loginEmail,
          label: 'Email',
          icon: Icons.alternate_email,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _textField(
          controller: _loginPass,
          label: 'Password',
          icon: Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 18),
        _primaryButton(
          icon: Icons.login_rounded,
          label: 'Masuk',
          onTap: _onLogin,
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _tab = 1),
            child: const Text(
              'Belum punya akun? Daftar',
              style: TextStyle(color: kTextPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _registerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textField(
          controller: _regName,
          label: 'Nama Lengkap',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 12),
        _textField(
          controller: _regEmail,
          label: 'Email',
          icon: Icons.alternate_email,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _textField(
          controller: _regPass,
          label: 'Password',
          icon: Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 18),
        _primaryButton(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Daftar',
          onTap: _onRegister,
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _tab = 0),
            child: const Text(
              'Sudah punya akun? Masuk',
              style: TextStyle(color: kTextPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileView() {
    final me = _me;
    final loggedIn = _token != null && me != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!loggedIn) ...[
          const SizedBox(height: 6),
          const Text(
            'Belum login.',
            style: TextStyle(color: kTextPrimary, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Silakan masuk terlebih dahulu di tab Login.',
            style: TextStyle(color: kTextMuted),
          ),
          const SizedBox(height: 16),
          _primaryButton(
            icon: Icons.login_rounded,
            label: 'Pindah ke Login',
            onTap: () => setState(() => _tab = 0),
          ),
        ] else ...[
          // Header profil
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0x335B8CFF),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me['name']?.toString() ?? '(tanpa nama)',
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      me['email']?.toString() ?? '-',
                      style: const TextStyle(color: kTextMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh profil',
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh, color: kTextPrimary),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            'Ganti Password',
            style: TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _textField(
            controller: _oldPass,
            label: 'Password Lama',
            icon: Icons.lock_reset,
            obscure: true,
          ),
          const SizedBox(height: 12),
          _textField(
            controller: _newPass,
            label: 'Password Baru',
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 16),
          _primaryButton(
            icon: Icons.save_alt_rounded,
            label: 'Simpan Password',
            onTap: _onChangePassword,
          ),
        ],
      ],
    );
  }

  // ---------- Reusable UI ----------

  Widget _glowBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 120, spreadRadius: 40),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: kGlassFill,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kGlassStroke),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: kTextPrimary),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: kTextPrimary),
        labelText: label,
        labelStyle: const TextStyle(color: kTextMuted),
        filled: true,
        fillColor: const Color(0x1FFFFFFF), // ~12% white
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kGlassStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4E9BFF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
