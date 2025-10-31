// lib/screens/screen_tugas_login.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthMode { login, register }

class ScreenTugasLogin extends StatefulWidget {
  const ScreenTugasLogin({super.key});

  @override
  State<ScreenTugasLogin> createState() => _ScreenTugasLoginState();
}

class _ScreenTugasLoginState extends State<ScreenTugasLogin> {
  final _formKey = GlobalKey<FormState>();

  AuthMode _mode = AuthMode.login;
  bool _loading = false;
  bool _obscurePassword = true;

  // controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  // simple in-memory current user (for UI)
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUser();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLoggedInUser() async {
    final sp = await SharedPreferences.getInstance();
    final logged = sp.getString('logged_in_user') ?? '';
    if (logged.isNotEmpty) {
      setState(() {
        _currentUserEmail = logged;
      });
    }
  }

  // users stored as JSON string of map email -> {name, password}
  Future<Map<String, dynamic>> _readUsersFromPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('mock_users') ?? '{}';
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      return m;
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeUsersToPrefs(Map<String, dynamic> users) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('mock_users', json.encode(users));
  }

  bool _isEmailValid(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }

  String? _validateName(String? v) {
    if (_mode == AuthMode.register) {
      if (v == null || v.trim().length < 2) return 'Masukkan nama minimal 2 karakter';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
    if (!_isEmailValid(v.trim())) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password wajib diisi';
    if (v.length < 6) return 'Password minimal 6 karakter';
    if (_mode == AuthMode.register) {
      // simple strength hint
      if (!RegExp(r'[A-Z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
        return 'Gunakan huruf besar & angka untuk keamanan lebih baik';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();

    try {
      final users = await _readUsersFromPrefs();

      if (_mode == AuthMode.register) {
        if (users.containsKey(email)) {
          _showSnack('Email sudah terdaftar. Silakan login atau pakai email lain.', isError: true);
          return;
        }
        // register
        users[email] = {'name': name, 'password': password};
        await _writeUsersToPrefs(users);
        await _setLoggedInUser(email);
        _showSnack('Registrasi berhasil — masuk sebagai $name');
        setState(() {
          _currentUserEmail = email;
        });
      } else {
        // login
        if (!users.containsKey(email)) {
          _showSnack('Akun tidak ditemukan. Silakan registrasi terlebih dahulu.', isError: true);
          return;
        }
        final stored = users[email] as Map<String, dynamic>;
        final storedPassword = stored['password']?.toString() ?? '';
        if (storedPassword != password) {
          _showSnack('Password salah. Coba lagi.', isError: true);
          return;
        }
        await _setLoggedInUser(email);
        _showSnack('Login berhasil — selamat datang kembali, ${stored['name'] ?? email}');
        setState(() {
          _currentUserEmail = email;
        });
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _setLoggedInUser(String email) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('logged_in_user', email);
  }

  Future<void> _logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('logged_in_user');
    setState(() {
      _currentUserEmail = null;
    });
    _showSnack('Berhasil logout');
  }

  void _showSnack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
      duration: const Duration(seconds: 2),
    ));
  }

  void _switchMode() {
    setState(() {
      _mode = _mode == AuthMode.login ? AuthMode.register : AuthMode.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _mode == AuthMode.register;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas 1 — Login / Register'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            children: [
              // If already logged in, show summary + logout
              if (_currentUserEmail != null) ...[
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 36, color: Colors.indigo),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Logged in as', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              const SizedBox(height: 4),
                              FutureBuilder<Map<String, dynamic>>(
                                future: _readUsersFromPrefs(),
                                builder: (context, snap) {
                                  if (!snap.hasData) return Text(_currentUserEmail ?? '', style: theme.textTheme.titleMedium);
                                  final map = snap.data!;
                                  final u = map[_currentUserEmail] as Map<String, dynamic>?;
                                  final name = u != null ? (u['name'] ?? '') : '';
                                  return Text(name.isNotEmpty ? '$name\n($_currentUserEmail)' : _currentUserEmail ?? '',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
                                },
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_outlined),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Card with form
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      // header
                      Row(
                        children: [
                          Icon(isRegister ? Icons.person_add_alt_1_outlined : Icons.login_outlined, size: 28, color: Colors.indigo.shade700),
                          const SizedBox(width: 12),
                          Text(isRegister ? 'Buat Akun Baru' : 'Masuk ke Akun', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                            onPressed: _switchMode,
                            child: Text(isRegister ? 'Sudah punya akun?' : 'Belum punya akun? Daftar'),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // name only for register
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: TextFormField(
                                controller: _nameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Nama lengkap',
                                  hintText: 'Masukkan nama Anda',
                                  prefixIcon: const Icon(Icons.person),
                                ),
                                validator: _validateName,
                              ),
                              crossFadeState: isRegister ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 250),
                            ),

                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'example@domain.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Minimal 6 karakter',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: _validatePassword,
                            ),

                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: _loading
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(isRegister ? 'Daftar & Masuk' : 'Masuk'),
                              ),
                            ),

                            const SizedBox(height: 10),
                            if (!isRegister)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () => _showForgotDialog(),
                                    child: const Text('Lupa password?'),
                                  )
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // small help / notes
              Text(
                'Catatan: Fitur ini adalah mock (tanpa backend). Semua akun disimpan lokal pada device menggunakan SharedPreferences untuk keperluan percobaan.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Reset password (mock)'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Masukkan email Anda'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
                onPressed: () async {
                  final email = ctrl.text.trim().toLowerCase();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan email terlebih dahulu')));
                    return;
                  }
                  final users = await _readUsersFromPrefs();
                  if (!users.containsKey(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email tidak ditemukan')));
                    return;
                  }
                  // for mock: just show dialog saying email sent
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Instruksi reset (mock) telah dikirim')));
                },
                child: const Text('Kirim'))
          ],
        );
      },
    );
  }
}
