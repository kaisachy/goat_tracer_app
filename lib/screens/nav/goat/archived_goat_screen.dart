import 'package:flutter/material.dart';
import 'package:goat_tracer_app/models/goat.dart';
import 'package:goat_tracer_app/services/goat/goat_service.dart';
import 'package:goat_tracer_app/services/goat/goat_history_service.dart';
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/screens/nav/goat/goat_detail_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goat_tracer_app/services/goat/goat_export_service.dart';

class ArchivedgoatScreen extends StatefulWidget {
  const ArchivedgoatScreen({super.key});

  @override
  State<ArchivedgoatScreen> createState() => _ArchivedgoatScreenState();
}

class _ArchivedgoatScreenState extends State<ArchivedgoatScreen> {
  List<Goat> _archivedGoat = [];
  List<Goat> _filteredGoatList = [];
  Map<String, Map<String, dynamic>> _goatEventDetails = {};
  final Map<String, bool> _expandedCards = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedReportType = 'Lost';

  @override
  void initState() {
    super.initState();
    _loadArchivedGoat();
  }

  List<Widget> _buildAgeLine(Goat goat) {
    String? ageText;
    if (goat.age != null && goat.age!.toString().trim().isNotEmpty &&
        goat.age!.toString().trim().toLowerCase() != 'unknown' &&
        goat.age!.toString().trim().toLowerCase() != 'n/a') {
      ageText = goat.age!.toString().trim();
    } else if (goat.dateOfBirth != null && goat.dateOfBirth!.isNotEmpty) {
      final formatted = _formatAgeFromDob(goat.dateOfBirth!);
      if (formatted.isNotEmpty) ageText = formatted;
    }

    if (ageText == null) return const [];

    return [
      const SizedBox(height: 2),
      Text(
        'Age: $ageText',
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    ];
  }

  String _formatAgeFromDob(String dobIso) {
    try {
      final dob = DateTime.parse(dobIso);
      final now = DateTime.now();
      int years = now.year - dob.year;
      int months = now.month - dob.month;
      int days = now.day - dob.day;

      if (days < 0) {
        final prevMonth = DateTime(now.year, now.month, 0);
        days += prevMonth.day;
        months -= 1;
      }
      if (months < 0) {
        months += 12;
        years -= 1;
      }

      final yearsLabel = '${years}y';
      final monthsLabel = '${months}m';

      if (years > 0) {
        return months > 0 ? '$yearsLabel $monthsLabel' : yearsLabel;
      }
      if (months > 0) return monthsLabel;
      final d = now.difference(dob).inDays;
      final daysLabel = '${d}d';
      return d <= 1 ? '1d' : daysLabel;
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadArchivedGoat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final goat = await GoatService.getArchivedgoat();
      
      // Fetch event details for each goat
      final Map<String, Map<String, dynamic>> eventDetails = {};
      for (final goatItem in goat) {
        try {
          // Fetch only this goat's history to ensure archive details are available
          final goatEvents = await GoatHistoryService.getgoatHistoryByTag(goatItem.tagNo);
          
          // Find the most recent archive-related event
          final archiveEvent = goatEvents.where((event) {
            final eventType = (event['history_type']?.toString().toLowerCase() ?? '');
            return eventType == 'sold' || eventType == 'mortality' || eventType == 'lost';
          }).toList();
          
          if (archiveEvent.isNotEmpty) {
            // Sort by date and get the most recent
            archiveEvent.sort((a, b) {
              final dateA = DateTime.tryParse(a['history_date'] ?? '1900-01-01') ?? DateTime(1900);
              final dateB = DateTime.tryParse(b['history_date'] ?? '1900-01-01') ?? DateTime(1900);
              return dateB.compareTo(dateA);
            });
            
            eventDetails[goatItem.tagNo] = archiveEvent.first;
          }
        } catch (e) {
          // If we can't fetch event details for this goat, continue with others
          debugPrint('Error fetching event details for ${goatItem.tagNo}: $e');
        }
      }
      
      setState(() {
        _archivedGoat = goat;
        _goatEventDetails = eventDetails;
        _filtergoat(); // Apply filters to the new data
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading archived goat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filtergoat();
  }

  void _filtergoat() {
    setState(() {
      _filteredGoatList = _archivedGoat.where((goat) {
        final matchesSearch = _searchQuery.isEmpty ||
            goat.tagNo.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesStatus = _selectedStatus == 'All' ||
            goat.status == _selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _unarchiveGoat(Goat goat) async {
    try {
      final success = await GoatService.unarchivegoat(goat.id);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('goat restored from archive successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadArchivedGoat(); // Refresh the list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to restore goat from archive'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring goat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUnarchiveDialog(Goat goat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restore goat'),
          content: Text('Are you sure you want to restore ${goat.tagNo} from the archive?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _unarchiveGoat(goat);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vibrantGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToGoatDetail(Goat goat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoatDetailScreen(
          goatId: goat.id,
          isArchived: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived goat'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivedGoat.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No archived goat found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search and Filter Bar
                    _buildSearchAndFilterBar(),
                    // Export controls row (below the filter bar)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Row(
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 215),
                            child: DropdownButtonFormField<String>(
                              value: _selectedReportType,
                              items: const [
                                DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                                DropdownMenuItem(value: 'Sold', child: Text('Sold')),
                                DropdownMenuItem(value: 'Mortality', child: Text('Mortality')),
                              ],
                              onChanged: (v) {
                                setState(() { _selectedReportType = v ?? 'Lost'; });
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
                                final rt = _mapArchivedReportTypeToParam(_selectedReportType);
                                final ok = await GoatExportService.downloadgoatListExcel(reportType: rt);
                                if (!context.mounted) return;
                                messenger.hideCurrentSnackBar();
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
                                final rt = _mapArchivedReportTypeToParam(_selectedReportType);
                                final ok = await GoatExportService.downloadgoatListPdf(reportType: rt);
                                if (!context.mounted) return;
                                messenger.hideCurrentSnackBar();
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
                    // goat List
                    Expanded(
                      child: _filteredGoatList.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadArchivedGoat,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _filteredGoatList.length,
                                itemBuilder: (context, index) =>
                                    _buildGoatCard(_filteredGoatList[index], index),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightGreen.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _handleSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by tag no.',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Status Filter Button
          Container(
            decoration: BoxDecoration(
              color: _selectedStatus != 'All' ? AppColors.primary : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedStatus != 'All' ? AppColors.primary : AppColors.lightGreen.withValues(alpha: 0.3)
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showStatusFilterDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: _selectedStatus != 'All' ? Colors.white : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedStatus,
                        style: TextStyle(
                          color: _selectedStatus != 'All' ? Colors.white : AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mapArchivedReportTypeToParam(String value) {
    switch (value) {
      case 'Lost':
        return 'lost';
      case 'Sold':
        return 'sold';
      case 'Mortality':
        return 'dead';
      default:
        return 'lost';
    }
  }

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption('All'),
              _buildStatusOption('Sold'),
              _buildStatusOption('Mortality'),
              _buildStatusOption('Lost'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(String status) {
    return ListTile(
      title: Text(status),
      leading: Radio<String>(
        value: status,
        groupValue: _selectedStatus,
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _selectedStatus = value;
            });
            _filtergoat();
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    bool hasActiveFilters = _searchQuery.isNotEmpty || _selectedStatus != 'All';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasActiveFilters ? Icons.search_off : Icons.archive_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters ? 'No goat found matching your filters' : 'No archived goat found',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedStatus = 'All';
                });
                _filtergoat();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoatCard(Goat goat, int index) {
    final isExpanded = _expandedCards[goat.tagNo] ?? false;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            // Header Row - Always Visible
            InkWell(
              onTap: () {
                setState(() {
                  _expandedCards[goat.tagNo] = !isExpanded;
                });
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Status Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _getStatusColor(goat.status).withValues(alpha: 0.1),
                        border: Border.all(
                          color: _getStatusColor(goat.status).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: FaIcon(
                          _getStatusIcon(goat.status),
                          color: _getStatusColor(goat.status),
                          size: 20,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Tag No and Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag No
                          Text(
                            goat.tagNo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Classification and Breed inline
                          Text(
                            '${goat.classification}'
                            '${(goat.breed != null && goat.breed!.isNotEmpty && goat.breed!.toLowerCase() != 'unknown') ? ' • ${goat.breed}' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ..._buildAgeLine(goat),
                        ],
                      ),
                    ),
                    
                    // Status Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(goat.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(goat.status).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        goat.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(goat.status),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Expand/Collapse Icon
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Action Button
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'restore') {
                          _showUnarchiveDialog(goat);
                        } else if (value == 'goat_info') {
                          _navigateToGoatDetail(goat);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'goat_info',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('goat Info'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(Icons.restore, color: AppColors.vibrantGreen),
                              SizedBox(width: 8),
                              Text('Restore'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Expandable Content
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: isExpanded ? null : 0,
              child: isExpanded
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          // Event Details Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getStatusColor(goat.status).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(goat.status).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(goat.status),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getArchiveDetailsText(goat),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sold':
        return AppColors.gold;
      case 'mortality':
        return Colors.red;
      case 'lost':
        return Colors.orange;
      default:
        return AppColors.vibrantGreen;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'sold':
        return FontAwesomeIcons.dollarSign;
      case 'mortality':
        return FontAwesomeIcons.skull;
      case 'lost':
        return FontAwesomeIcons.locationDot;
      default:
        return FontAwesomeIcons.cow;
    }
  }

  String _getArchiveDetailsText(Goat goat) {
    final eventData = _goatEventDetails[goat.tagNo];
    
    if (eventData == null) {
      // Fallback: show basic status information when no history record was found
      final status = goat.status.toLowerCase();
      if (status == 'sold') {
        return 'Sold (no detailed history record found).';
      } else if (status == 'mortality') {
        return 'Mortality (no detailed history record found).';
      } else if (status == 'lost') {
        return 'Lost (no detailed history record found).';
      }
      return 'This goat has been archived. Event details not available.';
    }
    
    final eventType = (eventData['history_type']?.toString().toLowerCase() ?? '');
    final eventDate = _formatDate(eventData['history_date']);
    final notes = eventData['notes']?.toString() ?? '';
    
    switch (eventType) {
      case 'sold':
        final amount = eventData['sold_amount']?.toString();
        final buyer = eventData['buyer']?.toString();
        String details = 'Sold on $eventDate';
        if (amount != null && amount.isNotEmpty) {
          final formattedAmount = _formatAmount(amount);
          details += '\nAmount: ₱$formattedAmount';
        }
        if (buyer != null && buyer.isNotEmpty) {
          details += '\nBuyer: $buyer';
        }
        if (notes.isNotEmpty) {
          details += '\nNotes: $notes';
        }
        return details;
        
      case 'mortality':
        final causeOfDeath = eventData['cause_of_death']?.toString();
        String details = 'Mortality on $eventDate';
        if (causeOfDeath != null && causeOfDeath.isNotEmpty) {
          details += '\nCause: $causeOfDeath';
        }
        if (notes.isNotEmpty) {
          details += '\nNotes: $notes';
        }
        return details;
        
      case 'lost':
        final lastLocation = eventData['last_known_location']?.toString();
        String details = 'Lost on $eventDate';
        if (lastLocation != null && lastLocation.isNotEmpty) {
          details += '\nLast Location: $lastLocation';
        }
        if (notes.isNotEmpty) {
          details += '\nNotes: $notes';
        }
        return details;
        
      default:
        return 'Archived on $eventDate${notes.isNotEmpty ? '\nNotes: $notes' : ''}';
    }
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
  
  String _formatAmount(String amount) {
    try {
      final number = double.parse(amount);
      return number.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return amount;
    }
  }
}



