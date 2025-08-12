import 'package:cattle_tracer_app/screens/nav/cattle/widgets/cattle_search_filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_form_screen.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_detail_screen.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CattleScreen extends StatefulWidget {
  const CattleScreen({super.key});

  @override
  State<CattleScreen> createState() => _CattleScreenState();
}

// ✨ MODIFIED: Added the WidgetsBindingObserver mixin
class _CattleScreenState extends State<CattleScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Cattle> _cattleList = [];
  List<Cattle> _filteredCattleList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedGender = 'All';
  String _selectedClassification = 'All';
  String _selectedStatus = 'All';
  String _selectedBreed = 'All';
  String _selectedGroupName = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // ✨ ADDED: Register the observer
    WidgetsBinding.instance.addObserver(this);

    _fetchCattle();
  }

  @override
  void dispose() {
    _animationController.dispose();

    // ✨ ADDED: Remove the observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ✨ ADDED: Override this method to listen for app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When the app is resumed (brought to the foreground), refresh the data.
    if (state == AppLifecycleState.resumed) {
      _fetchCattle();
    }
  }

  Future<void> _fetchCattle() async {
    // Prevent multiple fetches if already loading
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final data = await CattleService.getCattleInformation();
      if (mounted) {
        setState(() {
          _cattleList = data.map((e) => Cattle.fromJson(e)).toList();
          _filterCattle(); // Apply existing filters to the new data
          _isLoading = false;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load cattle data'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterCattle();
  }

  void _handleFiltersChanged(String gender, String classification, String status, String breed, String groupName) {
    setState(() {
      _selectedGender = gender;
      _selectedClassification = classification;
      _selectedStatus = status;
      _selectedBreed = breed;
      _selectedGroupName = groupName;
    });
    _filterCattle();
  }

  void _filterCattle() {
    setState(() {
      _filteredCattleList = _cattleList.where((cattle) {
        final matchesSearch = _searchQuery.isEmpty ||
            cattle.tagNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (cattle.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            cattle.status.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (cattle.breed?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (cattle.groupName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        final matchesGender = _selectedGender == 'All' ||
            cattle.gender == _selectedGender;

        final matchesClassification = _selectedClassification == 'All' ||
            cattle.classification == _selectedClassification;

        final matchesStatus = _selectedStatus == 'All' ||
            cattle.status == _selectedStatus;

        final matchesBreed = _selectedBreed == 'All' ||
            (cattle.breed != null && cattle.breed == _selectedBreed);

        final matchesGroupName = _selectedGroupName == 'All' ||
            (cattle.groupName != null && cattle.groupName == _selectedGroupName);

        return matchesSearch && matchesGender && matchesClassification &&
            matchesStatus && matchesBreed && matchesGroupName;
      }).toList();
    });
  }

  List<String> _getUniqueBreedOptions() {
    Set<String> breeds = {'All'};
    for (var cattle in _cattleList) {
      if (cattle.breed != null && cattle.breed!.isNotEmpty) {
        breeds.add(cattle.breed!);
      }
    }
    return breeds.toList()..sort();
  }

  List<String> _getUniqueGroupNameOptions() {
    Set<String> groupNames = {'All'};
    for (var cattle in _cattleList) {
      if (cattle.groupName != null && cattle.groupName!.isNotEmpty) {
        groupNames.add(cattle.groupName!);
      }
    }
    return groupNames.toList()..sort();
  }

  void _navigateToForm({Cattle? cattle}) async {
    // The await/fetch pattern is kept as a fallback and for immediate refresh
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CattleFormScreen(cattle: cattle),
      ),
    );
    _fetchCattle();
  }

  void _navigateToDetail(Cattle cattle) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CattleDetailScreen(cattle: cattle),
      ),
    );
    _fetchCattle();
  }

  void _confirmDelete(int id, String tagNo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Delete Cattle'),
          ],
        ),
        content: Text('Are you sure you want to delete cattle "$tagNo"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              );

              final success = await CattleService.deleteCattleInformation(id);

              if (mounted) {
                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cattle "$tagNo" deleted successfully'),
                      backgroundColor: AppColors.vibrantGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                  _fetchCattle();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to delete cattle'),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildCattleOptionsMenu(Cattle cattle) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppColors.textSecondary.withOpacity(0.8),
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      offset: const Offset(0, 10),
      color: Colors.white,
      shadowColor: Colors.black26,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Cattle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete,
                  color: Colors.red.shade600,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Cattle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'edit':
            _navigateToForm(cattle: cattle);
            break;
          case 'delete':
            _confirmDelete(cattle.id, cattle.tagNo);
            break;
        }
      },
    );
  }

  Widget _buildCattleCard(Cattle cattle, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.1 * index),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            1.0,
            curve: Curves.easeOutCubic,
          ),
        )),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Card(
            elevation: 3,
            shadowColor: AppColors.primary.withOpacity(0.2),
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.lightGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () => _navigateToDetail(cattle),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: cattle.hasPicture
                              ? Image.memory(
                            cattle.imageBytes!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: AppColors.lightGreen.withOpacity(0.5),
                                child: Icon(Icons.error_outline, color: Colors.red.shade400),
                              );
                            },
                          )
                              : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                            ),
                            child: Icon(
                              FontAwesomeIcons.cow,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            cattle.tagNo,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          cattle.gender == 'Male' ? Icons.male : Icons.female,
                                          size: 18,
                                          color: cattle.gender == 'Male'
                                              ? AppColors.primary
                                              : AppColors.accent,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (cattle.name != null && cattle.name!.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        cattle.name!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.category, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    cattle.classification,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (cattle.status.isNotEmpty) ...[
                                    Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        cattle.status,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accent,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Replace the edit/delete buttons with options menu
                        _buildCattleOptionsMenu(cattle),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (cattle.weight != null) ...[
                          Icon(Icons.monitor_weight, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${cattle.weight}kg',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (cattle.dateOfBirth != null) ...[
                          Icon(Icons.cake, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(DateTime.parse(cattle.dateOfBirth!)),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    bool hasActiveFilters = _searchQuery.isNotEmpty ||
        _selectedGender != 'All' ||
        _selectedClassification != 'All' ||
        _selectedStatus != 'All' ||
        _selectedBreed != 'All' ||
        _selectedGroupName != 'All';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              FontAwesomeIcons.cow,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasActiveFilters
                ? 'No cattle match your search'
                : 'No cattle records found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters
                ? 'Try adjusting your search or filters'
                : 'Add your first cattle to get started',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!hasActiveFilters) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Cattle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground.withOpacity(0.1),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading cattle data...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          if (_cattleList.isNotEmpty) ...[
            CattleSearchFilterWidget(
              onSearchChanged: _handleSearchChanged,
              onFiltersChanged: _handleFiltersChanged,
              initialGender: _selectedGender,
              initialClassification: _selectedClassification,
              initialStatus: _selectedStatus,
              initialBreed: _selectedBreed,
              initialGroupName: _selectedGroupName,
              breedOptions: _getUniqueBreedOptions(),
              groupNameOptions: _getUniqueGroupNameOptions(),
            ),
          ],

          Expanded(
            child: _filteredCattleList.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _fetchCattle,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _filteredCattleList.length,
                itemBuilder: (context, index) =>
                    _buildCattleCard(_filteredCattleList[index], index),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.vibrantGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToForm(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Cattle',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}