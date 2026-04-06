// Firebase & AdMob Configuration
// 
// This file contains all configuration for monetization
// Ready to integrate with actual Firebase project

class AdsConfig {
  // Google AdMob Banner IDs (Replace with your actual IDs)
  static const String bannerAdUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy';

  // Interstitial Ad ID
  static const String interstitialAdUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy';

  // Rewarded Ad ID
  static const String rewardedAdUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy';

  // Ad placement triggers
  static const bool showBannerOnHome = true;
  static const bool showInterstitialAfterMatch = true;
  static const bool showRewardedBeforeChestOpen = true;
  static const int matchesBeforeInterstitial = 3;
}

class FirebaseConfig {
  // Firebase Project ID
  static const String projectId = 'your-project-id';

  // Analytics events
  static const String eventMatchStart = 'match_start';
  static const String eventMatchWin = 'match_win';
  static const String eventMatchLose = 'match_lose';
  static const String eventSkillUpgrade = 'skill_upgrade';
  static const String eventChestOpen = 'chest_open';
  static const String eventLevelUp = 'level_up';
  static const String eventPowerUpUsed = 'powerup_used';
  static const String eventMissionComplete = 'mission_complete';
  static const String eventPetInteraction = 'pet_interaction';

  // Revenue events
  static const String eventInAppPurchase = 'in_app_purchase';
  static const String eventAdView = 'ad_view';
  static const String eventAdClick = 'ad_click';
  static const String eventSpendVirtualCurrency = 'spend_virtual_currency';
}

class IAPConfig {
  // Product IDs for Google Play & App Store
  static const String coinPackSmall = 'coins_100';
  static const String coinPackMedium = 'coins_500';
  static const String coinPackLarge = 'coins_2000';

  // Premium power-ups
  static const String premiumSpeedBoost = 'premium_speed_boost';
  static const String premiumClimbBoost = 'premium_climb_boost';
  static const String premiumSwimBoost = 'premium_swim_boost';

  // Battle Pass
  static const String seasonalBattlePass = 'battle_pass_season_1';

  // Prices (stored for reference, actual prices set in store)
  static Map<String, double> priceMap = {
    coinPackSmall: 0.99,
    coinPackMedium: 4.99,
    coinPackLarge: 9.99,
    premiumSpeedBoost: 2.99,
    premiumClimbBoost: 2.99,
    premiumSwimBoost: 2.99,
    seasonalBattlePass: 4.99,
  };
}

/// Analytics Service Wrapper
/// 
/// Use this to track events throughout the app
class AnalyticsService {
  static const bool isDebugMode = false; // Set to true for debug logging

  static void logMatchStart(String difficulty, String powerUp) {
    if (isDebugMode) {
      debugLog('[Analytics] Match started: difficulty=$difficulty, powerUp=$powerUp');
    }
  }

  static void logMatchResult(bool won, int coins, int xp) {
    if (isDebugMode) {
      debugLog('[Analytics] Match result: won=$won, coins=$coins, xp=$xp');
    }
  }

  static void logSkillUpgrade(String skillName) {
    if (isDebugMode) {
      debugLog('[Analytics] Skill upgraded: $skillName');
    }
  }

  static void logLevelUp(int newLevel) {
    if (isDebugMode) {
      debugLog('[Analytics] Leveled up: $newLevel');
    }
  }

  static void logMissionComplete(String missionId, int reward) {
    if (isDebugMode) {
      debugLog('[Analytics] Mission completed: $missionId, reward=$reward');
    }
  }

  static void logPurchase(String productId, double price) {
    if (isDebugMode) {
      debugLog('[Analytics] Purchase: $productId, price=$price');
    }
  }

  static void logAdEvent(String adType, String placement) {
    if (isDebugMode) {
      debugLog('[Analytics] Ad event: type=$adType, placement=$placement');
    }
  }

  static void debugLog(String message) {
    // TODO: Replace with actual logging framework (Crashlytics, etc)
  }
}

/// Monetization Helper
class MonetizationHelper {
  static bool shouldShowAd(int matchCount) {
    return matchCount % AdsConfig.matchesBeforeInterstitial == 0;
  }

  static double calculateMonthlyRevenue(
    int adImpressions,
    double cpmRate,
    int iapPurchases,
    double averageOrderValue,
  ) {
    double adRevenue = (adImpressions * cpmRate) / 1000;
    double iapRevenue = iapPurchases * averageOrderValue;
    return adRevenue + iapRevenue;
  }

  static String formatRevenueMetric(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }
}
