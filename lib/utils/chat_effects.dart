import 'dart:math';

enum EffectMotion { floatUp, fallDown, burstOutward, custom }

class ChatEffect {
  final String word;
  final String lottieAsset;
  final EffectMotion? motion; // null = random each time
  final double size;
  final int priority; // higher wins when multiple words match one message
  final bool once; // true = only ever plays once per conversation

  const ChatEffect({
    required this.word,
    required this.lottieAsset,
    required this.priority,
    this.motion,
    this.size = 160,
    this.once = false,
  });
}

/// All assets are expected at assets/lottie/<file>.json — filenames below
/// are locked in, so dropping real files in later needs zero code changes.
const List<ChatEffect> chatEffectsList = [
  // ---- Rare / hidden (highest priority, once per conversation) ----
  ChatEffect(
    word: 'marry me',
    lottieAsset: 'assets/lottie/ring_box.json',
    priority: 130,
    motion: EffectMotion.burstOutward,
    once: true,
  ),
  ChatEffect(
    word: 'anniversary',
    lottieAsset: 'assets/lottie/anniversary_fireworks.json',
    priority: 129,
    motion: EffectMotion.burstOutward,
    once: true,
  ),
  ChatEffect(
    word: 'best friend',
    lottieAsset: 'assets/lottie/friendship_stars.json',
    priority: 128,
    once: true,
  ),
  ChatEffect(
    word: 'galaxy',
    lottieAsset: 'assets/lottie/galaxy_spin.json',
    priority: 127,
    once: true,
  ),
  ChatEffect(
    word: 'wish',
    lottieAsset: 'assets/lottie/shooting_star.json',
    priority: 126,
    motion: EffectMotion.floatUp,
    once: true,
  ),
  ChatEffect(
    word: 'coffee',
    lottieAsset: 'assets/lottie/coffee_steam.json',
    priority: 125,
    motion: EffectMotion.floatUp,
    once: true,
  ),
  ChatEffect(
    word: 'pizza',
    lottieAsset: 'assets/lottie/pizza_spin.json',
    priority: 124,
    once: true,
  ),
  ChatEffect(
    word: 'party',
    lottieAsset: 'assets/lottie/confetti.json',
    priority: 123,
    motion: EffectMotion.fallDown,
    once: true,
  ),
  ChatEffect(
    word: 'dance',
    lottieAsset: 'assets/lottie/dance_lights.json',
    priority: 122,
    once: true,
  ),
  ChatEffect(
    word: 'congratulations',
    lottieAsset: 'assets/lottie/celebration.json',
    priority: 121,
    motion: EffectMotion.burstOutward,
    once: true,
  ),
  ChatEffect(
    word: 'birthday',
    lottieAsset: 'assets/lottie/birthday_cake.json',
    priority: 120,
    once: true,
  ),
  ChatEffect(
    word: 'cry',
    lottieAsset: 'assets/lottie/rain_cloud.json',
    priority: 119,
    motion: EffectMotion.fallDown,
    once: true,
  ),
  ChatEffect(
    word: 'sad',
    lottieAsset: 'assets/lottie/rain_cloud.json',
    priority: 119,
    motion: EffectMotion.fallDown,
    once: true,
  ),

  // ---- Everyday / romance / pride (regular tier) ----
  ChatEffect(
    word: 'i love you',
    lottieAsset: 'assets/lottie/heart_burst.json',
    priority: 20,
    motion: EffectMotion.burstOutward,
  ),
  ChatEffect(
    word: 'love',
    lottieAsset: 'assets/lottie/heart_burst.json',
    priority: 17,
    motion: EffectMotion.burstOutward,
  ),
  ChatEffect(
    word: 'soulmate',
    lottieAsset: 'assets/lottie/soulmate_stars.json',
    priority: 16,
  ),
  ChatEffect(
    word: 'date night',
    lottieAsset: 'assets/lottie/romantic_date.json',
    priority: 15,
  ),
  ChatEffect(
    word: 'date',
    lottieAsset: 'assets/lottie/romantic_date.json',
    priority: 14,
  ),
  ChatEffect(
    word: 'meetup',
    lottieAsset: 'assets/lottie/meetup_location.json',
    priority: 13,
  ),
  ChatEffect(
    word: 'meet up',
    lottieAsset: 'assets/lottie/meetup_location.json',
    priority: 13,
  ),
  ChatEffect(
    word: 'match',
    lottieAsset: 'assets/lottie/match_success.json',
    priority: 12,
  ),
  ChatEffect(
    word: 'kiss',
    lottieAsset: 'assets/lottie/kiss_sparkle.json',
    priority: 11,
    motion: EffectMotion.burstOutward,
  ),
  ChatEffect(
    word: 'hug',
    lottieAsset: 'assets/lottie/hug_animation.json',
    priority: 10,
  ),
  ChatEffect(
    word: 'hookup',
    lottieAsset: 'assets/lottie/neon_flame.json',
    priority: 9,
  ),
  ChatEffect(
    word: 'miss you',
    lottieAsset: 'assets/lottie/floating_heart.json',
    priority: 8,
    motion: EffectMotion.floatUp,
  ),
  ChatEffect(
    word: 'forever',
    lottieAsset: 'assets/lottie/infinity_particles.json',
    priority: 7,
  ),
  ChatEffect(
    word: 'fire',
    lottieAsset: 'assets/lottie/fire_glow.json',
    priority: 6,
  ),
  ChatEffect(
    word: 'hot',
    lottieAsset: 'assets/lottie/fire_glow.json',
    priority: 6,
  ),
  ChatEffect(
    word: 'magic',
    lottieAsset: 'assets/lottie/magic_dust.json',
    priority: 5,
  ),
  ChatEffect(
    word: 'flower',
    lottieAsset: 'assets/lottie/rose_bloom.json',
    priority: 4,
    motion: EffectMotion.fallDown,
  ),
  ChatEffect(
    word: 'rose',
    lottieAsset: 'assets/lottie/rose_bloom.json',
    priority: 4,
    motion: EffectMotion.fallDown,
  ),
  ChatEffect(
    word: 'good morning',
    lottieAsset: 'assets/lottie/sunrise.json',
    priority: 3,
    motion: EffectMotion.floatUp,
  ),
  ChatEffect(
    word: 'good night',
    lottieAsset: 'assets/lottie/moon_glow.json',
    priority: 3,
    motion: EffectMotion.floatUp,
  ),

  // ---- Pride / identity ----
  ChatEffect(
    word: 'rainbow',
    lottieAsset: 'assets/lottie/pride_rainbow.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'pride',
    lottieAsset: 'assets/lottie/pride_rainbow.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'queer',
    lottieAsset: 'assets/lottie/pride_sparkles.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'gay',
    lottieAsset: 'assets/lottie/pride_sparkles.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'lesbian',
    lottieAsset: 'assets/lottie/pride_sparkles.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'bisexual',
    lottieAsset: 'assets/lottie/pride_sparkles.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'bi',
    lottieAsset: 'assets/lottie/pride_sparkles.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'trans',
    lottieAsset: 'assets/lottie/pride_sparkles.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'pansexual',
    lottieAsset: 'assets/lottie/pride_sparkles.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'pan',
    lottieAsset: 'assets/lottie/pride_sparkles.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'asexual',
    lottieAsset: 'assets/lottie/pride_sparkles.json',
    priority: 18,
  ),
  ChatEffect(
    word: 'ace',
    lottieAsset: 'assets/lottie/pride_sparkles.json',
    priority: 18,
  ),
];

class ChatEffectMatcher {
  static final _rand = Random();

  /// [alreadyPlayed] = set of trigger words already fired this conversation.
  /// Pass it in from your screen state; matched `once` effects get added to it.
  static ChatEffect? findEffect(String message, Set<String> alreadyPlayed) {
    final lower = message.toLowerCase();

    final matches = chatEffectsList.where((effect) {
      if (effect.once && alreadyPlayed.contains(effect.word)) return false;
      final pattern = RegExp(r'\b' + RegExp.escape(effect.word) + r'\b');
      return pattern.hasMatch(lower);
    }).toList();

    if (matches.isEmpty) return null;

    matches.sort((a, b) => b.priority.compareTo(a.priority));
    final chosen = matches.first;
    if (chosen.once) alreadyPlayed.add(chosen.word);
    return chosen;
  }

  static EffectMotion randomMotion() {
    const motions = [
      EffectMotion.floatUp,
      EffectMotion.fallDown,
      EffectMotion.burstOutward,
    ];
    return motions[_rand.nextInt(motions.length)];
  }
}
