import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import './ai_game/ai_easy.dart';
import './ai_game/ai_medium.dart';
import './ai_game/ai_hard.dart';
import './person_game/person_easy.dart';
import './person_game/person_medium.dart';
import './person_game/person_hard.dart';
import './sound_manager.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _isMuted = false;

 @override
void initState() {
  super.initState();

  _scaleController = AnimationController(
    duration: const Duration(milliseconds: 1200),
    vsync: this,
  );
  _scaleController.forward();

  // 🎵 AUTO START HOME MUSIC

}

@override
void dispose() {
  _scaleController.dispose();
  super.dispose();
}



 


  void _showPlayModeSelection() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PlayModeSelectionPopup(
          onPlayModeSelect: (isAI) {
            Navigator.pop(context);
            if (isAI) {
              _showAIDifficultyPopup();
            } else {
              _showPersonDifficultyPopup();
            }
          },
        );
      },
    );
  }

  void _showAIDifficultyPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AIGameDifficultyPopup(
          onDifficultySelect: (difficulty) {
            Navigator.pop(context);
            _showGameRulesPopup(isAI: true, difficulty: difficulty);
          },
        );
      },
    );
  }

  void _showPersonDifficultyPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PersonGameDifficultyPopup(
          onDifficultySelect: (difficulty) {
            Navigator.pop(context);
            _showGameRulesPopup(isAI: false, difficulty: difficulty);
          },
        );
      },
    );
  }

  void _showGameRulesPopup({required bool isAI, required String difficulty}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameRulesPopup(
          isAI: isAI,
          difficulty: difficulty,
          onStartGame: () {
            Navigator.pop(context);
            _startGame(isAI: isAI, difficulty: difficulty);
          },
        );
      },
    );
  }

void _startGame({required bool isAI, required String difficulty}) {
  // ✅ Guard: prevents crash if widget disposed
  if (!mounted) return;

  // 🔇 Stop home music
  SoundManager.stopHomeMusic();

  final Widget screen = _getGameScreen(
    isAI: isAI,
    difficulty: difficulty,
  );

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => screen),
  );
}



 Widget _getGameScreen({
  required bool isAI,
  required String difficulty,
}) {
  if (isAI) {
    switch (difficulty) {
      case 'easy':
        return const AiEasyGame();
      case 'medium':
        return const AiMediumGame();
      case 'hard':
      default:
        return const AiHardGame();
    }
  } else {
    switch (difficulty) {
      case 'easy':
        return const PersonEasyGame();
      case 'medium':
        return const PersonMediumGame();
      case 'hard':
      default:
        return const PersonHardGame();
    }
  }
}


 void _toggleMute() {
  setState(() {
    _isMuted = !_isMuted;
  });

  SoundManager.setMuted(_isMuted);

  if (!_isMuted) {
    SoundManager.playHomeMusic();
  }
}



  Future<void> _openLink(String url) async {
  try {
    final uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Launch failed';
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open link')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A2F),
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A1A2F),
                      const Color(0xFF1a3a52),
                      const Color(0xFF0A1A2F),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Animated background orbs
            Positioned(
              top: -150,
              right: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue.withOpacity(0.1),
                      Colors.blue.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -120,
              left: -120,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.withOpacity(0.08),
                      Colors.purple.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.blue[300]!, Colors.cyan[300]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'DOTS & BOXES',
                            style: TextStyle(
                              fontFamily: 'Bungee',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
  SoundManager.click();
  _toggleMute();
},

                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isMuted
                                    ? [
                                        Colors.grey.withOpacity(0.6),
                                        Colors.grey.withOpacity(0.4)
                                      ]
                                    : [
                                        Colors.blue.withOpacity(0.6),
                                        Colors.cyan.withOpacity(0.4)
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isMuted
                                      ? Colors.grey.withOpacity(0.4)
                                      : Colors.blue.withOpacity(0.4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Logo and title
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _scaleController,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Logo
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.3),
                                Colors.cyan.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.cyan.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo_rb.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.games_outlined,
                                size: 70,
                                color: Colors.cyan.withOpacity(0.8),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Main title
                        const Text(
                          'DOTS & BOXES',
                          style: TextStyle(
                            fontFamily: 'Bungee',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.2),
                                Colors.cyan.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.cyan.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Premium Edition',
                            style: TextStyle(
                              fontFamily: 'Bungee',
                              fontSize: 13,
                              color: Colors.cyan,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Play Mode Buttons
                 Padding(
  padding: const EdgeInsets.symmetric(horizontal: 30),
  child: Column(
    children: [
      // Play with AI button
      Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade600,
              Colors.cyan.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              SoundManager.click();
              _showAIDifficultyPopup();
            },
            borderRadius: BorderRadius.circular(16),
            child: const Center(
              child: Text(
                'PLAY WITH AI',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),

      const SizedBox(height: 16),

      // Play with Person button
      Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade600,
              Colors.pink.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.5),
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              SoundManager.click();
              _showPersonDifficultyPopup();
            },
            borderRadius: BorderRadius.circular(16),
            child: const Center(
              child: Text(
                'PLAY WITH PERSON',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),


                  // Social buttons footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Follow Us',
                          style: TextStyle(
                            fontFamily: 'Bungee',
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              icon: Icons.message_rounded,
                              gradient: [
                                Colors.green.shade700,
                                Colors.green.shade500,
                              ],
                              onTap: () =>
                                  _openLink('https://wa.me/+9146293702'),
                            ),
                            const SizedBox(width: 20),
                            _buildSocialButton(
                              icon: Icons.camera_alt_rounded,
                              gradient: [
                                Colors.pink.shade700,
                                Colors.pink.shade500,
                              ],
                              onTap: () => _openLink(
                                  'https://instagram.com/aniket_jamunde_002'),
                            ),
                            const SizedBox(width: 20),
                            _buildSocialButton(
                              icon: Icons.language_rounded,
                              gradient: [
                                Colors.blue.shade700,
                                Colors.blue.shade500,
                              ],
                              onTap: () =>
                                  _openLink('https://aniketwebdev.netlify.app'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// Play Mode Selection Popup
class PlayModeSelectionPopup extends StatelessWidget {
  final Function(bool) onPlayModeSelect; // true = AI, false = Person

  const PlayModeSelectionPopup({super.key, required this.onPlayModeSelect});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1A2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Game Mode',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 30),
              _buildModeOption(
                context,
                'Play with AI',
                'Challenge the computer',
                Colors.blue,
                true,
              ),
              const SizedBox(height: 12),
              _buildModeOption(
                context,
                'Play with Person',
                'Play with another player',
                Colors.purple,
                false,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
 Navigator.pop(context);
SoundManager.cancel();


},
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    bool isAI,
  ) {
    return GestureDetector(
      onTap: () => onPlayModeSelect(isAI),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// AI Game Difficulty Popup
class AIGameDifficultyPopup extends StatelessWidget {
  final Function(String) onDifficultySelect;

  const AIGameDifficultyPopup({super.key, required this.onDifficultySelect});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1A2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select AI Difficulty',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 30),
              _buildDifficultyOption(
                context,
                'Easy',
                'AI makes random moves',
                Colors.green,
                'easy',
              ),
              const SizedBox(height: 12),
              _buildDifficultyOption(
                context,
                'Medium',
                'AI uses basic strategy',
                Colors.orange,
                'medium',
              ),
              const SizedBox(height: 12),
              _buildDifficultyOption(
                context,
                'Hard',
                'AI plays optimally',
                Colors.red,
                'hard',
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
  Navigator.pop(context);
SoundManager.cancel();

},
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    String difficulty,
  ) {
    return GestureDetector(
      onTap: () => onDifficultySelect(difficulty),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// Person Game Difficulty Popup
class PersonGameDifficultyPopup extends StatelessWidget {
  final Function(String) onDifficultySelect;

  const PersonGameDifficultyPopup({super.key, required this.onDifficultySelect});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1A2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Game Mode',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 30),
              _buildDifficultyOption(
                context,
                'Easy (4x4)',
                'Small grid',
                Colors.green,
                'easy',
              ),
              const SizedBox(height: 12),
              _buildDifficultyOption(
                context,
                'Medium (5x5)',
                'Medium grid',
                Colors.orange,
                'medium',
              ),
              const SizedBox(height: 12),
              _buildDifficultyOption(
                context,
                'Hard (6x6)',
                'Large grid',
                Colors.red,
                'hard',
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
  Navigator.pop(context);
SoundManager.cancel();

},
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    String difficulty,
  ) {
    return GestureDetector(
      onTap: () => onDifficultySelect(difficulty),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// Game Rules Popup
class GameRulesPopup extends StatelessWidget {
  final bool isAI;
  final String difficulty;
  final VoidCallback onStartGame;

  const GameRulesPopup({
    super.key,
    required this.isAI,
    required this.difficulty,
    required this.onStartGame,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1A2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Game Rules',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              _buildRuleItem(
                icon: Icons.grid_3x3,
                title: 'The Board',
                description:
                    'The game is played on a dot grid. Players take turns drawing lines.',
                iconColor: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildRuleItem(
                icon: Icons.touch_app,
                title: 'Draw Lines',
                description:
                    'Tap to draw lines between adjacent dots on the grid.',
                iconColor: Colors.cyan,
              ),
              const SizedBox(height: 16),
              _buildRuleItem(
                icon: Icons.layers,
                title: 'Claim Boxes',
                description:
                    'Complete the 4th side of a box to claim it with your color.',
                iconColor: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildRuleItem(
                icon: Icons.star,
                title: 'Bonus Turn',
                description:
                    'Get another turn when you complete a box. Plan your moves wisely!',
                iconColor: Colors.amber,
              ),
              const SizedBox(height: 16),
              _buildRuleItem(
                icon: Icons.emoji_events,
                title: 'Win',
                description:
                    'The player with the most boxes at the end of the game wins!',
                iconColor: Colors.orange,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
 Navigator.pop(context);
SoundManager.cancel();

},
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
  Navigator.pop(context);
SoundManager.cancel();

},
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: Text(
                                'Back',
                                style: TextStyle(
                                  fontFamily: 'Bungee',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: onStartGame,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade600,
                              Colors.green.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onStartGame,
                            borderRadius: BorderRadius.circular(14),
                            child: const Center(
                              child: Text(
                                'Start Game',
                                style: TextStyle(
                                  fontFamily: 'Bungee',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [iconColor.withOpacity(0.8), iconColor.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.75),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}