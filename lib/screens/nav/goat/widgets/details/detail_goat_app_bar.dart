// lib/screens/nav/goat/widgets/detail_goat_app_bar.dart

import 'package:flutter/material.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/goat_options_modal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DetailgoatAppBar extends StatelessWidget {
  final goat goat;
  final VoidCallback onAddEvent;
  final Function(goat) onEditgoat;
  final VoidCallback? ongoatUpdated;

  const DetailgoatAppBar({
    super.key,
    required this.goat,
    required this.onAddEvent,
    required this.onEditgoat,
    this.ongoatUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary, // Changed from backgroundColor to color
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                  color: Colors.white.withValues(alpha: 0.2),
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

              // goat Info
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
                            goat.tagNo.isNotEmpty ? '#${goat.tagNo}' : 'No Tag',
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            goat.classification.isNotEmpty
                                ? goat.classification
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            goat.status.isNotEmpty
                                ? goat.status
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    goatOptionsModal.show(
                      context: context,
                      goat: goat,
                      onAddEvent: onAddEvent,
                      onEditgoat: onEditgoat,
                      ongoatUpdated: ongoatUpdated, // Pass the callback
                    );
                  },
                  tooltip: 'More Options',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
