import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/features/settings/domain/models/settings_model.dart';

// Lightweight, self-contained in-code localization supporting English and Urdu (RTL-safe).
class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isRtl => language == AppLanguage.urdu;
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  // General App
  String get appTitle =>
      language == AppLanguage.urdu ? 'میچ 3 بلٹز' : 'Match-3 Blitz';
  String get loading =>
      language == AppLanguage.urdu ? 'لوڈ ہو رہا ہے...' : 'Loading...';
  String get close => language == AppLanguage.urdu ? 'بند کریں' : 'Close';
  String get cancel => language == AppLanguage.urdu ? 'منسوخ' : 'Cancel';
  String get ok => language == AppLanguage.urdu ? 'ٹھیک ہے' : 'OK';
  String get confirm => language == AppLanguage.urdu ? 'تصدیق' : 'Confirm';
  String get back => language == AppLanguage.urdu ? 'واپس' : 'Back';

  // Home Screen
  String get play => language == AppLanguage.urdu ? 'کھیلیں' : 'Play';
  String get continueGame =>
      language == AppLanguage.urdu ? 'جاری رکھیں' : 'Continue';
  String get levelMap =>
      language == AppLanguage.urdu ? 'مرحلہ نقشہ' : 'Level Map';
  String get dailyReward =>
      language == AppLanguage.urdu ? 'روزانہ انعام' : 'Daily Reward';
  String get shop => language == AppLanguage.urdu ? 'دکان' : 'Shop';
  String get settings => language == AppLanguage.urdu ? 'ترتیبات' : 'Settings';
  String get lives => language == AppLanguage.urdu ? 'زندگیاں' : 'Lives';
  String get coins => language == AppLanguage.urdu ? 'سکے' : 'Coins';
  String get fullLives => language == AppLanguage.urdu ? 'مکمل' : 'FULL';
  String nextLifeIn(String time) => language == AppLanguage.urdu
      ? 'اگلی زندگی: $time'
      : 'Next life in $time';
  String levelLabel(int level) =>
      language == AppLanguage.urdu ? 'مرحلہ $level' : 'Level $level';
  String get claimNow =>
      language == AppLanguage.urdu ? 'ابھی حاصل کریں!' : 'Claim Now!';

  // Level Select
  String get levelSelectTitle =>
      language == AppLanguage.urdu ? 'مرحلہ منتخب کریں' : 'Select Level';
  String totalStars(int stars, int maxStars) => language == AppLanguage.urdu
      ? 'ستارے: $stars / $maxStars'
      : 'Stars: $stars / $maxStars';
  String get levelLocked =>
      language == AppLanguage.urdu ? 'مرحلہ مقفل ہے' : 'Level Locked';
  String get playCost =>
      language == AppLanguage.urdu ? 'کھیلیں (1 زندگی)' : 'Play (1 Life)';
  String get noLivesTitle =>
      language == AppLanguage.urdu ? 'زندگیاں ختم!' : 'Out of Lives!';
  String get noLivesMessage => language == AppLanguage.urdu
      ? 'کھیل جاری رکھنے کے لیے نئی زندگیاں حاصل کریں یا انتظار کریں۔'
      : 'Wait for lives to refill or get more in the shop.';
  String get getMoreLives =>
      language == AppLanguage.urdu ? 'زندگیاں حاصل کریں' : 'Get Lives';

  // Game Objectives & HUD
  String get movesLeft =>
      language == AppLanguage.urdu ? 'چالیں باقی' : 'Moves';
  String get timeLeft => language == AppLanguage.urdu ? 'وقت باقی' : 'Time';
  String get targetScore =>
      language == AppLanguage.urdu ? 'ہدف اسکور' : 'Target Score';
  String get clearJelly =>
      language == AppLanguage.urdu ? 'جیلی صاف کریں' : 'Clear All Jelly';
  String get dropIngredients =>
      language == AppLanguage.urdu ? 'اجزاء گرائیں' : 'Drop Ingredients';
  String get collectPieces =>
      language == AppLanguage.urdu ? 'جواہرات جمع کریں' : 'Collect Gems';
  String get paused => language == AppLanguage.urdu ? 'روکا ہوا' : 'Paused';
  String get resume =>
      language == AppLanguage.urdu ? 'دوبارہ شروع' : 'Resume';
  String get restart =>
      language == AppLanguage.urdu ? 'نئے سرے سے' : 'Restart';
  String get quit => language == AppLanguage.urdu ? 'باہر نکلیں' : 'Quit';
  String get score => language == AppLanguage.urdu ? 'اسکور' : 'Score';
  String get bestScore =>
      language == AppLanguage.urdu ? 'بہترین اسکور' : 'Best';

  // Win / Lose Dialogs
  String get levelComplete =>
      language == AppLanguage.urdu ? 'مرحلہ مکمل!' : 'Level Complete!';
  String get victory => language == AppLanguage.urdu ? 'شاندار فتح!' : 'Victory!';
  String get nextLevel =>
      language == AppLanguage.urdu ? 'اگلا مرحلہ' : 'Next Level';
  String get levelFailed =>
      language == AppLanguage.urdu ? 'مرحلہ نا کام!' : 'Level Failed!';
  String get outOfMoves =>
      language == AppLanguage.urdu ? 'چالیں ختم ہو گئیں!' : 'Out of Moves!';
  String get outOfTime =>
      language == AppLanguage.urdu ? 'وقت ختم ہو گیا!' : 'Time Ran Out!';
  String get watchAdForMoves => language == AppLanguage.urdu
      ? 'اشتہار دیکھیں (+5 چالیں)'
      : 'Watch Ad (+5 Moves)';
  String get tryAgain =>
      language == AppLanguage.urdu ? 'دوبارہ کوشش کریں' : 'Try Again';

  // Boosters
  String get boosterHammer =>
      language == AppLanguage.urdu ? 'لالی پاپ ہتھوڑا' : 'Lollipop Hammer';
  String get boosterShuffle =>
      language == AppLanguage.urdu ? 'مفت تبدیلی' : 'Free Switch';
  String get boosterPlusFiveMoves =>
      language == AppLanguage.urdu ? '+5 چالیں' : '+5 Extra Moves';
  String get boosterColorSwap =>
      language == AppLanguage.urdu ? 'رنگ بم' : 'Color Bomb';
  String get tapPieceToSmash => language == AppLanguage.urdu
      ? 'توڑنے کے لیے کسی بھی جوہر کو چھوئیں'
      : 'Tap any piece to smash it!';
  String get tapPieceToBomb => language == AppLanguage.urdu
      ? 'بم کے ساتھ تبدیل کرنے کے لیے جوہر چھوئیں'
      : 'Tap a piece to swap with color bomb!';

  // Daily Rewards
  String get dailyRewardTitle =>
      language == AppLanguage.urdu ? 'روزانہ لاگ ان انعام' : 'Daily Login Reward';
  String dayNumber(int day) =>
      language == AppLanguage.urdu ? 'دن $day' : 'Day $day';
  String get claimReward =>
      language == AppLanguage.urdu ? 'انعام حاصل کریں' : 'Claim Reward';
  String get rewardClaimed =>
      language == AppLanguage.urdu ? 'حاصل کر لیا' : 'Claimed';
  String get comeBackTomorrow => language == AppLanguage.urdu
      ? 'اگلے انعام کے لیے کل واپس آئیں!'
      : 'Come back tomorrow for your next reward!';
  String get grandReward =>
      language == AppLanguage.urdu ? 'عظیم انعام!' : 'Grand Reward!';
  String get streakResetWarning => language == AppLanguage.urdu
      ? 'مسلسل لاگ ان رکھیں تاکہ سلسلہ نہ ٹوٹے!'
      : 'Keep your streak alive every day!';

  // Settings
  String get settingsTitle =>
      language == AppLanguage.urdu ? 'ترتیبات' : 'Settings';
  String get audioSection =>
      language == AppLanguage.urdu ? 'آواز اور احساس' : 'Audio & Haptics';
  String get soundEffects =>
      language == AppLanguage.urdu ? 'صوتی اثرات' : 'Sound Effects';
  String get backgroundMusic =>
      language == AppLanguage.urdu ? 'پس منظر کی موسیقی' : 'Music';
  String get hapticFeedback =>
      language == AppLanguage.urdu ? 'ہپٹک وائبریشن' : 'Haptic Vibration';
  String get accessibilitySection =>
      language == AppLanguage.urdu ? 'رسائی اور بصارت' : 'Accessibility';
  String get colorBlindMode =>
      language == AppLanguage.urdu ? 'رنگ اندھے پن کا موڈ' : 'Color-Blind Mode';
  String get colorBlindDesc => language == AppLanguage.urdu
      ? 'ہر جوہر کو منفرد ہندسی شکل دیتا ہے'
      : 'Displays distinct geometric shapes for each gem';
  String get appearanceSection =>
      language == AppLanguage.urdu ? 'طرزِ ظاہری' : 'Appearance';
  String get themeMode =>
      language == AppLanguage.urdu ? 'تھیم کا انتخاب' : 'Theme';
  String get themeSystem =>
      language == AppLanguage.urdu ? 'سسٹم' : 'System';
  String get themeLight => language == AppLanguage.urdu ? 'روشن' : 'Light';
  String get themeDark => language == AppLanguage.urdu ? 'تاریک' : 'Dark';
  String get languageSection =>
      language == AppLanguage.urdu ? 'زبان' : 'Language';
  String get restorePurchases =>
      language == AppLanguage.urdu ? 'خریداری بحال کریں' : 'Restore Purchases';
  String get resetProgress =>
      language == AppLanguage.urdu ? 'کھیل کی پیشرفت دوبارہ ترتیب دیں' : 'Reset Progress';
  String get resetProgressConfirmTitle => language == AppLanguage.urdu
      ? 'کیا آپ واقعی دوبارہ ترتیب دینا چاہتے ہیں؟'
      : 'Reset All Progress?';
  String get resetProgressConfirmDesc => language == AppLanguage.urdu
      ? 'یہ آپ کی تمام سطحوں کی پیشرفت اور اسکورز کو حذف کر دے گا۔ یہ عمل ناقابل واپسی ہے۔'
      : 'This will delete all your unlocked levels and high scores. This cannot be undone.';
  String get progressResetSuccess => language == AppLanguage.urdu
      ? 'پیشرفت کامیابی سے دوبارہ ترتیب دی گئی'
      : 'Progress reset successfully';
  String get purchasesRestoredSuccess => language == AppLanguage.urdu
      ? 'خریداری کامیابی سے بحال ہو گئی'
      : 'Purchases restored successfully';
  String get appVersion =>
      language == AppLanguage.urdu ? 'ورژن: 1.0.0' : 'Version: 1.0.0';

  // Shop
  String get shopTitle => language == AppLanguage.urdu ? 'دکان' : 'Shop';
  String get refillLives =>
      language == AppLanguage.urdu ? 'زندگیاں بھریں' : 'Refill Lives';
  String get fullRefill =>
      language == AppLanguage.urdu ? 'مکمل 5 زندگیاں' : 'Full 5 Lives';
  String get watchAdForLife => language == AppLanguage.urdu
      ? 'مفت زندگی حاصل کریں (اشتہار)'
      : 'Free +1 Life (Watch Ad)';
  String get watchAdForCoins => language == AppLanguage.urdu
      ? '+50 مفت سکے (اشتہار)'
      : '+50 Free Coins (Watch Ad)';
  String get coinPacks =>
      language == AppLanguage.urdu ? 'سکوں کے بنڈل' : 'Coin Packs';
  String get boosterPacks =>
      language == AppLanguage.urdu ? 'بوسٹر پیک' : 'Booster Packs';
  String get removeAds =>
      language == AppLanguage.urdu ? 'اشتہارات ہٹائیں' : 'Remove Ads';
  String get removeAdsDesc => language == AppLanguage.urdu
      ? 'تمام بینر اور درمیانی اشتہارات ہمیشہ کے لیے ختم کریں'
      : 'Permanently remove all banners and interstitial ads';
  String get purchased =>
      language == AppLanguage.urdu ? 'خریدا ہوا' : 'Purchased';
  String get notEnoughCoins =>
      language == AppLanguage.urdu ? 'ناکافی سکے!' : 'Not enough coins!';
  String get purchaseSuccess =>
      language == AppLanguage.urdu ? 'خریداری کامیاب!' : 'Purchase Successful!';
  String get adNotReady => language == AppLanguage.urdu
      ? 'اشتہار دستیاب نہیں، تھوڑی دیر بعد کوشش کریں'
      : 'Ad not ready yet. Please try again shortly.';
}

// Global provider for dynamic localized strings based on user settings.
final stringsProvider = Provider<AppStrings>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  final language = settingsAsync.value?.language ?? AppLanguage.english;
  return AppStrings(language);
});

