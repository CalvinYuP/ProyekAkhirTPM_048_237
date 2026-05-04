// lib/features/game/screens/game_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';

// --- MODEL KARTU ---
class MemoryCard {
  final String motif;
  final String imagePath;
  final int id;
  bool isFlipped;
  bool isMatched;
  
  MemoryCard({
    required this.motif,
    required this.imagePath,
    required this.id,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // --- STATE GAME ---
  List<MemoryCard> cards = [];
  List<int> selectedIndices = [];
  int moves = 0;
  int matches = 0;
  bool isProcessing = false;
  bool isGameActive = false;
  
  // --- TIMER & SKOR ---
  Timer? _timer;
  int seconds = 0;
  int score = 0;
  int highScore = 0;
  
  // --- SENSOR LIMITS ---
  int shakeUses = 2;
  int hintUses = 3;
  bool isShaking = false;
  bool isTilting = false;
  StreamSubscription? _shakeSub;
  StreamSubscription? _gyroSub;
  
  // --- AUDIO PLAYER ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // --- PREVIEW STATE ---
  bool _isPreviewMode = false;
  int _previewCountdown = 5;
  Timer? _countdownTimer;
  
  // --- ANIMATION CONTROLLER UNTUK COUNTDOWN ---
  late AnimationController _countdownAnimController;
  late Animation<double> _countdownScaleAnimation;
  late Animation<double> _countdownOpacityAnimation;
  
  // --- DATA MOTIF BATIK dengan Path Gambar ---
  final List<Map<String, String>> motifData = [
    {'name': 'Parang', 'image': 'assets/images/motif_batik/parang.jpg'},
    {'name': 'Kawung', 'image': 'assets/images/motif_batik/kawung.jpg'},
    {'name': 'Nitik', 'image': 'assets/images/motif_batik/nitik.jpg'},
    {'name': 'Truntum', 'image': 'assets/images/motif_batik/truntum.jpg'},
    {'name': 'Sido Mukti', 'image': 'assets/images/motif_batik/sidomukti.jpg'},
    {'name': 'Ceplok', 'image': 'assets/images/motif_batik/ceplok.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    
    _countdownAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _countdownScaleAnimation = Tween<double>(begin: 2.0, end: 1.0).animate(
      CurvedAnimation(parent: _countdownAnimController, curve: Curves.elasticOut),
    );
    
    _countdownOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _countdownAnimController, curve: Curves.easeIn),
    );
    
    _loadHighScore();
    _initGame();
    _startPreview();
    _initSensors();
  }

  // ✅ LOAD HIGH SCORE PER USER
  void _loadHighScore() async {
    final box = await Hive.openBox('game_scores');
    final storage = StorageService();
    final username = storage.currentUsername ?? 'default';
    final key = '${username}_high_score';
    
    setState(() => highScore = box.get(key, defaultValue: 0));
  }

  void _initGame() {
    List<MemoryCard> deck = [];
    for (int i = 0; i < motifData.length; i++) {
      deck.add(MemoryCard(motif: motifData[i]['name']!, imagePath: motifData[i]['image']!, id: i * 2));
      deck.add(MemoryCard(motif: motifData[i]['name']!, imagePath: motifData[i]['image']!, id: i * 2 + 1));
    }
    deck.shuffle(Random());
    
    setState(() {
      cards = deck;
      selectedIndices = [];
      moves = 0;
      matches = 0;
      seconds = 0;
      score = 0;
      isGameActive = false;
      shakeUses = 2;
      hintUses = 3;
      isProcessing = false;
    });
  }

  void _startPreview() {
    setState(() {
      _isPreviewMode = true;
      _previewCountdown = 5;
      for (var card in cards) {
        card.isFlipped = true;
      }
    });
    
    _animateCountdown();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_previewCountdown > 1) {
        setState(() => _previewCountdown--);
        _animateCountdown();
      } else {
        timer.cancel();
        _endPreview();
      }
    });
  }
  
  void _animateCountdown() {
    _countdownAnimController.reset();
    _countdownAnimController.forward();
  }
  
  void _endPreview() {
    setState(() {
      for (var card in cards) {
        card.isFlipped = false;
      }
      _isPreviewMode = false;
      isGameActive = true;
    });
    
    _startTimer();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Permainan dimulai! Temukan pasangan batiknya.',
                  style: TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isGameActive) {
        setState(() => seconds++);
      }
    });
  }

  void _initSensors() {
    _shakeSub = userAccelerometerEventStream().listen((event) {
      if (!isGameActive || isShaking || _isPreviewMode) return;
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      if (magnitude > 2.5 && shakeUses > 0) {
        _triggerShuffle();
      }
    });

    _gyroSub = gyroscopeEventStream().listen((event) {
      if (!isGameActive || isTilting || _isPreviewMode) return;
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      if (magnitude > 2.0 && hintUses > 0) {
        _triggerHint();
      }
    });
  }

  Future<void> _triggerShuffle() async {
    HapticFeedback.mediumImpact();
    setState(() { isShaking = true; shakeUses--; });
    
    List<MemoryCard> unmatched = cards.where((c) => !c.isMatched).toList();
    unmatched.shuffle(Random());
    
    int idx = 0;
    for (int i = 0; i < cards.length; i++) {
      if (!cards[i].isMatched) {
        cards[i] = unmatched[idx++];
      }
    }
    
    for (int i in selectedIndices) {
      cards[i].isFlipped = false;
    }
    selectedIndices.clear();
    isProcessing = false;
    
    setState(() {
      cards = List.from(cards);
      isShaking = false;
    });
  }

  Future<void> _triggerHint() async {
    if (hintUses <= 0 || isProcessing) return;
    HapticFeedback.lightImpact();
    setState(() { isTilting = true; hintUses--; });
    
    List<int> availableIndices = [];
    for (int i = 0; i < cards.length; i++) {
      if (!cards[i].isFlipped && !cards[i].isMatched && !selectedIndices.contains(i)) {
        availableIndices.add(i);
      }
    }
    
    if (availableIndices.length >= 2) {
      availableIndices.shuffle();
      final hintIdx = availableIndices.sublist(0, 2);
      
      setState(() {
        for (int idx in hintIdx) {
          cards[idx].isFlipped = true;
        }
      });
      
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted && isGameActive) {
        setState(() {
          for (int idx in hintIdx) {
            cards[idx].isFlipped = false;
          }
          isTilting = false;
        });
      }
    } else {
      setState(() => isTilting = false);
    }
  }

  void _onCardTap(int index) {
    if (!isGameActive || isProcessing || _isPreviewMode) return;
    if (cards[index].isFlipped || cards[index].isMatched) return;
    
    setState(() {
      cards[index].isFlipped = true;
      selectedIndices.add(index);
    });
    
    if (selectedIndices.length == 2) {
      moves++;
      isProcessing = true;
      _checkMatch();
    }
  }

  Future<void> _checkMatch() async {
    final first = selectedIndices[0];
    final second = selectedIndices[1];
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (cards[first].motif == cards[second].motif) {
      setState(() {
        cards[first].isMatched = true;
        cards[second].isMatched = true;
        matches++;
        selectedIndices.clear();
        isProcessing = false;
      });
      
      await _playSound('audio/match.wav');
      
      if (matches == motifData.length) _finishGame();
    } else {
      setState(() {
        cards[first].isFlipped = false;
        cards[second].isFlipped = false;
        selectedIndices.clear();
        isProcessing = false;
      });
    }
  }

  // ✅ FINISH GAME - SAVE SCORE PER USER
  void _finishGame() {
    isGameActive = false;
    _timer?.cancel();
    
    score = max(0, 1000 - (moves * 10) - (seconds * 1));
    
    if (score > highScore) {
      highScore = score;
      
      final storage = StorageService();
      final username = storage.currentUsername ?? 'default';
      final key = '${username}_high_score';
      
      Hive.box('game_scores').put(key, highScore);
    }
    
    _playSound('audio/win.wav');
    HapticFeedback.vibrate();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _showWinDialog();
    });
  }

  Future<void> _playSound(String fileName) async {
    try {
      await _audioPlayer.play(AssetSource(fileName));
    } catch (_) {}
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Row(children: [
          Icon(Icons.emoji_events, color: Colors.amber[700], size: 28),
          const SizedBox(width: 8),
          const Text('Selamat!', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Skor Akhir: $score', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          if (score >= highScore && score > 0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: const Text('🏆 REKOR BARU!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 16),
          Text('Waktu: ${Duration(seconds: seconds).toString().split('.').first} | Langkah: $moves', style: TextStyle(color: AppColors.textSecondary)),
        ]),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Tutup', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () { context.pop(); _initGame(); _startPreview(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Main Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _countdownAnimController.dispose();
    _shakeSub?.cancel();
    _gyroSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryLight), onPressed: () => context.pop()),
        title: const Text('Batik Memory Match'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primaryLight,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primaryLight),
                  const SizedBox(width: 4),
                  Text(
                    Duration(seconds: seconds).toString().split('.').first,
                    style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // ✅ Status Bar - DENGAN FLEXIBLE UNTUK MENCEGAH OVERFLOW
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // ✅ Langkah - Flexible
              Expanded(
                flex: 3,
                child: _buildStatusChip(Icons.touch_app_rounded, 'Langkah: $moves', AppColors.accent),
              ),
              
              // ✅ Countdown Preview (hanya saat preview)
              if (_isPreviewMode) ...[
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: AnimatedBuilder(
                    animation: _countdownAnimController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _countdownScaleAnimation.value,
                        child: Opacity(
                          opacity: _countdownOpacityAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.remove_red_eye_rounded, color: AppColors.primaryLight, size: 14),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Hafalkan! $_previewCountdown detik',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              if (!_isPreviewMode) const Spacer(),
              
              // ✅ Skor - Flexible
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: _buildStatusChip(Icons.star_rounded, 'Skor: $score', Colors.amber),
              ),
            ],
          ),
        ),
        
        // ✅ Sensor Badges
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSensorBadge('📳 Goyang', shakeUses),
              const SizedBox(width: 12),
              _buildSensorBadge('📐 Miring', hintUses),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // ✅ Game Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              physics: _isPreviewMode ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return GestureDetector(
                  onTap: () => _onCardTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: card.isFlipped || card.isMatched ? AppColors.surface : AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: (card.isFlipped || card.isMatched ? AppColors.primary : Colors.black).withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4))],
                      border: card.isMatched ? Border.all(color: Colors.green, width: 3) : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: card.isFlipped || card.isMatched
                          ? Stack(fit: StackFit.expand, children: [
                              Image.asset(card.imagePath, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                                return Container(color: AppColors.primaryLight, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.brush_rounded, color: AppColors.primary, size: 28),
                                  const SizedBox(height: 4),
                                  Text(card.motif, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center),
                                ]));
                              }),
                              Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent])),
                                  child: Text(card.motif, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ])
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.3), shape: BoxShape.circle), child: const Icon(Icons.pattern_rounded, color: Colors.white, size: 24)),
                              const SizedBox(height: 6),
                              Text('BATIK', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 2)),
                            ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // ✅ Footer
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('High Score: $highScore', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w500)),
              if (_isPreviewMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_rounded, color: AppColors.accent, size: 12),
                      const SizedBox(width: 4),
                      Text('Tutup dalam $_previewCountdown detik', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  // ✅ Status Chip - DENGAN FLEXIBLE
  Widget _buildStatusChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Sensor Badge - DENGAN FLEXIBLE
  Widget _buildSensorBadge(String label, int uses) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: uses > 0 ? AppColors.accent.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text('($uses)', style: TextStyle(fontSize: 10, color: uses > 0 ? AppColors.primary : Colors.grey)),
        ],
      ),
    );
  }
}