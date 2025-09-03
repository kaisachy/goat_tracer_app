import 'package:flutter/material.dart';
import '../../../../../constants/app_colors.dart';
import '../../vaccination/vaccination_schedule_screen.dart';
import '../../../../../services/vaccination_service.dart';
import '../../../../../services/cattle/cattle_service.dart';
import '../../../../../services/cattle/cattle_event_service.dart';

class ScheduleHeader extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchClear;
  final Widget child;

  const ScheduleHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.child,
  });

  @override
  State<ScheduleHeader> createState() => _ScheduleHeaderState();
}

class _ScheduleHeaderState extends State<ScheduleHeader> {
  bool _hasPendingVaccinations = false;
  bool _isLoadingVaccinationStatus = true;

  @override
  void initState() {
    super.initState();
    _checkVaccinationStatus();
  }

  Future<void> _checkVaccinationStatus() async {
    try {
      final cattleData = await CattleService.getAllCattle();
      final eventsData = await CattleEventService.getCattleEvent();
      
      final vaccinationService = VaccinationService();
      final schedules = await vaccinationService.generateVaccinationSchedules(
        allCattle: cattleData,
        allEvents: eventsData,
      );
      
      final cattleNeeding = vaccinationService.getCattleNeedingVaccination(
        schedules: schedules,
        allCattle: cattleData,
      );

      if (mounted) {
        setState(() {
          _hasPendingVaccinations = cattleNeeding.isNotEmpty;
          _isLoadingVaccinationStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasPendingVaccinations = false;
          _isLoadingVaccinationStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(context),
          const SizedBox(height: 16),
          widget.child,
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;

        return Row(
          children: [
            // Search bar
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: isNarrow ? 44 : 48,
                  maxHeight: isNarrow ? 44 : 48,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: widget.searchController,
                  onChanged: widget.onSearchChanged,
                  style: TextStyle(fontSize: isNarrow ? 13 : 14),
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: isNarrow ? 18 : 20,
                    ),
                    suffixIcon: widget.searchController.text.isNotEmpty == true
                        ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey.shade400,
                        size: isNarrow ? 16 : 18,
                      ),
                      onPressed: widget.onSearchClear,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(isNarrow ? 6 : 8),
                    )
                        : null,
                    hintText: isNarrow ? 'Search schedules...' : 'Search schedules, cattle, veterinarian...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: isNarrow ? 12 : 13,
                    ),
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 12 : 16,
                      vertical: isNarrow ? 10 : 12,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Vaccine button
            _buildVaccineButton(context, isNarrow),
          ],
        );
      },
    );
  }

  Widget _buildVaccineButton(BuildContext context, bool isNarrow) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: isNarrow ? 44 : 48,
          decoration: BoxDecoration(
            color: AppColors.vibrantGreen,  // Always green
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showVaccinationModal(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 12 : 16,
                  vertical: isNarrow ? 8 : 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.vaccines_rounded,  // Always vaccine icon
                      color: Colors.white,
                      size: isNarrow ? 18 : 20,
                    ),
                    if (!isNarrow) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Vaccine',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        // Notification badge with enhanced pulse animation
        if (_hasPendingVaccinations && !_isLoadingVaccinationStatus)
          Positioned(
            right: -4,
            top: -4,
            child: _PulsingRedDot(),
          ),
      ],
    );
  }

  void _showVaccinationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.vibrantGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.vaccines_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Needs Vaccination',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Vaccination content
            const Expanded(
              child: VaccinationScheduleScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingRedDot extends StatefulWidget {
  @override
  State<_PulsingRedDot> createState() => _PulsingRedDotState();
}

class _PulsingRedDotState extends State<_PulsingRedDot>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation - breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Glow animation - outer ring effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        return SizedBox(
          width: 20, // Fixed container size to prevent movement
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 20 * _glowAnimation.value,
                height: 20 * _glowAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.3 * (1 - _glowAnimation.value)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4 * _glowAnimation.value),
                      blurRadius: 8 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                  ],
                ),
              ),
              // Main red dot with pulse (no scale transform to prevent movement)
              Container(
                width: 12 * _pulseAnimation.value,
                height: 12 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.6),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

