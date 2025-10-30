import 'package:cattle_tracer_app/screens/nav/cattle/widgets/details/detail_cattle_hero_section.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/details/detail_cattle_tab_content.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/details/tab.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/history/history_cattle_tab_content.dart';
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_history_form_screen.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_form_screen.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';

class CattleDetailScreen extends StatefulWidget {
  final Cattle? cattle;
  final int? cattleId;
  final bool isArchived;

  const CattleDetailScreen({
    super.key, 
    this.cattle,
    this.cattleId,
    this.isArchived = false,
  }) : assert(cattle != null || cattleId != null, 'Either cattle or cattleId must be provided');

  @override
  State<CattleDetailScreen> createState() => _CattleDetailScreenState();
}

class _CattleDetailScreenState extends State<CattleDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Cattle? _currentCattle;
  bool _isUpdatingImage = false;
  bool _isLoading = false;
  bool _isRefreshing = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Refresh indicator key for programmatic control
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  
  // GlobalKey for history tab content to trigger refresh
  final GlobalKey<State<HistoryCattleTabContent>> _historyTabKey =
      GlobalKey<State<HistoryCattleTabContent>>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add listener to update FAB visibility when tab changes
    _tabController.addListener(() {
      setState(() {});
    });
    
    // Load cattle data if cattleId is provided
    if (widget.cattleId != null) {
      _isLoading = true;
      _loadCattleData();
    } else {
      _currentCattle = widget.cattle!;
    }

    // Initialize animations
    _initializeAnimations();

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();

    // Refresh cattle data on initialization to ensure we have the latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCattleData();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _navigateToAddEventForm() async {
    if (_currentCattle == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CattleHistoryFormScreen(
          cattleTag: _currentCattle!.tagNo,
        ),
      ),
    );

    if (result == true && mounted) {
      _showEnhancedSnackBar(
         'History record added successfully',
        Icons.event_available,
        AppColors.vibrantGreen,
        isSuccess: true,
      );
      _tabController.animateTo(1); // Switch to History tab
      
      // Refresh history tab data to show new history record
      if (_historyTabKey.currentState != null) {
        (_historyTabKey.currentState as dynamic).refresh();
      }
      await _refreshCattleData();
    }
  }

  void _navigateToEditCattle(Cattle cattle) async {
    if (_currentCattle == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CattleFormScreen(
          cattle: cattle,
        ),
      ),
    );

    if (result == true && mounted) {
      _showEnhancedSnackBar(
        'Cattle updated successfully',
        Icons.edit,
        AppColors.vibrantGreen,
        isSuccess: true,
      );
      // Refresh cattle data to show updates
      await _refreshCattleData();
    }
  }

  /// Enhanced refresh method with better error handling and user feedback
  Future<void> _refreshCattleData() async {
    if (_isLoading || _isRefreshing || _currentCattle == null) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      debugPrint('🔄 Refreshing cattle data for ID: ${_currentCattle!.id}');

      // Add a small delay to show loading state
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedCattle = await CattleService.getCattleById(_currentCattle!.id);

      if (updatedCattle != null && mounted) {
        debugPrint('✅ Updated cattle received successfully');
        debugPrint('   - Stage: ${updatedCattle.classification}');
        debugPrint('   - Status: ${updatedCattle.status}');
        debugPrint('   - Image: ${updatedCattle.cattlePicture != null ? "Present" : "None"}');

        // Check if there are actual changes to avoid unnecessary rebuilds
        final hasChanges = _hasDataChanged(_currentCattle!, updatedCattle);

        setState(() {
          _currentCattle = updatedCattle;
        });

        if (hasChanges) {
          debugPrint('📊 Data changes detected - UI will update');
          // Trigger a subtle animation to indicate refresh
          _animateRefresh();
        }
      } else {
        debugPrint('❌ Failed to get updated cattle data');
        if (mounted) {
          _showEnhancedSnackBar(
            'Failed to refresh data',
            Icons.refresh,
            Colors.orange,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error refreshing cattle data: $e');
      if (mounted) {
        _showEnhancedSnackBar(
          'Error refreshing data',
          Icons.error_outline,
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// Load cattle data when cattleId is provided
  Future<void> _loadCattleData() async {
    try {
      final cattle = await CattleService.getCattleById(widget.cattleId!);
      if (cattle != null && mounted) {
        setState(() {
          _currentCattle = cattle;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showEnhancedSnackBar(
            'Cattle not found',
            Icons.error_outline,
            Colors.red,
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading cattle data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showEnhancedSnackBar(
          'Error loading cattle data',
          Icons.error_outline,
          Colors.red,
        );
        Navigator.pop(context);
      }
    }
  }

  /// Check if there are meaningful changes between old and new cattle data
  bool _hasDataChanged(Cattle oldCattle, Cattle newCattle) {
    return oldCattle.classification != newCattle.classification ||
        oldCattle.status != newCattle.status ||
        oldCattle.cattlePicture != newCattle.cattlePicture ||
        oldCattle.weight != newCattle.weight ||
        oldCattle.breed != newCattle.breed ||
        oldCattle.dateOfBirth != newCattle.dateOfBirth;
  }

  /// Animate refresh to provide visual feedback
  void _animateRefresh() {
    _scaleController.reset();
    _scaleController.forward();
  }

  /// Handle cattle updates from the options modal
  void _onCattleUpdated() async {
    if (_currentCattle == null) return;
    
    debugPrint('🔄 Cattle update triggered from options modal');
    await _refreshCattleData();

    // Show visual confirmation that data was refreshed
    _showEnhancedSnackBar(
      'Cattle data refreshed',
      Icons.refresh,
      AppColors.lightGreen,
      isSuccess: true,
    );
  }

  /// Pull-to-refresh handler
  Future<void> _onPullToRefresh() async {
    if (_currentCattle == null) return;
    
    debugPrint('📱 Pull-to-refresh triggered');
    await _refreshCattleData();
  }

  Future<void> _updateCattleImage(String? base64Image) async {
    if (_isUpdatingImage || _currentCattle == null) {
      debugPrint('Image update already in progress or cattle not loaded');
      return;
    }

    setState(() {
      _isUpdatingImage = true;
    });

    try {
      debugPrint('Starting image update process...');

      // Validate image size if not null
      if (base64Image != null && !CattleService.validateImageSize(base64Image)) {
        _showEnhancedSnackBar(
          'Image is too large. Please select an image under 5MB.',
          Icons.error,
          Colors.red,
        );
        return;
      }

      debugPrint('Updating cattle picture in database...');
      final success = await CattleService.updateCattlePicture(
        _currentCattle!.id,
        base64Image,
      );

      if (success && mounted) {
        debugPrint('Database update successful, updating local state...');

        // Update the local cattle object immediately
        setState(() {
          _currentCattle = _currentCattle!.copyWith(cattlePicture: base64Image);
        });

        // Refresh cattle data to ensure sync with database
        debugPrint('Refreshing cattle data to sync with database...');
        await _refreshCattleData();

        // Show success message
        final message = base64Image == null
            ? 'Photo deleted successfully'
            : 'Photo updated successfully';
        final icon = base64Image == null ? Icons.delete : Icons.photo_camera;
        final color = base64Image == null ? Colors.orange : AppColors.vibrantGreen;

        _showEnhancedSnackBar(message, icon, color, isSuccess: true);
        debugPrint('Image update process completed successfully');
      } else if (mounted) {
        // Show error message
        final errorMessage = base64Image == null
            ? 'Failed to delete photo'
            : 'Failed to update photo';
        _showEnhancedSnackBar(errorMessage, Icons.error, Colors.red);
        debugPrint('Database update failed');
      }
    } catch (e) {
      debugPrint('Error updating cattle image: $e');
      if (mounted) {
        _showEnhancedSnackBar(
          'An error occurred while updating the photo',
          Icons.error,
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingImage = false;
        });
        debugPrint('Image update process finished');
      }
    }
  }

  void _showEnhancedSnackBar(
      String message,
      IconData icon,
      Color color, {
        bool isSuccess = false,
      }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSuccess)
                      const Text(
                        'Success!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSuccess)
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isSuccess ? 3 : 2),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while cattle data is being loaded
    if (_isLoading || _currentCattle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cattle Details'),
          backgroundColor: AppColors.darkGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.vibrantGreen),
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: !widget.isArchived && _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddEventForm,
              backgroundColor: AppColors.vibrantGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add History Record'),
              elevation: 4,
            )
          : null,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onPullToRefresh,
        color: AppColors.vibrantGreen,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        displacement: 60,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.lightGreen,
                Colors.white,
              ],
              stops: [0.0, 0.3],
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Section as a Sliver
              SliverToBoxAdapter(
                child: CattleHeroSection(
                  cattle: _currentCattle!,
                  onImageUpdate: _updateCattleImage,
                  onEditCattle: _navigateToEditCattle,
                  onAddEvent: _navigateToAddEventForm,
                  onCattleUpdated: _onCattleUpdated,
                  isUpdatingImage: _isUpdatingImage,
                  isArchived: widget.isArchived,
                ),
              ),

              // Loading indicator when refreshing
              if (_isRefreshing)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.vibrantGreen),
                    ),
                  ),
                ),

              // Sticky Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  tabBar: Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: CattleDetailTabs(
                          controller: _tabController,
                          fadeAnimation: _fadeAnimation,
                          slideAnimation: _slideAnimation,
                          onCattleUpdated: _onCattleUpdated,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Tab Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Details Tab content
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: CattleDetailsTabContent(
                        cattle: _currentCattle!,
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                      ),
                    ),

                    // History Tab content
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: HistoryCattleTabContent(
                        key: _historyTabKey,
                        cattle: _currentCattle!,
                        onAddEvent: _navigateToAddEventForm,
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

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;

  _StickyTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => 60.0; // Adjust based on your tab height

  @override
  double get maxExtent => 60.0; // Same as minExtent for consistent height

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return tabBar;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}