import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';
import 'main_navigation_screen.dart';

class PrestigeSplashScreen extends StatefulWidget {
  const PrestigeSplashScreen({super.key});

  @override
  State<PrestigeSplashScreen> createState() => _PrestigeSplashScreenState();
}

class _PrestigeSplashScreenState extends State<PrestigeSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _grp1Ctrl;
  late final AnimationController _grp2Ctrl;
  late final AnimationController _grp3Ctrl;
  late final AnimationController _grp4Ctrl;
  late final AnimationController _textCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _separatorCtrl;
  late final AnimationController _actionsCtrl;

  late final Animation<double> _grp1Anim;
  late final Animation<double> _grp2Anim;
  late final Animation<double> _grp3Anim;
  late final Animation<double> _grp4Anim;
  late final Animation<double> _textAnim;
  late final Animation<double> _taglineAnim;
  late final Animation<double> _separatorAnim;
  late final Animation<double> _actionsAnim;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _playSequence();
  }

  void _setupAnimations() {
    _grp1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _grp2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _grp3Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _grp4Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _separatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _actionsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _grp1Anim = CurvedAnimation(parent: _grp1Ctrl, curve: Curves.easeOut);
    _grp2Anim = CurvedAnimation(parent: _grp2Ctrl, curve: Curves.easeOut);
    _grp3Anim = CurvedAnimation(parent: _grp3Ctrl, curve: Curves.easeOut);
    _grp4Anim = CurvedAnimation(parent: _grp4Ctrl, curve: Curves.easeOut);
    _textAnim = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic);
    _separatorAnim = CurvedAnimation(
      parent: _separatorCtrl,
      curve: Curves.easeOut,
    );
    _taglineAnim = CurvedAnimation(
      parent: _taglineCtrl,
      curve: Curves.easeOutCubic,
    );
    _actionsAnim = CurvedAnimation(
      parent: _actionsCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _playSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _grp1Ctrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _grp2Ctrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    _grp3Ctrl.forward();
    _grp4Ctrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _separatorCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    _taglineCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _actionsCtrl.forward();
  }

  Future<void> _replay() async {
    _grp1Ctrl.reset();
    _grp2Ctrl.reset();
    _grp3Ctrl.reset();
    _grp4Ctrl.reset();
    _textCtrl.reset();
    _separatorCtrl.reset();
    _taglineCtrl.reset();
    _actionsCtrl.reset();
    await _playSequence();
  }

  void _continueToAuth() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  void dispose() {
    _grp1Ctrl.dispose();
    _grp2Ctrl.dispose();
    _grp3Ctrl.dispose();
    _grp4Ctrl.dispose();
    _textCtrl.dispose();
    _separatorCtrl.dispose();
    _taglineCtrl.dispose();
    _actionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoWidth = size.width < 380 ? 250.0 : 280.0;

    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Stack(
          children: [
            /// ==========================
            /// IMAGE DE FOND
            /// ==========================
            Positioned.fill(
              child: Image.asset(
                "assets/images/background.png",
                fit: BoxFit.cover,
              ),
            ),

            /// ==========================
            /// FLOU
            /// ==========================
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withValues(alpha: .25)),
              ),
            ),

            /// ==========================
            /// OVERLAY NOIR PREMIUM
            /// ==========================
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,

                    colors: [
                      Colors.black.withValues(alpha: .55),

                      Colors.black.withValues(alpha: .35),

                      Colors.black.withValues(alpha: .70),
                    ],
                  ),
                ),
              ),
            ),

            /// ==========================
            /// EFFETS DORÉS EXISTANTS
            /// ==========================
            const _GoldBackground(),

            /// ==========================
            /// CONTENU + ANIMATIONS
            /// ==========================
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 26),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _grp1Anim,
                        _grp2Anim,
                        _grp3Anim,
                        _grp4Anim,
                      ]),

                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(logoWidth, logoWidth * .9),

                          painter: PrestigeLogoPainter(
                            grp1: _grp1Anim.value,

                            grp2: _grp2Anim.value,

                            grp3: _grp3Anim.value,

                            grp4: _grp4Anim.value,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 26),

                    _FadeSlide(
                      animation: _textAnim,

                      offset: 16,

                      child: ShaderMask(
                        shaderCallback: AppColors.goldGradient.createShader,

                        child: Text(
                          "Prestige Immobilier",

                          textAlign: TextAlign.center,

                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: Colors.white,

                                fontSize: size.width < 380 ? 30 : 34,

                                fontStyle: FontStyle.italic,

                                fontWeight: FontWeight.w800,

                                shadows: [
                                  Shadow(
                                    blurRadius: 25,
                                    color: Colors.black54,

                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    AnimatedBuilder(
                      animation: _separatorAnim,

                      builder: (context, _) {
                        return Container(
                          width: 180 * _separatorAnim.value,

                          height: 1,

                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,

                                AppColors.primary.withValues(alpha: .75),

                                Colors.transparent,
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    _FadeSlide(
                      animation: _taglineAnim,

                      offset: 12,

                      child: ShaderMask(
                        shaderCallback: AppColors.goldGradient.createShader,

                        child: Text(
                          "L'EXCELLENCE À VOTRE SERVICE",

                          textAlign: TextAlign.center,

                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,

                                fontSize: 10,

                                fontWeight: FontWeight.w600,

                                letterSpacing: 3,
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 42),

                    _FadeSlide(
                      animation: _actionsAnim,

                      offset: 12,

                      child: Column(
                        children: [
                          FilledButton.icon(
                            key: const Key('splash_continue_button'),
                            onPressed: _continueToAuth,

                            icon: const Icon(Icons.login_rounded),

                            label: const Text("Entrer"),
                          ),

                          const SizedBox(height: 10),

                          TextButton.icon(
                            onPressed: _replay,

                            icon: const Icon(Icons.replay_rounded, size: 18),

                            label: const Text("Rejouer le logo"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldBackground extends StatelessWidget {
  const _GoldBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.09),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({
    required this.animation,
    required this.child,
    required this.offset,
  });

  final Animation<double> animation;
  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }
}

class PrestigeLogoPainter extends CustomPainter {
  PrestigeLogoPainter({
    required this.grp1,
    required this.grp2,
    required this.grp3,
    required this.grp4,
  });

  final double grp1;
  final double grp2;
  final double grp3;
  final double grp4;

  void _drawTaperedLine(Canvas canvas, List<double> points, double progress) {
    if (progress <= 0) return;

    final baseLeft = points[0];
    final baseRight = points[1];
    final topLeft = points[2];
    final topRight = points[3];
    final baseY = points[4];
    final topY = points[5];
    final currentTopY = baseY - (baseY - topY) * progress;
    final currentTopLeft = baseLeft + (topLeft - baseLeft) * progress;
    final currentTopRight = baseRight + (topRight - baseRight) * progress;
    final path = Path()
      ..moveTo(baseLeft, baseY)
      ..lineTo(baseRight, baseY)
      ..lineTo(currentTopRight, currentTopY)
      ..lineTo(currentTopLeft, currentTopY)
      ..close();

    final rect = Rect.fromLTWH(
      baseLeft,
      currentTopY,
      baseRight - baseLeft,
      baseY - currentTopY,
    );
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF9A6A10),
          Color(0xFFEDB830),
          Color(0xFFC8861C),
          Color(0xFFF7E27A),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(rect);

    canvas.drawPath(path, paint);
  }

  void _drawTaperedLineFromTop(
    Canvas canvas,
    List<double> points,
    double progress,
  ) {
    if (progress <= 0) return;

    final baseLeft = points[0];
    final baseRight = points[1];
    final topLeft = points[2];
    final topRight = points[3];
    final baseY = points[4];
    final topY = points[5];
    final currentBaseY = topY + (baseY - topY) * progress;
    final currentBaseLeft = topLeft + (baseLeft - topLeft) * progress;
    final currentBaseRight = topRight + (baseRight - topRight) * progress;
    final path = Path()
      ..moveTo(currentBaseLeft, currentBaseY)
      ..lineTo(currentBaseRight, currentBaseY)
      ..lineTo(topRight, topY)
      ..lineTo(topLeft, topY)
      ..close();

    final rect = Rect.fromLTWH(
      baseLeft,
      topY,
      baseRight - baseLeft,
      currentBaseY - topY,
    );
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF9A6A10),
          Color(0xFFEDB830),
          Color(0xFFC8861C),
          Color(0xFFF7E27A),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(rect);

    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 180);

    const g1 = [
      [22.0, 25.5, 23.0, 24.0, 160.0, 90.0],
      [28.0, 31.5, 29.0, 30.0, 160.0, 87.0],
      [34.0, 37.5, 35.0, 36.0, 160.0, 84.0],
    ];
    for (var i = 0; i < g1.length; i++) {
      _drawTaperedLine(canvas, g1[i], grp1);
    }

    const g2 = [
      [47.0, 51.0, 48.5, 49.5, 160.0, 44.0],
      [54.0, 58.0, 55.5, 56.5, 160.0, 39.0],
      [61.0, 65.0, 62.5, 63.5, 160.0, 34.0],
      [68.0, 72.0, 69.5, 70.5, 160.0, 29.0],
      [75.0, 79.0, 76.5, 77.5, 160.0, 24.0],
    ];
    for (var i = 0; i < g2.length; i++) {
      _drawTaperedLine(canvas, g2[i], grp2);
    }

    const g3 = [
      [84.0, 89.0, 86.4, 86.6, 76.0, 22.0],
      [93.0, 98.0, 95.4, 95.6, 75.0, 18.0],
      [102.0, 107.0, 104.4, 104.6, 74.0, 14.0],
    ];
    for (var i = 0; i < g3.length; i++) {
      _drawTaperedLineFromTop(canvas, g3[i], grp3);
    }

    const g4 = [
      [120.0, 124.0, 121.9, 122.1, 160.0, 78.0],
      [127.0, 131.0, 128.9, 129.1, 160.0, 80.0],
      [134.0, 138.0, 135.9, 136.1, 160.0, 82.0],
      [141.0, 144.0, 142.4, 142.6, 160.0, 85.0],
      [147.0, 150.0, 148.4, 148.6, 160.0, 87.0],
    ];
    for (var i = 0; i < g4.length; i++) {
      _drawTaperedLine(canvas, g4[i], grp4);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(PrestigeLogoPainter oldDelegate) {
    return true;
  }
}
