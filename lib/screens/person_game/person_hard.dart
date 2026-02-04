import 'package:flutter/material.dart';
import '../sound_manager.dart';

class PersonHardGame extends StatefulWidget {
  const PersonHardGame({super.key});

  @override
  State<PersonHardGame> createState() => _PersonHardGameState();
}

class _PersonHardGameState extends State<PersonHardGame>
    with TickerProviderStateMixin {
  static const int gridSize = 5;
  static const double dotRadius = 8;
  static const double spacing = 60;
  static const double offset = 30;

  late List<List<int>> horizontalLines;
  late List<List<int>> verticalLines;
  late List<List<int>> boxes;

  int player1Score = 0;
  int player2Score = 0;
  bool isPlayer1Turn = true;
  bool gameOver = false;
  String gameStatus = 'Player 1: Drag dot to dot';
  String? errorMessage;

  Offset? dragStartDot;
  Offset? dragCurrentPos;

  late AnimationController _animationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _setupAnimations();

    // ✅ Start animation safely ONCE
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward(); // ✅ SAFE

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  void _initializeGame() {
    horizontalLines = List.generate(
      gridSize + 1,
      (_) => List.filled(gridSize, 0),
    );
    verticalLines = List.generate(
      gridSize,
      (_) => List.filled(gridSize + 1, 0),
    );
    boxes = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    player1Score = 0;
    player2Score = 0;
    isPlayer1Turn = true;
    gameOver = false;
    gameStatus = 'Player 1: Drag dot to dot';
    dragStartDot = null;
    dragCurrentPos = null;
  }

  Map<String, int>? _getDotAt(Offset position) {
    for (int i = 0; i <= gridSize; i++) {
      for (int j = 0; j <= gridSize; j++) {
        double dotX = offset + j * spacing;
        double dotY = offset + i * spacing;
        if ((position.dx - dotX).abs() < 25 &&
            (position.dy - dotY).abs() < 25) {
          return {'row': i, 'col': j};
        }
      }
    }
    return null;
  }

  void _handleDragEnd(Offset endPosition) {
    if (dragStartDot == null || gameOver) {
      dragStartDot = null;
      dragCurrentPos = null;
      return;
    }

    final startDot = _getDotAt(dragStartDot!);
    final endDot = _getDotAt(endPosition);

    if (startDot == null || endDot == null) {
      _showError("Start and end on a dot!");
      dragStartDot = null;
      dragCurrentPos = null;
      return;
    }

    if (startDot['row'] == endDot['row'] && startDot['col'] == endDot['col']) {
      _showError("Connect two DIFFERENT dots!");
      dragStartDot = null;
      dragCurrentPos = null;
      return;
    }

    int r1 = startDot['row']!, c1 = startDot['col']!;
    int r2 = endDot['row']!, c2 = endDot['col']!;

    bool success = false;

    // Horizontal connection
    if (r1 == r2 && (c1 - c2).abs() == 1) {
      int col = c1 < c2 ? c1 : c2;
      if (horizontalLines[r1][col] == 0) {
        setState(() => horizontalLines[r1][col] = isPlayer1Turn ? 1 : 2);
        success = true;
      } else {
        _showError("Line already exists!");
      }
    }
    // Vertical connection
    else if (c1 == c2 && (r1 - r2).abs() == 1) {
      int row = r1 < r2 ? r1 : r2;
      if (verticalLines[row][c1] == 0) {
        setState(() => verticalLines[row][c1] = isPlayer1Turn ? 1 : 2);
        success = true;
      } else {
        _showError("Line already exists!");
      }
    } else {
      _showError("Only connect adjacent dots!");
    }

    if (success) {
      SoundManager.click(); // 🔊 line draw sound

      setState(() {
        bool boxCompleted = _checkForCompletedBoxes();

        if (!boxCompleted) {
          isPlayer1Turn = !isPlayer1Turn;
          gameStatus = isPlayer1Turn
              ? 'Player 1: Drag dot to dot'
              : 'Player 2: Drag dot to dot';
        } else {
          SoundManager.box(); // 🔊 box completed sound
          gameStatus = isPlayer1Turn
              ? 'Player 1 got a box! Your turn'
              : 'Player 2 got a box! Your turn';
        }

        _checkGameOver();
      });
    }

    dragStartDot = null;
    dragCurrentPos = null;
  }

  bool _checkForCompletedBoxes() {
    bool newlyCompleted = false;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (boxes[i][j] == 0 &&
            horizontalLines[i][j] != 0 &&
            horizontalLines[i + 1][j] != 0 &&
            verticalLines[i][j] != 0 &&
            verticalLines[i][j + 1] != 0) {
          boxes[i][j] = isPlayer1Turn ? 1 : 2;
          if (isPlayer1Turn) {
            player1Score++;
          } else {
            player2Score++;
          }
          newlyCompleted = true;
        }
      }
    }
    return newlyCompleted;
  }

  Future<void> _confirmExitGame() async {
    bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1A2F), Color(0xFF1a3a52)],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Exit Game?',
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 24,
                    color: Colors.red,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your current game will be lost!',
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: _exitButton(
                        label: 'NO',
                        color: Colors.blue,
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _exitButton(
                        label: 'YES',
                        color: Colors.red,
                        onTap: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldExit == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _checkGameOver() {
    if (gameOver) return; // ⛔ prevent double win sound

    if (player1Score + player2Score == gridSize * gridSize) {
      gameOver = true;
      gameStatus = player1Score > player2Score
          ? "Player 1 Wins!"
          : "Player 2 Wins!";

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          SoundManager.win();
          _showWinnerPopup();
        }
      });
    }
  }

  void _showError(String msg) {
    SoundManager.cancel(); // 🔊 error sound
    setState(() => errorMessage = msg);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => errorMessage = null);
    });
  }

  void _showWinnerPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildWinnerDialog(),
    );
  }

  Widget _exitButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Bungee',
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerDialog() {
    bool player1Wins = player1Score > player2Score;
    bool isTie = player1Score == player2Score;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF0A1A2F), const Color(0xFF1a3a52)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isTie
                ? Colors.amber.withOpacity(0.5)
                : (player1Wins
                      ? Colors.cyan.withOpacity(0.5)
                      : Colors.pink.withOpacity(0.5)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isTie
                  ? Colors.amber.withOpacity(0.3)
                  : (player1Wins
                        ? Colors.cyan.withOpacity(0.3)
                        : Colors.pink.withOpacity(0.3)),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy Icon
            ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Icon(
                Icons.emoji_events,
                size: 80,
                color: isTie
                    ? Colors.amber
                    : (player1Wins ? Colors.cyan : Colors.pink),
              ),
            ),
            const SizedBox(height: 30),

            // Winner Text
            Text(
              isTie
                  ? "It's a Tie!"
                  : player1Wins
                  ? "Player 1 Wins!"
                  : "Player 2 Wins!",
              style: TextStyle(
                fontFamily: 'Bungee',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isTie
                    ? Colors.amber
                    : (player1Wins ? Colors.cyan : Colors.pink),
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              isTie ? "Both players tied!" : "Congratulations!",
              style: TextStyle(
                fontFamily: 'Bungee',
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 30),

            // Final Scores
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Player 1',
                        style: TextStyle(
                          fontFamily: 'Bungee',
                          fontSize: 12,
                          color: Colors.cyan,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$player1Score',
                        style: const TextStyle(
                          fontFamily: 'Bungee',
                          fontSize: 32,
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Player 2',
                        style: TextStyle(
                          fontFamily: 'Bungee',
                          fontSize: 12,
                          color: Colors.pink,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$player2Score',
                        style: const TextStyle(
                          fontFamily: 'Bungee',
                          fontSize: 32,
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },

                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },

                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Text(
                              'HOME',
                              style: TextStyle(
                                fontFamily: 'Bungee',
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
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
                    onTap: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      setState(() => _initializeGame());
                    },

                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
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
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            setState(() => _initializeGame());
                          },

                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Text(
                              'REPLAY',
                              style: TextStyle(
                                fontFamily: 'Bungee',
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
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
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double boardSize = spacing * gridSize + (offset * 2);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A2F),
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // AppBar Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        SoundManager.cancel();
                        _confirmExitGame();
                      },

                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                    ),
                    const Text(
                      'PERSON HARD (5x5)',
                      style: TextStyle(
                        fontFamily: 'Bungee',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Scores Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreCard(
                      'Player 1',
                      player1Score,
                      Colors.cyan,
                      isPlayer1Turn,
                    ),
                    _buildScoreCard(
                      'Player 2',
                      player2Score,
                      Colors.pink,
                      !isPlayer1Turn,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Game Status
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: errorMessage != null
                        ? [
                            Colors.red.withOpacity(0.2),
                            Colors.red.withOpacity(0.1),
                          ]
                        : [
                            Colors.blue.withOpacity(0.2),
                            Colors.blue.withOpacity(0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: errorMessage != null
                        ? Colors.red.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    errorMessage ?? gameStatus,
                    style: TextStyle(
                      fontFamily: 'Bungee',
                      fontSize: 14,
                      color: errorMessage != null ? Colors.red : Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Game Board
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onPanStart: (details) =>
                        dragStartDot = details.localPosition,
                    onPanUpdate: (details) {
                      setState(() => dragCurrentPos = details.localPosition);
                    },

                    onPanEnd: (details) =>
                        _handleDragEnd(dragCurrentPos ?? Offset.zero),
                    onTapDown: (details) => _showError("Drag from dot to dot!"),
                    child: CustomPaint(
                      size: Size(boardSize, boardSize),
                      painter: GameBoardPainter(
                        horizontalLines: horizontalLines,
                        verticalLines: verticalLines,
                        boxes: boxes,
                        spacing: spacing,
                        gridSize: gridSize,
                        dragStartDot: dragStartDot,
                        dragCurrentPos: dragCurrentPos,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [color.withOpacity(0.3), color.withOpacity(0.15)]
              : [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(isActive ? 0.6 : 0.3),
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Bungee',
              fontSize: 12,
              color: color,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score.toString(),
            style: TextStyle(
              fontFamily: 'Bungee',
              fontSize: 32,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class GameBoardPainter extends CustomPainter {
  final List<List<int>> horizontalLines, verticalLines, boxes;
  final double spacing;
  final int gridSize;
  final Offset? dragStartDot;
  final Offset? dragCurrentPos;
  static const double offset = 30;

  GameBoardPainter({
    required this.horizontalLines,
    required this.verticalLines,
    required this.boxes,
    required this.spacing,
    required this.gridSize,
    this.dragStartDot,
    this.dragCurrentPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;

    // Draw Boxes
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (boxes[i][j] != 0) {
          paint.color = (boxes[i][j] == 1 ? Colors.cyan : Colors.pink)
              .withOpacity(0.25);
          canvas.drawRect(
            Rect.fromLTWH(
              offset + j * spacing,
              offset + i * spacing,
              spacing,
              spacing,
            ),
            paint,
          );
        }
      }
    }

    // Draw horizontal lines
    paint.strokeWidth = 5;
    for (int i = 0; i <= gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (horizontalLines[i][j] != 0) {
          paint.color = horizontalLines[i][j] == 1 ? Colors.cyan : Colors.pink;
          canvas.drawLine(
            Offset(offset + j * spacing, offset + i * spacing),
            Offset(offset + (j + 1) * spacing, offset + i * spacing),
            paint,
          );
        }
      }
    }

    // Draw vertical lines
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j <= gridSize; j++) {
        if (verticalLines[i][j] != 0) {
          paint.color = verticalLines[i][j] == 1 ? Colors.cyan : Colors.pink;
          canvas.drawLine(
            Offset(offset + j * spacing, offset + i * spacing),
            Offset(offset + j * spacing, offset + (i + 1) * spacing),
            paint,
          );
        }
      }
    }

    // Draw preview line while dragging
    if (dragStartDot != null && dragCurrentPos != null) {
      paint.color = Colors.white.withOpacity(0.5);
      paint.strokeWidth = 3;
      paint.strokeCap = StrokeCap.round;
      canvas.drawLine(dragStartDot!, dragCurrentPos!, paint);
    }

    // Draw Dots
    paint.color = Colors.white;
    paint.strokeWidth = 1;
    for (int i = 0; i <= gridSize; i++) {
      for (int j = 0; j <= gridSize; j++) {
        canvas.drawCircle(
          Offset(offset + j * spacing, offset + i * spacing),
          7,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
