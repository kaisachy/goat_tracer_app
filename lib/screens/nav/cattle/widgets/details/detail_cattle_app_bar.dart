// lib/screens/nav/cattle/widgets/detail_cattle_app_bar.dart

import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/cattle_options_modal.dart';
import 'package:cattle_tracer_app/utils/cattle_age_classification.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DetailCattleAppBar extends StatefulWidget {
  final Cattle cattle;
  final VoidCallback onAddEvent;
  final Function(Cattle) onEditCattle;
  final VoidCallback? onCattleUpdated;

  const DetailCattleAppBar({
    super.key,
    required this.cattle,
    required this.onAddEvent,
    required this.onEditCattle,
    this.onCattleUpdated,
  });

  @override
  State<DetailCattleAppBar> createState() => _DetailCattleAppBarState();
}

class _DetailCattleAppBarState extends State<DetailCattleAppBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary, // Changed from backgroundColor to color
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Back Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Go Back',
                ),
              ),

              const SizedBox(width: 16),

              // Cattle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.tag,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.cattle.tagNo.isNotEmpty ? '#${widget.cattle.tagNo}' : 'No Tag',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.cattle.classification.isNotEmpty
                                ? widget.cattle.classification
                                : 'No Stage',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.cattle.status.isNotEmpty
                                ? widget.cattle.status
                                : 'No Status',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Options Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        CattleOptionsModal.show(
                          context: context,
                          cattle: widget.cattle,
                          onAddEvent: widget.onAddEvent,
                          onEditCattle: widget.onEditCattle,
                          onCattleUpdated: widget.onCattleUpdated, // Pass the callback
                        );
                      },
                      tooltip: 'More Options',
                    ),
                    if (!CattleAgeClassification.isClassificationAccurate(widget.cattle))
                      Positioned(
                        right: 4,
                        top: 4,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              FadeTransition(
                                opacity: _opacityAnimation,
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.yellow[700]?.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.yellow[700],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.warning_amber,
                                    color: Colors.white,
                                    size: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}