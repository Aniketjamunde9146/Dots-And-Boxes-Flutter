import 'package:flutter/material.dart';
import 'dart:math';
import '../sound_manager.dart';

class AiMediumGame extends StatefulWidget {
  const AiMediumGame({super.key});

  @override
  State<AiMediumGame> createState() => _AiMediumGameState();
}

class _AiMediumGameState extends State<AiMediumGame>
    with TickerProviderStateMixin {
  static const int gridSize = 4;
  static const double dotRadius = 8;
  static const double spacing = 60;
  static const double offset = 30;

  late List<List<int>> horizontalLines;
  late List<List<int>> verticalLines;
  late List<List<int>> boxes;

  int playerScore = 0;
  int aiScore = 0;
  bool isPlayerTurn = true;
  bool gameOver = false;
  bool _isDisposed = false;
  String gameStatus = 'Your turn: Drag dot to dot';
  String? errorMessage;

  Offset? dragStartDot;
  Offset? dragCurrentPos;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  final Random _random = Random();
  bool _aiIsThinking = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward(); // ✅ start ONCE

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
    playerScore = 0;
    aiScore = 0;
    isPlayerTurn = true;
    gameOver = false;
    gameStatus = 'Your turn: Drag dot to dot';
    dragStartDot = null;
    dragCurrentPos = null;
    _aiIsThinking = false;
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
    if (dragStartDot == null || gameOver || !isPlayerTurn || _aiIsThinking) {
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
        setState(() => horizontalLines[r1][col] = 1);
        success = true;
      } else {
        _showError("Line already exists!");
      }
    }
    // Vertical connection
    else if (c1 == c2 && (r1 - r2).abs() == 1) {
      int row = r1 < r2 ? r1 : r2;
      if (verticalLines[row][c1] == 0) {
        setState(() => verticalLines[row][c1] = 1);
        success = true;
      } else {
        _showError("Line already exists!");
      }
    } else {
      _showError("Only connect adjacent dots!");
    }

    if (success) {
      SoundManager.click(); // 👆 correct

      setState(() {
        bool boxCompleted = _checkForCompletedBoxes(isPlayer: true);

        if (boxCompleted) {
          SoundManager.box(); // 👆 correct
          gameStatus = 'You got a box! Your turn';
        } else {
          isPlayerTurn = false;
          gameStatus = 'AI is thinking...';
        }

        _checkGameOver();
      });

      if (!isPlayerTurn && !gameOver) {
        _makeAiMove();
      }
    }

    dragStartDot = null;
    dragCurrentPos = null;
  }

  bool _checkForCompletedBoxes({required bool isPlayer}) {
    bool newlyCompleted = false;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (boxes[i][j] == 0 &&
            horizontalLines[i][j] != 0 &&
            horizontalLines[i + 1][j] != 0 &&
            verticalLines[i][j] != 0 &&
            verticalLines[i][j + 1] != 0) {
          boxes[i][j] = isPlayer ? 1 : 2;
          if (isPlayer) {
            playerScore++;
          } else {
            aiScore++;
          }
          newlyCompleted = true;
        }
      }
    }
    return newlyCompleted;
  }

  // AI Logic - Balanced for 50/50 win rate
  Future<void> _makeAiMove() async {
    if (_isDisposed || !mounted || gameOver || _aiIsThinking) return;

    setState(() {
      _aiIsThinking = true;
      isPlayerTurn = false; // ✅ ADD THIS
    });

    // Add thinking delay for realism
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(800)));

    if (!mounted || _isDisposed || gameOver) return;

    // Strategy weights for balanced gameplay
    Map<String, dynamic>? selectedMove;

    // 40% chance: Look for moves that complete a box
    if (_random.nextDouble() < 0.4) {
      selectedMove = _findBoxCompletingMove();
    }

    // 30% chance: Look for safe moves (won't give opponent a box)
    if (selectedMove == null && _random.nextDouble() < 0.43) {
      selectedMove = _findSafeMove();
    }

    // Otherwise: Make a random valid move
    selectedMove ??= _findRandomMove();

    if (selectedMove != null) {
      setState(() {
        if (selectedMove!['type'] == 'horizontal') {
          horizontalLines[selectedMove['row']][selectedMove['col']] = 2;
        } else {
          verticalLines[selectedMove['row']][selectedMove['col']] = 2;
        }
        SoundManager.click();
        bool boxCompleted = _checkForCompletedBoxes(isPlayer: false);

        if (boxCompleted) {
          SoundManager.box(); // ✅ ONLY when box is completed
          gameStatus = 'AI got a box! AI continues...';

          // AI plays again
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!_isDisposed && mounted && !gameOver && !isPlayerTurn) {
              _makeAiMove();
            }
          });
        } else {
          isPlayerTurn = true;
          gameStatus = 'Your turn: Drag dot to dot';
        }

        _checkGameOver();
        _aiIsThinking = false;
      });
    } else {
      setState(() {
        _aiIsThinking = false;
        isPlayerTurn = true;
        gameStatus = 'Your turn: Drag dot to dot';
      });
    }
  }

  // Find a move that completes a box
  Map<String, dynamic>? _findBoxCompletingMove() {
    List<Map<String, dynamic>> completingMoves = [];

    // Check horizontal lines
    for (int i = 0; i <= gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (horizontalLines[i][j] == 0) {
          if (_wouldCompleteBox(i, j, true)) {
            completingMoves.add({'type': 'horizontal', 'row': i, 'col': j});
          }
        }
      }
    }

    // Check vertical lines
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j <= gridSize; j++) {
        if (verticalLines[i][j] == 0) {
          if (_wouldCompleteBox(i, j, false)) {
            completingMoves.add({'type': 'vertical', 'row': i, 'col': j});
          }
        }
      }
    }

    return completingMoves.isEmpty
        ? null
        : completingMoves[_random.nextInt(completingMoves.length)];
  }

  // Check if placing a line would complete any box
  bool _wouldCompleteBox(int row, int col, bool isHorizontal) {
    if (isHorizontal) {
      // Check box above
      if (row > 0) {
        if (horizontalLines[row - 1][col] != 0 &&
            verticalLines[row - 1][col] != 0 &&
            verticalLines[row - 1][col + 1] != 0) {
          return true;
        }
      }
      // Check box below
      if (row < gridSize) {
        if (horizontalLines[row + 1][col] != 0 &&
            verticalLines[row][col] != 0 &&
            verticalLines[row][col + 1] != 0) {
          return true;
        }
      }
    } else {
      // Check box to the left
      if (col > 0) {
        if (horizontalLines[row][col - 1] != 0 &&
            horizontalLines[row + 1][col - 1] != 0 &&
            verticalLines[row][col - 1] != 0) {
          return true;
        }
      }
      // Check box to the right
      if (col < gridSize) {
        if (horizontalLines[row][col] != 0 &&
            horizontalLines[row + 1][col] != 0 &&
            verticalLines[row][col + 1] != 0) {
          return true;
        }
      }
    }
    return false;
  }

  // Find a safe move that won't give the opponent a box
  Map<String, dynamic>? _findSafeMove() {
    List<Map<String, dynamic>> safeMoves = [];

    // Check horizontal lines
    for (int i = 0; i <= gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (horizontalLines[i][j] == 0) {
          if (!_wouldGiveOpponentBox(i, j, true)) {
            safeMoves.add({'type': 'horizontal', 'row': i, 'col': j});
          }
        }
      }
    }

    // Check vertical lines
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j <= gridSize; j++) {
        if (verticalLines[i][j] == 0) {
          if (!_wouldGiveOpponentBox(i, j, false)) {
            safeMoves.add({'type': 'vertical', 'row': i, 'col': j});
          }
        }
      }
    }

    return safeMoves.isEmpty
        ? null
        : safeMoves[_random.nextInt(safeMoves.length)];
  }

  // Check if a move would give opponent a box on their next turn
  bool _wouldGiveOpponentBox(int row, int col, bool isHorizontal) {
    if (isHorizontal) {
      // Check if this creates a 3-sided box above
      if (row > 0) {
        int sides = 0;
        if (horizontalLines[row - 1][col] != 0) sides++;
        if (verticalLines[row - 1][col] != 0) sides++;
        if (verticalLines[row - 1][col + 1] != 0) sides++;
        if (sides == 3) return true;
      }
      // Check if this creates a 3-sided box below
      if (row < gridSize) {
        int sides = 0;
        if (horizontalLines[row + 1][col] != 0) sides++;
        if (verticalLines[row][col] != 0) sides++;
        if (verticalLines[row][col + 1] != 0) sides++;
        if (sides == 3) return true;
      }
    } else {
      // Check if this creates a 3-sided box to the left
      if (col > 0) {
        int sides = 0;
        if (horizontalLines[row][col - 1] != 0) sides++;
        if (horizontalLines[row + 1][col - 1] != 0) sides++;
        if (verticalLines[row][col - 1] != 0) sides++;
        if (sides == 3) return true;
      }
      // Check if this creates a 3-sided box to the right
      if (col < gridSize) {
        int sides = 0;
        if (horizontalLines[row][col] != 0) sides++;
        if (horizontalLines[row + 1][col] != 0) sides++;
        if (verticalLines[row][col + 1] != 0) sides++;
        if (sides == 3) return true;
      }
    }
    return false;
  }

  // Find any random valid move
  Map<String, dynamic>? _findRandomMove() {
    List<Map<String, dynamic>> allMoves = [];

    for (int i = 0; i <= gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (horizontalLines[i][j] == 0) {
          allMoves.add({'type': 'horizontal', 'row': i, 'col': j});
        }
      }
    }

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j <= gridSize; j++) {
        if (verticalLines[i][j] == 0) {
          allMoves.add({'type': 'vertical', 'row': i, 'col': j});
        }
      }
    }

    return allMoves.isEmpty ? null : allMoves[_random.nextInt(allMoves.length)];
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
    if (gameOver) return; // ⛔ prevents double sound

    if (playerScore + aiScore == gridSize * gridSize) {
      gameOver = true;

      if (playerScore > aiScore) {
        gameStatus = "You Win!";
      } else if (aiScore > playerScore) {
        gameStatus = "AI Wins!";
      } else {
        gameStatus = "It's a Tie!";
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          SoundManager.win(); // 🏆 WIN SOUND
          _showWinnerPopup();
        }
      });
    }
  }

  void _showError(String msg) {
    SoundManager.cancel(); // ❌ error sound
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
    bool playerWins = playerScore > aiScore;
    bool isTie = playerScore == aiScore;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1A2F), Color(0xFF1a3a52)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isTie
                ? Colors.amber.withOpacity(0.5)
                : (playerWins
                      ? Colors.cyan.withOpacity(0.5)
                      : Colors.red.withOpacity(0.5)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isTie
                  ? Colors.amber.withOpacity(0.3)
                  : (playerWins
                        ? Colors.cyan.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3)),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Icon(
                isTie
                    ? Icons.handshake
                    : (playerWins ? Icons.emoji_events : Icons.smart_toy),
                size: 80,
                color: isTie
                    ? Colors.amber
                    : (playerWins ? Colors.cyan : Colors.red),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              isTie ? "It's a Tie!" : (playerWins ? "You Win!" : "AI Wins!"),
              style: TextStyle(
                fontFamily: 'Bungee',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isTie
                    ? Colors.amber
                    : (playerWins ? Colors.cyan : Colors.red),
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isTie
                  ? "Both tied!"
                  : (playerWins
                        ? "Congratulations!"
                        : "Better luck next time!"),
              style: TextStyle(
                fontFamily: 'Bungee',
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 30),
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
                        'You',
                        style: TextStyle(
                          fontFamily: 'Bungee',
                          fontSize: 12,
                          color: Colors.cyan,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$playerScore',
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
                        'AI',
                        style: TextStyle(
                          fontFamily: 'Bungee',
                          fontSize: 12,
                          color: Colors.pink,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$aiScore',
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
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      if (!_isDisposed && mounted) {
                        setState(() => _initializeGame());
                      }
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
                            Navigator.pop(context);
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
    _isDisposed = true;
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1A2F), Color(0xFF1a3a52), Color(0xFF0A1A2F)],
            stops: [0.0, 0.5, 1.0],
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
                        SoundManager.cancel(); // ❌ exit sound
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
                      'AI MEDIUM (5x5)',
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
                      'You',
                      playerScore,
                      Colors.cyan,
                      isPlayerTurn,
                    ),
                    _buildScoreCard('AI', aiScore, Colors.pink, !isPlayerTurn),
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
                    onPanStart: (details) {
                      if (isPlayerTurn && !_aiIsThinking) {
                        dragStartDot = details.localPosition;
                      }
                    },
                    onPanUpdate: (details) {
                      if (isPlayerTurn && !_aiIsThinking) {
                        setState(() => dragCurrentPos = details.localPosition);
                      }
                    },
                    onPanEnd: (details) {
                      if (isPlayerTurn && !_aiIsThinking) {
                        _handleDragEnd(dragCurrentPos ?? Offset.zero);
                      }
                    },
                    onTapDown: (details) {
                      if (isPlayerTurn && !_aiIsThinking) {
                        _showError("Drag from dot to dot!");
                      }
                    },
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
