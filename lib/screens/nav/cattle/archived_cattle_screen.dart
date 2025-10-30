import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_history_service.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/cattle_detail_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ArchivedCattleScreen extends StatefulWidget {
  const ArchivedCattleScreen({super.key});

  @override
  State<ArchivedCattleScreen> createState() => _ArchivedCattleScreenState();
}

class _ArchivedCattleScreenState extends State<ArchivedCattleScreen> {
  List<Cattle> _archivedCattle = [];
  List<Cattle> _filteredCattleList = [];
  Map<String, Map<String, dynamic>> _cattleEventDetails = {};
  Map<String, bool> _expandedCards = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadArchivedCattle();
  }

  Future<void> _loadArchivedCattle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cattle = await CattleService.getArchivedCattle();
      
      // Fetch event details for each cattle
      final Map<String, Map<String, dynamic>> eventDetails = {};
      for (final cattleItem in cattle) {
        try {
          final events = await CattleHistoryService.getCattleHistory();
          final cattleEvents = events.where((event) =>
              (event['cattle_tag']?.toString().trim().toLowerCase() ?? '') ==
                  cattleItem.tagNo.trim().toLowerCase()
          ).toList();
          
          // Find the most recent archive-related event
          final archiveEvent = cattleEvents.where((event) {
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
            
            eventDetails[cattleItem.tagNo] = archiveEvent.first;
          }
        } catch (e) {
          // If we can't fetch event details for this cattle, continue with others
          print('Error fetching event details for ${cattleItem.tagNo}: $e');
        }
      }
      
      setState(() {
        _archivedCattle = cattle;
        _cattleEventDetails = eventDetails;
        _filterCattle(); // Apply filters to the new data
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading archived cattle: $e'),
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
    _filterCattle();
  }

  void _filterCattle() {
    setState(() {
      _filteredCattleList = _archivedCattle.where((cattle) {
        final matchesSearch = _searchQuery.isEmpty ||
            cattle.tagNo.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesStatus = _selectedStatus == 'All' ||
            cattle.status == _selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _unarchiveCattle(Cattle cattle) async {
    try {
      final success = await CattleService.unarchiveCattle(cattle.id);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cattle restored from archive successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadArchivedCattle(); // Refresh the list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to restore cattle from archive'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring cattle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUnarchiveDialog(Cattle cattle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restore Cattle'),
          content: Text('Are you sure you want to restore ${cattle.tagNo} from the archive?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _unarchiveCattle(cattle);
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

  void _navigateToCattleDetail(Cattle cattle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CattleDetailScreen(
          cattleId: cattle.id,
          isArchived: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Cattle'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivedCattle.isEmpty
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
                        'No archived cattle found',
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
                    
                    // Cattle List
                    Expanded(
                      child: _filteredCattleList.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadArchivedCattle,
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
                border: Border.all(color: AppColors.lightGreen.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
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
                color: _selectedStatus != 'All' ? AppColors.primary : AppColors.lightGreen.withOpacity(0.3)
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
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
            _filterCattle();
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
            hasActiveFilters ? 'No cattle found matching your filters' : 'No archived cattle found',
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
                _filterCattle();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCattleCard(Cattle cattle, int index) {
    final isExpanded = _expandedCards[cattle.tagNo] ?? false;
    
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
                  _expandedCards[cattle.tagNo] = !isExpanded;
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
                        color: _getStatusColor(cattle.status).withOpacity(0.1),
                        border: Border.all(
                          color: _getStatusColor(cattle.status).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: FaIcon(
                          _getStatusIcon(cattle.status),
                          color: _getStatusColor(cattle.status),
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
                            cattle.tagNo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Classification and Breed inline
                          Text(
                            '${cattle.classification}${cattle.breed != null && cattle.breed!.isNotEmpty ? ' • ${cattle.breed}' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (cattle.age != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Age: ${cattle.age}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Status Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(cattle.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(cattle.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        cattle.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(cattle.status),
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
                          _showUnarchiveDialog(cattle);
                        } else if (value == 'cattle_info') {
                          _navigateToCattleDetail(cattle);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'cattle_info',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Cattle Info'),
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
                          color: AppColors.lightGreen.withOpacity(0.1),
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
                              color: _getStatusColor(cattle.status).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(cattle.status).withOpacity(0.2),
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
                                    color: _getStatusColor(cattle.status),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getArchiveDetailsText(cattle),
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

  String _getArchiveDetailsText(Cattle cattle) {
    final eventData = _cattleEventDetails[cattle.tagNo];
    
    if (eventData == null) {
      return 'This cattle has been archived. Event details not available.';
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
