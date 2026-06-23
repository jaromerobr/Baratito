// Splash screen — Baratito branded entry.
//
// Shows the Baratito "B" logo with brand colors,
// then redirects based on auth state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../../core/router.dart';
import '../../../../core/supabase_client.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 2500), _navigateBasedOnAuth);
  }

  Future<void> _navigateBasedOnAuth() async {
    if (!mounted) return;

    final user = SupabaseClientHelper.auth.currentUser;

    if (user == null) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Secondary background
          Container(color: cs.secondary),

          // Primary diagonal shapes
          Positioned(
            top: -60,
            right: -80,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -math.pi / 6 + (_bgController.value * 0.05),
                  child: child,
                );
              },
              child: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(160),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -100,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: math.pi / 5 - (_bgController.value * 0.04),
                  child: child,
                );
              },
              child: Container(
                width: 280,
                height: 380,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(130),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
          ),

          // Floating decorative icons
          _buildSplashIcon(Icons.local_offer_outlined,
              top: size.height * 0.15, left: 40),
          _buildSplashIcon(Icons.favorite_outline_rounded,
              top: size.height * 0.12, right: 50),
          _buildSplashIcon(Icons.checkroom_outlined,
              bottom: size.height * 0.20, left: 30),
          _buildSplashIcon(Icons.sync_outlined,
              bottom: size.height * 0.15, right: 40),

          // Logo centered
          Center(
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "B" container
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withAlpha(30),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'B',
                          style: GoogleFonts.poppins(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'BARATITO',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: cs.onSecondary,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Segunda mano, nueva oportunidad.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: cs.onSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: cs.primary.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplashIcon(IconData icon,
      {double? top, double? bottom, double? left, double? right}) {
    final cs = Theme.of(context).colorScheme;
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cs.onPrimary.withAlpha(50),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: cs.onPrimary.withAlpha(180), size: 22),
      ),
    );
  }
}
