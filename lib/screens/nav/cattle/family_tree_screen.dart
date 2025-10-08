import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cattle_tracer_app/models/cattle.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/services/cattle/cattle_service.dart';

class FamilyTreeScreen extends StatefulWidget {
  final Cattle cattle;

  const FamilyTreeScreen({super.key, required this.cattle});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  Map<String, dynamic>? _familyTreeData;
  Map<int, List<dynamic>> _siblingOffspring = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFamilyTree();
  }

  Future<void> _loadFamilyTree() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get simple family tree data - only immediate family
      final familyTreeData = await CattleService.getFamilyTree(widget.cattle.id);
      
      // Ensure we have a valid data structure
      Map<String, dynamic> processedData = {};
      
      if (familyTreeData != null) {
        processedData = Map<String, dynamic>.from(familyTreeData);
        
        // Ensure cattle data exists
        if (processedData['cattle'] == null) {
          processedData['cattle'] = {
            'id': widget.cattle.id,
            'tag_no': widget.cattle.tagNo,
            'classification': widget.cattle.classification
          };
        }
        
        // Ensure parents is a Map
        if (processedData['parents'] is! Map<String, dynamic>) {
          processedData['parents'] = <String, dynamic>{};
        }
        
        // Ensure siblings is a List
        if (processedData['siblings'] is! List<dynamic>) {
          processedData['siblings'] = <dynamic>[];
        }
        
        // Ensure offspring is a List
        if (processedData['offspring'] is! List<dynamic>) {
          processedData['offspring'] = <dynamic>[];
        }
        
        // Load offspring of siblings
        final siblingsData = processedData['siblings'];
        if (siblingsData is List<dynamic>) {
          for (var sibling in siblingsData) {
            if (sibling != null && sibling is Map<String, dynamic> && sibling['id'] != null) {
              try {
                final siblingTree = await CattleService.getFamilyTree(sibling['id']);
                if (siblingTree != null && siblingTree['offspring'] is List<dynamic>) {
                  _siblingOffspring[sibling['id']] = siblingTree['offspring'] as List<dynamic>;
                }
              } catch (e) {
                // Continue if we can't get sibling's offspring
                print('Could not get offspring for sibling ${sibling['id']}: $e');
              }
            }
          }
        }
      } else {
        // Create minimal data structure if API returns null
        processedData = {
          'cattle': {
            'id': widget.cattle.id,
            'tag_no': widget.cattle.tagNo,
            'classification': widget.cattle.classification
          },
          'parents': <String, dynamic>{},
          'siblings': <dynamic>[],
          'offspring': <dynamic>[]
        };
      }
      
      if (mounted) {
        setState(() {
          _familyTreeData = processedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.vibrantGreen),
                  ),
                ),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: _buildErrorState(),
            )
          else if (_familyTreeData != null)
            SliverToBoxAdapter(
              child: _buildSimpleFamilyTree(),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkGreen,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.account_tree,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Family Tree',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkGreen, AppColors.vibrantGreen],
            ),
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Error Loading Family Tree',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFamilyTree,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFamilyTree() {
    // Safe data extraction with null checks
    final cattleData = _familyTreeData!['cattle'];
    final cattle = (cattleData is Map<String, dynamic>) ? cattleData : 
        {'id': widget.cattle.id, 'tag_no': widget.cattle.tagNo, 'classification': widget.cattle.classification};
    
    final parentsData = _familyTreeData!['parents'];
    final parents = (parentsData is Map<String, dynamic>) ? parentsData : <String, dynamic>{};
    
    final siblingsData = _familyTreeData!['siblings'];
    final siblings = (siblingsData is List<dynamic>) ? siblingsData : <dynamic>[];
    
    final offspringData = _familyTreeData!['offspring'];
    final offspring = (offspringData is List<dynamic>) ? offspringData : <dynamic>[];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header with selected cattle info
            _buildHeader(cattle),
            const SizedBox(height: 40),
            
            // Parents Level (Dam and Sire)
            _buildParentsLevel(parents),
            const SizedBox(height: 20),
            
            // Current Generation with integrated connections
            _buildConnectedCurrentGeneration(cattle, siblings, parents),
            const SizedBox(height: 20),
            
            // Offspring Level (includes offspring of selected cattle and siblings)
            _buildOffspringLevel(offspring, siblings),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> cattle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.vibrantGreen, AppColors.lightGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.vibrantGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_tree,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Family Tree for #${cattle['tag_no']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentsLevel(Map<String, dynamic> parents) {
    final dam = parents['mother'];
    final sire = parents['father'];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'Parents',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCattleNode(dam, label: 'Dam (Mother)'),
            const SizedBox(width: 80),
            _buildCattleNode(sire, label: 'Sire (Father)'),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectedCurrentGeneration(Map<String, dynamic> selectedCattle, List<dynamic> siblings, Map<String, dynamic> parents) {
    // Filter out null siblings and ensure we have valid data
    final validSiblings = siblings.where((sibling) => sibling != null && sibling is Map<String, dynamic>).toList();
    final allChildren = [...validSiblings, selectedCattle];
    final childrenCount = allChildren.length;
    
    return Column(
      children: [
        // Connection lines from parents
        _buildParentConnections(childrenCount, parents),
        const SizedBox(height: 10),
        
        // Current generation cattle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // All siblings and selected cattle
            for (int i = 0; i < allChildren.length; i++) ...[
              if (i > 0) const SizedBox(width: 40),
              _buildCattleNode(
                allChildren[i], 
                label: allChildren[i]['id'] == selectedCattle['id'] ? 'Selected' : 'Sibling',
                isSelected: allChildren[i]['id'] == selectedCattle['id'],
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 10),
        // Connection lines to offspring
        _buildOffspringConnections(childrenCount),
      ],
    );
  }

  Widget _buildParentConnections(int childrenCount, Map<String, dynamic> parents) {
    final hasParents = parents['mother'] != null || parents['father'] != null;
    if (!hasParents) return Container();
    
    return Column(
      children: [
        // Vertical line from parents center
        Container(
          width: 2,
          height: 30,
          color: AppColors.lightGreen.withOpacity(0.7),
        ),
        // T-junction
        Stack(
          alignment: Alignment.center,
          children: [
            // Horizontal line spanning all children
            Container(
              width: (childrenCount * 120.0) + ((childrenCount - 1) * 40.0),
              height: 2,
              color: AppColors.lightGreen.withOpacity(0.7),
            ),
            // Junction circle
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        // Vertical drops to each child
        SizedBox(
          width: (childrenCount * 120.0) + ((childrenCount - 1) * 40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(childrenCount, (index) => 
              Container(
                width: 2,
                height: 30,
                color: AppColors.lightGreen.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOffspringConnections(int childrenCount) {
    return Column(
      children: [
        // Vertical lines up from each child
        SizedBox(
          width: (childrenCount * 120.0) + ((childrenCount - 1) * 40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(childrenCount, (index) => 
              Container(
                width: 2,
                height: 30,
                color: AppColors.lightGreen.withOpacity(0.7),
              ),
            ),
          ),
        ),
        // T-junction (inverted)
        Stack(
          alignment: Alignment.center,
          children: [
            // Horizontal line collecting from all children
            Container(
              width: (childrenCount * 120.0) + ((childrenCount - 1) * 40.0),
              height: 2,
              color: AppColors.lightGreen.withOpacity(0.7),
            ),
            // Junction circle
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        // Vertical line to offspring center
        Container(
          width: 2,
          height: 30,
          color: AppColors.lightGreen.withOpacity(0.7),
        ),
      ],
    );
  }

  Widget _buildOffspringLevel(List<dynamic> offspring, List<dynamic> siblings) {
    // Collect all offspring (from selected cattle and siblings)
    List<Map<String, dynamic>> allOffspring = [];
    
    // Add offspring of selected cattle
    for (var child in offspring) {
      if (child != null && child is Map<String, dynamic>) {
        try {
          final childData = Map<String, dynamic>.from(child);
          childData['parent_relation'] = 'Selected';
          allOffspring.add(childData);
        } catch (e) {
          print('Error processing offspring: $e');
        }
      }
    }
    
    // Add offspring of siblings (nieces/nephews)
    for (var sibling in siblings) {
      if (sibling != null && sibling is Map<String, dynamic> && sibling['id'] != null) {
        final siblingOffspring = _siblingOffspring[sibling['id']] ?? [];
        for (var child in siblingOffspring) {
          if (child != null && child is Map<String, dynamic>) {
            try {
              final childData = Map<String, dynamic>.from(child);
              childData['parent_relation'] = 'Sibling (#${sibling['tag_no'] ?? 'Unknown'})';
              allOffspring.add(childData);
            } catch (e) {
              print('Error processing sibling offspring: $e');
            }
          }
        }
      }
    }

    if (allOffspring.isEmpty) {
      return Container();
    }

    return Wrap(
      spacing: 40,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: allOffspring.map((child) => 
        _buildCattleNode(
          child, 
          label: child['parent_relation'] == 'Selected' ? null : 'Niece/Nephew'
        )
      ).toList(),
    );
  }

  Widget _buildCattleNode(Map<String, dynamic>? cattleData, {String? label, bool isSelected = false}) {
    return Container(
      width: 120,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cattleData == null ? Colors.grey.shade100 : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(cattleData == null ? 0.05 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: cattleData == null 
                ? Border.all(color: Colors.grey.shade300, width: 2)
                : isSelected 
                  ? Border.all(color: AppColors.vibrantGreen, width: 3)
                  : Border.all(color: AppColors.lightGreen.withOpacity(0.3), width: 2),
            ),
            child: ClipOval(
              child: cattleData == null
                  ? _buildEmptyPlaceholder()
                  : _hasValidImage(cattleData)
                      ? Image.memory(
                          base64Decode(cattleData['cattle_picture']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cattleData == null 
                ? Colors.grey.shade300 
                : isSelected 
                  ? AppColors.vibrantGreen 
                  : AppColors.lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cattleData == null 
                ? 'None'
                : '#${cattleData['tag_no']}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cattleData == null ? Colors.grey.shade600 : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (cattleData != null && cattleData['classification'] != null) ...[
            const SizedBox(height: 4),
            Text(
              cattleData['classification'],
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: cattleData == null ? Colors.grey.shade500 : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.help_outline,
        color: Colors.grey.shade400,
        size: 32,
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
      ),
      child: const Icon(
        FontAwesomeIcons.cow,
        color: AppColors.lightGreen,
        size: 24,
      ),
    );
  }


  bool _hasValidImage(Map<String, dynamic>? cattleData) {
    return cattleData != null &&
           cattleData['cattle_picture'] != null && 
           cattleData['cattle_picture'].toString().isNotEmpty;
  }
}
