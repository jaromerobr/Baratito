/// Perfil público de un usuario: su rating, sus productos (en venta / vendidos)
/// y las reseñas que ha recibido. Se abre al tocar al vendedor en un producto.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import '../../../../core/supabase_client.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../../../reviews/data/review_repository.dart';
import '../../../reviews/presentation/providers/reviews_provider.dart';
import '../../../reviews/presentation/widgets/star_rating.dart';
import '../../../moderation/presentation/providers/moderation_providers.dart';
import '../../../moderation/presentation/widgets/user_moderation_actions.dart';
import '../../data/profile_repository.dart';
import '../providers/public_profile_providers.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final isMe = SupabaseClientHelper.auth.currentUser?.id == userId;
    final blocked = ref.watch(isBlockedProvider(userId)).asData?.value ?? false;
    final name = profileAsync.asData?.value?.fullName;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.palette.background,
        appBar: BaratitoAppBar(
          title: const Text('Perfil'),
          actions: isMe
              ? null
              : [
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'report') {
                        reportUserFlow(context, ref,
                            reportedId: userId, reportedName: name);
                      } else if (v == 'block') {
                        toggleBlockFlow(context, ref,
                            userId: userId,
                            currentlyBlocked: blocked,
                            name: name);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'report',
                          child: Text('Reportar usuario')),
                      PopupMenuItem(
                          value: 'block',
                          child: Text(
                              blocked ? 'Desbloquear' : 'Bloquear usuario')),
                    ],
                  ),
                ],
        ),
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Usuario no encontrado'));
            }
            if (blocked) {
              return _BlockedState(
                onUnblock: () => toggleBlockFlow(context, ref,
                    userId: userId, currentlyBlocked: true, name: name),
              );
            }
            return Column(
              children: [
                _Header(profile: profile),
                Material(
                  color: context.palette.surface,
                  child: TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: context.palette.textSecondary,
                    indicatorColor: AppColors.primary,
                    labelStyle:
                        GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    tabs: const [
                      Tab(text: 'En venta'),
                      Tab(text: 'Vendidos'),
                      Tab(text: 'Reseñas'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ProductsGrid(
                        sellerId: userId,
                        status: 'active',
                        emptyText: 'No tiene productos en venta',
                      ),
                      _ProductsGrid(
                        sellerId: userId,
                        status: 'sold',
                        emptyText: 'Aún no ha vendido nada',
                      ),
                      _ReviewsTab(userId: userId),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BlockedState extends StatelessWidget {
  final VoidCallback onUnblock;
  const _BlockedState({required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 56, color: context.palette.textHint),
            const Gap(14),
            Text('Bloqueaste a este usuario',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const Gap(6),
            Text('No ves sus productos ni sus mensajes.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: context.palette.textSecondary)),
            const Gap(18),
            OutlinedButton(
                onPressed: onUnblock, child: const Text('Desbloquear')),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PublicProfile profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl;
    return Container(
      width: double.infinity,
      color: context.palette.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? const Icon(Icons.person, size: 36, color: Colors.white)
                    : null,
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName,
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    if (profile.username != null)
                      Text('@${profile.username}',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.primary)),
                    const Gap(6),
                    if (profile.ratingCount > 0)
                      StarRating(
                        rating: profile.ratingAvg,
                        count: profile.ratingCount,
                        size: 16,
                      )
                    else
                      Text('Sin valoraciones aún',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: context.palette.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const Gap(10),
            Text(profile.bio!,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: context.palette.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _ProductsGrid extends ConsumerWidget {
  final String sellerId;
  final String status;
  final String emptyText;
  const _ProductsGrid({
    required this.sellerId,
    required this.status,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async =
        ref.watch(userProductsProvider((sellerId: sellerId, status: status)));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Text(emptyText,
                style: GoogleFonts.poppins(
                    color: context.palette.textSecondary)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.66,
          ),
          itemCount: products.length,
          itemBuilder: (context, i) => ProductCard(
            product: products[i],
            onTap: () => context.push('/product/${products[i].id}'),
          ),
        );
      },
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  final String userId;
  const _ReviewsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userReviewsProvider(userId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Text('Sin reseñas todavía',
                style: GoogleFonts.poppins(
                    color: context.palette.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, _) => const Gap(10),
          itemBuilder: (context, i) => _ReviewTile(review: reviews[i]),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final UserReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final avatar = ProfileRepository.avatarUrl(review.reviewerAvatarPath);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withAlpha(30),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? const Icon(Icons.person,
                        size: 18, color: AppColors.primary)
                    : null,
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName,
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(
                      '${review.role == 'buyer' ? 'Como comprador' : 'Como vendedor'} · '
                      '${DateFormat('dd/MM/yyyy').format(review.createdAt.toLocal())}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: context.palette.textHint),
                    ),
                  ],
                ),
              ),
              StarRating(rating: review.rating.toDouble(), size: 14),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const Gap(8),
            Text(review.comment!,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: context.palette.textPrimary)),
          ],
        ],
      ),
    );
  }
}
