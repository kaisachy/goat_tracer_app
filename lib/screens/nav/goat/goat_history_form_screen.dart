// lib/screens/nav/goat/goat_history_form_screen.dart

import 'package:goat_tracer_app/screens/nav/goat/widgets/history/history_specific_fields.dart';
import 'package:goat_tracer_app/screens/nav/goat/widgets/history/history_type_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/goat.dart';
import '../../../services/goat/goat_history_service.dart';
import '../../../services/goat/goat_service.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/history_type_utils.dart';
import 'modals/Kid_registration_dialog.dart';
import 'widgets/history/history_goat_info_card.dart';
import 'widgets/history/history_notes_section.dart';
import 'modals/history_success_dialog.dart';
import 'modals/history_delete_confirmation_dialog.dart';

class GoatHistoryFormScreen extends StatefulWidget {
  final GoatHistoryRecord? historyRecord;
  final String? goatTag;
  final String? initialHistoryType;

  const GoatHistoryFormScreen({
    super.key,
    this.historyRecord,
    this.goatTag,
    this.initialHistoryType,
  });

  @override
  State<GoatHistoryFormScreen> createState() => _GoatHistoryFormScreenState();
}

class _GoatHistoryFormScreenState extends State<GoatHistoryFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<HistorySpecificFieldsState> _historySpecificFieldsKey =
  GlobalKey<HistorySpecificFieldsState>();
  late bool isEditing;
  bool _isLoading = false;

  // goat details
  Goat? _goatDetails;

  // Partner linkage for unified editing when editing buck reciprocal breeding
  String? _partnerTagForEdit;
  int? _partnerHistoryIdForEdit;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String selectedHistoryType = 'Select type of history record';

  // New state for temporary kid data
  Map<String, dynamic>? _temporaryKidData;

  @override
  void initState() {
    super.initState();
    isEditing = widget.historyRecord != null;
    
    // Set initial history type if provided
    if (widget.initialHistoryType != null) {
      selectedHistoryType = widget.initialHistoryType!;
    }
    
    _initializeAnimations();
    _initializeControllers();
    _loadgoatDetails();

    // Load existing kid data if editing birth history record
    if (isEditing && widget.historyRecord != null && widget.historyRecord!.historyType == 'Gives Birth') {
      _loadExistingKidData();
    }
    
    // Load breeding history data if editing breeding history record
    debugPrint('DEBUG: Checking if should load breeding history data');
    debugPrint('DEBUG: isEditing: $isEditing');
    debugPrint('DEBUG: widget.historyRecord: ${widget.historyRecord}');
    if (widget.historyRecord != null) {
      debugPrint('DEBUG: widget.historyRecord!.historyType: "${widget.historyRecord!.historyType}"');
    }
    
    if (isEditing && widget.historyRecord != null && widget.historyRecord!.historyType == 'Breeding') {
      debugPrint('DEBUG: Loading breeding history data...');
      // Use post-frame callback to ensure controllers are initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBreedingHistoryData();
      });
    } else {
      debugPrint('DEBUG: Not loading breeding history data - conditions not met');
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
  }

  void _initializeControllers() {
    final fields = [
      'Buck_tag', 'Kid_tag', 'history_date',
      'diagnosis', 'technician', 'medicine_given', 'semen_used',
      'estimated_return_date', 'weighed_result', 'breeding_date',
      'expected_delivery_date', 'cause_of_death', 'notes',
      'last_known_location', 'breeding_type', 'disease_type', 'disease_type_other',
      'sold_amount', 'buyer'
    ];

    for (var field in fields) {
      String initialValue = '';
      if (isEditing && widget.historyRecord != null) {
        final historyJson = widget.historyRecord!.toJson();
        initialValue = historyJson[field]?.toString() ?? '';
      }
      _controllers[field] = TextEditingController(text: initialValue);
    }
  }

  Future<Map<String, dynamic>?> _getLatestHistoryRecord({
    required String goatTag,
    required String historyType,
  }) async {
    try {
      final all = await GoatHistoryService.getgoatHistory();
      final filtered = all
          .where((e) =>
              e['goat_tag'] == goatTag &&
              (e['history_type']?.toString().toLowerCase() ?? '') ==
                  historyType.toLowerCase())
          .toList();
      if (filtered.isEmpty) return null;
      filtered.sort((a, b) {
        try {
          final da = DateTime.parse(a['history_date']);
          final db = DateTime.parse(b['history_date']);
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });
      return filtered.first;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleHistoryTypeChanged(String value) async {
    debugPrint('DEBUG: _handleHistoryTypeChanged called with value: $value');
    setState(() => selectedHistoryType = value);

    if (_goatDetails == null) {
      debugPrint('DEBUG: _goatDetails is null, returning early');
      return;
    }
    final goatTag = _goatDetails!.tagNo;
    debugPrint('DEBUG: Processing history type change for goat: $goatTag');

    // Clear autofill targets before applying
    _controllers['breeding_date']?.text = _controllers['breeding_date']?.text ?? '';
    _controllers['expected_delivery_date']?.text = _controllers['expected_delivery_date']?.text ?? '';

    // Pregnant requires latest Breeding; autofill breeding_date, expected_delivery_date, buck/semen
    if (value.toLowerCase() == 'pregnant') {
      debugPrint('DEBUG: Processing Pregnant history record for goat: $goatTag');
      final latestBreeding = await _getLatestHistoryRecord(goatTag: goatTag, historyType: 'Breeding');
      debugPrint('DEBUG: Latest breeding history record found: $latestBreeding');
      if (latestBreeding == null) {
        debugPrint('DEBUG: No breeding history record found, showing warning');
        _showWarningMessage('No recent Breeding history record found. Cannot create Pregnant history record.');
        setState(() => selectedHistoryType = 'Select type of history record');
        return;
      }

      final breedingDateStr = latestBreeding['history_date']?.toString();
      if (breedingDateStr != null && breedingDateStr.isNotEmpty) {
        _controllers['breeding_date']?.text = breedingDateStr;
        try {
          final breedingDate = DateTime.parse(breedingDateStr);
          final expectedDelivery = breedingDate.add(const Duration(days: 150));
          final formatted = '${expectedDelivery.year.toString().padLeft(4, '0')}-'
              '${expectedDelivery.month.toString().padLeft(2, '0')}-'
              '${expectedDelivery.day.toString().padLeft(2, '0')}';
          _controllers['expected_delivery_date']?.text = formatted;
          // Also trigger UI-side calculation to refresh dependent widgets
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _historySpecificFieldsKey.currentState?.calculateAndDisplayDeliveryDate(breedingDate);
          });
        } catch (_) {}
      }
      // Autofill buck/semen and technician if present
      final buckTag = latestBreeding['Buck_tag']?.toString();
      final semen = latestBreeding['semen_used']?.toString();
      debugPrint('DEBUG: Found Buck_tag: $buckTag, semen_used: $semen');

      // If semen is present (AI), treat semen's buck as the buck selection
      if (semen != null && semen.isNotEmpty) {
        debugPrint('DEBUG: Processing semen: $semen');
        _controllers['semen_used']?.text = semen;
        // Try to extract the buck tag from semen label like "TAG123 (Name) Semen"
        String extractedBuckTag = semen.trim();
        if (extractedBuckTag.toLowerCase().endsWith('semen')) {
          extractedBuckTag = extractedBuckTag.substring(0, extractedBuckTag.length - 5).trim();
        }
        // Extract tag from format like "TAG123 (Name)" or just "TAG123"
        int stop = extractedBuckTag.indexOf(' ');
        int paren = extractedBuckTag.indexOf('(');
        if (stop == -1 || (paren != -1 && paren < stop)) {
          stop = paren;
        }
        final finalBuckTag = stop == -1 ? extractedBuckTag : extractedBuckTag.substring(0, stop).trim();
        debugPrint('DEBUG: Extracted buck tag from semen: $finalBuckTag');
        if (finalBuckTag.isNotEmpty) {
          _controllers['Buck_tag']?.text = finalBuckTag;
          debugPrint('DEBUG: Set Buck_tag controller to: $finalBuckTag');
        }
      } else if (buckTag != null && buckTag.isNotEmpty) {
        debugPrint('DEBUG: Using direct Buck_tag: $buckTag');
        _controllers['Buck_tag']?.text = buckTag;
        _controllers['semen_used']?.text = '';
        debugPrint('DEBUG: Set Buck_tag controller to: $buckTag');
      }
      final tech = latestBreeding['technician']?.toString();
      if (tech != null && tech.isNotEmpty) {
        _controllers['technician']?.text = tech;
      }
      
      // Force UI refresh to ensure dropdowns pick up the controller values
      if (mounted) {
        setState(() {});
        debugPrint('DEBUG: Triggered setState after Pregnant auto-fill');
      }
    }

    // Gives Birth requires latest Pregnant; autofill breeding_date and expected_delivery_date
    if (value.toLowerCase() == 'gives birth') {
      debugPrint('DEBUG: Processing Gives Birth history record for goat: $goatTag');
      final latestPregnant = await _getLatestHistoryRecord(goatTag: goatTag, historyType: 'Pregnant');
      debugPrint('DEBUG: Latest pregnant history record found: $latestPregnant');
      if (latestPregnant == null) {
        debugPrint('DEBUG: No pregnant history record found, showing warning');
        _showWarningMessage('No Pregnant history record found. Cannot create Gives Birth history record.');
        setState(() => selectedHistoryType = 'Select type of history record');
        return;
      }

      final breedingDate = latestPregnant['breeding_date']?.toString();
      if (breedingDate != null && breedingDate.isNotEmpty) {
        _controllers['breeding_date']?.text = breedingDate;
      }
      final due = latestPregnant['expected_delivery_date']?.toString();
      if (due != null && due.isNotEmpty) {
        _controllers['expected_delivery_date']?.text = due;
      }

      // Autofill sire info from latest Pregnant (preferred) or fallback to latest Breeding
      String? semen = latestPregnant['semen_used']?.toString();
      String? buck = latestPregnant['Buck_tag']?.toString();
      debugPrint('DEBUG: Found in pregnant history record - Buck_tag: $buck, semen_used: $semen');
      if ((semen == null || semen.isEmpty) && (buck == null || buck.isEmpty)) {
        debugPrint('DEBUG: No sire info in pregnant history record, falling back to latest breeding');
        final latestBreeding = await _getLatestHistoryRecord(goatTag: goatTag, historyType: 'Breeding');
        debugPrint('DEBUG: Latest breeding history record for fallback: $latestBreeding');
        semen = latestBreeding?['semen_used']?.toString();
        buck = latestBreeding?['Buck_tag']?.toString();
        debugPrint('DEBUG: Fallback values - Buck_tag: $buck, semen_used: $semen');
      }

      if (semen != null && semen.isNotEmpty) {
        debugPrint('DEBUG: Processing semen for Gives Birth: $semen');
        _controllers['semen_used']?.text = semen;
        // Extract buck tag from semen label like "TAG123 (Name) Semen"
        String extracted = semen.trim();
        if (extracted.toLowerCase().endsWith('semen')) {
          extracted = extracted.substring(0, extracted.length - 5).trim();
        }
        int stop = extracted.indexOf(' ');
        int paren = extracted.indexOf('(');
        if (stop == -1 || (paren != -1 && paren < stop)) {
          stop = paren;
        }
        final buckTag = stop == -1 ? extracted : extracted.substring(0, stop).trim();
        debugPrint('DEBUG: Extracted buck tag from semen for Gives Birth: $buckTag');
        if (buckTag.isNotEmpty) {
          _controllers['Buck_tag']?.text = buckTag;
          debugPrint('DEBUG: Set Buck_tag controller for Gives Birth to: $buckTag');
        }
      } else if (buck != null && buck.isNotEmpty) {
        debugPrint('DEBUG: Using direct Buck_tag for Gives Birth: $buck');
        _controllers['Buck_tag']?.text = buck;
        _controllers['semen_used']?.text = '';
        debugPrint('DEBUG: Set Buck_tag controller for Gives Birth to: $buck');
      }

      // Force UI refresh so dropdowns pick up controller values
      if (mounted) {
        setState(() {});
        debugPrint('DEBUG: Triggered setState after Gives Birth auto-fill');
      }

      // If no kid data yet, prompt user to add kid when saving
    }
  }

  // Load existing kid data for editing
  Future<void> _loadExistingKidData() async {
    if (widget.historyRecord == null || widget.historyRecord!.kidTag == null) return;

    try {
      final kidTagString = widget.historyRecord!.kidTag!;
      debugPrint('Loading kid data for tag string: $kidTagString');
      
      // Check if there are multiple kid tags (comma-separated)
      if (kidTagString.contains(',')) {
        // Multiple calves - split by comma and load the first one for now
        final kidTags = kidTagString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
        debugPrint('Found multiple kid tags: $kidTags');
        
        if (kidTags.isNotEmpty) {
          // Load the first kid for editing
          final firstKidTag = kidTags.first;
          final kid = await GoatService.getGoatByTag(firstKidTag);
          if (kid != null && mounted) {
            setState(() {
              _temporaryKidData = {
                'tag_no': kid.tagNo,
                'sex': kid.sex,
                'registered': true, // Mark as already registered since it exists
                'isEditMode': true,
                'kidId': kid.id,
                'pendingOperation': 'update',
                'fullKidData': {
                  'id': kid.id,
                  'tag_no': kid.tagNo,
                  'sex': kid.sex,
                  'date_of_birth': kid.dateOfBirth,
                  'classification': kid.classification,
                  'status': kid.status,
                  'breed': kid.breed,
                  'source': kid.source,
                  'mother_tag': kid.motherTag,
                  'father_tag': kid.fatherTag,
                  'weight': kid.weight,
                  'group_name': kid.groupName,
                  'notes': kid.notes,
                },
              };
              _controllers['Kid_tag']?.text = kidTagString; // Keep the full string for display
            });
            debugPrint('Loaded first kid data: ${kid.tagNo} with ID: ${kid.id}');
          }
        }
      } else {
        // Single kid
        final kid = await GoatService.getGoatByTag(kidTagString);
        if (kid != null && mounted) {
          setState(() {
            _temporaryKidData = {
              'tag_no': kid.tagNo,
              'sex': kid.sex,
              'registered': true, // Mark as already registered since it exists
              'isEditMode': true,
              'kidId': kid.id,
              'pendingOperation': 'update',
              'fullKidData': {
                'id': kid.id,
                'tag_no': kid.tagNo,
                'sex': kid.sex,
                'date_of_birth': kid.dateOfBirth,
                'classification': kid.classification,
                'status': kid.status,
                'breed': kid.breed,
                'source': kid.source,
                'mother_tag': kid.motherTag,
                'father_tag': kid.fatherTag,
                'weight': kid.weight,
                'group_name': kid.groupName,
                'notes': kid.notes,
              },
            };
            _controllers['Kid_tag']?.text = kid.tagNo;
          });
          debugPrint('Loaded existing kid data: ${kid.tagNo} with ID: ${kid.id}');
        }
      }
    } catch (e) {
      debugPrint('Error loading kid data: $e');
      // If we can't load the kid, clear the temporary data
      if (mounted) {
        setState(() {
          _temporaryKidData = null;
          _controllers['Kid_tag']?.text = '';
        });
      }
    }
  }

  Future<void> _loadBreedingHistoryData() async {
    try {
      if (widget.historyRecord == null) {
        debugPrint('DEBUG: No history record to load breeding data from');
        return;
      }
      
      final eventJson = widget.historyRecord!.toJson();
      debugPrint('DEBUG: Loading breeding history data: $eventJson');
      debugPrint('DEBUG: History type: ${widget.historyRecord!.historyType}');
      debugPrint('DEBUG: Available fields in history record: ${eventJson.keys.toList()}');
      
      // Set breeding type (map human-readable <-> snake_case)
      final breedingType = eventJson['breeding_type']?.toString();
      debugPrint('DEBUG: Found breeding_type in history record: $breedingType');
      if (breedingType != null && breedingType.isNotEmpty) {
        final btLower = breedingType.toLowerCase().trim();
        String normalized;
        if (btLower == 'artificial insemination') {
          normalized = 'artificial_insemination';
        } else if (btLower == 'natural breeding') {
          normalized = 'natural_breeding';
        } else {
          // Already snake_case or unknown variant
          normalized = btLower.replaceAll(' ', '_');
        }
        _controllers['breeding_type']?.text = normalized;
        debugPrint('DEBUG: Set breeding type controller to (normalized): $normalized');
      } else {
        debugPrint('DEBUG: No breeding_type found in history record data');
        // Fallback inference based on available fields
        final semenUsedVal = eventJson['semen_used']?.toString() ?? '';
        final buckTagVal = eventJson['Buck_tag']?.toString() ?? '';
        if (semenUsedVal.isNotEmpty) {
          _controllers['breeding_type']?.text = 'artificial_insemination';
          debugPrint('DEBUG: Inferred breeding_type as artificial_insemination from semen_used');
        } else if (buckTagVal.isNotEmpty) {
          _controllers['breeding_type']?.text = 'natural_breeding';
          debugPrint('DEBUG: Inferred breeding_type as natural_breeding from Buck_tag');
        }
      }
      
      // Set semen used
      final semenUsed = eventJson['semen_used']?.toString();
      debugPrint('DEBUG: Found semen_used in history record: $semenUsed');
      if (semenUsed != null && semenUsed.isNotEmpty) {
        _controllers['semen_used']?.text = semenUsed;
        debugPrint('DEBUG: Set semen_used controller to: $semenUsed');
      } else {
        debugPrint('DEBUG: No semen_used found in history record data');
        // Fallback for AI: if breeding_type is AI and Buck_tag exists, use Buck_tag as semen_used
        final currentBreedingType = _controllers['breeding_type']?.text ?? '';
        final buckTagVal = eventJson['Buck_tag']?.toString() ?? '';
        if (currentBreedingType == 'artificial_insemination' && buckTagVal.isNotEmpty) {
          _controllers['semen_used']?.text = buckTagVal;
          debugPrint('DEBUG: Inferred semen_used from Buck_tag for AI: $buckTagVal');
        }
      }
      
      // Set buck tag
      final buckTag = eventJson['Buck_tag']?.toString();
      debugPrint('DEBUG: Found Buck_tag in history record: $buckTag');
      if (buckTag != null && buckTag.isNotEmpty) {
        _controllers['Buck_tag']?.text = buckTag;
        debugPrint('DEBUG: Set Buck_tag controller to: $buckTag');
      } else {
        debugPrint('DEBUG: No Buck_tag found in history record data');
      }
      
      // Set technician
      final technician = eventJson['technician']?.toString();
      debugPrint('DEBUG: Found technician in history record: $technician');
      if (technician != null && technician.isNotEmpty) {
        _controllers['technician']?.text = technician;
        debugPrint('DEBUG: Set technician controller to: $technician');
      } else {
        debugPrint('DEBUG: No technician found in history record data');
      }
      
      // buck-side reciprocal hydration: if subject is male and fields are missing, try to fetch partner Doe/Doeling history record on same date
      try {
        final isMaleSubject = (_goatDetails?.sex.toLowerCase() == 'male');
        final isBreeding = (widget.historyRecord!.historyType.toLowerCase() == 'breeding');
      final String _ = (_controllers['breeding_type']?.text ?? '').trim();
      // Values read below directly from controllers when needed; avoid unused locals
        final eventDate = (eventJson['history_date']?.toString() ?? '').trim();
        if (isMaleSubject && isBreeding && eventDate.isNotEmpty) {
          final notes = (eventJson['notes']?.toString() ?? '');
          // Expect notes like: "Breeding with <TAG>"
          String? partnerTag;
          final marker = 'Breeding with ';
          final idx = notes.indexOf(marker);
          if (idx != -1) {
            partnerTag = notes.substring(idx + marker.length).trim();
          }
          if (partnerTag != null && partnerTag.isNotEmpty) {
            debugPrint('DEBUG: Hydration - attempting to fetch partner history record for tag: $partnerTag on $eventDate');
            final allPartnerEvents = await GoatHistoryService.getgoatHistoryByTag(partnerTag);
            // Client-side filter by goat_tag to be safe
            final partnerEvents = allPartnerEvents.where((e) => (e['goat_tag']?.toString() ?? '') == partnerTag).toList();
            // Normalize dates to day precision
            DateTime? targetDate;
            try { targetDate = DateTime.parse(eventDate); } catch (_) { targetDate = null; }
            Map<String, dynamic> partner = {};
            if (targetDate != null) {
              final sameDay = partnerEvents.firstWhere(
                (e) {
                  try {
                    if ((e['history_type']?.toString().toLowerCase() ?? '') != 'breeding') return false;
                    final d = DateTime.parse(e['history_date']?.toString() ?? '');
                    return d.year == targetDate!.year && d.month == targetDate.month && d.day == targetDate.day;
                  } catch (_) { return false; }
                },
                orElse: () => {},
              );
              partner = sameDay;
              // Fallback: nearest breeding event on/before date
              if (partner.isEmpty) {
                final breedingEvents = partnerEvents.where((e) => (e['history_type']?.toString().toLowerCase() ?? '') == 'breeding').toList();
                breedingEvents.sort((a, b) {
                  DateTime? ad, bd;
                  try { ad = DateTime.parse(a['history_date']?.toString() ?? ''); } catch (_) {}
                  try { bd = DateTime.parse(b['history_date']?.toString() ?? ''); } catch (_) {}
                  if (ad == null || bd == null) return 0;
                  return bd.compareTo(ad);
                });
                for (final e in breedingEvents) {
                  try {
                    final d = DateTime.parse(e['history_date']?.toString() ?? '');
                    if (!d.isAfter(targetDate)) { partner = e; break; }
                  } catch (_) {}
                }
              }
            }
            if (partner.isNotEmpty) {
              // Save partner identifiers for unified editing on save
              _partnerTagForEdit = partnerTag;
              try {
                _partnerHistoryIdForEdit = partner['id'] is int
                    ? partner['id'] as int
                    : int.tryParse((partner['id']?.toString() ?? ''));
              } catch (_) {
                _partnerHistoryIdForEdit = int.tryParse((partner['id']?.toString() ?? ''));
              }
              // Prefer partner values to hydrate UI-only fields
              final partnerBT = partner['breeding_type']?.toString();
              if (partnerBT != null && partnerBT.isNotEmpty) {
                final btLower = partnerBT.toLowerCase();
                String normalized;
                if (btLower == 'artificial insemination') {
                  normalized = 'artificial_insemination';
                } else if (btLower == 'natural breeding') {
                  normalized = 'natural_breeding';
                } else {
                  normalized = btLower.replaceAll(' ', '_');
                }
                _controllers['breeding_type']?.text = normalized;
                debugPrint('DEBUG: Hydration - set breeding_type from partner: $normalized');
              }
              final semenPartner = partner['semen_used']?.toString();
              if (semenPartner != null && semenPartner.isNotEmpty) {
                _controllers['semen_used']?.text = semenPartner;
                debugPrint('DEBUG: Hydration - set semen_used from partner: $semenPartner');
              }
              final techPartner = partner['technician']?.toString();
              if (techPartner != null && techPartner.isNotEmpty) {
                _controllers['technician']?.text = techPartner;
                debugPrint('DEBUG: Hydration - set technician from partner: $techPartner');
              }
              // Copy date fields if missing
              final estReturn = (_controllers['estimated_return_date']?.text ?? '').trim();
              if (estReturn.isEmpty) {
                final pEst = partner['estimated_return_date']?.toString();
                if (pEst != null && pEst.isNotEmpty) {
                  _controllers['estimated_return_date']?.text = pEst;
                  debugPrint('DEBUG: Hydration - set estimated_return_date from partner: $pEst');
                }
              }
              final breedingDate = (_controllers['breeding_date']?.text ?? '').trim();
              if (breedingDate.isEmpty) {
                final pBreed = partner['breeding_date']?.toString();
                if (pBreed != null && pBreed.isNotEmpty) {
                  _controllers['breeding_date']?.text = pBreed;
                  debugPrint('DEBUG: Hydration - set breeding_date from partner: $pBreed');
                }
              }
              final expectedDelivery = (_controllers['expected_delivery_date']?.text ?? '').trim();
              if (expectedDelivery.isEmpty) {
                final pEDD = partner['expected_delivery_date']?.toString();
                if (pEDD != null && pEDD.isNotEmpty) {
                  _controllers['expected_delivery_date']?.text = pEDD;
                  debugPrint('DEBUG: Hydration - set expected_delivery_date from partner: $pEDD');
                }
              }
              // For Natural breeding on buck-side, prefill buck dropdown with current buck tag (UI only)
              final btNow = (_controllers['breeding_type']?.text ?? '').trim();
              if (btNow == 'natural_breeding') {
                final buckCtrl = _controllers['Buck_tag'];
                if (buckCtrl != null && buckCtrl.text.trim().isEmpty) {
                  final buckTagSelf = _goatDetails?.tagNo ?? '';
                  if (buckTagSelf.isNotEmpty) {
                    buckCtrl.text = buckTagSelf;
                    debugPrint('DEBUG: Hydration - set Buck_tag to self for natural breeding UI: $buckTagSelf');
                  }
                }
              }
            } else {
              debugPrint('DEBUG: Hydration - no matching partner breeding history record found');
              // Fallback: assume Natural on buck-side for completeness in UI
              _controllers['breeding_type']?.text = 'natural_breeding';
              final buckCtrl = _controllers['Buck_tag'];
              if (buckCtrl != null && buckCtrl.text.trim().isEmpty) {
                final buckTagSelf = _goatDetails?.tagNo ?? '';
                if (buckTagSelf.isNotEmpty) {
                  buckCtrl.text = buckTagSelf;
                  debugPrint('DEBUG: Hydration Fallback - set breeding_type to natural_breeding and Buck_tag to self: $buckTagSelf');
                }
              }
            }
          } else {
            debugPrint('DEBUG: Hydration - could not extract partner tag from notes: "$notes"');
          }
        }
      } catch (e) {
        debugPrint('DEBUG: Error hydrating buck reciprocal fields from partner: $e');
      }

      // Force UI refresh so dropdowns pick up controller values
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      debugPrint('Error loading breeding history data: $e');
    }
  }

  void _handleHistoryDateSelected(DateTime selectedDate) {
    if (selectedHistoryType.toLowerCase() == 'breeding') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _historySpecificFieldsKey.currentState
            ?.calculateAndDisplayReturnToHeatDate(selectedDate);
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadgoatDetails() async {
    // Get Goat Tag from either widget.goatTag or from the event being edited
    String? goatTag = widget.goatTag;
    if (goatTag == null && isEditing && widget.historyRecord != null) {
      goatTag = widget.historyRecord!.goatTag;
    }

    if (goatTag == null || goatTag.isEmpty) {
      _showErrorMessage('Invalid Goat Tag provided');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final goat = await GoatService.getGoatByTag(goatTag);

      // Animations are played only after the initial data is fetched.
      _fadeController.forward();
      _slideController.forward();

      if (goat != null && mounted) {
        setState(() {
          _goatDetails = goat;
        });

        if (isEditing && widget.historyRecord != null && _goatDetails != null) {
          await _setEditEventType(_goatDetails!);
          // Ensure breeding data hydration runs after goat details are available
          if (widget.historyRecord!.historyType == 'Breeding') {
            await _loadBreedingHistoryData();
          }
        }
      } else {
        if (mounted) {
          _showErrorMessage(
              'goat with tag "$goatTag" not found in the database');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error loading goat details: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setEditEventType(Goat goat) async {
    final editEventType = widget.historyRecord!.historyType;
    await Future.delayed(Duration.zero);

    final eventTypes = _getEventTypesForSex(goat.sex, classification: goat.classification);

    if (eventTypes.contains(editEventType)) {
      setState(() {
        selectedHistoryType = editEventType;
      });
    } else {
      setState(() {
        selectedHistoryType = 'Select type of event';
      });

      if (mounted) {
        _showWarningMessage(
            'History type "$editEventType" is not valid for ${goat.sex.toLowerCase()} goat. Please select a valid history type.');
      }
    }
  }

  List<String> _getEventTypesForSex(String sex, {String? classification}) {
    // Use the centralized utility method instead of duplicating logic
    return HistoryTypeUtils.getHistoryTypesForSex(sex, classification: classification);
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          overflow: TextOverflow.visible, softWrap: true),
      backgroundColor: Colors.red[600],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      duration: const Duration(seconds: 5),
    ));
  }

  void _showWarningMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          overflow: TextOverflow.visible, softWrap: true),
      backgroundColor: Colors.orange[600],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      duration: const Duration(seconds: 4),
    ));
  }


  // Execute kid operations only after successful event save
  Future<bool> _executeKidOperations() async {
    if (_temporaryKidData == null || _temporaryKidData!['fullKidData'] == null) {
      debugPrint('No kid operations to execute');
      return true; // No operations needed
    }

    try {
      final pendingOperation = _temporaryKidData!['pendingOperation'];
      final kidData = _temporaryKidData!['fullKidData'] as Map<String, dynamic>;
      final kidTag = _safeParseString(kidData['tag_no']) ?? '';

      debugPrint('Executing kid $pendingOperation for: $kidTag');

      bool success;
      if (pendingOperation == 'update') {
        // Ensure we have the ID for update
        int? kidId = _safeParseInt(kidData['id']) ?? _safeParseInt(_temporaryKidData!['kidId']);

        if (kidId == null) {
          debugPrint('No kid ID found for update, trying to find by tag');
          final existingKid = await GoatService.getGoatByTag(kidTag);
          if (existingKid != null) {
            kidId = existingKid.id;
            kidData['id'] = kidId;
          } else {
            throw Exception('Could not find existing kid with tag: $kidTag');
          }
        }

        success = await GoatService.updateGoatInformation(kidData);
        debugPrint('kid update result: $success for ID: $kidId');
      } else {
        // Create new kid - remove ID if present
        final newKidData = Map<String, dynamic>.from(kidData);
        newKidData.remove('id');

        success = await GoatService.storegoatInformation(newKidData);
        debugPrint('kid registration result: $success');
      }

      if (success) {
        // Update temporary data to reflect successful operation
        setState(() {
          _temporaryKidData!['registered'] = true;
        });
      }

      return success;
    } catch (e) {
      debugPrint('Error executing kid operations: $e');
      return false;
    }
  }

  Future<bool> _updateMotherStatus() async {
    try {
      if (_goatDetails != null) {
        final updateData = Map<String, dynamic>.from(_goatDetails!.toJson());
        updateData['status'] = 'Lactating';
        return await GoatService.updateGoatInformation(updateData);
      }
      return false;
    } catch (e) {
      debugPrint('Error updating mother status: $e');
      return false;
    }
  }

  Future<void> _handleGivesBirthEvent() async {
    try {
      bool kidHandled = false;
      bool motherStatusUpdated = false;
      String kidStatus = '';

      // Execute kid operations
      // Prefer multi-kid from HistorySpecificFields if available
      final multiCalves = _historySpecificFieldsKey.currentState?.getCalves();
      if (multiCalves != null && multiCalves.isNotEmpty) {
        bool allOk = true;
        for (final kid in multiCalves) {
          // Expect structure similar to _temporaryKidData
          final Map<String, dynamic> full = Map<String, dynamic>.from(kid['fullKidData'] ?? kid);
          // Ensure parent links
          full['mother_tag'] = _goatDetails?.tagNo ?? full['mother_tag'];
          full['father_tag'] = _controllers['Buck_tag']?.text.isNotEmpty == true
              ? _controllers['Buck_tag']!.text
              : full['father_tag'];

          // Enforce create or update explicitly
          final String pending = (kid['pendingOperation'] ?? 'create').toString();
          if (pending == 'create') {
            full.remove('id');
          }

          final Map<String, dynamic> op = {
            'pendingOperation': pending,
            'fullKidData': full,
            'tag_no': full['tag_no'],
            'kidId': full['id'],
            'isEditMode': pending == 'update',
          };
          _temporaryKidData = op;
          final ok = await _executeKidOperations();
          allOk = allOk && ok;
        }
        kidHandled = allOk;
      } else {
        kidHandled = await _executeKidOperations();
      }

      if (_temporaryKidData != null) {
        final kidTag = _temporaryKidData!['tag_no'] ?? 'unknown';
        final isEditMode = _temporaryKidData!['isEditMode'] == true;
        kidStatus = kidHandled
            ? (isEditMode ? 'kid $kidTag updated successfully' : 'kid $kidTag registered successfully')
            : (isEditMode ? 'Failed to update kid $kidTag' : 'Failed to register kid $kidTag');
      } else {
        kidStatus = 'No kid data to process';
        kidHandled = true; // No kid to handle
      }

      // Update mother status
      motherStatusUpdated = await _updateMotherStatus();
      final motherStatus = motherStatusUpdated
          ? 'Mother status updated to Lactating'
          : 'Failed to update mother status';

      // Log the results for debugging
      debugPrint('Birth event results - kid: $kidStatus, Mother: $motherStatus');

    } catch (e) {
      // Log any errors that occur during the process
      debugPrint('Error in _handleGivesBirthEvent: $e');
    }
  }

  Future<void> _handleCastratedEvent() async {
    try {
      bool goatClassificationUpdated = false;
      String goatStatus = '';

      // Update goat classification to Buckling
      if (_goatDetails != null) {
        final goatUpdateData = Map<String, dynamic>.from(_goatDetails!.toJson());
        goatUpdateData['classification'] = 'Buckling';
        goatClassificationUpdated = await GoatService.updateGoatInformation(goatUpdateData);
        goatStatus = goatClassificationUpdated
            ? 'goat ${_goatDetails!.tagNo} classification updated to Buckling'
            : 'Failed to update goat ${_goatDetails!.tagNo} classification to Buckling';
      }

      // Log the result for debugging
      debugPrint('Castrated event result: $goatStatus');

      // Optional: Show success feedback to user
      if (mounted && goatClassificationUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('goat classification updated to Buckling'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      debugPrint('Error in _handleCastratedEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update goat classification to Buckling'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openKidRegistrationDialog() async {
    // Get Goat Tag from either widget.goatTag or from the event being edited
    String? goatTag = widget.goatTag;
    if (goatTag == null && isEditing && widget.historyRecord != null) {
      goatTag = widget.historyRecord!.goatTag;
    }
    
    final motherTag = goatTag ?? '';
    final fatherTag = _controllers['Buck_tag']?.text ?? '';

    // Prepare existing kid data for the dialog with safe type conversion
    Map<String, dynamic>? existingKidData;
    if (_temporaryKidData != null) {
      try {
        existingKidData = <String, dynamic>{};

        // Copy basic fields with safe conversion
        existingKidData['tag_no'] = _safeParseString(_temporaryKidData!['tag_no']);
        existingKidData['name'] = _safeParseString(_temporaryKidData!['name']);
        existingKidData['sex'] = _safeParseString(_temporaryKidData!['sex']);
        existingKidData['registered'] = _temporaryKidData!['registered'] ?? false;
        existingKidData['isEditMode'] = _temporaryKidData!['isEditMode'] ?? false;

        // Safely get the kid ID
        int? kidId = _safeParseInt(_temporaryKidData!['kidId']);
        if (kidId != null) {
          existingKidData['kidId'] = kidId;
        }

        // Copy fullKidData if it exists
        if (_temporaryKidData!['fullKidData'] != null) {
          final originalFullData = _temporaryKidData!['fullKidData'] as Map<String, dynamic>;
          existingKidData['fullKidData'] = <String, dynamic>{};

          // Copy each field with safe type conversion
          final fullData = existingKidData['fullKidData'] as Map<String, dynamic>;
          fullData['tag_no'] = _safeParseString(originalFullData['tag_no']);
          fullData['name'] = _safeParseString(originalFullData['name']);
          fullData['sex'] = _safeParseString(originalFullData['sex']);
          fullData['date_of_birth'] = _safeParseString(originalFullData['date_of_birth']);
          fullData['classification'] = _safeParseString(originalFullData['classification']);
          fullData['status'] = _safeParseString(originalFullData['status']);
          fullData['breed'] = _safeParseString(originalFullData['breed']);
          fullData['source'] = _safeParseString(originalFullData['source']);
          fullData['mother_tag'] = _safeParseString(originalFullData['mother_tag']);
          fullData['father_tag'] = _safeParseString(originalFullData['father_tag']);
          fullData['weight'] = _safeParseDouble(originalFullData['weight']);
          fullData['group_name'] = _safeParseString(originalFullData['group_name']);
          fullData['notes'] = _safeParseString(originalFullData['notes']);

          // Include ID if available
          if (kidId != null) {
            fullData['id'] = kidId;
          } else if (originalFullData['id'] != null) {
            final id = _safeParseInt(originalFullData['id']);
            if (id != null) {
              fullData['id'] = id;
            }
          }
        }

        debugPrint('Prepared kid data for dialog: kidId=$kidId, isEditMode=${existingKidData['isEditMode']}');
      } catch (e) {
        debugPrint('Error preparing kid data for dialog: $e');
        existingKidData = null;
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => KidRegistrationDialog(
        motherTag: motherTag,
        fatherTag: fatherTag,
        existingKidData: existingKidData,
        isEditMode: _temporaryKidData != null,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _temporaryKidData = result;
        // Update the Kid_tag controller
        _controllers['Kid_tag']?.text = _safeParseString(result['tag_no']) ?? '';
      });
      debugPrint('kid dialog result: ${result['pendingOperation']} operation prepared for ${result['tag_no']}');
    }
  }

  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String? _safeParseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Please fix the form validation errors.');
      return;
    }

    if (selectedHistoryType == 'Select type of history record') {
      _showErrorMessage('Please select a history type.');
      return;
    }

    if (_goatDetails == null) {
      _showErrorMessage('goat information not loaded. Please try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get Goat Tag from either widget.goatTag or from the event being edited
      String? goatTag = widget.goatTag;
      if (goatTag == null && isEditing && widget.historyRecord != null) {
        goatTag = widget.historyRecord!.goatTag;
      }

      // Prepare data with better validation
      final data = <String, dynamic>{
        'goat_tag': goatTag?.trim(),
        'history_type': selectedHistoryType,
        'history_date': _controllers['history_date']!.text.trim(),
        'notes': _controllers['notes']!.text.trim(),
      };

      // Handle Kid_tag specially for Gives Birth history with multiple calves
      String kidTagValue = _controllers['Kid_tag']!.text.trim();
      if (selectedHistoryType.toLowerCase() == 'gives birth') {
        final multiCalves = _historySpecificFieldsKey.currentState?.getCalves();
        if (multiCalves != null && multiCalves.isNotEmpty) {
          // Collect all kid tags from multiple calves
          final kidTags = multiCalves
              .map((kid) => kid['tag_no']?.toString())
              .where((tag) => tag != null && tag.isNotEmpty)
              .toList();
          if (kidTags.isNotEmpty) {
            kidTagValue = kidTags.join(', ');
            debugPrint('DEBUG: Multiple kid tags collected: $kidTagValue');
          }
        }
      }

      // Add optional fields only if they have values
      final optionalFields = {
        'Buck_tag': _controllers['Buck_tag']!.text.trim(),
        'Kid_tag': kidTagValue,
        'diagnosis': _controllers['diagnosis']!.text.trim(),
        'technician': _controllers['technician']!.text.trim(),
        'medicine_given': _controllers['medicine_given']!.text.trim(),
        'semen_used': _controllers['semen_used']!.text.trim(),
        'estimated_return_date': _controllers['estimated_return_date']!.text.trim(),
        'breeding_date': _controllers['breeding_date']!.text.trim(),
        'expected_delivery_date': _controllers['expected_delivery_date']!.text.trim(),
        'cause_of_death': _controllers['cause_of_death']!.text.trim(),
        'last_known_location': _controllers['last_known_location']!.text.trim(),
        'sold_amount': _controllers['sold_amount']!.text.trim(),
        'buyer': _controllers['buyer']!.text.trim(),
        'disease_type': (() {
          final disease = _controllers['disease_type']!.text.trim();
          final other = _controllers['disease_type_other']!.text.trim();
          if (disease.toLowerCase() == 'other' && other.isNotEmpty) return other;
          return disease;
        })(),
      };

      // Add breeding type for breeding history
      if (selectedHistoryType.toLowerCase() == 'breeding') {
        final breedingFieldsKey = _historySpecificFieldsKey.currentState;
        final breedingType = breedingFieldsKey?.getBreedingType();
        if (breedingType != null) {
          data['breeding_type'] = breedingType;
        }
      }

      // Add non-empty optional fields
      optionalFields.forEach((key, value) {
        if (value.isNotEmpty) {
          data[key] = value;
        }
      });

      // Note: We remove estimated_return_date only from the buck-side payload later,
      // to ensure the partner Doe/Doeling keeps it when updated.

      // Handle weight field specially
      if (_controllers['weighed_result']!.text.trim().isNotEmpty) {
        final weight = double.tryParse(_controllers['weighed_result']!.text.trim());
        if (weight != null && weight > 0) {
          data['weighed_result'] = weight;
        } else {
          _showErrorMessage('Please enter a valid weight value.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Handle sold_amount field specially (remove commas and convert to number)
      if (_controllers['sold_amount']!.text.trim().isNotEmpty) {
        final cleanAmount = _controllers['sold_amount']!.text.trim().replaceAll(',', '');
        final amount = double.tryParse(cleanAmount);
        if (amount != null && amount > 0) {
          data['sold_amount'] = amount;
        } else {
          _showErrorMessage('Please enter a valid sale amount.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Validate required fields
      if (data['goat_tag'] == null || data['goat_tag'].toString().isEmpty) {
        throw Exception('Goat Tag is required');
      }

      if (data['history_date'].toString().isEmpty) {
        throw Exception('Event date is required');
      }

      // Validate cause of death for mortality history
      if (selectedHistoryType.toLowerCase() == 'mortality' &&
          _controllers['cause_of_death']!.text.trim().isEmpty) {
        _showErrorMessage('Cause of death is required for mortality history.');
        setState(() => _isLoading = false);
        return;
      }

      // Validate required fields for sold history
      if (selectedHistoryType.toLowerCase() == 'sold') {
        if (_controllers['sold_amount']!.text.trim().isEmpty) {
          _showErrorMessage('Sale amount is required for sold history.');
          setState(() => _isLoading = false);
          return;
        }
        if (_controllers['buyer']!.text.trim().isEmpty) {
          _showErrorMessage('Buyer information is required for sold history.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Additional validation for specific event types
      // If Sick, ensure disease type is provided; if Other, require custom text
      if (selectedHistoryType.toLowerCase() == 'sick') {
        final disease = _controllers['disease_type']!.text.trim();
        final diseaseOther = _controllers['disease_type_other']!.text.trim();
        if (disease.isEmpty) {
          _showErrorMessage('Please select a Type of Disease.');
          setState(() => _isLoading = false);
          return;
        }
        if (disease.toLowerCase() == 'other' && diseaseOther.isEmpty) {
          _showErrorMessage('Please specify the disease when selecting Other.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // If Treated, ensure there is at least one prior Sick event for this goat
      if (selectedHistoryType.toLowerCase() == 'treated') {
        try {
          final tag = (data['goat_tag'] ?? '').toString();
          final eventsForTag = await GoatHistoryService.getgoatHistoryByTag(tag);
          final hasSick = eventsForTag.any((e) => (e['history_type']?.toString().toLowerCase() ?? '') == 'sick');
          if (!hasSick) {
            _showErrorMessage('Cannot create Treated event: no prior Sick event found for #$tag.');
            setState(() => _isLoading = false);
            return;
          }
        } catch (_) {
          _showErrorMessage('Unable to verify prior Sick history. Please try again.');
          setState(() => _isLoading = false);
          return;
        }
      }
      // Enforce prerequisite: Pregnant requires latest Breeding
      if (selectedHistoryType.toLowerCase() == 'pregnant') {
        final latestBreeding = await _getLatestHistoryRecord(
          goatTag: data['goat_tag'],
          historyType: 'Breeding',
        );
        if (latestBreeding == null) {
          _showErrorMessage('Cannot create Pregnant history record: no Breeding history record found.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Enforce prerequisite: Gives Birth requires latest Pregnant
      if (selectedHistoryType.toLowerCase() == 'gives birth') {
        final latestPregnant = await _getLatestHistoryRecord(
          goatTag: data['goat_tag'],
          historyType: 'Pregnant',
        );
        if (latestPregnant == null) {
          _showErrorMessage('Cannot create Gives Birth history record: no Pregnant history record found.');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (selectedHistoryType.toLowerCase() == 'gives birth') {
        final multiCalves = _historySpecificFieldsKey.currentState?.getCalves();
        final hasMulti = multiCalves != null && multiCalves.isNotEmpty;
        final hasSingle = _controllers['Kid_tag']!.text.trim().isNotEmpty || _temporaryKidData != null;
        if (!hasMulti && !hasSingle) {
          _showErrorMessage('Please add at least one kid for birth history.');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (selectedHistoryType.toLowerCase() == 'breeding') {
        // Get breeding type from the breeding event fields
        final breedingFieldsKey = _historySpecificFieldsKey.currentState;
        final breedingType = breedingFieldsKey?.getBreedingType();
        
        if (breedingType == 'artificial_insemination') {
          // For AI, require semen_used and technician
          if (_controllers['semen_used']!.text.trim().isEmpty) {
            _showErrorMessage('Semen selection is required for Artificial Insemination.');
            setState(() => _isLoading = false);
            return;
          }
          if (_controllers['technician']!.text.trim().isEmpty) {
            _showErrorMessage('Technician is required for Artificial Insemination.');
            setState(() => _isLoading = false);
            return;
          }
        } else if (breedingType == 'natural_breeding') {
          // For natural breeding, require Buck_tag only
          if (_controllers['Buck_tag']!.text.trim().isEmpty) {
            _showErrorMessage('buck selection is required for Natural Breeding.');
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      // Log the data being sent (for debugging)
      debugPrint('=== FORM SUBMISSION DEBUG ===');
      debugPrint('Submitting event data: $data');
      debugPrint('Is editing: $isEditing');
      debugPrint('Selected event type: $selectedHistoryType');
      debugPrint('goat details loaded: ${_goatDetails != null}');
      if (_temporaryKidData != null) {
        debugPrint('Temporary kid data: $_temporaryKidData');
      }

      bool eventSuccess;

      try {
        if (isEditing) {
          if (widget.historyRecord?.id == null) {
            throw Exception('Event ID is required for editing');
          }
          data['id'] = widget.historyRecord!.id;

          // Unified editing: if editing a buck reciprocal breeding, first update the partner Doe/Doeling event with full details
          final isBuckSubject = _goatDetails?.sex.toLowerCase() == 'male';
          final isBreedingEdit = selectedHistoryType.toLowerCase() == 'breeding';
          if (isBuckSubject && isBreedingEdit && _partnerTagForEdit != null && _partnerHistoryIdForEdit != null) {
            // Build partner payload mirroring current UI values
            final partnerData = Map<String, dynamic>.from(data);
            partnerData['id'] = _partnerHistoryIdForEdit;
            partnerData['goat_tag'] = _partnerTagForEdit;
            // Do not propagate notes into the partner event
            partnerData.remove('notes');
            // Ensure breeding_type mirrors UI selection
            final breedingFieldsKey = _historySpecificFieldsKey.currentState;
            final partnerBT = breedingFieldsKey?.getBreedingType();
            if (partnerBT != null) {
              partnerData['breeding_type'] = partnerBT;
            }
            // For AI, partner needs semen_used and technician; for Natural, partner needs Buck_tag (self)
            if ((partnerBT ?? '').toLowerCase() == 'artificial_insemination') {
              // keep semen_used, technician from current controllers
              partnerData.remove('Buck_tag');
            } else if ((partnerBT ?? '').toLowerCase() == 'natural_breeding') {
              // set Buck_tag to this buck's tag; remove semen/technician
              final buckSelf = _goatDetails?.tagNo ?? '';
              if (buckSelf.isNotEmpty) partnerData['Buck_tag'] = buckSelf;
              partnerData.remove('semen_used');
              partnerData.remove('technician');
            }
            // Remove return-to-heat only from buck payload (current 'data'), not from partnerData
            data.remove('estimated_return_date');
            // Execute partner update before saving the buck event
            final partnerOk = await GoatHistoryService.updategoatHistory(partnerData);
            debugPrint('Unified edit: partner update result: $partnerOk');
          }

          // Unified editing: if editing a female breeding event, update the buck reciprocal as well
          final isFemaleSubject = _goatDetails?.sex.toLowerCase() == 'female';
          if (isFemaleSubject && isBreedingEdit) {
            // Determine partner buck tag based on breeding_type
            final breedingFieldsKey = _historySpecificFieldsKey.currentState;
            final bt = breedingFieldsKey?.getBreedingType() ?? data['breeding_type']?.toString();
            String? partnerBuckTag;
            if ((bt ?? '').toLowerCase() == 'natural_breeding') {
              partnerBuckTag = _controllers['Buck_tag']?.text.trim();
            } else if ((bt ?? '').toLowerCase() == 'artificial_insemination') {
              // For AI, buck tag is not used; reciprocal exists but without sire fields
              partnerBuckTag = null;
            }

            if (partnerBuckTag != null && partnerBuckTag.isNotEmpty) {
              // Fetch partner buck history and find matching breeding by date
              final allPartnerEvents = await GoatHistoryService.getgoatHistoryByTag(partnerBuckTag);
              final partnerEvents = allPartnerEvents.where((e) => (e['goat_tag']?.toString() ?? '') == partnerBuckTag).toList();
              Map<String, dynamic> partner = {};
              try {
                final targetDate = DateTime.parse(data['history_date']);
                partner = partnerEvents.firstWhere(
                  (e) {
                    try {
                      if ((e['history_type']?.toString().toLowerCase() ?? '') != 'breeding') return false;
                      final d = DateTime.parse(e['history_date']?.toString() ?? '');
                      return d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day;
                    } catch (_) { return false; }
                  },
                  orElse: () => {},
                );
              } catch (_) {}

              if (partner.isNotEmpty) {
                // Build buck-side payload with limited fields and explicitly omit return-to-heat
                final buckData = <String, dynamic>{
                  'id': partner['id'],
                  'goat_tag': partnerBuckTag,
                  'history_type': 'Breeding',
                  'history_date': data['history_date'],
                  'breeding_type': 'Natural Breeding',
                  // Do not overwrite partner buck notes
                };
                // Execute buck update
                final buckOk = await GoatHistoryService.updategoatHistory(buckData);
                debugPrint('Unified edit: buck reciprocal update result: $buckOk');
              }
            }
          }

          debugPrint('Updating event with ID: ${widget.historyRecord!.id}');
          eventSuccess = await GoatHistoryService.updategoatHistory(data);
        } else {
          debugPrint('Creating new history record');
          eventSuccess = await GoatHistoryService.storegoatHistory(data);
        }

        debugPrint('Event service result: $eventSuccess');
      } catch (serviceError) {
        debugPrint('Service error details: $serviceError');
        debugPrint('Service error type: ${serviceError.runtimeType}');

        // More specific error handling
        String errorMessage = 'Service error: $serviceError';
        if (serviceError.toString().contains('SocketException')) {
          errorMessage = 'Network error: Please check your internet connection.';
        } else if (serviceError.toString().contains('TimeoutException')) {
          errorMessage = 'Request timeout: Please try again.';
        } else if (serviceError.toString().contains('FormatException')) {
          errorMessage = 'Data format error: Please check your input.';
        }

        throw Exception(errorMessage);
      }

      if (eventSuccess) {
        debugPrint('Event saved successfully, handling specific event types...');

        // Event saved successfully, now handle specific event types
        try {
          debugPrint('🎯 Event type handling - selectedHistoryType: "$selectedHistoryType"');
          if (selectedHistoryType.toLowerCase() == 'gives birth') {
            debugPrint('🎯 Handling Gives Birth event');
            await _handleGivesBirthEvent();
          } else if (selectedHistoryType.toLowerCase() == 'breeding') {
            debugPrint('🎯 Handling Breeding event');
            await _handleBreedingEvent();
          } else if (selectedHistoryType.toLowerCase() == 'pregnant') {
            debugPrint('🎯 Handling Pregnant event');
            await _handlePregnantEvent();
          } else if (selectedHistoryType.toLowerCase() == 'castrated') {
            debugPrint('🎯 Handling Castrated event');
            await _handleCastratedEvent();
          } else if (selectedHistoryType.toLowerCase() == 'mortality') {
            debugPrint('🎯 Handling Mortality event');
            await _handleMortalityEvent();
          } else if (selectedHistoryType.toLowerCase() == 'lost') {
            debugPrint('🎯 Handling Lost event');
            await _handleLostEvent();
          } else if (selectedHistoryType.toLowerCase() == 'sold') {
            debugPrint('🎯 Handling Sold event');
            await _handleSoldEvent();
          } else if (selectedHistoryType.toLowerCase() == 'weighed') {
            debugPrint('🎯 Handling Weighed event');
            await _handleWeighedEvent();
          } else if (selectedHistoryType.toLowerCase() == 'sick') {
            debugPrint('🎯 Handling Sick event');
            await _handleSickEvent();
          } else {
            debugPrint('🎯 No specific event handler for: "$selectedHistoryType"');
          }
        } catch (eventSpecificError) {
          // Log but don't fail the entire operation for event-specific errors
          debugPrint('Warning - Event-specific operation failed: $eventSpecificError');

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('History record saved, but some related operations may have failed: ${eventSpecificError.toString()}'),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              duration: const Duration(seconds: 4),
            ),
          );
        }

        if (!mounted) return;
        SuccessDialog.show(
          context: context,
          isEditing: isEditing,
          onContinue: () {
            Navigator.pop(context);
            Navigator.pop(context, true);
          },
        );
      } else {
        // More specific error message based on operation
        String errorDetail = isEditing ?
        'Failed to update the goat event. Please verify your data and try again.' :
        'Failed to create the goat event. Please check your input data and network connection.';

        throw Exception('$errorDetail The service returned false, which may indicate:\n'
            '• Server validation errors\n'
            '• Network connectivity issues\n'
            '• Authentication problems\n'
            '• Invalid data format\n\n'
            'Check the console logs for more details.');
      }
    } catch (e) {
      debugPrint('=== ERROR IN _submitForm ===');
      debugPrint('Error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Stack trace: ${StackTrace.current}');

      String userFriendlyMessage;
      if (e.toString().contains('Network error')) {
        userFriendlyMessage = 'Network error: Please check your internet connection and try again.';
      } else if (e.toString().contains('timeout')) {
        userFriendlyMessage = 'Request timed out: Please try again.';
      } else if (e.toString().contains('Service error')) {
        userFriendlyMessage = e.toString();
      } else {
        userFriendlyMessage = 'Error saving event: ${e.toString()}';
      }

      if (!mounted) return;
      _showErrorMessage(userFriendlyMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSoldEvent() async {
    try {
      bool goatStatusUpdated = false;
      bool goatArchived = false;
      String goatStatus = '';

      // Update goat status to Sold
      if (_goatDetails != null) {
        final goatUpdateData = Map<String, dynamic>.from(_goatDetails!.toJson());
        goatUpdateData['status'] = 'Sold';
        goatStatusUpdated = await GoatService.updateGoatInformation(goatUpdateData);
        goatStatus = goatStatusUpdated
            ? 'goat ${_goatDetails!.tagNo} status updated to Sold'
            : 'Failed to update goat ${_goatDetails!.tagNo} status to Sold';

        // Auto-archive the goat after updating status
        if (goatStatusUpdated) {
          final soldAmount = _controllers['sold_amount']?.text.trim() ?? '';
          final buyer = _controllers['buyer']?.text.trim() ?? '';
          final notes = _controllers['notes']?.text.trim() ?? '';
          
          String archiveNotes = '';
          if (soldAmount.isNotEmpty) {
            archiveNotes += 'Sale amount: ₱${soldAmount.replaceAll(',', '')}';
          }
          if (buyer.isNotEmpty) {
            archiveNotes += archiveNotes.isNotEmpty ? '\nBuyer: $buyer' : 'Buyer: $buyer';
          }
          if (notes.isNotEmpty) {
            archiveNotes += archiveNotes.isNotEmpty ? '\nNotes: $notes' : 'Notes: $notes';
          }
          
          goatArchived = await GoatService.archivegoat(
            _goatDetails!.id, 
            'Sold',
            notes: archiveNotes.isNotEmpty ? archiveNotes : null,
          );
          
          debugPrint('Auto-archive result for sold goat: $goatArchived');
        }
      }

      // Log the result for debugging
      debugPrint('Sold event result: $goatStatus');

      // Show success feedback to user
      if (mounted && goatStatusUpdated) {
        final message = goatArchived 
            ? 'goat status updated to Sold and moved to archive'
            : 'goat status updated to Sold';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: goatArchived ? Colors.green[600] : Colors.blue[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      debugPrint('Error in _handleSoldEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update goat status to Sold'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool _shouldShowReturnToHeatField() {
    return _goatDetails?.sex.toLowerCase() == 'female' &&
        selectedHistoryType.toLowerCase() == 'breeding';
  }

  Future<void> _handleBreedingEvent() async {
    debugPrint('🚀🚀🚀 _handleBreedingEvent() CALLED! 🚀🚀🚀');
    try {
      bool doeStatusUpdated = false;
      String doeStatus = '';

      // Update Doe (mother) status to Breeding
      if (_goatDetails != null) {
        final doeUpdateData = Map<String, dynamic>.from(_goatDetails!.toJson());
        doeUpdateData['status'] = 'Breeding';
        doeStatusUpdated = await GoatService.updateGoatInformation(doeUpdateData);
        doeStatus = doeStatusUpdated
            ? 'Doe ${_goatDetails!.tagNo} status updated to Breeding'
            : 'Failed to update Doe ${_goatDetails!.tagNo} status';
      }

      // Log the results for debugging
      debugPrint('Breeding event results:');
      debugPrint('- Doe: $doeStatus');

      final returnToHeatText = _controllers['estimated_return_date']?.text ?? '';
      if (returnToHeatText.isNotEmpty) {
        final DateTime? returnToHeatDate = DateTime.tryParse(returnToHeatText);
        final today = DateTime.now();
        if (returnToHeatDate != null &&
            returnToHeatDate.year == today.year &&
            returnToHeatDate.month == today.month &&
            returnToHeatDate.day == today.day) {
          final doeUpdateData = Map<String, dynamic>.from(_goatDetails!.toJson());
          doeUpdateData['status'] = 'Healthy';
          final updated = await GoatService.updateGoatInformation(doeUpdateData);
          if (updated) {
            debugPrint('Doe ${_goatDetails!.tagNo} status auto-updated to Healthy');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Doe ${_goatDetails!.tagNo} status changed to Healthy (Return to Heat)'),
                  backgroundColor: Colors.green[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }

      // Create reciprocal breeding event for the male goat
      debugPrint('DEBUG: About to create reciprocal breeding event');
      debugPrint('DEBUG: Current goat details: ${_goatDetails?.tagNo}');
      debugPrint('DEBUG: Breeding type controller value: ${_controllers['breeding_type']?.text}');
      debugPrint('DEBUG: Semen used controller value: ${_controllers['semen_used']?.text}');
      debugPrint('DEBUG: buck tag controller value: ${_controllers['Buck_tag']?.text}');
      await _createReciprocalBreedingEvent();

      // Log the results for debugging
      debugPrint('Breeding event results:');
      debugPrint('- Doe: $doeStatus');

      // Optional: Show a snackbar with summary if needed
      if (mounted && doeStatusUpdated) {

        // You can uncomment this if you want to show success feedback
        /*
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          duration: const Duration(seconds: 3),
        ),
      );
      */
      }

    } catch (e) {
      // Log any errors that occur during the process
      debugPrint('Error in _handleBreedingEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Some breeding history operations may have failed'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _createReciprocalBreedingEvent() async {
    debugPrint('🔥🔥🔥 _createReciprocalBreedingEvent() CALLED! 🔥🔥🔥');
    try {
      final breedingType = _controllers['breeding_type']?.text ?? '';
      String? partnergoatTag;
      
      debugPrint('DEBUG: Creating reciprocal breeding event');
      debugPrint('DEBUG: Breeding type: $breedingType');
      debugPrint('DEBUG: All controller values:');
      debugPrint('  - breeding_type: ${_controllers['breeding_type']?.text}');
      debugPrint('  - semen_used: ${_controllers['semen_used']?.text}');
      debugPrint('  - Buck_tag: ${_controllers['Buck_tag']?.text}');
      debugPrint('  - history_date: ${_controllers['history_date']?.text}');
      
      // Determine the partner goat based on breeding type
      if (breedingType == 'artificial_insemination') {
        final semenUsed = _controllers['semen_used']?.text ?? '';
        debugPrint('DEBUG: Semen used: $semenUsed');
        if (semenUsed.isNotEmpty) {
          // We now store pure tag. If any old label format slips through, fall back to parsing.
          if (semenUsed.contains(' Semen')) {
            String tagPart = semenUsed.replaceAll(' Semen', '');
            if (tagPart.contains(' (') && tagPart.contains(')')) {
              partnergoatTag = tagPart.split(' (')[0];
            } else {
              partnergoatTag = tagPart;
            }
            debugPrint('DEBUG: Extracted buck tag from semen label: $partnergoatTag');
          } else {
            partnergoatTag = semenUsed.trim();
            debugPrint('DEBUG: Using semen_used as pure tag for partner: $partnergoatTag');
          }
        }
      } else if (breedingType == 'natural_breeding') {
        partnergoatTag = _controllers['Buck_tag']?.text ?? '';
        debugPrint('DEBUG: buck tag from natural breeding: $partnergoatTag');
      } else {
        // Fallback: try to determine from available fields
        debugPrint('DEBUG: Unknown breeding type, trying fallback detection');
        final semenUsed = _controllers['semen_used']?.text ?? '';
        final buckTag = _controllers['Buck_tag']?.text ?? '';
        
        if (semenUsed.isNotEmpty) {
          debugPrint('DEBUG: Fallback - using semen field');
          if (semenUsed.contains(' Semen')) {
            String tagPart = semenUsed.replaceAll(' Semen', '');
            if (tagPart.contains(' (') && tagPart.contains(')')) {
              partnergoatTag = tagPart.split(' (')[0];
            } else {
              partnergoatTag = tagPart;
            }
          }
        } else if (buckTag.isNotEmpty) {
          debugPrint('DEBUG: Fallback - using buck tag field');
          partnergoatTag = buckTag;
        }
      }
      
      if (partnergoatTag == null || partnergoatTag.isEmpty) {
        debugPrint('DEBUG: No partner goat found for reciprocal breeding event');
        debugPrint('DEBUG: Breeding type was: $breedingType');
        debugPrint('DEBUG: Semen used was: ${_controllers['semen_used']?.text}');
        debugPrint('DEBUG: buck tag was: ${_controllers['Buck_tag']?.text}');
        return;
      }
      
      // Find the partner goat
      final partnergoat = await GoatService.getGoatByTag(partnergoatTag);
      if (partnergoat == null) {
        debugPrint('Partner goat not found: $partnergoatTag');
        return;
      }
      
      // Check if partner goat is male (buck)
      final partnerSex = partnergoat.sex.toLowerCase().trim();
      if (partnerSex != 'male') {
        debugPrint('Partner goat is not male, skipping reciprocal breeding event');
        return;
      }
      
      // Check if a breeding event already exists for this partner on the same date
      final eventDate = _controllers['history_date']?.text ?? '';
      if (eventDate.isNotEmpty) {
        final existingEvents = await GoatHistoryService.getgoatHistoryByTag(partnergoatTag);
        debugPrint('DEBUG: Checking for existing history for partner: $partnergoatTag');
        debugPrint('DEBUG: Found ${existingEvents.length} history for partner');
        
        // Filter history to only include those for the specific partner goat
        final partnerEvents = existingEvents.where((event) => 
          event['goat_tag']?.toString() == partnergoatTag
        ).toList();
        
        debugPrint('DEBUG: Filtered to ${partnerEvents.length} history for partner goat');
        
        final hasExistingBreedingEvent = partnerEvents.any((event) => 
          event['history_type']?.toString().toLowerCase() == 'breeding' && 
          event['history_date']?.toString() == eventDate
        );
        
        if (hasExistingBreedingEvent) {
          debugPrint('DEBUG: Breeding event already exists for partner goat on this date');
          return;
        } else {
          debugPrint('DEBUG: No existing breeding event found for partner on this date');
        }
      }
      
      // Create reciprocal breeding event for the male
      final reciprocalEventData = {
        'goat_tag': partnergoatTag,
        // Use proper case to match backend ENUM
        'history_type': 'Breeding',
        'history_date': _controllers['history_date']?.text ?? '',
        // Map to human-readable for backend storage
        'breeding_type': (breedingType == 'artificial_insemination')
            ? 'Artificial Insemination'
            : (breedingType == 'natural_breeding')
                ? 'Natural Breeding'
                : breedingType,
        'notes': 'Breeding with ${_goatDetails?.tagNo ?? 'unknown'}',
        'user_id': 1, // Use default user ID for now
      };
      
      // Add breeding-specific fields
      if (breedingType == 'artificial_insemination') {
        // Do not include semen_used for reciprocal buck event
        reciprocalEventData['technician'] = _controllers['technician']?.text ?? '';
      } else if (breedingType == 'natural_breeding') {
        reciprocalEventData['Buck_tag'] = _controllers['Buck_tag']?.text ?? '';
      }
      
      final result = await GoatHistoryService.storegoatHistory(reciprocalEventData);
      
      if (result) {
        debugPrint('Successfully created reciprocal breeding event for $partnergoatTag');
        
        // Update partner goat status to Breeding
        final partnerUpdateData = Map<String, dynamic>.from(partnergoat.toJson());
        partnerUpdateData['status'] = 'Breeding';
        await GoatService.updateGoatInformation(partnerUpdateData);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reciprocal breeding history record created for $partnergoatTag'),
              backgroundColor: Colors.blue[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('Failed to create reciprocal breeding event for $partnergoatTag');
      }
      
    } catch (e) {
      debugPrint('Error creating reciprocal breeding event: $e');
      // Don't show error to user as this is a secondary operation
    }
  }

  Future<void> _handlePregnantEvent() async {
    try {
      bool doeStatusUpdated = false;
      String doeStatus = '';

      // Update Doe (mother) status to Pregnant
      if (_goatDetails != null) {
        final doeUpdateData = Map<String, dynamic>.from(_goatDetails!.toJson());
        doeUpdateData['status'] = 'Pregnant';
        doeStatusUpdated = await GoatService.updateGoatInformation(doeUpdateData);
        doeStatus = doeStatusUpdated
            ? 'Doe ${_goatDetails!.tagNo} status updated to Pregnant'
            : 'Failed to update Doe ${_goatDetails!.tagNo} status to Pregnant';
      }

      // Log the result for debugging
      debugPrint('Pregnant event result: $doeStatus');

      // Optional: Show success feedback to user
      if (mounted && doeStatusUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('goat status updated to Pregnant'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      debugPrint('Error in _handlePregnantEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update goat status to Pregnant'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleMortalityEvent() async {
    try {
      bool goatStatusUpdated = false;
      bool goatArchived = false;
      String goatStatus = '';

      // Update goat status to Mortality
      if (_goatDetails != null) {
        final goatUpdateData = Map<String, dynamic>.from(_goatDetails!.toJson());
        goatUpdateData['status'] = 'Mortality';
        goatStatusUpdated = await GoatService.updateGoatInformation(goatUpdateData);
        goatStatus = goatStatusUpdated
            ? 'goat ${_goatDetails!.tagNo} status updated to Mortality'
            : 'Failed to update goat ${_goatDetails!.tagNo} status to Mortality';

        // Auto-archive the goat after updating status
        if (goatStatusUpdated) {
          final causeOfDeath = _controllers['cause_of_death']?.text.trim() ?? '';
          final notes = _controllers['notes']?.text.trim() ?? '';
          final archiveNotes = causeOfDeath.isNotEmpty 
              ? 'Cause of death: $causeOfDeath${notes.isNotEmpty ? '\nNotes: $notes' : ''}'
              : notes;
          
          goatArchived = await GoatService.archivegoat(
            _goatDetails!.id, 
            'Mortality',
            notes: archiveNotes.isNotEmpty ? archiveNotes : null,
          );
          
          debugPrint('Auto-archive result for mortality goat: $goatArchived');
        }
      }

      // Log the result for debugging
      debugPrint('Mortality event result: $goatStatus');

      // Show success feedback to user
      if (mounted && goatStatusUpdated) {
        final message = goatArchived 
            ? 'goat status updated to Mortality and moved to archive'
            : 'goat status updated to Mortality';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: goatArchived ? Colors.green[600] : Colors.grey[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      debugPrint('Error in _handleMortalityEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update goat status to Mortality'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleWeighedEvent() async {
    try {
      if (_goatDetails == null) return;

      final weightText = _controllers['weighed_result']?.text.trim() ?? '';
      final latestWeight = double.tryParse(weightText);

      if (latestWeight == null || latestWeight <= 0) {
        debugPrint('Weighed event: invalid or empty weight, skipping goat weight update');
        return;
      }

      final goatUpdateData = Map<String, dynamic>.from(_goatDetails!.toJson());
      goatUpdateData['weight'] = latestWeight;

      final updated = await GoatService.updateGoatInformation(goatUpdateData);
      debugPrint('goat weight update result: $updated');

      if (mounted && updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated weight to ${latestWeight.toStringAsFixed(1)} kg'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _handleWeighedEvent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update goat weight'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleLostEvent() async {
    try {
      bool goatStatusUpdated = false;
      bool goatArchived = false;
      String goatStatus = '';

      // Update goat status to Lost
      if (_goatDetails != null) {
        final goatUpdateData = Map<String, dynamic>.from(_goatDetails!.toJson());
        goatUpdateData['status'] = 'Lost';
        goatStatusUpdated = await GoatService.updateGoatInformation(goatUpdateData);
        goatStatus = goatStatusUpdated
            ? 'goat ${_goatDetails!.tagNo} status updated to Lost'
            : 'Failed to update goat ${_goatDetails!.tagNo} status to Lost';

        // Auto-archive the goat after updating status
        if (goatStatusUpdated) {
          final lastLocation = _controllers['last_known_location']?.text.trim() ?? '';
          final notes = _controllers['notes']?.text.trim() ?? '';
          final archiveNotes = lastLocation.isNotEmpty 
              ? 'Last known location: $lastLocation${notes.isNotEmpty ? '\nNotes: $notes' : ''}'
              : notes;
          
          goatArchived = await GoatService.archivegoat(
            _goatDetails!.id, 
            'Lost',
            notes: archiveNotes.isNotEmpty ? archiveNotes : null,
          );
          
          debugPrint('Auto-archive result for lost goat: $goatArchived');
        }
      }

      // Log the result for debugging
      debugPrint('Lost event result: $goatStatus');

      // Show success feedback to user
      if (mounted && goatStatusUpdated) {
        final message = goatArchived 
            ? 'goat status updated to Lost and moved to archive'
            : 'goat status updated to Lost';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: goatArchived ? Colors.green[600] : Colors.amber[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      debugPrint('Error in _handleLostEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update goat status to Lost'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleSickEvent() async {
    try {
      bool goatStatusUpdated = false;
      String goatStatus = '';

      // Update goat status to Sick
      if (_goatDetails != null) {
        final goatUpdateData = Map<String, dynamic>.from(_goatDetails!.toJson());
        goatUpdateData['status'] = 'Sick';
        goatStatusUpdated = await GoatService.updateGoatInformation(goatUpdateData);
        goatStatus = goatStatusUpdated
            ? 'goat ${_goatDetails!.tagNo} status updated to Sick'
            : 'Failed to update goat ${_goatDetails!.tagNo} status to Sick';
      }

      // Log the result for debugging
      debugPrint('Sick event result: $goatStatus');

      // Optional: Show success feedback to user
      if (mounted && goatStatusUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('goat status updated to Sick'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      debugPrint('Error in _handleSickEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update goat status to Sick'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await DeleteConfirmationDialog.show(context);
    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success =
      await GoatHistoryService.deletegoatHistory(widget.historyRecord!.id);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Goat History' : 'Add Goat History',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        actions: isEditing
            ? [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteEvent,
            tooltip: 'Delete Event',
          )
        ]
            : null,
      ),
      body: SafeArea(
        child: _isLoading && _goatDetails == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.vibrantGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading goat information...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        )
            : FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // goat Info Card
                            HistorygoatInfoCard(
                              goatDetails: _goatDetails,
                              goatTag: widget.goatTag,
                            ),
                            const SizedBox(height: 30),

                            // Event Type Section
                            HistoryTypeDropdown(
                              goatDetails: _goatDetails,
                              selectedHistoryType: selectedHistoryType,
                              controllers: _controllers,
                              locked: !isEditing && widget.initialHistoryType != null,
                              onHistoryTypeChanged: (value) {
                                if (value != null) {
                                  _handleHistoryTypeChanged(value);
                                }
                              },
                              onHistoryDateSelected: _handleHistoryDateSelected,
                            ),
                            const SizedBox(height: 30),

                            // History-specific fields
                            HistorySpecificFields(
                              key: _historySpecificFieldsKey,
                              selectedEventType: selectedHistoryType,
                              controllers: _controllers,
                              goatTag: widget.goatTag ?? (isEditing && widget.historyRecord != null ? widget.historyRecord!.goatTag : null),
                              temporaryKidData: _temporaryKidData,
                              onEditKidPressed: _openKidRegistrationDialog,
                              showReturnToHeat: _shouldShowReturnToHeatField(),
                            ),

                            // Notes Section
                            HistoryNotesSection(
                              controller: _controllers['notes']!,
                            ),
                            const SizedBox(height: 40),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading || _goatDetails == null
                                    ? null
                                    : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.vibrantGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  shadowColor:
                                  AppColors.vibrantGreen.withValues(alpha: 0.3),
                                ),
                                icon: _isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Icon(
                                  isEditing
                                      ? FontAwesomeIcons.penToSquare
                                      : FontAwesomeIcons.plus,
                                  size: 18,
                                ),
                                label: Text(
                                  _isLoading
                                      ? 'Saving...'
                                      : (isEditing ? 'Update Event' : 'Create Event'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}