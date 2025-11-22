// lib/screens/nav/profile/modals/farm_details_modal.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:goat_tracer_app/constants/app_colors.dart';
import 'package:goat_tracer_app/services/profile/farm_details_service.dart';
import 'package:goat_tracer_app/services/address_service.dart';
import 'package:goat_tracer_app/config.dart';

class FarmDetailsModal extends StatefulWidget {
  final Map<String, dynamic>? farmDetails;
  final bool isEditingMode;
  final VoidCallback onSaveSuccess;
  final VoidCallback onToggleEditMode;

  const FarmDetailsModal({
    super.key,
    required this.farmDetails,
    required this.isEditingMode,
    required this.onSaveSuccess,
    required this.onToggleEditMode,
  });

  @override
  State<FarmDetailsModal> createState() => _FarmDetailsModalState();
}

class _FarmDetailsModalState extends State<FarmDetailsModal> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController farmNameController;
  late TextEditingController farmTypeController;
  late TextEditingController farmClassificationController;
  late TextEditingController farmAreaController;
  late TextEditingController coopController;
  // farmLocationController removed - using structured address fields instead
  bool _isLoading = false;
  final List<String> _farmTypeOptions = const ['Meat Goat', 'Dairy Goat'];
  String? _selectedFarmType;
  
  final List<String> _farmLandAreaOptions = const [
    'Below 1 hectare',
    '1-2 hectares',
    '2-3 hectares',
    '3-5 hectares',
    '5-10 hectares',
    '10-20 hectares',
    '20 hectares above'
  ];
  String? _selectedFarmLandArea;
  
  final List<String> _farmClassificationOptions = const [
    'Backyard - 1-15 Does',
    'Commercial - 16 and above Does'
  ];
  String? _selectedFarmClassification;
  bool _localEditingMode = false;
  Map<String, dynamic>? _currentFarmDetails;
  
  // Address validation state variables
  List<dynamic> _regions = [];
  List<dynamic> _provinces = [];
  List<dynamic> _municipalities = [];
  List<dynamic> _barangays = [];
  Map<String, dynamic>? _selectedRegion;
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedMunicipality;
  Map<String, dynamic>? _selectedBarangay;
  bool _isLoadingRegions = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingMunicipalities = false;
  bool _isLoadingBarangays = false;

  // Farm latitude and longitude fields
  double? _farmLatitude;
  double? _farmLongitude;
  Timer? _farmGeocodeTimer;
  int _geocodeRequestCounter = 0; // Guards against stale responses
  int _activeGeocodeRequestId = 0;

  @override
  void initState() {
    super.initState();
    _localEditingMode = widget.isEditingMode;
    _currentFarmDetails = widget.farmDetails;
    final farm = widget.farmDetails;
    farmNameController = TextEditingController(text: farm?['farm_name'] ?? '');
    farmTypeController = TextEditingController(text: farm?['farm_type'] ?? '');
    farmClassificationController = TextEditingController(text: farm?['farm_classification'] ?? '');
    farmAreaController = TextEditingController(text: farm?['farm_land_area']?.toString() ?? '');
    coopController = TextEditingController(text: farm?['cooperative_affiliation'] ?? '');
    // farmLocationController removed - using structured address fields instead
    _selectedFarmType = (farm?['farm_type'] is String && farm!['farm_type'].toString().isNotEmpty)
        ? farm['farm_type']
        : null;
    
    // Initialize farm coordinates from the new structured fields (null-safe)
    final String? latStr = farm?['farm_latitude']?.toString();
    final String? lngStr = farm?['farm_longitude']?.toString();
    _farmLatitude = (latStr != null && latStr.isNotEmpty) ? double.tryParse(latStr) : null;
    _farmLongitude = (lngStr != null && lngStr.isNotEmpty) ? double.tryParse(lngStr) : null;
    
    // Initialize farm land area dropdown
    final farmLandArea = farm?['farm_land_area'];
    if (farmLandArea != null && farmLandArea.toString().isNotEmpty) {
      // Handle numeric values by converting to appropriate text
      String areaText = farmLandArea.toString();
      
      // If it's a numeric value, try to map it to our dropdown options
      if (double.tryParse(areaText) != null) {
        final numericValue = double.parse(areaText);
        if (numericValue < 1) {
          _selectedFarmLandArea = 'Below 1 hectare';
        } else if (numericValue >= 1 && numericValue <= 2) {
          _selectedFarmLandArea = '1-2 hectares';
        } else if (numericValue > 2 && numericValue <= 3) {
          _selectedFarmLandArea = '2-3 hectares';
        } else if (numericValue > 3 && numericValue <= 5) {
          _selectedFarmLandArea = '3-5 hectares';
        } else if (numericValue > 5 && numericValue <= 10) {
          _selectedFarmLandArea = '5-10 hectares';
        } else if (numericValue > 10 && numericValue <= 20) {
          _selectedFarmLandArea = '10-20 hectares';
        } else if (numericValue > 20) {
          _selectedFarmLandArea = '20 hectares above';
        } else {
          _selectedFarmLandArea = null;
        }
      } else {
        // If it's already text, try to match with dropdown options
        _selectedFarmLandArea = _farmLandAreaOptions.firstWhere(
          (option) => option.toLowerCase().contains(areaText.toLowerCase()) ||
                     areaText.toLowerCase().contains(option.toLowerCase()),
          orElse: () => '', // Return empty string if no match found
        );
        // If no match found, set to null
        if (_selectedFarmLandArea == '') {
          _selectedFarmLandArea = null;
        }
      }
    } else {
      _selectedFarmLandArea = null;
    }
    
    // Initialize farm classification dropdown
    final farmClassification = farm?['farm_classification']?.toString();
    if (farmClassification != null && farmClassification.isNotEmpty) {
      // Try to match existing value with dropdown options
      _selectedFarmClassification = _farmClassificationOptions.firstWhere(
        (option) => option.toLowerCase().contains(farmClassification.toLowerCase()) ||
                   farmClassification.toLowerCase().contains(option.toLowerCase()),
        orElse: () => '', // Return empty string if no match found
      );
      // If no match found, set to null
      if (_selectedFarmClassification == '') {
        _selectedFarmClassification = null;
      }
    } else {
      _selectedFarmClassification = null;
    }
    
    // Load regions then provinces for selected region, then initialize address
    _loadRegions().then((_) {
      _initializeAddressFromStructuredData(farm);
    });
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      debugPrint('Loading regions...');
      final regions = await AddressService.getRegions();
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
      // Determine initial region: saved farm_region or Region 2 default
      final savedRegionName = widget.farmDetails?['farm_region']?.toString();
      Map<String, dynamic>? initialRegion;
      if (savedRegionName != null && savedRegionName.isNotEmpty) {
        initialRegion = regions.firstWhere(
          (r) => (r['name']?.toString().toLowerCase() == savedRegionName.toLowerCase()) ||
                  (savedRegionName.toLowerCase().contains((r['name'] ?? '').toString().toLowerCase())),
          orElse: () => {},
        );
      }
      initialRegion ??= regions.firstWhere(
        (r) => r['name'] == 'REGION II (CAGAYAN VALLEY)' || r['code'] == '020000000' ||
               (r['name']?.toString().toLowerCase().contains('cagayan valley') ?? false),
        orElse: () => regions.isNotEmpty ? regions.first : {},
      );
      if (initialRegion != null && initialRegion.isNotEmpty) {
        setState(() => _selectedRegion = initialRegion);
        await _loadProvincesForRegion(initialRegion['code']);
      }
    } catch (e) {
      debugPrint('Error loading regions: $e');
      setState(() => _isLoadingRegions = false);
      _showMessage('Failed to load regions. Please try again.', Colors.red);
    }
  }

  Future<void> _loadProvincesForRegion(String regionCode) async {
    setState(() => _isLoadingProvinces = true);
    try {
      final provinces = await AddressService.getProvinces(regionCode);
      setState(() {
        _provinces = provinces;
        _selectedProvince = null;
        _municipalities = [];
        _barangays = [];
        _selectedMunicipality = null;
        _selectedBarangay = null;
        _isLoadingProvinces = false;
      });
      debugPrint('Loaded ${provinces.length} provinces for region $regionCode');
    } catch (e) {
      debugPrint('Error loading provinces for region: $e');
      setState(() => _isLoadingProvinces = false);
      _showMessage('Failed to load provinces for selected region.', Colors.red);
    }
  }

  @override
  void dispose() {
    farmNameController.dispose();
    farmTypeController.dispose();
    farmClassificationController.dispose();
    farmAreaController.dispose();
    coopController.dispose();
    // farmLocationController removed - using structured address fields instead
    _farmGeocodeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop && _localEditingMode) {
          // Exit edit mode when modal is closed
          widget.onToggleEditMode();
        }
      },
      child: Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            _buildHeader(),

            const SizedBox(height: 24),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: _localEditingMode
                      ? _buildEditingForm()
                      : _buildViewContent(),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.agriculture,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Farm Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                _localEditingMode
                    ? 'Edit your farm information'
                    : 'View your farm information',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        Tooltip(
          message: _localEditingMode ? 'Save & Exit Edit Mode' : 'Edit',
          child: GestureDetector(
            onTap: () async {
              if (_localEditingMode) {
                // Save when exiting edit mode
                await _saveFarmDetails();
              } else {
                // Enter edit mode
                setState(() {
                  _localEditingMode = true;
                });
                widget.onToggleEditMode();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _localEditingMode ? Colors.green : AppColors.accent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _localEditingMode && _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _localEditingMode ? Icons.check_rounded : Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditingForm() {
    return Column(
      children: [
        _buildStyledTextField(
          controller: farmNameController,
          label: 'Farm Classification',
          icon: FontAwesomeIcons.leaf,
        ),
        const SizedBox(height: 20),

        _buildFarmTypeDropdown(),
        const SizedBox(height: 20),

        _buildFarmClassificationDropdown(),
        const SizedBox(height: 20),

        _buildFarmLandAreaDropdown(),
        const SizedBox(height: 20),

        _buildStyledTextField(
          controller: coopController,
          label: 'Cooperative Membership',
          icon: FontAwesomeIcons.handshake,
        ),
        const SizedBox(height: 20),

        // Farm Location Section
        _buildFarmLocationSection(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFarmTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedFarmType,
        isExpanded: true,
        items: _farmTypeOptions
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ))
            .toList(),
        onChanged: (val) {
          setState(() {
            _selectedFarmType = val;
            farmTypeController.text = val ?? '';
          });
        },
        validator: (val) {
          if (val == null || val.isEmpty) {
            return 'Please select farm type';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Farm Type',
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const FaIcon(
              FontAwesomeIcons.tractor,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildFarmLandAreaDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedFarmLandArea,
        isExpanded: true,
        items: _farmLandAreaOptions
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ))
            .toList(),
        onChanged: (val) {
          setState(() {
            _selectedFarmLandArea = val;
            farmAreaController.text = val ?? '';
          });
        },
        validator: (val) {
          if (val == null || val.isEmpty) {
            return 'Please select farm land area';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Farm Land Area',
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const FaIcon(
              FontAwesomeIcons.expand,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildFarmClassificationDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedFarmClassification,
        isExpanded: true,
        items: _farmClassificationOptions
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ))
            .toList(),
        onChanged: (val) {
          setState(() {
            _selectedFarmClassification = val;
            farmClassificationController.text = val ?? '';
          });
        },
        validator: (val) {
          if (val == null || val.isEmpty) {
            return 'Please select farm classification';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Farm Classification',
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const FaIcon(
              FontAwesomeIcons.shapes,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        maxLines: null,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  // Address validation methods
  Future<void> _loadMunicipalities(String provinceCode) async {
    setState(() => _isLoadingMunicipalities = true);
    try {
      final municipalities = await AddressService.getMunicipalities(provinceCode);
      setState(() {
        _municipalities = municipalities;
        _barangays = [];
        _selectedBarangay = null;
        _selectedMunicipality = null;
        _isLoadingMunicipalities = false;
        // Clear coordinates when province changes
        _farmLatitude = null;
        _farmLongitude = null;
      });
    } catch (e) {
      setState(() => _isLoadingMunicipalities = false);
      _showMessage('Failed to load municipalities: $e', Colors.red);
    }
  }

  Future<void> _loadBarangays(String municipalityCode) async {
    setState(() => _isLoadingBarangays = true);
    try {
      final barangays = await AddressService.getBarangays(municipalityCode);
      setState(() {
        _barangays = barangays;
        _isLoadingBarangays = false;
      });
      // Only trigger geocoding if a barangay is already selected (for edit mode)
      if (_selectedBarangay != null && _selectedBarangay!['name'] != null && _selectedBarangay!['name'].isNotEmpty) {
        debugPrint('Barangays loaded, existing barangay selected: ${_selectedBarangay!['name']}, triggering geocoding...');
        _debounceFarmGeocode();
      } else {
        debugPrint('Barangays loaded, no barangay selected yet - waiting for user selection');
      }
    } catch (e) {
      setState(() => _isLoadingBarangays = false);
      _showMessage('Failed to load barangays: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Debounced farm geocoding (mirror JS: single-shot request after 500ms)
  void _debounceFarmGeocode() {
    _farmGeocodeTimer?.cancel();

    _farmGeocodeTimer = Timer(const Duration(milliseconds: 500), () {
      _performSingleGeocode();
    });
  }

  // Remove persistent/fallback logic to match JS exactly

  // Single-shot geocoding (JS parity)
  Future<void> _performSingleGeocode() async {
    final province = _selectedProvince?['name'];
    final municipality = _selectedMunicipality?['name'];
    final barangay = _selectedBarangay?['name'];

    // Only geocode when a barangay is selected to ensure barangay-level coordinates
    if (province == null || municipality == null || barangay == null || barangay.isEmpty) {
      setState(() {
        _farmLatitude = null;
        _farmLongitude = null;
      });
      return;
    }

    setState(() {
    });

    final currentRequestId = ++_geocodeRequestCounter;
    _activeGeocodeRequestId = currentRequestId;

    try {
      final queryParams = <String, String>{
        'province': province!,
        'municipality': municipality,
        'barangay': barangay,
      };
      final uri = Uri.parse('${AppConfig.baseUrl}/api/geocode')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      // Ignore stale responses
      if (!mounted || currentRequestId != _activeGeocodeRequestId) return;

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['latitude'] != null &&
            data['data']['longitude'] != null) {
          final lat = double.tryParse(data['data']['latitude'].toString());
          final lng = double.tryParse(data['data']['longitude'].toString());
          if (lat != null && lng != null) {
            setState(() {
              _farmLatitude = lat;
              _farmLongitude = lng;
            });
            return;
          }
        }
      }

      // Fallback: clear on failure
      setState(() {
        _farmLatitude = null;
        _farmLongitude = null;
      });
    } catch (e) {
      if (!mounted || currentRequestId != _activeGeocodeRequestId) return;
      setState(() {
        _farmLatitude = null;
        _farmLongitude = null;
      });
    }
  }

  // Manual retry no longer needed (JS parity: single-shot on change)

  Future<void> _initializeAddressFromStructuredData(Map<String, dynamic>? farm) async {
    if (farm == null) return;
    
    try {
      // Ensure regions are loaded
      if (_regions.isEmpty) {
        await _loadRegions();
      }
      // Select saved region if present
      final farmRegion = farm['farm_region']?.toString();
      if (farmRegion != null && farmRegion.isNotEmpty && _regions.isNotEmpty) {
        final match = _regions.firstWhere(
          (r) => (r['name']?.toString().toLowerCase() == farmRegion.toLowerCase()) ||
                  (farmRegion.toLowerCase().contains((r['name'] ?? '').toString().toLowerCase())),
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          setState(() => _selectedRegion = match);
          await _loadProvincesForRegion(match['code']);
        }
      }
      // If provinces somehow still not loaded, load for current selected region
      if (_provinces.isEmpty && _selectedRegion != null) {
        await _loadProvincesForRegion(_selectedRegion!['code']);
      }
      
      // Initialize from structured fields
      final farmProvince = farm['farm_province']?.toString();
      final farmMunicipality = farm['farm_municipality']?.toString();
      final farmBarangay = farm['farm_barangay']?.toString();
      
      // Find and select the province
      if (farmProvince != null && farmProvince.isNotEmpty) {
        for (var province in _provinces) {
          if (province['name'].toString().toLowerCase() == farmProvince.toLowerCase()) {
            _selectedProvince = province;
            await _loadMunicipalities(province['code']);
            
            // Find and select the municipality
            if (farmMunicipality != null && farmMunicipality.isNotEmpty) {
              for (var municipality in _municipalities) {
                if (municipality['name'].toString().toLowerCase() == farmMunicipality.toLowerCase()) {
                  _selectedMunicipality = municipality;
                  await _loadBarangays(municipality['code']);
                  
                  // Find and select the barangay
                  if (farmBarangay != null && farmBarangay.isNotEmpty) {
                    for (var barangay in _barangays) {
                      if (barangay['name'].toString().toLowerCase() == farmBarangay.toLowerCase()) {
                        _selectedBarangay = barangay;
                        break;
                      }
                    }
                  }
                  break;
                }
              }
            }
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize address from structured data: $e');
    }
  }

  Widget _buildProvinceField() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedProvince?['code']?.toString(),
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Province',
              labelStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.mapLocation,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
            items: _provinces.map<DropdownMenuItem<String>>((province) {
              return DropdownMenuItem<String>(
                value: province['code']?.toString(),
                child: Text(
                  province['name'] ?? 'Unknown Province',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: _isLoadingProvinces
                ? null
                : (String? newValue) {
                    if (newValue != null) {
                      final selectedProvince = _provinces.firstWhere(
                        (province) => province['code']?.toString() == newValue,
                        orElse: () => {},
                      );
                      setState(() {
                        _selectedProvince = selectedProvince.isNotEmpty ? selectedProvince : null;
                        _municipalities = [];
                        _barangays = [];
                        _selectedMunicipality = null;
                        _selectedBarangay = null;
                        // Clear coordinates when province changes
                        _farmLatitude = null;
                        _farmLongitude = null;
                      });
                      if (selectedProvince.isNotEmpty) {
                        debugPrint('📍 Province selected: ${selectedProvince['name']}, loading municipalities...');
                        _loadMunicipalities(selectedProvince['code']);
                      }
                    } else {
                      setState(() {
                        _selectedProvince = null;
                        _municipalities = [];
                        _barangays = [];
                        _selectedMunicipality = null;
                        _selectedBarangay = null;
                        // Clear coordinates when province is cleared
                        _farmLatitude = null;
                        _farmLongitude = null;
                      });
                    }
                  },
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Please select a province';
              }
              return null;
            },
            hint: _isLoadingProvinces
                ? const Text(
                    'Loading provinces...',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                : const Text(
                    'Select Province',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
          ),
        ),
        if (_isLoadingProvinces)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMunicipalityDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedMunicipality?['code'],
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Municipality/City',
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const FaIcon(
              FontAwesomeIcons.city,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        items: _municipalities.map<DropdownMenuItem<String>>((municipality) {
          return DropdownMenuItem<String>(
            value: municipality['code']?.toString(),
            child: Text(
              municipality['name'] ?? 'Unknown Municipality',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
        onChanged: _isLoadingMunicipalities || _selectedProvince == null
            ? null
            : (String? newValue) {
          if (newValue != null) {
            final selectedMunicipality = _municipalities.firstWhere(
              (municipality) => municipality['code']?.toString() == newValue,
              orElse: () => {},
            );
            // Stop any ongoing geocoding when municipality changes
            _farmGeocodeTimer?.cancel();
            
            setState(() {
              _selectedMunicipality = selectedMunicipality.isNotEmpty ? selectedMunicipality : null;
              _barangays = [];
              _selectedBarangay = null;
              // Clear farm coordinates when municipality changes (will be updated when barangay is selected)
              _farmLatitude = null;
              _farmLongitude = null;
            });
            if (selectedMunicipality.isNotEmpty) {
              debugPrint('🏙️ Municipality selected: ${selectedMunicipality['name']}, loading barangays...');
              _loadBarangays(selectedMunicipality['code']);
              // Note: Geocoding will only happen when barangay is selected
            }
          } else {
            setState(() {
              _selectedMunicipality = null;
              _barangays = [];
              _selectedBarangay = null;
              // Clear farm coordinates when municipality is cleared
              _farmLatitude = null;
              _farmLongitude = null;
            });
          }
        },
        validator: (String? value) {
          if (_selectedProvince != null && (value == null || value.isEmpty)) {
            return 'Please select a municipality';
          }
          return null;
        },
        hint: _isLoadingMunicipalities
            ? const Text(
                'Loading municipalities...',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : _selectedProvince == null
                ? const Text(
                    'Select province first',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                : const Text(
                    'Municipality',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
      ),
    );
  }

  Widget _buildBarangayDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedBarangay?['code']?.toString(),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Barangay',
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const FaIcon(
              FontAwesomeIcons.house,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          filled: true,
          fillColor: _selectedProvince == null || _selectedMunicipality == null ? Colors.grey[50] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        items: _barangays.map<DropdownMenuItem<String>>((barangay) {
          return DropdownMenuItem<String>(
            value: barangay['code']?.toString(),
            child: Text(
              barangay['name'] ?? 'Unknown Barangay',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
        onChanged: _isLoadingBarangays || _selectedProvince == null || _selectedMunicipality == null
            ? null
            : (String? newValue) {
                if (newValue != null) {
                  final selectedBarangay = _barangays.firstWhere(
                    (barangay) => barangay['code']?.toString() == newValue,
                    orElse: () => {},
                  );
                  setState(() {
                    _selectedBarangay = selectedBarangay.isNotEmpty ? selectedBarangay : null;
                  });
                  // Stop any ongoing geocoding and start fresh
                  _farmGeocodeTimer?.cancel();
                  
                  // Trigger debounced geocoding when barangay is selected (coordinates will be updated)
                  if (selectedBarangay.isNotEmpty) {
                    debugPrint('🎯 Barangay selected: ${selectedBarangay['name']}, starting fresh geocoding...');
                    // Clear previous coordinates immediately
                    setState(() {
                      _farmLatitude = null;
                      _farmLongitude = null;
                    });
                    _debounceFarmGeocode();
                  } else {
                    // Only clear coordinates when barangay is cleared/empty
                    debugPrint('Barangay cleared, clearing farm coordinates');
                    setState(() {
                      _farmLatitude = null;
                      _farmLongitude = null;
                    });
                  }
                } else {
                  setState(() {
                    _selectedBarangay = null;
                    // Clear farm coordinates when barangay is cleared
                    _farmLatitude = null;
                    _farmLongitude = null;
                  });
                }
              },
        validator: (String? value) {
          if (_selectedMunicipality != null && (value == null || value.isEmpty)) {
            return 'Please select a barangay';
          }
          return null;
        },
        hint: _isLoadingBarangays
            ? const Text(
                'Loading barangays...',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : _selectedProvince == null || _selectedMunicipality == null
                ? const Text(
                    'Select municipality first',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                : const Text(
                    'Barangay',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
      ),
    );
  }

  Widget _buildFarmLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGreen.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.mapLocation,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Farm Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Address Fields
          _buildRegionDropdown(),
          const SizedBox(height: 16),
          _buildProvinceField(),
          const SizedBox(height: 16),

          _buildMunicipalityDropdown(),
          const SizedBox(height: 16),

          _buildBarangayDropdown(),
          const SizedBox(height: 16),

          // Farm coordinates status hidden
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildRegionDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRegion?['code']?.toString(),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Region',
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const FaIcon(
              FontAwesomeIcons.globe,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        items: _regions.map<DropdownMenuItem<String>>((region) {
          return DropdownMenuItem<String>(
            value: region['code']?.toString(),
            child: Text(
              region['name'] ?? 'Unknown Region',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
        onChanged: _isLoadingRegions
            ? null
            : (String? newValue) async {
                if (newValue != null) {
                  final selected = _regions.firstWhere(
                    (r) => r['code']?.toString() == newValue,
                    orElse: () => {},
                  );
                  setState(() {
                    _selectedRegion = selected.isNotEmpty ? selected : null;
                    _selectedProvince = null;
                    _selectedMunicipality = null;
                    _selectedBarangay = null;
                    _provinces = [];
                    _municipalities = [];
                    _barangays = [];
                    _farmLatitude = null;
                    _farmLongitude = null;
                  });
                  if (selected.isNotEmpty) {
                    await _loadProvincesForRegion(selected['code']);
                  }
                } else {
                  setState(() {
                    _selectedRegion = null;
                    _selectedProvince = null;
                    _selectedMunicipality = null;
                    _selectedBarangay = null;
                    _provinces = [];
                    _municipalities = [];
                    _barangays = [];
                    _farmLatitude = null;
                    _farmLongitude = null;
                  });
                }
              },
        validator: (String? value) {
          if (value == null || value.isEmpty) {
            return 'Please select a region';
          }
          return null;
        },
        hint: _isLoadingRegions
            ? const Text(
                'Loading regions...',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : const Text(
                'Select Region',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
      ),
    );
  }

  Widget _buildViewContent() {
    final farmDetails = _currentFarmDetails ?? widget.farmDetails;
    return Column(
      children: [
        _buildInfoCard('Farm Name', farmDetails?['farm_name'] ?? 'None', FontAwesomeIcons.leaf),
        const SizedBox(height: 16),

        _buildInfoCard('Farm Type', farmDetails?['farm_type'] ?? 'None', FontAwesomeIcons.tractor),
        const SizedBox(height: 16),

        _buildInfoCard('Farm Classification', farmDetails?['farm_classification'] ?? 'None', FontAwesomeIcons.shapes),
        const SizedBox(height: 16),

        _buildInfoCard('Farm Land Area', farmDetails?['farm_land_area'] ?? 'None', FontAwesomeIcons.expand),
        const SizedBox(height: 16),

        _buildInfoCard('Cooperative Membership', farmDetails?['cooperative_affiliation'] ?? 'None', FontAwesomeIcons.handshake),
        const SizedBox(height: 16),

        _buildInfoCard('Farm Location', _formatFarmLocation(), FontAwesomeIcons.mapLocation),
        const SizedBox(height: 24),
      ],
    );
  }


  String _formatFarmLocation() {
    if (_selectedProvince != null && _selectedMunicipality != null && _selectedBarangay != null) {
      final regionName = _selectedRegion?['name']?.toString();
      final base = '${_selectedBarangay!['name']}, ${_selectedMunicipality!['name']}, ${_selectedProvince!['name']}';
      return regionName != null && regionName.isNotEmpty ? '$base, $regionName' : base;
    } else if (_selectedProvince != null && _selectedMunicipality != null) {
      final regionName = _selectedRegion?['name']?.toString();
      final base = '${_selectedMunicipality!['name']}, ${_selectedProvince!['name']}';
      return regionName != null && regionName.isNotEmpty ? '$base, $regionName' : base;
    } else {
      // Fallback to structured fields from current farm details
      final farm = _currentFarmDetails ?? widget.farmDetails;
      if (farm != null) {
        final parts = <String>[];
        if (farm['farm_barangay']?.toString().isNotEmpty == true) parts.add(farm['farm_barangay']);
        if (farm['farm_municipality']?.toString().isNotEmpty == true) parts.add(farm['farm_municipality']);
        if (farm['farm_province']?.toString().isNotEmpty == true) parts.add(farm['farm_province']);
        if (farm['farm_region']?.toString().isNotEmpty == true) parts.add(farm['farm_region']);
        if (parts.isNotEmpty) return parts.join(', ');
      }
      return 'None';
    }
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFarmDetails() async {
    if (!formKey.currentState!.validate()) {
      // If validation fails, don't exit edit mode
      return;
    }

    setState(() => _isLoading = true);

      // Attempt a final single geocode before submission if coordinates are empty and barangay is selected
      if ((_farmLatitude == null || _farmLongitude == null) && _selectedBarangay != null && _selectedBarangay!['name'] != null && _selectedBarangay!['name'].isNotEmpty) {
        await _performSingleGeocode();
      }

      final Map<String, dynamic> updateData = {
        'farm_name': farmNameController.text,
        'farm_type': farmTypeController.text,
        'farm_classification': _selectedFarmClassification ?? '',
        'farm_land_area': _selectedFarmLandArea ?? '',
        'cooperative_affiliation': coopController.text,
        'farm_region': _selectedRegion?['name'] ?? '',
        'farm_province': _selectedProvince?['name'] ?? '',
        'farm_municipality': _selectedMunicipality?['name'] ?? '',
        'farm_barangay': _selectedBarangay?['name'] ?? '',
      };
      
      // Add farm coordinates if available
      if (_farmLatitude != null && _farmLongitude != null) {
        updateData['farm_latitude'] = _farmLatitude!.toStringAsFixed(7);
        updateData['farm_longitude'] = _farmLongitude!.toStringAsFixed(7);
      }
      
      debugPrint('Farm details update data: $updateData');

      bool success = false;
      try {
        if (widget.farmDetails?['id'] == null) {
          success = await FarmDetailsService.storeFarmDetails(updateData);
        } else {
          success = await FarmDetailsService.updateFarmDetails(updateData);
        }
      } catch (e) {
        success = false;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (success) {
        // Reload farm details to show updated information
        final updatedFarmDetails = await FarmDetailsService.getFarmDetails();
        if (mounted && updatedFarmDetails != null) {
          // Update the widget's farm details by reloading the modal state
          // Since this is a StatefulWidget, we need to update the local state
          setState(() {
            _localEditingMode = false;
            _currentFarmDetails = updatedFarmDetails; // Update local farm details for view mode
            // Update controllers with new data
            farmNameController.text = updatedFarmDetails['farm_name'] ?? '';
            farmTypeController.text = updatedFarmDetails['farm_type'] ?? '';
            farmClassificationController.text = updatedFarmDetails['farm_classification'] ?? '';
            farmAreaController.text = updatedFarmDetails['farm_land_area']?.toString() ?? '';
            coopController.text = updatedFarmDetails['cooperative_affiliation'] ?? '';
            
            // Update selected values
            _selectedFarmType = updatedFarmDetails['farm_type'];
            _selectedFarmClassification = updatedFarmDetails['farm_classification'];
            _selectedFarmLandArea = updatedFarmDetails['farm_land_area']?.toString();
            
            // Update coordinates
            final latStr = updatedFarmDetails['farm_latitude']?.toString();
            final lngStr = updatedFarmDetails['farm_longitude']?.toString();
            _farmLatitude = (latStr != null && latStr.isNotEmpty) ? double.tryParse(latStr) : null;
            _farmLongitude = (lngStr != null && lngStr.isNotEmpty) ? double.tryParse(lngStr) : null;
          });
          
          // Reinitialize address from updated data
          await _initializeAddressFromStructuredData(updatedFarmDetails);
        }
        widget.onToggleEditMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleCheck,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Farm details saved successfully!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.vibrantGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onSaveSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleXmark,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Save failed. Please try again.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
  }
}
