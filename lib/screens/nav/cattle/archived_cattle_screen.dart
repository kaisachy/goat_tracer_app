import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ArchivedCattleScreen extends StatefulWidget {
  const ArchivedCattleScreen({super.key});

  @override
  State<ArchivedCattleScreen> createState() => _ArchivedCattleScreenState();
}

class _ArchivedCattleScreenState extends State<ArchivedCattleScreen> {
  List<Cattle> _archivedCattle = [];
  List<Cattle> _filteredCattleList = [];
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
      setState(() {
        _archivedCattle = cattle;
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

  void _handleStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
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
              _buildStatusOption('Deceased'),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            // You can add navigation to cattle detail if needed
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Cattle Image/Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _getStatusColor(cattle.status).withOpacity(0.1),
                    border: Border.all(
                      color: _getStatusColor(cattle.status).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: cattle.hasPicture
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            cattle.imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: FaIcon(
                            FontAwesomeIcons.cow,
                            color: _getStatusColor(cattle.status),
                            size: 30,
                          ),
                        ),
                ),
                
                const SizedBox(width: 16),
                
                // Cattle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cattle.tagNo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${cattle.sex} • ${cattle.classification}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (cattle.breed != null && cattle.breed!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          cattle.breed!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
                
                // Status Label and Action Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    
                    // Action Button
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'restore') {
                          _showUnarchiveDialog(cattle);
                        }
                      },
                      itemBuilder: (context) => [
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sold':
        return AppColors.gold;
      case 'deceased':
        return Colors.red;
      default:
        return AppColors.vibrantGreen;
    }
  }
}
