import 'package:flutter/material.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'goat_lineage_card.dart';
import 'goat_management_card.dart';
import 'detail_goat_info_cards.dart';

class GoatDetailsTabContent extends StatelessWidget {
  final Goat goat;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const GoatDetailsTabContent({
    super.key,
    required this.goat,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 30),
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedCard(
                  delay: 100,
                  child: GoatBasicInfoCard(
                    key: GoatBasicInfoCard.createKey(goat),
                    goat: goat,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAnimatedCard(
                  delay: 200,
                  child: GoatLineageCard(goat: goat),
                ),
                const SizedBox(height: 20),
                _buildAnimatedCard(
                  delay: 300,
                  child: GoatManagementCard(goat: goat),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required Widget child, required int delay}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
