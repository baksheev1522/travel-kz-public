import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/bloc/auth_bloc.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isSaved = false;

  File? _pickedImage;
  String? _avatarBase64; // хранится в Firestore как строка

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists || !mounted) return;

    final data = doc.data()!;
    setState(() {
      _nameCtrl.text = data['name'] as String? ?? '';
      _surnameCtrl.text = data['surname'] as String? ?? '';
      _phoneCtrl.text = data['phone'] as String? ?? '';
      _emailCtrl.text = data['email'] as String? ??
          FirebaseAuth.instance.currentUser?.email ?? '';
      _avatarBase64 = data['avatarBase64'] as String?;
    });
  }

  // ── Выбор фото ───────────────────────────────────────────────────
  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Сфотографировать'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSave(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Выбрать из галереи'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSave(ImageSource.gallery);
              },
            ),
            if (_avatarBase64 != null && _avatarBase64!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.error),
                title: const Text('Удалить фото',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteAvatar();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Конвертируем в base64 и сохраняем в Firestore ────────────────
  Future<void> _pickAndSave(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Конвертируем фото в base64 строку
      final bytes = await File(picked.path).readAsBytes();
      final base64Str = base64Encode(bytes);

      // Сохраняем строку в Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'avatarBase64': base64Str});

      if (mounted) {
        setState(() {
          _pickedImage = File(picked.path);
          _avatarBase64 = base64Str;
          _isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Фото обновлено ✓'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Не удалось загрузить фото'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _deleteAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'avatarBase64': null});

    if (mounted) {
      setState(() {
        _pickedImage = null;
        _avatarBase64 = null;
      });
    }
  }

  // ── Сохранение профиля ───────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameCtrl.text.trim(),
        'surname': _surnameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });

      // Обновляем BLoC стейт
      if (mounted) {
        final state = context.read<AuthBloc>().state;
        if (state is AuthAuthenticatedState) {
          final updated = state.user.copyWith(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          );
          context.read<AuthBloc>().emit(AuthAuthenticatedState(updated));
        }

        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Профиль сохранён ✓'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ));
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ошибка сохранения. Попробуйте ещё раз.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Avatar widget ────────────────────────────────────────────────
  ImageProvider? get _avatarImage {
    if (_pickedImage != null) return FileImage(_pickedImage!);
    if (_avatarBase64 != null && _avatarBase64!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_avatarBase64!));
      } catch (_) {}
    }
    return null;
  }

  String get _initials {
    final n = _nameCtrl.text.trim();
    final s = _surnameCtrl.text.trim();
    if (n.isNotEmpty && s.isNotEmpty) return '${n[0]}${s[0]}'.toUpperCase();
    if (n.isNotEmpty) return n[0].toUpperCase();
    return '?';
  }

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  String _level(int bonuses) {
    if (bonuses >= 50000) return 'Gold ⭐';
    if (bonuses >= 20000) return 'Silver';
    return 'Basic';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state is AuthAuthenticatedState ? state.user : null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        // Явно белый — перебиваем тему
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Редактировать профиль',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _save,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : _isSaved
                      ? const Icon(Icons.check, color: Colors.white)
                      : const Text(
                          'Сохранить',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Avatar ────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _isUploadingPhoto ? null : _showPickerOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: _avatarImage,
                      child: _avatarImage == null
                          ? Text(_initials,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ))
                          : null,
                    ),
                    // Спиннер загрузки
                    if (_isUploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                      ),
                    // Кнопка камеры
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_outlined,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                _emailCtrl.text.isNotEmpty
                    ? _emailCtrl.text
                    : user?.email ?? '',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey500),
              ),
            ),

            const SizedBox(height: 24),

            // ── Personal info ──────────────────────────────────
            _SectionLabel(label: 'Личные данные'),
            _Card(
              child: Column(
                children: [
                  _Field(
                    controller: _nameCtrl,
                    label: 'Имя',
                    hint: 'Как в паспорте',
                    icon: Icons.person_outline,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Введите имя'
                        : null,
                  ),
                  const Divider(height: 1, indent: 52),
                  _Field(
                    controller: _surnameCtrl,
                    label: 'Фамилия',
                    hint: 'Как в паспорте',
                    icon: Icons.person_outline,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Введите фамилию'
                        : null,
                  ),
                  const Divider(height: 1, indent: 52),
                  _Field(
                    controller: _phoneCtrl,
                    label: 'Телефон',
                    hint: '+7 (___) ___-__-__',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+\s\-\(\)]')),
                    ],
                    validator: (v) =>
                        v == null || v.trim().length < 10
                            ? 'Введите телефон'
                            : null,
                  ),
                  const Divider(height: 1, indent: 52),
                  _Field(
                    controller: _emailCtrl,
                    label: 'Email',
                    hint: 'example@mail.com',
                    icon: Icons.email_outlined,
                    enabled: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Bonus info ─────────────────────────────────────
            _SectionLabel(label: 'Бонусный счёт'),
            _Card(
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A6FE8), Color(0xFF00C9A7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.stars_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_fmt((user?.bonusPoints ?? 0).toDouble())} ₸',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.grey900,
                          ),
                        ),
                        Text('Доступно бонусов',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500)),
                      ],
                    ),
                  ),
                  Text(
                    _level(user?.bonusPoints ?? 0),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF57C00),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Security ───────────────────────────────────────
            _SectionLabel(label: 'Безопасность'),
            _Card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: AppColors.grey600, size: 20),
                ),
                title: const Text('Изменить пароль',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.grey400),
                onTap: () => _showChangePassword(context),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Новый пароль',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Минимум 6 символов',
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.length < 6) return;
                  try {
                    await FirebaseAuth.instance.currentUser
                        ?.updatePassword(ctrl.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Пароль изменён'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Ошибка. Перелогиньтесь и попробуйте снова.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Сохранить пароль',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.grey500)),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: child,
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: TextStyle(
          color: enabled ? AppColors.grey900 : AppColors.grey400,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon,
              color: enabled ? AppColors.grey500 : AppColors.grey300,
              size: 20),
          labelStyle:
              const TextStyle(color: AppColors.grey500, fontSize: 13),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
}