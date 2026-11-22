import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/routing/route_names.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _navScrolled = false;
  bool _mobileMenuOpen = false;

  // Section GlobalKeys for anchor scrolling
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _problemKey = GlobalKey();
  final GlobalKey _solutionsKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _aiKey = GlobalKey();
  final GlobalKey _impactKey = GlobalKey();
  final GlobalKey _trustKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  late AnimationController _networkController;
  late AnimationController _heroFadeController;
  late Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _networkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _heroFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroFade = CurvedAnimation(
      parent: _heroFadeController,
      curve: Curves.easeOut,
    );
    _heroFadeController.forward();

    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 60;
      if (scrolled != _navScrolled) {
        setState(() => _navScrolled = scrolled);
      }
    });
  }

  @override
  void dispose() {
    _networkController.dispose();
    _heroFadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    setState(() => _mobileMenuOpen = false);
    final ctx = key.currentContext;
    final renderObject = ctx?.findRenderObject();
    if (renderObject == null || !_scrollController.hasClients) return;

    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) return;

    final position = _scrollController.position;
    final targetOffset = viewport
        .getOffsetToReveal(renderObject, 0)
        .offset
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    position.jumpTo(targetOffset);
  }

  bool get _isDesktop {
    final w = MediaQuery.of(context).size.width;
    return w >= 1280;
  }

  bool get _isTablet {
    final w = MediaQuery.of(context).size.width;
    return w >= 600 && w < 1280;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Spacer for sticky navbar
                const SizedBox(height: 72),
                Container(
                  key: _heroKey,
                  color: Colors.transparent,
                  child: _HeroSection(
                    heroFade: _heroFade,
                    networkController: _networkController,
                    isDesktop: _isDesktop,
                    onExploreTap: () => _scrollToKey(_solutionsKey),
                    onHowItWorksTap: () => _scrollToKey(_howItWorksKey),
                  ),
                ),
                Container(
                  key: _problemKey,
                  color: Colors.transparent,
                  child: _ProblemSection(isDesktop: _isDesktop),
                ),
                Container(
                  key: _solutionsKey,
                  color: Colors.transparent,
                  child: _SolutionsSection(
                    isDesktop: _isDesktop,
                    isTablet: _isTablet,
                  ),
                ),
                Container(
                  key: _howItWorksKey,
                  color: Colors.transparent,
                  child: _HowItWorksSection(isDesktop: _isDesktop),
                ),
                Container(
                  key: _aiKey,
                  color: Colors.transparent,
                  child: _AICapabilitiesSection(
                    isDesktop: _isDesktop,
                    isTablet: _isTablet,
                  ),
                ),
                Container(
                  key: _impactKey,
                  color: Colors.transparent,
                  child: _ImpactSection(
                    isDesktop: _isDesktop,
                    isTablet: _isTablet,
                  ),
                ),
                Container(
                  key: _trustKey,
                  color: Colors.transparent,
                  child: _TrustSection(
                    isDesktop: _isDesktop,
                    isTablet: _isTablet,
                  ),
                ),
                Container(
                  key: _contactKey,
                  color: Colors.transparent,
                  child: _Footer(
                    isDesktop: _isDesktop,
                    onNavTap: (key) => _scrollToKey(key),
                    heroKey: _heroKey,
                    solutionsKey: _solutionsKey,
                    aiKey: _aiKey,
                    contactKey: _contactKey,
                  ),
                ),
              ],
            ),
          ),

          // Sticky Navbar
          _Navbar(
            scrolled: _navScrolled,
            mobileMenuOpen: _mobileMenuOpen,
            isDesktop: _isDesktop,
            onMenuToggle: () =>
                setState(() => _mobileMenuOpen = !_mobileMenuOpen),
            onLoginTap: () => context.go(RouteNames.login),
            onNavTap: (key) => _scrollToKey(key),
            heroKey: _heroKey,
            problemKey: _problemKey,
            solutionsKey: _solutionsKey,
            aiKey: _aiKey,
            howItWorksKey: _howItWorksKey,
            contactKey: _contactKey,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// NAVBAR
// ─────────────────────────────────────────────────────────
class _Navbar extends StatelessWidget {
  final bool scrolled;
  final bool mobileMenuOpen;
  final bool isDesktop;
  final VoidCallback onMenuToggle;
  final VoidCallback onLoginTap;
  final void Function(GlobalKey) onNavTap;
  final GlobalKey heroKey;
  final GlobalKey problemKey;
  final GlobalKey solutionsKey;
  final GlobalKey aiKey;
  final GlobalKey howItWorksKey;
  final GlobalKey contactKey;

  const _Navbar({
    required this.scrolled,
    required this.mobileMenuOpen,
    required this.isDesktop,
    required this.onMenuToggle,
    required this.onLoginTap,
    required this.onNavTap,
    required this.heroKey,
    required this.problemKey,
    required this.solutionsKey,
    required this.aiKey,
    required this.howItWorksKey,
    required this.contactKey,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 72,
            decoration: BoxDecoration(
              color: scrolled
                  ? AppColors.bgSecondary.withValues(alpha: 0.95)
                  : Colors.transparent,
              border: scrolled
                  ? const Border(
                      bottom: BorderSide(
                        color: AppColors.borderSubtle,
                        width: 1,
                      ),
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.accentPrimary,
                              AppColors.accentSecondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'LIFE-LINK ',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: 'AI',
                              style: TextStyle(
                                color: AppColors.accentPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  if (isDesktop) ...[
                    _NavLink('Home', onTap: () => onNavTap(heroKey)),
                    _NavLink('About', onTap: () => onNavTap(problemKey)),
                    _NavLink('Solutions', onTap: () => onNavTap(solutionsKey)),
                    _NavLink('AI Technology', onTap: () => onNavTap(aiKey)),
                    _NavLink(
                      'Hospital Network',
                      onTap: () => onNavTap(solutionsKey),
                    ),
                    _NavLink('Contact', onTap: () => onNavTap(contactKey)),
                    const SizedBox(width: 24),
                    AppButton(
                      label: 'Login',
                      onPressed: onLoginTap,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.small,
                      icon: Icons.login,
                    ),
                  ] else ...[
                    IconButton(
                      icon: Icon(
                        mobileMenuOpen ? Icons.close : Icons.menu,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: onMenuToggle,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Mobile dropdown menu
          if (!isDesktop && mobileMenuOpen)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bgSecondary.withValues(alpha: 0.98),
                border: const Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MobileNavLink('Home', onTap: () => onNavTap(heroKey)),
                  _MobileNavLink('About', onTap: () => onNavTap(problemKey)),
                  _MobileNavLink(
                    'Solutions',
                    onTap: () => onNavTap(solutionsKey),
                  ),
                  _MobileNavLink('AI Technology', onTap: () => onNavTap(aiKey)),
                  _MobileNavLink(
                    'Hospital Network',
                    onTap: () => onNavTap(solutionsKey),
                  ),
                  _MobileNavLink(
                    'How It Works',
                    onTap: () => onNavTap(howItWorksKey),
                  ),
                  _MobileNavLink('Contact', onTap: () => onNavTap(contactKey)),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Login to Platform',
                    onPressed: onLoginTap,
                    icon: Icons.login,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, {required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: _hovered
                  ? AppColors.accentPrimary
                  : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _MobileNavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MobileNavLink(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final Animation<double> heroFade;
  final AnimationController networkController;
  final bool isDesktop;
  final VoidCallback onExploreTap;
  final VoidCallback onHowItWorksTap;

  const _HeroSection({
    required this.heroFade,
    required this.networkController,
    required this.isDesktop,
    required this.onExploreTap,
    required this.onHowItWorksTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 600),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.5),
          radius: 1.2,
          colors: [Color(0xFF0D2541), AppColors.bgPrimary],
        ),
      ),
      child: Stack(
        children: [
          // Background grid pattern
          Positioned.fill(child: _GridBackground()),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : 24,
              vertical: 60,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _HeroText(
                          heroFade: heroFade,
                          onExploreTap: onExploreTap,
                          onHowItWorksTap: onHowItWorksTap,
                        ),
                      ),
                      const SizedBox(width: 60),
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 440,
                          child: _NetworkVisualization(
                            controller: networkController,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroText(
                        heroFade: heroFade,
                        onExploreTap: onExploreTap,
                        onHowItWorksTap: onHowItWorksTap,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 320,
                        child: _NetworkVisualization(
                          controller: networkController,
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

class _HeroText extends StatelessWidget {
  final Animation<double> heroFade;
  final VoidCallback onExploreTap;
  final VoidCallback onHowItWorksTap;

  const _HeroText({
    required this.heroFade,
    required this.onExploreTap,
    required this.onHowItWorksTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final headlineSize = screenWidth < 400
        ? 36.0
        : screenWidth < 600
        ? 40.0
        : 48.0;

    return FadeTransition(
      opacity: heroFade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.accentPrimary.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radio_button_checked,
                  color: AppColors.accentPrimary,
                  size: 10,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'National Healthcare Coordination Platform',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.accentPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Headline
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: headlineSize,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.5,
              ),
              children: [
                const TextSpan(text: 'One Connected\nNetwork. '),
                TextSpan(
                  text: 'Countless\nLives Supported.',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [
                          AppColors.accentPrimary,
                          AppColors.accentSecondary,
                        ],
                      ).createShader(const Rect.fromLTWH(0, 0, 400, 80)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Supporting text
          const Text(
            'An AI-assisted national healthcare coordination platform\nconnecting verified hospitals to discover critical resources\nand coordinate faster responses.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.7,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 40),

          // CTA Row
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              AppButton(
                label: 'Explore Platform',
                onPressed: onExploreTap,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                icon: Icons.rocket_launch_rounded,
              ),
              AppButton(
                label: 'How It Works',
                onPressed: onHowItWorksTap,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.large,
                icon: Icons.play_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Trust strip
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _TrustPill(Icons.verified_user, 'Verified Hospitals Only'),
              _TrustPill(Icons.lock_outline, 'Privacy First'),
              _TrustPill(Icons.person_pin, 'Human Oversight Always'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.accentPrimary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// NETWORK VISUALIZATION
// ─────────────────────────────────────────────────────────
class _NetworkVisualization extends StatelessWidget {
  final AnimationController controller;
  const _NetworkVisualization({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _NetworkPainter(controller.value),
          child: Container(),
        );
      },
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final double t;
  _NetworkPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;

    // Hospital node positions (6 around a ring)
    const nodeCount = 6;
    final nodePositions = List.generate(nodeCount, (i) {
      final angle = (2 * math.pi * i / nodeCount) - math.pi / 2;
      return Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    });

    final nodeLabels = [
      'Hospital A',
      'Hospital B',
      'Hospital C',
      'Blood Bank',
      'ICU Unit',
      'Organ Coord',
    ];

    // Draw edges (hospital → center)
    for (int i = 0; i < nodeCount; i++) {
      final edgePaint = Paint()
        ..color = AppColors.accentPrimary.withValues(alpha: 0.18)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(nodePositions[i], center, edgePaint);

      // Animated data packet along edge
      final packetT = (t + i / nodeCount) % 1.0;
      final packetPos = Offset.lerp(nodePositions[i], center, packetT)!;
      final packetPaint = Paint()
        ..color = AppColors.accentPrimary.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(packetPos, 3.5, packetPaint);

      // Reverse packet
      final revT = (t + 0.5 + i / nodeCount) % 1.0;
      final revPos = Offset.lerp(center, nodePositions[i], revT)!;
      final revPaint = Paint()
        ..color = AppColors.accentSecondary.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(revPos, 2.5, revPaint);
    }

    // Cross-connection edges between adjacent nodes (ring)
    for (int i = 0; i < nodeCount; i++) {
      final next = (i + 1) % nodeCount;
      final ringPaint = Paint()
        ..color = AppColors.borderSubtle.withValues(alpha: 0.5)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(nodePositions[i], nodePositions[next], ringPaint);
    }

    // Draw hospital nodes
    for (int i = 0; i < nodeCount; i++) {
      final pos = nodePositions[i];
      // Glow
      final glowPaint = Paint()
        ..color = AppColors.accentSecondary.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(pos, 24, glowPaint);

      // Node fill
      final nodeFill = Paint()
        ..color = AppColors.bgCard
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 20, nodeFill);

      final nodeBorder = Paint()
        ..color = AppColors.accentSecondary.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, 20, nodeBorder);

      // Hospital cross icon (simple cross)
      final crossPaint = Paint()
        ..color = AppColors.accentSecondary
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(pos.dx, pos.dy - 8),
        Offset(pos.dx, pos.dy + 8),
        crossPaint,
      );
      canvas.drawLine(
        Offset(pos.dx - 8, pos.dy),
        Offset(pos.dx + 8, pos.dy),
        crossPaint,
      );

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: nodeLabels[i],
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 70);
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + 25));
    }

    // Central AI Hub — pulsing
    final pulseRadius = 32 + 6 * math.sin(t * 2 * math.pi);

    final hubGlow = Paint()
      ..color = AppColors.accentPrimary.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, pulseRadius + 10, hubGlow);

    // Pulse ring
    final pulseRing = Paint()
      ..color = AppColors.accentPrimary.withValues(
        alpha: 0.25 * (1 - (t % 0.5) * 2),
      )
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, pulseRadius + 20 * (t % 0.5), pulseRing);

    final hubFill = Paint()
      ..color = const Color(0xFF0E2235)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pulseRadius, hubFill);

    final hubBorder = Paint()
      ..color = AppColors.accentPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, pulseRadius, hubBorder);

    // AI text in hub
    final aiTp = TextPainter(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'LIFE-LINK\n',
            style: TextStyle(
              color: AppColors.accentPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          TextSpan(
            text: 'AI HUB',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 60);
    aiTp.paint(
      canvas,
      Offset(center.dx - aiTp.width / 2, center.dy - aiTp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_NetworkPainter old) => old.t != t;
}

class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ─────────────────────────────────────────────────────────
// SECTION HEADER WIDGET
// ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color eyebrowColor;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.eyebrowColor = AppColors.accentPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: eyebrowColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: eyebrowColor.withValues(alpha: 0.35)),
          ),
          child: Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              color: eyebrowColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// PROBLEM SECTION
// ─────────────────────────────────────────────────────────
class _ProblemSection extends StatelessWidget {
  final bool isDesktop;
  const _ProblemSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final problems = [
      (
        Icons.call_split,
        AppColors.danger,
        'Fragmented Communication',
        'Hospitals operate in silos. Critical resource availability is scattered across phone calls, faxes, and disconnected systems, causing dangerous delays in time-sensitive situations.',
      ),
      (
        Icons.search_off,
        AppColors.warning,
        'Resource Discovery Delays',
        'Finding available blood units, organ donors, ICU beds, or life-saving equipment requires manual coordination across dozens of facilities with no unified view.',
      ),
      (
        Icons.sync_disabled,
        AppColors.accentSecondary,
        'Coordination Gaps',
        'Without a central coordination layer, response times suffer. Healthcare professionals spend critical minutes on logistics instead of patient care.',
      ),
    ];

    return Container(
      color: AppColors.bgSecondary,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isDesktop ? 80 : 24,
      ),
      child: Column(
        children: [
          const _SectionHeader(
            eyebrow: 'The Challenge',
            title: 'A Fractured System in\nCritical Moments',
            subtitle: 'Healthcare coordination today relies on fragmented, manual processes\nthat put lives at risk during the moments that matter most.',
            eyebrowColor: AppColors.danger,
          ),
          const SizedBox(height: 56),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: problems
                  .map(
                    (p) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _ProblemCard(
                          icon: p.$1,
                          color: p.$2,
                          title: p.$3,
                          description: p.$4,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            Column(
              children: problems
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ProblemCard(
                        icon: p.$1,
                        color: p.$2,
                        title: p.$3,
                        description: p.$4,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _ProblemCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowAccent: GlowAccent.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SOLUTIONS SECTION
// ─────────────────────────────────────────────────────────
class _SolutionsSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  const _SolutionsSection({required this.isDesktop, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final modules = [
      (
        Icons.favorite_rounded,
        AppColors.accentPrimary,
        'Organ & Tissue\nCoordination',
        'Real-time tracking of organ and tissue availability across verified medical centers with AI-assisted matching and logistics support.',
        ['Live Availability', 'Cross-match AI', 'Logistics Routing'],
      ),
      (
        Icons.water_drop_rounded,
        AppColors.danger,
        'Blood Bank\nNetwork',
        'Unified blood inventory across hospitals and blood banks with demand forecasting and emergency routing for rare blood types.',
        ['Inventory Grid', 'Demand Forecast', 'Emergency Route'],
      ),
      (
        Icons.hotel_rounded,
        AppColors.accentSecondary,
        'ICU & Emergency\nBeds',
        'Live ICU bed occupancy and availability across all network hospitals, enabling immediate patient transfer coordination.',
        ['Live Occupancy', 'Transfer Coord.', 'Surge Alerts'],
      ),
      (
        Icons.precision_manufacturing_rounded,
        AppColors.equipmentAmber,
        'Medical Equipment\nSharing',
        'Discover ventilators, defibrillators, imaging systems, and critical equipment available for verified inter-hospital sharing.',
        ['Equipment Search', 'Availability Map', 'Request Queue'],
      ),
    ];

    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

    return Container(
      color: AppColors.bgPrimary,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isDesktop ? 80 : 24,
      ),
      child: Column(
        children: [
          const _SectionHeader(
            eyebrow: 'Our Solutions',
            title: 'Four Modules.\nOne Unified Network.',
            subtitle: 'Each module addresses a critical gap in healthcare resource coordination,\npowered by AI and connected through a single secure platform.',
          ),
          const SizedBox(height: 56),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 0.65 : (isTablet ? 0.85 : 1.0),
            ),
            itemCount: modules.length,
            itemBuilder: (context, i) {
              final m = modules[i];
              return _SolutionCard(
                icon: m.$1,
                color: m.$2,
                title: m.$3,
                description: m.$4,
                features: m.$5,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SolutionCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final List<String> features;
  const _SolutionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.features,
  });

  @override
  State<_SolutionCard> createState() => _SolutionCardState();
}

class _SolutionCardState extends State<_SolutionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.bgCardHover : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.5)
                : AppColors.borderSubtle,
            width: 1.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.12),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color.withValues(alpha: 0.2),
                    widget.color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.color.withValues(alpha: 0.35)),
              ),
              child: Icon(widget.icon, color: widget.color, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                widget.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 14),
            ...widget.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: widget.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
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

// ─────────────────────────────────────────────────────────
// HOW IT WORKS SECTION
// ─────────────────────────────────────────────────────────
class _HowItWorksSection extends StatelessWidget {
  final bool isDesktop;
  const _HowItWorksSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        Icons.upload_rounded,
        AppColors.accentPrimary,
        'Institutions Share Reports',
        'Participating institutions can report resource indicators through approved channels. This prototype uses fictional sample data and has no live hospital connection.',
      ),
      (
        Icons.verified_rounded,
        AppColors.accentSecondary,
        'AI-Assisted Data Checks',
        'The demo assistant can summarize synthetic records and flag missing or stale fields. It does not verify institutions or validate real-world availability.',
      ),
      (
        Icons.hub_rounded,
        AppColors.success,
        'Search Reported Resources',
        'Authorized users can search reported indicators to prepare an enquiry. Results are not resource matches, guarantees, reservations, or allocations.',
      ),
      (
        Icons.admin_panel_settings_rounded,
        AppColors.warning,
        'People Review Next Steps',
        'Authorized people decide whether to proceed through established institutional pathways. This prototype only records simulated workflow steps.',
      ),
      (
        Icons.groups_rounded,
        AppColors.accentPrimary,
        'Institutions Coordinate Directly',
        'Any real-world response requires direct confirmation by authorized institutions and medical professionals; the prototype sends no requests externally.',
      ),
    ];

    return Container(
      color: AppColors.bgSecondary,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isDesktop ? 80 : 24,
      ),
      child: Column(
        children: [
          const _SectionHeader(
            eyebrow: 'How It Works',
            title: 'Five Steps to Faster\nCoordination',
            subtitle: 'A transparent, human-supervised workflow from data submission\nto coordinated action — with AI assisting every step.',
          ),
          const SizedBox(height: 56),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(steps.length, (i) {
                final s = steps[i];
                return Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _StepCard(
                          stepNumber: i + 1,
                          icon: s.$1,
                          color: s.$2,
                          title: s.$3,
                          description: s.$4,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Icon(
                            Icons.chevron_right,
                            color: AppColors.borderLight,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            )
          else
            Column(
              children: List.generate(steps.length, (i) {
                final s = steps[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _StepCard(
                    stepNumber: i + 1,
                    icon: s.$1,
                    color: s.$2,
                    title: s.$3,
                    description: s.$4,
                    horizontal: true,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool horizontal;
  const _StepCard({
    required this.stepNumber,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Text(
          '0$stepNumber',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    if (horizontal) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            badge,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          badge,
          const SizedBox(height: 16),
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// AI CAPABILITIES SECTION
// ─────────────────────────────────────────────────────────
class _AICapabilitiesSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  const _AICapabilitiesSection({
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final caps = [
      (
        Icons.search_rounded,
        AppColors.aiPurple,
        'Natural Language Search',
        'Query the platform in plain language. "Find O- blood within 50km of Delhi" — the AI interprets, searches, and surfaces results instantly.',
      ),
      (
        Icons.fact_check_rounded,
        AppColors.accentPrimary,
        'Data Quality Checks',
        'AI-powered validation flags duplicate entries, stale data, and inconsistencies before they affect coordination decisions.',
      ),
      (
        Icons.trending_up_rounded,
        AppColors.accentSecondary,
        'Demand Forecasting',
        'Predictive models analyze seasonal patterns, event data, and historical trends to anticipate resource demand before it becomes critical.',
      ),
      (
        Icons.local_shipping_rounded,
        AppColors.success,
        'Logistics Assistance',
        'Route optimization and logistics guidance for time-sensitive transfers — organs, blood, equipment — across the network geography.',
      ),
      (
        Icons.warning_amber_rounded,
        AppColors.warning,
        'Anomaly Detection',
        'Real-time surveillance of data patterns identifies unusual consumption spikes, potential shortages, or reporting anomalies for early intervention.',
      ),
    ];

    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgPrimary, Color(0xFF0A1A2D)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isDesktop ? 80 : 24,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.aiPurpleGlow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.aiPurple.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.aiPurple,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader(
            eyebrow: 'AI Technology',
            title: 'Intelligence That\nSupports Human Decisions',
            subtitle: 'Five AI capabilities that make the platform smarter, faster, and\nmore reliable — always with human experts in control.',
            eyebrowColor: AppColors.aiPurple,
          ),
          const SizedBox(height: 56),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.3 : (isTablet ? 1.1 : 1.2),
            ),
            itemCount: caps.length,
            itemBuilder: (context, i) {
              final c = caps[i];
              return _AiCapabilityCard(
                icon: c.$1,
                color: c.$2,
                title: c.$3,
                description: c.$4,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AiCapabilityCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _AiCapabilityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  State<_AiCapabilityCard> createState() => _AiCapabilityCardState();
}

class _AiCapabilityCardState extends State<_AiCapabilityCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.5)
                : AppColors.borderSubtle,
            width: 1.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.color.withValues(alpha: 0.3)),
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                widget.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// IMPACT SECTION
// ─────────────────────────────────────────────────────────
class _ImpactSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  const _ImpactSection({required this.isDesktop, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('500+', 'Network Hospitals', '(Demo)', AppColors.accentPrimary),
      ('24/7', 'Coordination Active', '(Demo)', AppColors.accentSecondary),
      ('< 8 min', 'Avg. Resource Match', '(Demo)', AppColors.success),
      ('4 Modules', 'Resource Categories', '(Demo)', AppColors.equipmentAmber),
    ];

    return Container(
      color: AppColors.bgSecondary,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isDesktop ? 80 : 24,
      ),
      child: Column(
        children: [
          const _SectionHeader(
            eyebrow: 'Platform Scale',
            title: 'Built for National\nHealthcare Infrastructure',
            subtitle:
                'Demonstrating the potential of unified coordination at scale.',
          ),
          const SizedBox(height: 20),

          // PROMINENT DISCLAIMER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DEMO NOTICE: All statistics displayed below are illustrative figures for demonstration purposes only. '
                    'They do not represent actual national healthcare outcomes, real hospital data, or verified operational results.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.4 : (isTablet ? 1.2 : 1.4),
            ),
            itemCount: stats.length,
            itemBuilder: (context, i) {
              final s = stats[i];
              return GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.$1,
                      style: TextStyle(
                        color: s.$4,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.$3,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TRUST SECTION
// ─────────────────────────────────────────────────────────
class _TrustSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  const _TrustSection({required this.isDesktop, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final pillars = [
      (
        Icons.lock_rounded,
        AppColors.accentPrimary,
        'Privacy & Security',
        'This demonstration does not collect patient-identifiable information. A production deployment would require institution-approved safeguards and applicable privacy and regulatory review.',
      ),
      (
        Icons.verified_user_rounded,
        AppColors.accentSecondary,
        'Verified Institutions Only',
        'The network is designed for verified hospitals, blood banks, and medical institutions. Production access would require institutional identity checks, authorization, and regular review.',
      ),
      (
        Icons.supervised_user_circle_rounded,
        AppColors.success,
        'Human Oversight Always',
        'The AI assists — it does not make allocation decisions. Authorized human healthcare coordinators remain responsible for reviewing proposed coordination pathways.',
      ),
      (
        Icons.gavel_rounded,
        AppColors.warning,
        'Official Allocation Pathways',
        'The platform is intended to support, not replace or bypass, official allocation protocols and authorized pathways such as NOTTO-aligned organ allocation.',
      ),
    ];

    return Container(
      color: AppColors.bgPrimary,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isDesktop ? 80 : 24,
      ),
      child: Column(
        children: [
          const _SectionHeader(
            eyebrow: 'Trust & Safety',
            title: 'Responsible Technology\nfor Healthcare',
            subtitle: 'Built with accountability at its core. Every design decision prioritizes\nsafety, human judgment, and institutional integrity.',
          ),
          const SizedBox(height: 56),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 0.68 : (isTablet ? 0.85 : 0.9),
            ),
            itemCount: pillars.length,
            itemBuilder: (context, i) {
              final p = pillars[i];
              return GlassCard(
                glowAccent: GlowAccent.none,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: p.$2.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.$2.withValues(alpha: 0.3)),
                      ),
                      child: Icon(p.$1, color: p.$2, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      p.$3,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: Text(
                        p.$4,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.65,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final bool isDesktop;
  final void Function(GlobalKey) onNavTap;
  final GlobalKey heroKey;
  final GlobalKey solutionsKey;
  final GlobalKey aiKey;
  final GlobalKey contactKey;

  const _Footer({
    required this.isDesktop,
    required this.onNavTap,
    required this.heroKey,
    required this.solutionsKey,
    required this.aiKey,
    required this.contactKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050E18),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: 60,
      ),
      child: Column(
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _FooterBrand()),
                const SizedBox(width: 60),
                Expanded(
                  flex: 2,
                  child: _FooterLinks(
                    onNavTap: onNavTap,
                    heroKey: heroKey,
                    solutionsKey: solutionsKey,
                    aiKey: aiKey,
                  ),
                ),
                const SizedBox(width: 40),
                const Expanded(flex: 2, child: _FooterContact()),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FooterBrand(),
                const SizedBox(height: 32),
                _FooterLinks(
                  onNavTap: onNavTap,
                  heroKey: heroKey,
                  solutionsKey: solutionsKey,
                  aiKey: aiKey,
                ),
                const SizedBox(height: 32),
                const _FooterContact(),
              ],
            ),

          const SizedBox(height: 48),
          const Divider(color: AppColors.borderSubtle, thickness: 1),
          const SizedBox(height: 24),

          // Bottom disclaimers
          Wrap(
            spacing: 24,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              Text(
                '© 2026 LIFE-LINK AI · Demo Platform',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              Text(
                'Not for Clinical Use',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Concept Aligned with NOTTO Framework',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              Text(
                'For Healthcare Technology Research Only',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentPrimary, AppColors.accentSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'LIFE-LINK AI',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Connecting Hospitals. Coordinating Resources.\nSupporting Faster Care.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: const Text(
            '⚠ Demo Platform — Not for Clinical Use',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  final void Function(GlobalKey) onNavTap;
  final GlobalKey heroKey;
  final GlobalKey solutionsKey;
  final GlobalKey aiKey;

  const _FooterLinks({
    required this.onNavTap,
    required this.heroKey,
    required this.solutionsKey,
    required this.aiKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLATFORM',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        _FooterLink('Home', () => onNavTap(heroKey)),
        _FooterLink('Solutions', () => onNavTap(solutionsKey)),
        _FooterLink('AI Technology', () => onNavTap(aiKey)),
        _FooterLink('Hospital Network', () => onNavTap(solutionsKey)),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}

class _FooterContact extends StatelessWidget {
  const _FooterContact();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTACT',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        _FooterContactItem(Icons.email_outlined, 'contact@lifelink-ai.example'),
        _FooterContactItem(Icons.language, 'www.lifelink-ai.example'),
        _FooterContactItem(
          Icons.location_on_outlined,
          'India — National Platform',
        ),
        const SizedBox(height: 20),
        const Text(
          'This is a research and demonstration project.\nAll contact details are placeholders.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _FooterContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FooterContactItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.accentPrimary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
