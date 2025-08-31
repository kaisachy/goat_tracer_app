import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'cattle_lineage_card.dart';
import 'cattle_management_card.dart';
import 'cattle_notes_section.dart';
import 'detail_cattle_info_cards.dart';

class CattleDetailsTabContent extends StatelessWidget {
  final Cattle cattle;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const CattleDetailsTabContent({
    super.key,
    required this.cattle,
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
                  child: CattleBasicInfoCard(
                    key: CattleBasicInfoCard.createKey(cattle),
                    cattle: cattle,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAnimatedCard(
                  delay: 200,
                  child: CattleLineageCard(cattle: cattle),
                ),
                const SizedBox(height: 20),
                _buildAnimatedCard(
                  delay: 300,
                  child: CattleManagementCard(cattle: cattle),
                ),
                const SizedBox(height: 20),
                _buildAnimatedCard(
                  delay: 500,
                  child: CattleNotesSection(cattle: cattle),
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
