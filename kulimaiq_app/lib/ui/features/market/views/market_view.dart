import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/crop_type.dart';
import '../../../../domain/models/market_listing.dart';
import '../../../../l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/kulima_card.dart';
import '../../../core/widgets/section_header.dart';
import '../view_models/market_view_model.dart';

class MarketView extends StatefulWidget {
  const MarketView({super.key});

  @override
  State<MarketView> createState() => _MarketViewState();
}

class _MarketViewState extends State<MarketView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MarketViewModel>();
    final s = vm.strings;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: vm.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              SectionHeader(
                title: s.t('market_title'),
                subtitle: s.t('market_subtitle'),
              ),
              ...vm.listings.map(
                (listing) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ListingCard(listing: listing, strings: s),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.strings});

  final MarketListing listing;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final posted = DateFormat.MMMd().format(listing.postedAt);

    return KulimaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(_cropIcon(listing.crop), color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.cropLabel(listing.crop.id),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  listing.sellerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  listing.location,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _InfoTag(
                      icon: Icons.scale_rounded,
                      label: '${listing.quantityKg.toStringAsFixed(0)} kg',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _InfoTag(icon: Icons.schedule_rounded, label: posted),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.phone_rounded,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      listing.contactPhone,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${listing.pricePerKg}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                strings.t('market_price'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _cropIcon(CropType crop) => crop.icon;
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
