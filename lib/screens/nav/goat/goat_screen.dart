import 'package:goat_tracer_app/screens/nav/goat/widgets/goat_search_filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';
import 'package:goat_tracer_app/services/goat/goat_export_service.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_form_screen.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_detail_screen.dart';
import 'package:goat_tracer_app/screens/nav/goat/archived_goat_screen.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_history_form_screen.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/change_stage_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/change_status_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/archive_option.dart';
import 'package:goat_tracer_app/screens/nav/goat/modals/options/delete_option.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class GoatScreen extends StatefulWidget {
  const GoatScreen({super.key});

  @override
  State<GoatScreen> createState() => _GoatScreenState();
}

// ✨ MODIFIED: Added the WidgetsBindingObserver mixin
class _GoatScreenState extends State<GoatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Goat> _goatList = [];
  List<Goat> _filteredGoatList = [];
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

    _fetchGoat();
  }

  Widget _buildAddgoatGrid() {
    final List<Map<String, dynamic>> items = [
      {
        'label': 'Buck',
        'iconPath': 'assets/images/goat-icons/buck.png',
        'color': AppColors.vibrantGreen,
        'fallback': Icons.male,
      },
      {
        'label': 'Doe',
        'iconPath': 'assets/images/goat-icons/doe.png',
        'color': AppColors.primary,
        'fallback': 'goat', // Special marker for goat icon
      },
      {
        'label': 'Buckling',
        'iconPath': 'assets/images/goat-icons/buckling.png',
        'color': Colors.blue,
        'fallback': Icons.pets,
      },
      {
        'label': 'Doeling',
        'iconPath': 'assets/images/goat-icons/doeling.png',
        'color': AppColors.accent,
        'fallback': Icons.female,
      },
      {
        'label': 'Grower (M)',
        'classification': 'Growers',
        'sex': 'Male',
        'iconPath': 'assets/images/goat-icons/growers.png',
        'color': AppColors.lightGreen,
        'fallback': Icons.trending_up,
      },
      {
        'label': 'Grower (F)',
        'classification': 'Growers',
        'sex': 'Female',
        'iconPath': 'assets/images/goat-icons/growers.png',
        'color': AppColors.lightGreen,
        'fallback': Icons.trending_up,
      },
      {
        'label': 'Kid (M)',
        'classification': 'Kid',
        'sex': 'Male',
        'iconPath': 'assets/images/goat-icons/kid.png',
        'color': Colors.orange,
        'fallback': Icons.child_care,
      },
      {
        'label': 'Kid (F)',
        'classification': 'Kid',
        'sex': 'Female',
        'iconPath': 'assets/images/goat-icons/kid.png',
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
          shadowColor: color.withValues(alpha: 0.25),
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final String label = item['label'] as String;
              if (label.contains('Grower') || label.contains('Kid')) {
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
                          final fallback = item['fallback'];
                          if (fallback == 'goat') {
                            return Image.asset(
                              'assets/images/goat-icons/goat.png',
                              width: 48,
                              height: 48,
                              color: color,
                            );
                          }
                          return Icon(fallback as IconData, color: color, size: 48);
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
      _fetchGoat();
    }
  }

  Future<void> _fetchGoat() async {
    // Always set loading state to true when starting to fetch
    setState(() => _isLoading = true);
    
    try {
      // First, check and auto-update goat classifications if needed
      final updatedCount = await GoatService.autoUpdategoatClassifications();
      
      if (updatedCount > 0 && mounted) {
        debugPrint('✅ Auto-updated $updatedCount goat classification(s)');
      }

      final data = await GoatService.getGoatInformation();
      if (mounted) {
        setState(() {
          _goatList = data.map((e) => Goat.fromJson(e)).toList();
          _filterGoat(); // Apply existing filters to the new data
          _isLoading = false;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load goat data'),
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
    _filterGoat();
  }

  void _handleFiltersChanged(String sex, String classification, String status, String breed, String groupName) {
    setState(() {
      _selectedSex = sex;
      _selectedClassification = classification;
      _selectedStatus = status;
      _selectedBreed = breed;
      _selectedGroupName = groupName;
    });
    _filterGoat();
  }

  int _classificationSortKey(Goat goat) {
    // Desired order:
    // 0 Buck, 1 Doe, 2 Buckling, 3 Doeling, 4 Male Growers, 5 Female Growers, 6 Male Kid, 7 Female Kid
    switch (goat.classification) {
      case 'Buck':
        return 0;
      case 'Doe':
        return 1;
      case 'Buckling':
        return 2;
      case 'Doeling':
        return 3;
      case 'Growers':
        return goat.sex == 'Female' ? 5 : 4;
      case 'Kid':
        return goat.sex == 'Female' ? 7 : 6;
      default:
        return 99;
    }
  }

  void _filterGoat() {
    setState(() {
      _filteredGoatList = _goatList.where((goat) {
        final matchesSearch = _searchQuery.isEmpty ||
            goat.tagNo.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesSex = _selectedSex == 'All' ||
            goat.sex == _selectedSex;

        final matchesClassification = _selectedClassification == 'All' ||
            goat.classification == _selectedClassification;

        final matchesStatus = _selectedStatus == 'All' ||
            goat.status == _selectedStatus;

        final matchesBreed = _selectedBreed == 'All' ||
            (goat.breed != null && goat.breed == _selectedBreed);

        final matchesGroupName = _selectedGroupName == 'All' ||
            (goat.groupName != null && goat.groupName == _selectedGroupName);

        return matchesSearch && matchesSex && matchesClassification &&
            matchesStatus && matchesBreed && matchesGroupName;
      }).toList();
      // Apply desired ordering
      _filteredGoatList.sort((a, b) {
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
    for (var goat in _goatList) {
      if (goat.breed != null && goat.breed!.isNotEmpty) {
        breeds.add(goat.breed!);
      }
    }
    return breeds.toList()..sort();
  }

  List<String> _getUniqueGroupNameOptions() {
    Set<String> groupNames = {'All'};
    for (var goat in _goatList) {
      if (goat.groupName != null && goat.groupName!.isNotEmpty) {
        groupNames.add(goat.groupName!);
      }
    }
    return groupNames.toList()..sort();
  }

  String? _mapReportTypeToParam(String value) {
    switch (value) {
      case 'All':
        return null;
      case 'Buck':
        return 'Buck';
      case 'Doe':
        return 'Doe';
      case 'Buckling':
        return 'Buckling';
      case 'Doeling':
        return 'Doeling';
      case 'Growers (Male)':
        return 'growers_male';
      case 'Growers (Female)':
        return 'growers_female';
      case 'Kid (Male)':
        return 'Kid_male';
      case 'Kid (Female)':
        return 'Kid_female';
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

  void _navigateToForm({Goat? goat, String? preSelectedClassification, String? preSelectedSex}) async {
    // The await/fetch pattern is kept as a fallback and for immediate refresh
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GoatFormScreen(
          goat: goat,
          preSelectedClassification: preSelectedClassification,
          preSelectedSex: preSelectedSex,
        ),
      ),
    );
    _fetchGoat();
  }

  void _navigateToDetail(Goat goat) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GoatDetailScreen(goat: goat),
      ),
    );
    _fetchGoat();
  }







  Widget _buildGoatOptionsMenu(Goat goat) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppColors.textSecondary.withValues(alpha: 0.8),
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
                  color: AppColors.vibrantGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.vibrantGreen.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.edit_outlined, color: AppColors.vibrantGreen, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Edit Goat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                  color: AppColors.darkGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.darkGreen.withValues(alpha: 0.2)),
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
                  color: AppColors.lightGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.lightGreen.withValues(alpha: 0.2)),
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
                  color: AppColors.vibrantGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.vibrantGreen.withValues(alpha: 0.2)),
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
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
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
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
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
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
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
                  color: Colors.red.shade600.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade600.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.delete_forever_outlined, color: Colors.red.shade600, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Delete Goat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade600)),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) async {
        switch (value) {
          case 'edit':
            _navigateToForm(goat: goat);
            break;
          case 'add_event':
            // Directly use the goat whose menu was clicked
              if (!mounted) break;
              await Navigator.push(
                context,
                MaterialPageRoute(
                builder: (context) => GoatHistoryFormScreen(goatTag: goat.tagNo),
                ),
              );
              if (!mounted) break;
              _fetchGoat();
            break;
          case 'export_excel':
            // Directly export the goat whose menu was clicked
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Generating Excel report...'),
                  ],
                ),
                backgroundColor: Colors.blue.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 10),
              ),
            );
            final okX = await GoatExportService.downloadgoatExcel(goat.id.toString());
            if (!mounted) break;
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text(okX ? 'Excel report ready! Choose where to open/save.' : 'Failed to download Excel report.'),
                backgroundColor: okX ? Colors.green.shade600 : Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            break;
          case 'export_pdf':
            // Directly export the goat whose menu was clicked
            final messengerPdf = ScaffoldMessenger.of(context);
            messengerPdf.hideCurrentSnackBar();
            messengerPdf.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Generating PDF report...'),
                  ],
                ),
                backgroundColor: Colors.blue.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 10),
              ),
            );
            final okP = await GoatExportService.downloadgoatPdf(goat.id.toString());
            if (!mounted) break;
            messengerPdf.hideCurrentSnackBar();
            messengerPdf.showSnackBar(
              SnackBar(
                content: Text(okP ? 'PDF report ready! Choose where to open/save.' : 'Failed to generate PDF report.'),
                backgroundColor: okP ? Colors.green.shade600 : Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            break;
          case 'change_stage':
            ChangeStageOption.show(context, goat, _fetchGoat);
            break;
          case 'change_status':
            ChangeStatusOption.show(context, goat, _fetchGoat);
            break;
          case 'archive':
            ArchiveOption.show(context, goat: goat, onGoatUpdated: _fetchGoat);
            break;
          case 'delete':
            DeleteOption.show(context, goat: goat, onGoatDeleted: _fetchGoat);
            break;
        }
      },
    );
  }

  Widget _buildGoatCard(Goat goat, int index) {
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
            shadowColor: AppColors.primary.withValues(alpha: 0.2),
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.lightGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () => _navigateToDetail(goat),
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
                          child: goat.hasPicture
                              ? Image.memory(
                            goat.imageBytes!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: AppColors.lightGreen.withValues(alpha: 0.5),
                                child: Icon(Icons.error_outline, color: Colors.red.shade400),
                              );
                            },
                          )
                              : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/goat-icons/goat.png',
                                width: 28,
                                height: 28,
                              color: AppColors.primary,
                                fit: BoxFit.contain,
                              ),
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
                                            goat.tagNo,
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
                                          goat.sex == 'Male' ? Icons.male : Icons.female,
                                          size: 18,
                                          color: goat.sex == 'Male'
                                              ? AppColors.primary
                                              : AppColors.accent,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (goat.status.isNotEmpty)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 140),
                                      child: Text(
                                        goat.status,
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
                                    (goat.classification == 'Growers' || goat.classification == 'Kid')
                                        ? '${goat.classification} (${goat.sex})'
                                        : goat.classification,
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
                              if (goat.breed != null && goat.breed!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        goat.breed!,
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
                        _buildGoatOptionsMenu(goat),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (goat.weight != null) ...[
                          Icon(Icons.monitor_weight, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${goat.weight}kg',
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
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Image.asset(
              'assets/images/goat-icons/goat.png',
              width: 60,
              height: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasActiveFilters
                ? 'No goat match your search'
                : 'No goat records found',
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
                : 'Add your first goat to get started',
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
      backgroundColor: AppColors.pageBackground.withValues(alpha: 0.1),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: 'Add Goat'),
                  Tab(text: 'Goat List'),
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
              'Loading goat data...',
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
                        // Tab 1: Add Goat (classification grid)
                        _buildAddgoatGrid(),
                        // Tab 2: goat List
                        Column(
        children: [
          if (_goatList.isNotEmpty) ...[
            GoatSearchFilterWidget(
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
                    builder: (context) => const ArchivedgoatScreen(),
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
                        DropdownMenuItem(value: 'Buck', child: Text('Buck')),
                        DropdownMenuItem(value: 'Doe', child: Text('Doe')),
                        DropdownMenuItem(value: 'Buckling', child: Text('Buckling')),
                        DropdownMenuItem(value: 'Doeling', child: Text('Doeling')),
                        DropdownMenuItem(value: 'Growers (Male)', child: Text('Growers (Male)')),
                        DropdownMenuItem(value: 'Growers (Female)', child: Text('Growers (Female)')),
                        DropdownMenuItem(value: 'Kid (Male)', child: Text('Kid (Male)')),
                        DropdownMenuItem(value: 'Kid (Female)', child: Text('Kid (Female)')),
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
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.hideCurrentSnackBar();
                        final rt = _mapReportTypeToParam(_selectedReportType);
                        final ok = await GoatExportService.downloadgoatListExcel(reportType: rt);
                        if (!mounted) return;
                        messenger.showSnackBar(
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
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.hideCurrentSnackBar();
                        final rt = _mapReportTypeToParam(_selectedReportType);
                        final ok = await GoatExportService.downloadgoatListPdf(reportType: rt);
                        if (!mounted) return;
                        messenger.showSnackBar(
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
            child: _filteredGoatList.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _fetchGoat,
              color: AppColors.primary,
              child: ListView.builder(
                                        padding: const EdgeInsets.only(bottom: 16),
                itemCount: _filteredGoatList.length,
                itemBuilder: (context, index) =>
                    _buildGoatCard(_filteredGoatList[index], index),
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

