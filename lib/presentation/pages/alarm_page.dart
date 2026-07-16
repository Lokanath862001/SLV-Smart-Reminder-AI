import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/tts/tts_service.dart';
import '../../core/vibration/vibration_service.dart';
import '../../data/models/reminder_model.dart';
import '../state/reminder_state.dart';
import '../state/settings_state.dart';

class AlarmPage extends ConsumerStatefulWidget {
  final String reminderId;
  const AlarmPage({super.key, required this.reminderId});

  @override
  ConsumerState<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends ConsumerState<AlarmPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  final List<BubbleParticle> _particles = [];
  Timer? _ttsTimer;
  Timer? _vibrateTimer;
  ReminderModel? _reminder;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(() {
        _updateParticles();
      })..repeat();

    _generateParticles();
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(BubbleParticle(
        x: random.nextDouble(),
        y: random.nextDouble() * 1.2,
        size: random.nextDouble() * 12 + 6,
        speed: random.nextDouble() * 0.005 + 0.002,
        opacity: random.nextDouble() * 0.3 + 0.1,
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      for (var p in _particles) {
        p.y -= p.speed;
        if (p.y < -0.1) {
          p.y = 1.1;
          p.x = math.Random().nextDouble();
        }
      }
    });
  }

  void _setupAlarmsAndTTS() {
    if (_reminder == null) return;
    
    // Voice loop
    final spokenText = _reminder!.voiceMessage.isNotEmpty 
        ? _reminder!.voiceMessage 
        : "Time for ${_reminder!.title}. ${_reminder!.subtitle}";
        
    TtsService.speak(spokenText);
    _ttsTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      TtsService.speak(spokenText);
    });

    // Vibration loop
    if (_reminder!.vibrationEnabled) {
      VibrationService.vibrateAlarm();
      _vibrateTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        VibrationService.vibrateAlarm();
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _ttsTimer?.cancel();
    _vibrateTimer?.cancel();
    TtsService.stop();
    VibrationService.cancel();
    super.dispose();
  }

  void _actionDone() {
    if (_reminder != null) {
      ref.read(reminderProvider.notifier).toggleComplete(_reminder!.id);
    }
    Navigator.of(context).pop();
  }

  void _actionSkip() {
    // If recurring, reschedule to next, else dismiss
    if (_reminder != null) {
      if (_reminder!.repeatOption == 'Once') {
        ref.read(reminderProvider.notifier).deleteReminder(_reminder!.id);
      } else {
        // Just dismiss alarm state
      }
    }
    Navigator.of(context).pop();
  }

  void _showSnoozeOptions() {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Snooze Reminder",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _snoozeChip(5),
                  _snoozeChip(10),
                  _snoozeChip(15),
                  _snoozeChip(30),
                  _snoozeChip(60),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _snoozeChip(int minutes) {
    return ActionChip(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      label: Text("$minutes min"),
      onPressed: () {
        ref.read(reminderProvider.notifier).snoozeReminder(_reminder!.id, minutes);
        Navigator.pop(context); // close sheet
        Navigator.pop(context); // close AlarmPage
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final list = ref.watch(reminderProvider);
      try {
        _reminder = list.firstWhere((r) => r.id == widget.reminderId);
        _setupAlarmsAndTTS();
      } catch (_) {
        // Fallback placeholder model if not found
        _reminder = ReminderModel(
          id: widget.reminderId,
          title: "Smart Reminder",
          subtitle: "Attention Required",
          description: "",
          category: "General",
          priority: "High",
          dateTime: DateTime.now(),
          repeatOption: "Once",
          iconCodePoint: Icons.notifications.codePoint,
          colorValue: Colors.deepPurpleAccent.value,
          emoji: "⏰",
          voiceMessage: "Attention Required",
          soundEnabled: true,
          vibrationEnabled: true,
          flashEnabled: false,
          isCompleted: false,
          isMissed: false,
          snoozeCount: 0,
          createdAt: DateTime.now(),
          notes: "",
        );
        _setupAlarmsAndTTS();
      }
      _initialized = true;
    }

    final reminderColor = Color(_reminder?.colorValue ?? Colors.deepPurpleAccent.value);
    final formattedTime = DateFormat('hh:mm a').format(DateTime.now());

    return Scaffold(
      body: Stack(
        children: [
          // Liquid Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  reminderColor.withOpacity(0.85),
                  Theme.of(context).scaffoldBackgroundColor,
                  reminderColor.withOpacity(0.2),
                ],
              ),
            ),
          ),
          
          // Bubbles
          CustomPaint(
            painter: BubblePainter(particles: _particles, color: reminderColor),
            child: Container(),
          ),

          // Main contents
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header (Current Time & Status)
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: Column(
                    children: [
                      Text(
                        formattedTime,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontWeight: FontWeight.w900,
                          fontSize: 64,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _reminder?.category.toUpperCase() ?? "REMINDER",
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Icon with Halo Animation
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Outer Halo
                      RotationTransition(
                        turns: _rotationController,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: reminderColor.withOpacity(0.2),
                              width: 6,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      ),
                      
                      // Pulsing inner ring
                      ScaleTransition(
                        scale: Tween(begin: 0.9, end: 1.15).animate(
                          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                        ),
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: reminderColor.withOpacity(0.15),
                            boxShadow: [
                              BoxShadow(
                                color: reminderColor.withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Core Icon container
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _reminder?.emoji ?? "⏰",
                          style: const TextStyle(fontSize: 60),
                        ),
                      ),
                    ],
                  ),
                ),

                // Title and description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        _reminder?.title ?? "",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _reminder?.subtitle ?? _reminder?.description ?? "",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Alarm Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
                  child: Row(
                    children: [
                      // Skip
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2)),
                            minimumSize: const Size.fromHeight(60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: _actionSkip,
                          child: Text(
                            "Skip",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Done/Complete
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: reminderColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                          ),
                          onPressed: _actionDone,
                          child: const Text(
                            "Done",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Snooze
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2)),
                            minimumSize: const Size.fromHeight(60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: _showSnoozeOptions,
                          child: Text(
                            "Snooze",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class BubbleParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  BubbleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class BubblePainter extends CustomPainter {
  final List<BubbleParticle> particles;
  final Color color;

  BubblePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = color.withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
