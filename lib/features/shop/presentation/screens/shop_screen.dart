import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/core/localization/app_strings.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/features/game/domain/models/game_event.dart';
import 'package:match3_game/features/shop/presentation/providers/shop_providers.dart';

/// Full-screen in-game shop and quick modal dialog for purchasing lives,
/// booster supplies, currency packs, and ad removal.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  /// Displays the shop as a modal bottom sheet.
  static Future<void> showAsModal(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.9,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: ShopScreen(),
        ),
      ),
    );
  }

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _isLoading = false;

  Future<void> _buyLifeRefill() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(livesServiceProvider).addLives(5);
      _showMessage('Full Lives Refilled!');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _watchAdForLife() async {
    final strings = ref.read(stringsProvider);
    setState(() => _isLoading = true);
    try {
      final adService = ref.read(adServiceProvider);
      await adService.showRewarded(
        rewardType: 'life',
        onRewarded: () async {
          await ref.read(livesServiceProvider).addLives(5);
          _showMessage('+5 Lives Earned!');
        },
        onFailed: () {
          _showMessage(strings.adNotReady, isError: true);
        },
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _watchAdForCoins() async {
    final strings = ref.read(stringsProvider);
    setState(() => _isLoading = true);
    try {
      final adService = ref.read(adServiceProvider);
      await adService.showRewarded(
        rewardType: 'coins',
        onRewarded: () async {
          await ref.read(coinsProvider.notifier).addCoins(500);
          _showMessage('+500 Coins Earned!');
        },
        onFailed: () {
          _showMessage(strings.adNotReady, isError: true);
        },
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claimFreeBoosters(BoosterType type, int count) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(boosterInventoryProvider.notifier)
          .addBoosters(type, count);
      _showMessage('+$count Boosters Added! (مفت بوسٹر حاصل ہو گئے)');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claimFreeCoins() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(coinsProvider.notifier).addCoins(1000);
      _showMessage('+1000 Free Coins Claimed! (مفت سکے حاصل ہو گئے)');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enableFreeRemoveAds() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(settingsProvider.notifier).updateRemoveAds(true);
      _showMessage('Ads Removed Free! (تمام اشتہارات ہٹا دیے گئے)');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final coins = ref.watch(coinsProvider).value ?? 0;
    final lives = ref.watch(livesCountProvider).value ?? 5;
    final settings = ref.watch(settingsProvider).value;
    final isRemoveAdsOwned = settings?.removeAdsPurchased ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF16152B),
      appBar: AppBar(
        title: Text(
          strings.shopTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E38),
        elevation: 0,
        actions: [
          // Coins Indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on,
                    color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Lives Indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: const Color(0xFFFF5252)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: Color(0xFFFF5252), size: 18),
                const SizedBox(width: 4),
                Text(
                  '$lives/5',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // LIVES SECTION
              _buildSectionHeader(
                icon: Icons.favorite,
                title: strings.refillLives,
                color: const Color(0xFFFF5252),
              ),
              _buildCard(
                child: Column(
                  children: [
                    _buildShopTile(
                      icon: Icons.favorite,
                      iconColor: const Color(0xFFFF5252),
                      title: strings.fullRefill,
                      subtitle: 'Instantly get 5/5 lives',
                      actionText: 'FREE',
                      onTap: _buyLifeRefill,
                    ),
                    const Divider(color: Colors.white12),
                    _buildShopTile(
                      icon: Icons.play_circle_fill,
                      iconColor: Colors.amber,
                      title: strings.watchAdForLife,
                      subtitle: 'Watch a short video for +5 Lives',
                      actionText: 'FREE',
                      onTap: _watchAdForLife,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // BOOSTER PACKS (Free & Unlimited)
              _buildSectionHeader(
                icon: Icons.flash_on,
                title: strings.boosterPacks,
                color: Colors.cyanAccent,
              ),
              _buildCard(
                child: Column(
                  children: [
                    _buildShopTile(
                      icon: Icons.gavel,
                      iconColor: Colors.cyanAccent,
                      title: '10x ${strings.boosterHammer}',
                      subtitle: 'Smash single gems without moves',
                      actionText: 'FREE',
                      onTap: () =>
                          _claimFreeBoosters(BoosterType.hammer, 10),
                    ),
                    const Divider(color: Colors.white12),
                    _buildShopTile(
                      icon: Icons.shuffle,
                      iconColor: Colors.purpleAccent,
                      title: '10x ${strings.boosterShuffle}',
                      subtitle: 'Shuffle board pieces',
                      actionText: 'FREE',
                      onTap: () =>
                          _claimFreeBoosters(BoosterType.shuffle, 10),
                    ),
                    const Divider(color: Colors.white12),
                    _buildShopTile(
                      icon: Icons.add_circle,
                      iconColor: Colors.greenAccent,
                      title: '10x ${strings.boosterPlusFiveMoves}',
                      subtitle: 'Add 5 extra turns in level',
                      actionText: 'FREE',
                      onTap: () =>
                          _claimFreeBoosters(BoosterType.plusFiveMoves, 10),
                    ),
                    const Divider(color: Colors.white12),
                    _buildShopTile(
                      icon: Icons.bubble_chart,
                      iconColor: Colors.amberAccent,
                      title: '10x ${strings.boosterColorSwap}',
                      subtitle: 'Swap color of any gem',
                      actionText: 'FREE',
                      onTap: () =>
                          _claimFreeBoosters(BoosterType.colorSwap, 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // FREE COINS SECTION
              _buildSectionHeader(
                icon: Icons.monetization_on,
                title: strings.coinPacks,
                color: const Color(0xFFFFD700),
              ),
              _buildCard(
                child: Column(
                  children: [
                    _buildShopTile(
                      icon: Icons.card_giftcard,
                      iconColor: const Color(0xFFFFD700),
                      title: '1000 Free Coins Gift',
                      subtitle: 'Claim free bonus currency anytime',
                      actionText: 'FREE',
                      onTap: _claimFreeCoins,
                    ),
                    const Divider(color: Colors.white12),
                    _buildShopTile(
                      icon: Icons.videocam,
                      iconColor: Colors.amber,
                      title: strings.watchAdForCoins,
                      subtitle: 'Earn free currency on demand',
                      actionText: 'FREE',
                      onTap: _watchAdForCoins,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // REMOVE ADS
              _buildSectionHeader(
                icon: Icons.block,
                title: strings.removeAds,
                color: Colors.deepOrangeAccent,
              ),
              _buildCard(
                child: _buildShopTile(
                  icon: Icons.block,
                  iconColor: Colors.deepOrangeAccent,
                  title: strings.removeAds,
                  subtitle: strings.removeAdsDesc,
                  actionText: isRemoveAdsOwned ? strings.purchased : 'FREE',
                  isOwned: isRemoveAdsOwned,
                  onTap: isRemoveAdsOwned ? null : _enableFreeRemoveAds,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222040),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _buildShopTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback? onTap,
    bool isOwned = false,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      trailing: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOwned ? Colors.grey.shade800 : const Color(0xFFFF9800),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: Text(
          actionText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

