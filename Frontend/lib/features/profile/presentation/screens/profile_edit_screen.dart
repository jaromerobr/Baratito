/// Edit profile screen — name, username, phone, bio and avatar.
library;

import 'package:flutter/material.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../utils/validators.dart';
import '../../data/profile_repository.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final _repo = ProfileRepository();
  Uint8List? _newAvatar;
  String? _currentAvatarUrl;
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _newAvatar = bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_newAvatar != null) {
        await _repo.uploadAvatar(_newAvatar!);
      }
      await _repo.updateProfile(
        fullName: _nameCtrl.text,
        username: _userCtrl.text,
        phone: _phoneCtrl.text,
        bio: _bioCtrl.text,
      );
      ref.invalidate(currentUserProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado ✓')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.code == '23505'
          ? 'Ese nombre de usuario ya está en uso'
          : 'No se pudo guardar: ${e.message}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    // Prefill once when the profile arrives.
    profileAsync.whenData((p) {
      if (!_initialized && p != null) {
        _nameCtrl.text = p.fullName ?? '';
        _userCtrl.text = p.username ?? '';
        _phoneCtrl.text = p.phone ?? '';
        _bioCtrl.text = p.bio ?? '';
        _currentAvatarUrl = ProfileRepository.avatarUrl(p.avatarPath);
        _initialized = true;
      }
    });

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: BaratitoAppBar(
        title: Text('Editar perfil',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    _AvatarPreview(
                        bytes: _newAvatar, url: _currentAvatarUrl),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _pickAvatar,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.camera_alt,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),
              _label('Nombre completo'),
              TextFormField(
                controller: _nameCtrl,
                maxLength: 60,
                decoration: _dec('Tu nombre'),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
              ),
              _label('Nombre de usuario'),
              TextFormField(
                controller: _userCtrl,
                maxLength: 20,
                // Solo minúsculas, números, punto y guion bajo (también al pegar).
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._]')),
                ],
                validator: Validators.usernameOptional,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: _dec('@usuario (opcional)'),
              ),
              _label('Teléfono'),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                // Rechaza letras incluso pegadas desde el portapapeles.
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.phoneOptional,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: _dec('Ej. 0991234567 (opcional)'),
              ),
              _label('Biografía'),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: _dec('Cuéntale a los demás sobre ti (opcional)'),
              ),
              const Gap(16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Guardar cambios',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(t,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textPrimary)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.palette.textHint),
        filled: true,
        fillColor: context.palette.surface,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}

class _AvatarPreview extends StatelessWidget {
  final Uint8List? bytes;
  final String? url;
  const _AvatarPreview({required this.bytes, required this.url});

  @override
  Widget build(BuildContext context) {
    final radius = 52.0;
    if (bytes != null) {
      return CircleAvatar(radius: radius, backgroundImage: MemoryImage(bytes!));
    }
    if (url != null) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(url!));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.person, size: 52, color: Colors.white),
    );
  }
}
