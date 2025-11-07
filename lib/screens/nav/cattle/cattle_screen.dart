import 'package:cattle_tracer_app/screens/nav/cattle/widgets/cattle_search_filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_export_service.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_form_screen.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_detail_screen.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/archived_cattle_screen.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_history_form_screen.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/change_stage_option.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/change_status_option.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/archive_option.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/modals/options/delete_option.dart';
import 'package:cattle_tracer_app/screens/nav/history/cattle_selection_modal.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
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
  String _selectedSex = 'All';
  String _selectedClassification = 'All';
  String _selectedStatus = 'All';
  String _selectedBreed = 'All';
  String _selectedGroupName = 'All';
  String _selectedReportType = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // FAB menu state
  AnimationController? _fabAnimationController;

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
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );


    // ✨ ADDED: Register the observer
    WidgetsBinding.instance.addObserver(this);

    _fetchCattle();
  }

  Widget _buildAddCattleGrid() {
    final List<Map<String, dynamic>> items = [
      {
        'label': 'Bull',
        'iconPath': 'assets/images/cattle-icons/bull.png',
        'color': AppColors.vibrantGreen,
        'fallback': Icons.male,
      },
      {
        'label': 'Cow',
        'iconPath': 'assets/images/cattle-icons/cow.png',
        'color': AppColors.primary,
        'fallback': FontAwesomeIcons.cow,
      },
      {
        'label': 'Steer',
        'iconPath': 'assets/images/cattle-icons/steer.png',
        'color': Colors.blue,
        'fallback': Icons.pets,
      },
      {
        'label': 'Heifer',
        'iconPath': 'assets/images/cattle-icons/heifer.png',
        'color': AppColors.accent,
        'fallback': Icons.female,
      },
      {
        'label': 'Grower (M)',
        'classification': 'Growers',
        'sex': 'Male',
        'iconPath': 'assets/images/cattle-icons/growers.png',
        'color': AppColors.lightGreen,
        'fallback': Icons.trending_up,
      },
      {
        'label': 'Grower (F)',
        'classification': 'Growers',
        'sex': 'Female',
        'iconPath': 'assets/images/cattle-icons/growers.png',
        'color': AppColors.lightGreen,
        'fallback': Icons.trending_up,
      },
      {
        'label': 'Calf (M)',
        'classification': 'Calf',
        'sex': 'Male',
        'iconPath': 'assets/images/cattle-icons/calf.png',
        'color': Colors.orange,
        'fallback': Icons.child_care,
      },
      {
        'label': 'Calf (F)',
        'classification': 'Calf',
        'sex': 'Female',
        'iconPath': 'assets/images/cattle-icons/calf.png',
        'color': Colors.orange,
        'fallback': Icons.child_care,
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 4 / 3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final Color color = item['color'] as Color;
        return Card(
          elevation: 3,
          shadowColor: color.withOpacity(0.25),
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withOpacity(0.25), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final String label = item['label'] as String;
              if (label.contains('Grower') || label.contains('Calf')) {
                _navigateToForm(
                  preSelectedClassification: item['classification'] as String,
                  preSelectedSex: item['sex'] as String,
                );
              } else {
                _navigateToForm(preSelectedClassification: label);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        item['iconPath'] as String,
                        width: 56,
                        height: 56,
                        color: color,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(item['fallback'] as IconData, color: color, size: 48);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController?.dispose();

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
    // Always set loading state to true when starting to fetch
    setState(() => _isLoading = true);
    
    try {
      // First, check and auto-update cattle classifications if needed
      final updatedCount = await CattleService.autoUpdateCattleClassifications();
      
      if (updatedCount > 0 && mounted) {
        debugPrint('✅ Auto-updated $updatedCount cattle classification(s)');
      }

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

  void _handleFiltersChanged(String sex, String classification, String status, String breed, String groupName) {
    setState(() {
      _selectedSex = sex;
      _selectedClassification = classification;
      _selectedStatus = status;
      _selectedBreed = breed;
      _selectedGroupName = groupName;
    });
    _filterCattle();
  }

  int _classificationSortKey(Cattle cattle) {
    // Desired order:
    // 0 Bull, 1 Cow, 2 Steer, 3 Heifer, 4 Male Growers, 5 Female Growers, 6 Male Calf, 7 Female Calf
    switch (cattle.classification) {
      case 'Bull':
        return 0;
      case 'Cow':
        return 1;
      case 'Steer':
        return 2;
      case 'Heifer':
        return 3;
      case 'Growers':
        return cattle.sex == 'Female' ? 5 : 4;
      case 'Calf':
        return cattle.sex == 'Female' ? 7 : 6;
      default:
        return 99;
    }
  }

  void _filterCattle() {
    setState(() {
      _filteredCattleList = _cattleList.where((cattle) {
        final matchesSearch = _searchQuery.isEmpty ||
            cattle.tagNo.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesSex = _selectedSex == 'All' ||
            cattle.sex == _selectedSex;

        final matchesClassification = _selectedClassification == 'All' ||
            cattle.classification == _selectedClassification;

        final matchesStatus = _selectedStatus == 'All' ||
            cattle.status == _selectedStatus;

        final matchesBreed = _selectedBreed == 'All' ||
            (cattle.breed != null && cattle.breed == _selectedBreed);

        final matchesGroupName = _selectedGroupName == 'All' ||
            (cattle.groupName != null && cattle.groupName == _selectedGroupName);

        return matchesSearch && matchesSex && matchesClassification &&
            matchesStatus && matchesBreed && matchesGroupName;
      }).toList();
      // Apply desired ordering
      _filteredCattleList.sort((a, b) {
        final ka = _classificationSortKey(a);
        final kb = _classificationSortKey(b);
        if (ka != kb) return ka.compareTo(kb);
        // Tie-breaker: tag number ascending
        return a.tagNo.toLowerCase().compareTo(b.tagNo.toLowerCase());
      });
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

  String? _mapReportTypeToParam(String value) {
    switch (value) {
      case 'All':
        return null;
      case 'Bull':
        return 'bull';
      case 'Cow':
        return 'cow';
      case 'Steer':
        return 'steer';
      case 'Heifer':
        return 'heifer';
      case 'Growers (Male)':
        return 'growers_male';
      case 'Growers (Female)':
        return 'growers_female';
      case 'Calf (Male)':
        return 'calf_male';
      case 'Calf (Female)':
        return 'calf_female';
      case 'Breeding':
        return 'breeding';
      case 'Pregnant':
        return 'pregnant';
      case 'Sick':
        return 'sick';
      default:
        return null;
    }
  }

  void _navigateToForm({Cattle? cattle, String? preSelectedClassification, String? preSelectedSex}) async {
    // The await/fetch pattern is kept as a fallback and for immediate refresh
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CattleFormScreen(
          cattle: cattle,
          preSelectedClassification: preSelectedClassification,
          preSelectedSex: preSelectedSex,
        ),
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
          height: 36,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.vibrantGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.vibrantGreen.withOpacity(0.2)),
                ),
                child: const Icon(Icons.edit_outlined, color: AppColors.vibrantGreen, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Edit Cattle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'add_event',
          height: 36,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.darkGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.darkGreen.withOpacity(0.2)),
                ),
                child: const Icon(Icons.event_note_outlined, color: AppColors.darkGreen, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Add History Record', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'change_stage',
          height: 36,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.lightGreen.withOpacity(0.2)),
                ),
                child: const Icon(Icons.arrow_upward_outlined, color: AppColors.lightGreen, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Change Stage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'change_status',
          height: 36,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.vibrantGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.vibrantGreen.withOpacity(0.2)),
                ),
                child: const Icon(Icons.swap_horiz, color: AppColors.vibrantGreen, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Change Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'export_excel',
          height: 36,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                alignment: Alignment.center,
                child: const FaIcon(FontAwesomeIcons.fileExcel, color: Colors.green, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Download Excel Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'export_pdf',
          height: 36,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Generate PDF Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'archive',
          height: 36,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                ),
                child: const Icon(Icons.archive_outlined, color: AppColors.gold, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Archive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.shade600.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade600.withOpacity(0.2)),
                ),
                child: Icon(Icons.delete_forever_outlined, color: Colors.red.shade600, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Delete Cattle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade600)),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) async {
        switch (value) {
          case 'edit':
            _navigateToForm(cattle: cattle);
            break;
          case 'add_event':
            // Show cattle selection modal for adding history
            final selectedTag = await showDialog<String>(
              context: context,
              builder: (context) => const CattleSelectionModal(),
            );
            if (selectedTag != null && context.mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CattleHistoryFormScreen(cattleTag: selectedTag),
                ),
              );
              _fetchCattle();
            }
            break;
          case 'export_excel':
          case 'export_pdf':
            // Show cattle selection modal for export
            final selectedTag = await showDialog<String>(
              context: context,
              builder: (context) => const CattleSelectionModal(),
            );
            if (selectedTag != null && context.mounted) {
              final selectedCattle = _cattleList.firstWhere(
                (c) => c.tagNo == selectedTag,
                orElse: () => cattle,
              );
              if (value == 'export_excel') {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                final okX = await CattleExportService.downloadCattleExcel(selectedCattle.id.toString());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(okX ? 'Excel report ready! Choose where to open/save.' : 'Failed to download Excel report.'),
                      backgroundColor: okX ? Colors.green.shade600 : Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } else if (value == 'export_pdf') {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                final okP = await CattleExportService.downloadCattlePdf(selectedCattle.id.toString());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(okP ? 'PDF report ready! Choose where to open/save.' : 'Failed to generate PDF report.'),
                      backgroundColor: okP ? Colors.green.shade600 : Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            }
            break;
          case 'change_stage':
            ChangeStageOption.show(context, cattle, _fetchCattle);
            break;
          case 'change_status':
            ChangeStatusOption.show(context, cattle, _fetchCattle);
            break;
          case 'archive':
            ArchiveOption.show(context, cattle: cattle, onCattleUpdated: _fetchCattle);
            break;
          case 'delete':
            DeleteOption.show(context);
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
                                          cattle.sex == 'Male' ? Icons.male : Icons.female,
                                          size: 18,
                                          color: cattle.sex == 'Male'
                                              ? AppColors.primary
                                              : AppColors.accent,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (cattle.status.isNotEmpty)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 140),
                                      child: Text(
                                        cattle.status,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accent,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
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
                                    (cattle.classification == 'Growers' || cattle.classification == 'Calf')
                                        ? '${cattle.classification} (${cattle.sex})'
                                        : cattle.classification,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Age display removed as requested
                                ],
                              ),
                              if (cattle.breed != null && cattle.breed!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cattle.breed!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                              ],
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
        _selectedSex != 'All' ||
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
      backgroundColor: AppColors.pageBackground.withOpacity(0.1),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: 'Add Cattle'),
                  Tab(text: 'Cattle List'),
                ],
              ),
            ),
            Expanded(
        child: _isLoading
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
                  : TabBarView(
                      children: [
                        // Tab 1: Add Cattle (classification grid)
                        _buildAddCattleGrid(),
                        // Tab 2: Cattle List
                        Column(
        children: [
          if (_cattleList.isNotEmpty) ...[
            CattleSearchFilterWidget(
              onSearchChanged: _handleSearchChanged,
              onFiltersChanged: _handleFiltersChanged,
              initialSex: _selectedSex,
              initialClassification: _selectedClassification,
              initialStatus: _selectedStatus,
              initialBreed: _selectedBreed,
              initialGroupName: _selectedGroupName,
              breedOptions: _getUniqueBreedOptions(),
              groupNameOptions: _getUniqueGroupNameOptions(),
              onArchivePressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ArchivedCattleScreen(),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  // Report type selector
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 215),
                    child: DropdownButtonFormField<String>(
                      value: _selectedReportType,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'Bull', child: Text('Bull')),
                        DropdownMenuItem(value: 'Cow', child: Text('Cow')),
                        DropdownMenuItem(value: 'Steer', child: Text('Steer')),
                        DropdownMenuItem(value: 'Heifer', child: Text('Heifer')),
                        DropdownMenuItem(value: 'Growers (Male)', child: Text('Growers (Male)')),
                        DropdownMenuItem(value: 'Growers (Female)', child: Text('Growers (Female)')),
                        DropdownMenuItem(value: 'Calf (Male)', child: Text('Calf (Male)')),
                        DropdownMenuItem(value: 'Calf (Female)', child: Text('Calf (Female)')),
                        DropdownMenuItem(value: 'Breeding', child: Text('Breeding')),
                        DropdownMenuItem(value: 'Pregnant', child: Text('Pregnant')),
                        DropdownMenuItem(value: 'Sick', child: Text('Sick')),
                      ],
                      onChanged: (v) {
                        setState(() { _selectedReportType = v ?? 'All'; });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Report type',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF107C41),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      tooltip: 'Export Excel',
                      icon: const FaIcon(FontAwesomeIcons.fileExcel, color: Colors.white, size: 20),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        final rt = _mapReportTypeToParam(_selectedReportType);
                        final ok = await CattleExportService.downloadCattleListExcel(reportType: rt);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Excel report ready! Choose where to open/save.' : 'Failed to download Excel report.'),
                            backgroundColor: ok ? Colors.green.shade600 : Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      tooltip: 'Export PDF',
                      icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        final rt = _mapReportTypeToParam(_selectedReportType);
                        final ok = await CattleExportService.downloadCattleListPdf(reportType: rt);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'PDF report ready! Choose where to open/save.' : 'Failed to generate PDF report.'),
                            backgroundColor: ok ? Colors.green.shade600 : Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: _filteredCattleList.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _fetchCattle,
              color: AppColors.primary,
              child: ListView.builder(
                                        padding: const EdgeInsets.only(bottom: 16),
                itemCount: _filteredCattleList.length,
                itemBuilder: (context, index) =>
                    _buildCattleCard(_filteredCattleList[index], index),
              ),
            ),
          ),
        ],
      ),
                    ],
                  ),
                    ),
                  ],
            ),
          ),
    );
  }
}
