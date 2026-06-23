/// Posts screen — Dio + FutureBuilder demo with 3 reactive states.
///
/// Demonstrates:
/// - Async network call using [PostRepository] (powered by Dio).
/// - [FutureBuilder] controlling three states:
///   1. **Loading**: Animated [CircularProgressIndicator] with label.
///   2. **Success**: Optimized [ListView.builder] rendering JSON posts.
///   3. **Error**: Clean error screen with icon, message, and retry button.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../data/post_model.dart';
import '../../data/post_repository.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen>
    with SingleTickerProviderStateMixin {
  final PostRepository _repository = PostRepository();
  late Future<List<Post>> _postsFuture;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _postsFuture = _repository.getPosts();

    // Pulse animation for the loading indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Retry: create a new Future to trigger FutureBuilder rebuild.
  void _retry() {
    setState(() {
      _postsFuture = _repository.getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeModel = context.watch<ThemeModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Posts — Demo Dio',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeModel.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
            ),
            onPressed: () => context.read<ThemeModel>().toggleTheme(),
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          // ── STATE 1: Loading ──────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(cs);
          }

          // ── STATE 3: Error ───────────────────────────
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString(), cs);
          }

          // ── STATE 2: Success ─────────────────────────
          final posts = snapshot.data;
          if (posts == null || posts.isEmpty) {
            return _buildEmptyState(cs);
          }

          return _buildSuccessState(posts, cs);
        },
      ),
    );
  }

  // ── STATE 1: LOADING ──────────────────────────────────
  Widget _buildLoadingState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated pulsing container with CircularProgressIndicator
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cargando posts...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conectando con el servidor vía Dio',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: cs.outline,
            ),
          ),
        ],
      ),
    );
  }

  // ── STATE 2: SUCCESS — ListView.builder ───────────────
  Widget _buildSuccessState(List<Post> posts, ColorScheme cs) {
    return Column(
      children: [
        // Header card with stats
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.onPrimary.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud_done_rounded,
                  color: cs.onPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${posts.length} posts cargados',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimary,
                      ),
                    ),
                    Text(
                      'Petición exitosa vía Dio + FutureBuilder',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: cs.onPrimary.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Optimized ListView.builder
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _PostCard(post: post, index: index);
            },
          ),
        ),
      ],
    );
  }

  // ── STATE 3: ERROR ────────────────────────────────────
  Widget _buildErrorState(String errorMessage, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon in red circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: cs.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Algo salió mal!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Retry button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────
  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: cs.secondary.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 48,
              color: cs.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay posts disponibles',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El servidor no retornó ningún dato.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post Card Widget ────────────────────────────────────
class _PostCard extends StatelessWidget {
  final Post post;
  final int index;

  const _PostCard({required this.post, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post number badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withAlpha(200),
                  cs.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Post content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  post.body,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // User ID chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'User #${post.userId}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: cs.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
