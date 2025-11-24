import 'package:goat_tracer_app/screens/nav/goat/widgets/details/detail_goat_hero_section.dart';
import 'package:goat_tracer_app/screens/nav/goat/widgets/details/detail_goat_tab_content.dart';
import 'package:goat_tracer_app/screens/nav/goat/widgets/details/tab.dart';
import 'package:goat_tracer_app/screens/nav/goat/widgets/history/history_goat_tab_content.dart';
import 'package:flutter/material.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_history_form_screen.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_form_screen.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';
import 'package:goat_tracer_app/services/user_guide_service.dart';
import 'package:showcaseview/showcaseview.dart';
import 'dart:async';

class GoatDetailScreen extends StatefulWidget {
  final Goat? goat;
  final int? goatId;
  final bool isArchived;

  const GoatDetailScreen({
    super.key, 
    this.goat,
    this.goatId,
    this.isArchived = false,
  }) : assert(goat != null || goatId != null, 'Either goat or goatId must be provided');

  @override
  State<GoatDetailScreen> createState() => GoatDetailScreenState();
}

class GoatDetailScreenState extends State<GoatDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Goat? _currentGoat;
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
  final GlobalKey<State<HistorygoatTabContent>> _historyTabKey =
      GlobalKey<State<HistorygoatTabContent>>();

  // User guide keys
  final GlobalKey _heroSectionKey = GlobalKey();
  final GlobalKey _tabBarKey = GlobalKey();
  final GlobalKey _detailsTabKey = GlobalKey();
  final GlobalKey _historyTabShowcaseKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();
  
  // Store the ShowCaseWidget context
  BuildContext? _showCaseContext;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add listener to update FAB visibility when tab changes
    _tabController.addListener(() {
      setState(() {});
    });
    
    // Load goat data if goatId is provided
    if (widget.goatId != null) {
      _isLoading = true;
      _loadgoatData();
    } else {
      _currentGoat = widget.goat!;
    }

    // Initialize animations
    _initializeAnimations();

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();

    // Refresh goat data on initialization to ensure we have the latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshgoatData();
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
    _scrollController.dispose();
    super.dispose();
  }

  /// Helper method to scroll to a showcase widget
  Future<void> _scrollToShowcase(GlobalKey key) async {
    final context = key.currentContext;
    if (context != null && _scrollController.hasClients) {
      try {
        // Special handling for tab bar - it's sticky/pinned, so don't scroll
        // The tab bar is always visible at the top, so no scrolling needed
        if (key == _tabBarKey) {
          debugPrint('Tab bar showcase - skipping scroll since it\'s sticky');
          return; // Don't scroll for sticky tab bar
        } else {
          await Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.2, // Show widget at 20% from top to leave room for tooltip
          );
        }
      } catch (e) {
        debugPrint('Error scrolling to showcase: $e');
      }
    }
  }

  /// Public method to start the user guide (can be called programmatically)
  void startUserGuide() async {
    if (_showCaseContext == null) {
      debugPrint('ShowCase context not available yet');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait a moment and try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // Reset the guide completion status
    await UserGuideService.resetGuide('goat_detail');
    debugPrint('User guide reset, starting showcase...');
    
    if (mounted && _showCaseContext != null) {
      try {
        // Wait for widgets to be fully rendered
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Build showcase list based on current tab
        final List<GlobalKey> showcaseKeys = [
          _heroSectionKey,
          _tabBarKey,
        ];
        
        // Add tab-specific showcases based on current tab
        if (_tabController.index == 0) {
          // Details tab is active
          showcaseKeys.add(_detailsTabKey);
        } else if (_tabController.index == 1) {
          // History tab is active
          showcaseKeys.add(_historyTabShowcaseKey);
          if (!widget.isArchived) {
            showcaseKeys.add(_fabKey);
          }
        }
        
        // Start the showcase - it will auto-scroll to each item
        ShowCaseWidget.of(_showCaseContext!).startShowCase(showcaseKeys);
      } catch (e) {
        debugPrint('Error starting user guide: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to start user guide. Please try again.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _navigateToAddEventForm() async {
    if (_currentGoat == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => GoatHistoryFormScreen(
          goatTag: _currentGoat!.tagNo,
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
      await _refreshgoatData();
    }
  }

  void _navigateToEditGoat(Goat goat) async {
    if (_currentGoat == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GoatFormScreen(
          goat: goat,
        ),
      ),
    );

    if (result == true && mounted) {
      _showEnhancedSnackBar(
        'goat updated successfully',
        Icons.edit,
        AppColors.vibrantGreen,
        isSuccess: true,
      );
      // Refresh goat data to show updates
      await _refreshgoatData();
    }
  }

  /// Enhanced refresh method with better error handling and user feedback
  Future<void> _refreshgoatData() async {
    if (_isLoading || _isRefreshing || _currentGoat == null) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      debugPrint('🔄 Refreshing goat data for ID: ${_currentGoat!.id}');

      // Add a small delay to show loading state
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedGoat = await GoatService.getGoatById(_currentGoat!.id);

      if (updatedGoat != null && mounted) {
        debugPrint('✅ Updated goat received successfully');
        debugPrint('   - Stage: ${updatedGoat.classification}');
        debugPrint('   - Status: ${updatedGoat.status}');
        debugPrint('   - Image: ${updatedGoat.goatPicture != null ? "Present" : "None"}');

        // Check if there are actual changes to avoid unnecessary rebuilds
        final hasChanges = _hasDataChanged(_currentGoat!, updatedGoat);

        setState(() {
          _currentGoat = updatedGoat;
        });

        if (hasChanges) {
          debugPrint('📊 Data changes detected - UI will update');
          // Trigger a subtle animation to indicate refresh
          _animateRefresh();
        }
      } else {
        debugPrint('❌ Failed to get updated goat data');
        if (mounted) {
          _showEnhancedSnackBar(
            'Failed to refresh data',
            Icons.refresh,
            Colors.orange,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error refreshing goat data: $e');
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

  /// Load goat data when goatId is provided
  Future<void> _loadgoatData() async {
    try {
      final goat = await GoatService.getGoatById(widget.goatId!);
      if (goat != null && mounted) {
        setState(() {
          _currentGoat = goat;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showEnhancedSnackBar(
            'goat not found',
            Icons.error_outline,
            Colors.red,
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading goat data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showEnhancedSnackBar(
          'Error loading goat data',
          Icons.error_outline,
          Colors.red,
        );
        Navigator.pop(context);
      }
    }
  }

  /// Check if there are meaningful changes between old and new goat data
  bool _hasDataChanged(Goat oldGoat, Goat newGoat) {
    return oldGoat.classification != newGoat.classification ||
        oldGoat.status != newGoat.status ||
        oldGoat.goatPicture != newGoat.goatPicture ||
        oldGoat.weight != newGoat.weight ||
        oldGoat.breed != newGoat.breed ||
        oldGoat.dateOfBirth != newGoat.dateOfBirth;
  }

  /// Animate refresh to provide visual feedback
  void _animateRefresh() {
    _scaleController.reset();
    _scaleController.forward();
  }

  /// Handle goat updates from the options modal
  void _onGoatUpdated() async {
    if (_currentGoat == null) return;
    
    debugPrint('🔄 goat update triggered from options modal');
    await _refreshgoatData();

    // Show visual confirmation that data was refreshed
    _showEnhancedSnackBar(
      'goat data refreshed',
      Icons.refresh,
      AppColors.lightGreen,
      isSuccess: true,
    );
  }

  /// Pull-to-refresh handler
  Future<void> _onPullToRefresh() async {
    if (_currentGoat == null) return;
    
    debugPrint('📱 Pull-to-refresh triggered');
    await _refreshgoatData();
  }

  Future<void> _updategoatImage(String? base64Image) async {
    if (_isUpdatingImage || _currentGoat == null) {
      debugPrint('Image update already in progress or goat not loaded');
      return;
    }

    setState(() {
      _isUpdatingImage = true;
    });

    try {
      debugPrint('Starting image update process...');

      // Validate image size if not null
      if (base64Image != null && !GoatService.validateImageSize(base64Image)) {
        _showEnhancedSnackBar(
          'Image is too large. Please select an image under 5MB.',
          Icons.error,
          Colors.red,
        );
        return;
      }

      debugPrint('Updating goat picture in database...');
      final success = await GoatService.updategoatPicture(
        _currentGoat!.id,
        base64Image,
      );

      if (success && mounted) {
        debugPrint('Database update successful, updating local state...');

        // Update the local goat object immediately
        setState(() {
          _currentGoat = _currentGoat!.copyWith(goatPicture: base64Image);
        });

        // Refresh goat data to ensure sync with database
        debugPrint('Refreshing goat data to sync with database...');
        await _refreshgoatData();

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
      debugPrint('Error updating goat image: $e');
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
                  color: Colors.white.withValues(alpha: 0.2),
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
    // Show loading indicator while goat data is being loaded
    if (_isLoading || _currentGoat == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('goat Details'),
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

    return ShowCaseWidget(
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 300),
      onFinish: () async {
        debugPrint('User guide finished, marking as completed...');
        await UserGuideService.markGuideCompleted('goat_detail');
        debugPrint('User guide marked as completed');
      },
      onStart: (index, key) {
        // Ensure the widget is scrolled into view
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToShowcase(key);
        });
      },
      builder: (showCaseContext) {
        // Store the ShowCaseWidget context
        _showCaseContext = showCaseContext;
        
        return Scaffold(
          floatingActionButton: !widget.isArchived && _tabController.index == 1
              ? Showcase(
                  key: _fabKey,
                  title: 'Add History Record',
                  description: 'Quickly add a new history record for this goat. This button appears when you are on the History tab. Tap it to record events like vaccinations, treatments, or other important activities.',
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tooltipBackgroundColor: AppColors.vibrantGreen,
                  textColor: Colors.white,
                  child: FloatingActionButton.extended(
                    onPressed: _navigateToAddEventForm,
                    backgroundColor: AppColors.vibrantGreen,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add History Record'),
                    elevation: 4,
                  ),
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
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Section as a Sliver
              SliverToBoxAdapter(
                child: Showcase(
                  key: _heroSectionKey,
                  title: 'Goat Information',
                  description: 'View comprehensive goat details including photo, tag number, classification, status, breed, weight, and other important information. Tap the edit button to modify goat details or the camera icon to update the photo.',
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tooltipBackgroundColor: AppColors.primary,
                  textColor: Colors.white,
                  child: GoatHeroSection(
                    goat: _currentGoat!,
                    onImageUpdate: _updategoatImage,
                    onEditGoat: _navigateToEditGoat,
                    onAddEvent: _navigateToAddEventForm,
                    onGoatUpdated: _onGoatUpdated,
                    onStartUserGuide: startUserGuide,
                    isUpdatingImage: _isUpdatingImage,
                    isArchived: widget.isArchived,
                  ),
                ),
              ),

              // Loading indicator when refreshing
              if (_isRefreshing)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withValues(alpha: 0.5),
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
                        child: Builder(
                          builder: (context) {
                            final tabsWidget = GoatDetailTabs(
                              controller: _tabController,
                              fadeAnimation: _fadeAnimation,
                              slideAnimation: _slideAnimation,
                              onGoatUpdated: _onGoatUpdated,
                            );
                            return GoatDetailTabs(
                              controller: _tabController,
                              fadeAnimation: _fadeAnimation,
                              slideAnimation: _slideAnimation,
                              onGoatUpdated: _onGoatUpdated,
                              tabBarWrapper: Showcase(
                                key: _tabBarKey,
                                title: 'Navigation Tabs',
                                description: 'Switch between "Details" to view comprehensive goat information and "History" to see all recorded events and activities. Use these tabs to navigate between different views of the goat data.',
                                targetShapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tooltipBackgroundColor: AppColors.primary,
                                textColor: Colors.white,
                                child: tabsWidget.buildTabBar(),
                              ),
                            );
                          },
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
                    Showcase(
                      key: _detailsTabKey,
                      title: 'Goat Details',
                      description: 'View detailed information about this goat including personal information, physical characteristics, breeding details, health records, and other relevant data. All information can be edited by tapping the edit button in the hero section.',
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tooltipBackgroundColor: AppColors.primary,
                      textColor: Colors.white,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: GoatDetailsTabContent(
                          goat: _currentGoat!,
                          fadeAnimation: _fadeAnimation,
                          slideAnimation: _slideAnimation,
                        ),
                      ),
                    ),

                    // History Tab content
                    Showcase(
                      key: _historyTabShowcaseKey,
                      title: 'Goat History',
                      description: 'View all recorded events and activities for this goat including vaccinations, treatments, breeding records, weight changes, and other important history. Pull down to refresh or use the floating action button to add a new history record.',
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tooltipBackgroundColor: AppColors.primary,
                      textColor: Colors.white,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: HistorygoatTabContent(
                          key: _historyTabKey,
                          goat: _currentGoat!,
                          onAddEvent: _navigateToAddEventForm,
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
      },
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
