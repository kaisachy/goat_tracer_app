// lib/screens/nav/cattle/cattle_event_form_screen.dart

import 'package:cattle_tracer_app/screens/nav/cattle/widgets/events/event_specific_fields.dart';
import 'package:cattle_tracer_app/screens/nav/cattle/widgets/events/event_type_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/cattle.dart';
import '../../../services/cattle/cattle_event_service.dart';
import '../../../services/cattle/cattle_service.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/event_type_utils.dart';
import 'modals/calf_registration_dialog.dart';
import 'widgets/events/event_cattle_info_card.dart';
import 'widgets/events/event_notes_section.dart';
import 'modals/event_success_dialog.dart';
import 'modals/event_delete_confirmation_dialog.dart';

class CattleEventFormScreen extends StatefulWidget {
  final CattleEvent? event;
  final String? cattleTag;

  const CattleEventFormScreen({
    super.key,
    this.event,
    this.cattleTag,
  });

  @override
  State<CattleEventFormScreen> createState() => _CattleEventFormScreenState();
}

class _CattleEventFormScreenState extends State<CattleEventFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<EventSpecificFieldsState> _eventSpecificFieldsKey =
  GlobalKey<EventSpecificFieldsState>();
  late bool isEditing;
  bool _isLoading = false;

  // Cattle details
  Cattle? _cattleDetails;

  // Partner linkage for unified editing when editing bull reciprocal breeding
  String? _partnerTagForEdit;
  int? _partnerEventIdForEdit;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String selectedEventType = 'Select type of event';

  // New state for temporary calf data
  Map<String, dynamic>? _temporaryCalfData;

  @override
  void initState() {
    super.initState();
    isEditing = widget.event != null;
    _initializeAnimations();
    _initializeControllers();
    _loadCattleDetails();

    // Load existing calf data if editing birth event
    if (isEditing && widget.event != null && widget.event!.eventType == 'Gives Birth') {
      _loadExistingCalfData();
    }
    
    // Load breeding event data if editing breeding event
    print('DEBUG: Checking if should load breeding event data');
    print('DEBUG: isEditing: $isEditing');
    print('DEBUG: widget.event: ${widget.event}');
    if (widget.event != null) {
      print('DEBUG: widget.event!.eventType: "${widget.event!.eventType}"');
    }
    
    if (isEditing && widget.event != null && widget.event!.eventType == 'Breeding') {
      print('DEBUG: Loading breeding event data...');
      // Use post-frame callback to ensure controllers are initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBreedingEventData();
      });
    } else {
      print('DEBUG: Not loading breeding event data - conditions not met');
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
      'bull_tag', 'calf_tag', 'event_date',
      'diagnosis', 'technician', 'medicine_given', 'semen_used',
      'estimated_return_date', 'weighed_result', 'breeding_date',
      'expected_delivery_date', 'cause_of_death', 'notes',
      'last_known_location', 'breeding_type', 'disease_type', 'disease_type_other'
    ];

    for (var field in fields) {
      String initialValue = '';
      if (isEditing && widget.event != null) {
        final eventJson = widget.event!.toJson();
        initialValue = eventJson[field]?.toString() ?? '';
      }
      _controllers[field] = TextEditingController(text: initialValue);
    }
  }

  Future<Map<String, dynamic>?> _getLatestEvent({
    required String cattleTag,
    required String eventType,
  }) async {
    try {
      final all = await CattleEventService.getCattleEvent();
      final filtered = all
          .where((e) =>
              e['cattle_tag'] == cattleTag &&
              (e['event_type']?.toString().toLowerCase() ?? '') ==
                  eventType.toLowerCase())
          .toList();
      if (filtered.isEmpty) return null;
      filtered.sort((a, b) {
        try {
          final da = DateTime.parse(a['event_date']);
          final db = DateTime.parse(b['event_date']);
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

  Future<void> _handleEventTypeChanged(String value) async {
    print('DEBUG: _handleEventTypeChanged called with value: $value');
    setState(() => selectedEventType = value);

    if (_cattleDetails == null) {
      print('DEBUG: _cattleDetails is null, returning early');
      return;
    }
    final cattleTag = _cattleDetails!.tagNo;
    print('DEBUG: Processing event type change for cattle: $cattleTag');

    // Clear autofill targets before applying
    _controllers['breeding_date']?.text = _controllers['breeding_date']?.text ?? '';
    _controllers['expected_delivery_date']?.text = _controllers['expected_delivery_date']?.text ?? '';

    // Pregnant requires latest Breeding; autofill breeding_date, expected_delivery_date, bull/semen
    if (value.toLowerCase() == 'pregnant') {
      print('DEBUG: Processing Pregnant event for cattle: $cattleTag');
      final latestBreeding = await _getLatestEvent(cattleTag: cattleTag, eventType: 'Breeding');
      print('DEBUG: Latest breeding event found: $latestBreeding');
      if (latestBreeding == null) {
        print('DEBUG: No breeding event found, showing warning');
        _showWarningMessage('No recent Breeding event found. Cannot create Pregnant event.');
        setState(() => selectedEventType = 'Select type of event');
        return;
      }

      final breedingDateStr = latestBreeding['event_date']?.toString();
      if (breedingDateStr != null && breedingDateStr.isNotEmpty) {
        _controllers['breeding_date']?.text = breedingDateStr;
        try {
          final breedingDate = DateTime.parse(breedingDateStr);
          final expectedDelivery = breedingDate.add(const Duration(days: 283));
          final formatted = '${expectedDelivery.year.toString().padLeft(4, '0')}-'
              '${expectedDelivery.month.toString().padLeft(2, '0')}-'
              '${expectedDelivery.day.toString().padLeft(2, '0')}';
          _controllers['expected_delivery_date']?.text = formatted;
          // Also trigger UI-side calculation to refresh dependent widgets
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _eventSpecificFieldsKey.currentState?.calculateAndDisplayDeliveryDate(breedingDate);
          });
        } catch (_) {}
      }
      // Autofill bull/semen and technician if present
      final bullTag = latestBreeding['bull_tag']?.toString();
      final semen = latestBreeding['semen_used']?.toString();
      print('DEBUG: Found bull_tag: $bullTag, semen_used: $semen');

      // If semen is present (AI), treat semen's bull as the bull selection
      if (semen != null && semen.isNotEmpty) {
        print('DEBUG: Processing semen: $semen');
        _controllers['semen_used']?.text = semen;
        // Try to extract the bull tag from semen label like "TAG123 (Name) Semen"
        String extractedBullTag = semen.trim();
        if (extractedBullTag.toLowerCase().endsWith('semen')) {
          extractedBullTag = extractedBullTag.substring(0, extractedBullTag.length - 5).trim();
        }
        // Extract tag from format like "TAG123 (Name)" or just "TAG123"
        int stop = extractedBullTag.indexOf(' ');
        int paren = extractedBullTag.indexOf('(');
        if (stop == -1 || (paren != -1 && paren < stop)) {
          stop = paren;
        }
        final finalBullTag = stop == -1 ? extractedBullTag : extractedBullTag.substring(0, stop).trim();
        print('DEBUG: Extracted bull tag from semen: $finalBullTag');
        if (finalBullTag.isNotEmpty) {
          _controllers['bull_tag']?.text = finalBullTag;
          print('DEBUG: Set bull_tag controller to: $finalBullTag');
        }
      } else if (bullTag != null && bullTag.isNotEmpty) {
        print('DEBUG: Using direct bull_tag: $bullTag');
        _controllers['bull_tag']?.text = bullTag;
        _controllers['semen_used']?.text = '';
        print('DEBUG: Set bull_tag controller to: $bullTag');
      }
      final tech = latestBreeding['technician']?.toString();
      if (tech != null && tech.isNotEmpty) {
        _controllers['technician']?.text = tech;
      }
      
      // Force UI refresh to ensure dropdowns pick up the controller values
      if (mounted) {
        setState(() {});
        print('DEBUG: Triggered setState after Pregnant auto-fill');
      }
    }

    // Gives Birth requires latest Pregnant; autofill breeding_date and expected_delivery_date
    if (value.toLowerCase() == 'gives birth') {
      print('DEBUG: Processing Gives Birth event for cattle: $cattleTag');
      final latestPregnant = await _getLatestEvent(cattleTag: cattleTag, eventType: 'Pregnant');
      print('DEBUG: Latest pregnant event found: $latestPregnant');
      if (latestPregnant == null) {
        print('DEBUG: No pregnant event found, showing warning');
        _showWarningMessage('No Pregnant event found. Cannot create Gives Birth event.');
        setState(() => selectedEventType = 'Select type of event');
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
      String? bull = latestPregnant['bull_tag']?.toString();
      print('DEBUG: Found in pregnant event - bull_tag: $bull, semen_used: $semen');
      if ((semen == null || semen.isEmpty) && (bull == null || bull.isEmpty)) {
        print('DEBUG: No sire info in pregnant event, falling back to latest breeding');
        final latestBreeding = await _getLatestEvent(cattleTag: cattleTag, eventType: 'Breeding');
        print('DEBUG: Latest breeding event for fallback: $latestBreeding');
        semen = latestBreeding?['semen_used']?.toString();
        bull = latestBreeding?['bull_tag']?.toString();
        print('DEBUG: Fallback values - bull_tag: $bull, semen_used: $semen');
      }

      if (semen != null && semen.isNotEmpty) {
        print('DEBUG: Processing semen for Gives Birth: $semen');
        _controllers['semen_used']?.text = semen;
        // Extract bull tag from semen label like "TAG123 (Name) Semen"
        String extracted = semen.trim();
        if (extracted.toLowerCase().endsWith('semen')) {
          extracted = extracted.substring(0, extracted.length - 5).trim();
        }
        int stop = extracted.indexOf(' ');
        int paren = extracted.indexOf('(');
        if (stop == -1 || (paren != -1 && paren < stop)) {
          stop = paren;
        }
        final bullTag = stop == -1 ? extracted : extracted.substring(0, stop).trim();
        print('DEBUG: Extracted bull tag from semen for Gives Birth: $bullTag');
        if (bullTag.isNotEmpty) {
          _controllers['bull_tag']?.text = bullTag;
          print('DEBUG: Set bull_tag controller for Gives Birth to: $bullTag');
        }
      } else if (bull != null && bull.isNotEmpty) {
        print('DEBUG: Using direct bull_tag for Gives Birth: $bull');
        _controllers['bull_tag']?.text = bull;
        _controllers['semen_used']?.text = '';
        print('DEBUG: Set bull_tag controller for Gives Birth to: $bull');
      }

      // Force UI refresh so dropdowns pick up controller values
      if (mounted) {
        setState(() {});
        print('DEBUG: Triggered setState after Gives Birth auto-fill');
      }

      // If no calf data yet, prompt user to add calf when saving
    }
  }

  // Load existing calf data for editing
  Future<void> _loadExistingCalfData() async {
    if (widget.event == null || widget.event!.calfTag == null) return;

    try {
      final calfTagString = widget.event!.calfTag!;
      print('Loading calf data for tag string: $calfTagString');
      
      // Check if there are multiple calf tags (comma-separated)
      if (calfTagString.contains(',')) {
        // Multiple calves - split by comma and load the first one for now
        final calfTags = calfTagString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
        print('Found multiple calf tags: $calfTags');
        
        if (calfTags.isNotEmpty) {
          // Load the first calf for editing
          final firstCalfTag = calfTags.first;
          final calf = await CattleService.getCattleByTag(firstCalfTag);
          if (calf != null && mounted) {
            setState(() {
              _temporaryCalfData = {
                'tag_no': calf.tagNo,
                'sex': calf.sex,
                'registered': true, // Mark as already registered since it exists
                'isEditMode': true,
                'calfId': calf.id,
                'pendingOperation': 'update',
                'fullCalfData': {
                  'id': calf.id,
                  'tag_no': calf.tagNo,
                  'sex': calf.sex,
                  'date_of_birth': calf.dateOfBirth,
                  'classification': calf.classification,
                  'status': calf.status,
                  'breed': calf.breed,
                  'source': calf.source,
                  'mother_tag': calf.motherTag,
                  'father_tag': calf.fatherTag,
                  'weight': calf.weight,
                  'group_name': calf.groupName,
                  'notes': calf.notes,
                },
              };
              _controllers['calf_tag']?.text = calfTagString; // Keep the full string for display
            });
            print('Loaded first calf data: ${calf.tagNo} with ID: ${calf.id}');
          }
        }
      } else {
        // Single calf
        final calf = await CattleService.getCattleByTag(calfTagString);
        if (calf != null && mounted) {
          setState(() {
            _temporaryCalfData = {
              'tag_no': calf.tagNo,
              'sex': calf.sex,
              'registered': true, // Mark as already registered since it exists
              'isEditMode': true,
              'calfId': calf.id,
              'pendingOperation': 'update',
              'fullCalfData': {
                'id': calf.id,
                'tag_no': calf.tagNo,
                'sex': calf.sex,
                'date_of_birth': calf.dateOfBirth,
                'classification': calf.classification,
                'status': calf.status,
                'breed': calf.breed,
                'source': calf.source,
                'mother_tag': calf.motherTag,
                'father_tag': calf.fatherTag,
                'weight': calf.weight,
                'group_name': calf.groupName,
                'notes': calf.notes,
              },
            };
            _controllers['calf_tag']?.text = calf.tagNo;
          });
          print('Loaded existing calf data: ${calf.tagNo} with ID: ${calf.id}');
        }
      }
    } catch (e) {
      print('Error loading calf data: $e');
      // If we can't load the calf, clear the temporary data
      if (mounted) {
        setState(() {
          _temporaryCalfData = null;
          _controllers['calf_tag']?.text = '';
        });
      }
    }
  }

  Future<void> _loadBreedingEventData() async {
    try {
      if (widget.event == null) {
        print('DEBUG: No event to load breeding data from');
        return;
      }
      
      final eventJson = widget.event!.toJson();
      print('DEBUG: Loading breeding event data: $eventJson');
      print('DEBUG: Event type: ${widget.event!.eventType}');
      print('DEBUG: Available fields in event: ${eventJson.keys.toList()}');
      
      // Set breeding type (map human-readable <-> snake_case)
      final breedingType = eventJson['breeding_type']?.toString();
      print('DEBUG: Found breeding_type in event: $breedingType');
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
        print('DEBUG: Set breeding type controller to (normalized): $normalized');
      } else {
        print('DEBUG: No breeding_type found in event data');
        // Fallback inference based on available fields
        final semenUsedVal = eventJson['semen_used']?.toString() ?? '';
        final bullTagVal = eventJson['bull_tag']?.toString() ?? '';
        if (semenUsedVal.isNotEmpty) {
          _controllers['breeding_type']?.text = 'artificial_insemination';
          print('DEBUG: Inferred breeding_type as artificial_insemination from semen_used');
        } else if (bullTagVal.isNotEmpty) {
          _controllers['breeding_type']?.text = 'natural_breeding';
          print('DEBUG: Inferred breeding_type as natural_breeding from bull_tag');
        }
      }
      
      // Set semen used
      final semenUsed = eventJson['semen_used']?.toString();
      print('DEBUG: Found semen_used in event: $semenUsed');
      if (semenUsed != null && semenUsed.isNotEmpty) {
        _controllers['semen_used']?.text = semenUsed;
        print('DEBUG: Set semen_used controller to: $semenUsed');
      } else {
        print('DEBUG: No semen_used found in event data');
        // Fallback for AI: if breeding_type is AI and bull_tag exists, use bull_tag as semen_used
        final currentBreedingType = _controllers['breeding_type']?.text ?? '';
        final bullTagVal = eventJson['bull_tag']?.toString() ?? '';
        if (currentBreedingType == 'artificial_insemination' && bullTagVal.isNotEmpty) {
          _controllers['semen_used']?.text = bullTagVal;
          print('DEBUG: Inferred semen_used from bull_tag for AI: $bullTagVal');
        }
      }
      
      // Set bull tag
      final bullTag = eventJson['bull_tag']?.toString();
      print('DEBUG: Found bull_tag in event: $bullTag');
      if (bullTag != null && bullTag.isNotEmpty) {
        _controllers['bull_tag']?.text = bullTag;
        print('DEBUG: Set bull_tag controller to: $bullTag');
      } else {
        print('DEBUG: No bull_tag found in event data');
      }
      
      // Set technician
      final technician = eventJson['technician']?.toString();
      print('DEBUG: Found technician in event: $technician');
      if (technician != null && technician.isNotEmpty) {
        _controllers['technician']?.text = technician;
        print('DEBUG: Set technician controller to: $technician');
      } else {
        print('DEBUG: No technician found in event data');
      }
      
      // Bull-side reciprocal hydration: if subject is male and fields are missing, try to fetch partner cow/heifer event on same date
      try {
        final isMaleSubject = (_cattleDetails?.sex.toLowerCase() == 'male');
        final isBreeding = (widget.event!.eventType.toLowerCase() == 'breeding');
      final String _ = (_controllers['breeding_type']?.text ?? '').trim();
      // Values read below directly from controllers when needed; avoid unused locals
        final eventDate = (eventJson['event_date']?.toString() ?? '').trim();
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
            print('DEBUG: Hydration - attempting to fetch partner event for tag: $partnerTag on $eventDate');
            final allPartnerEvents = await CattleEventService.getCattleEventsByTag(partnerTag);
            // Client-side filter by cattle_tag to be safe
            final partnerEvents = allPartnerEvents.where((e) => (e['cattle_tag']?.toString() ?? '') == partnerTag).toList();
            // Normalize dates to day precision
            DateTime? targetDate;
            try { targetDate = DateTime.parse(eventDate); } catch (_) { targetDate = null; }
            Map<String, dynamic> partner = {};
            if (targetDate != null) {
              final sameDay = partnerEvents.firstWhere(
                (e) {
                  try {
                    if ((e['event_type']?.toString().toLowerCase() ?? '') != 'breeding') return false;
                    final d = DateTime.parse(e['event_date']?.toString() ?? '');
                    return d.year == targetDate!.year && d.month == targetDate.month && d.day == targetDate.day;
                  } catch (_) { return false; }
                },
                orElse: () => {},
              );
              partner = sameDay;
              // Fallback: nearest breeding event on/before date
              if (partner.isEmpty) {
                final breedingEvents = partnerEvents.where((e) => (e['event_type']?.toString().toLowerCase() ?? '') == 'breeding').toList();
                breedingEvents.sort((a, b) {
                  DateTime? ad, bd;
                  try { ad = DateTime.parse(a['event_date']?.toString() ?? ''); } catch (_) {}
                  try { bd = DateTime.parse(b['event_date']?.toString() ?? ''); } catch (_) {}
                  if (ad == null || bd == null) return 0;
                  return bd.compareTo(ad);
                });
                for (final e in breedingEvents) {
                  try {
                    final d = DateTime.parse(e['event_date']?.toString() ?? '');
                    if (!d.isAfter(targetDate)) { partner = e; break; }
                  } catch (_) {}
                }
              }
            }
            if (partner.isNotEmpty) {
              // Save partner identifiers for unified editing on save
              _partnerTagForEdit = partnerTag;
              try {
                _partnerEventIdForEdit = partner['id'] is int
                    ? partner['id'] as int
                    : int.tryParse((partner['id']?.toString() ?? ''));
              } catch (_) {
                _partnerEventIdForEdit = int.tryParse((partner['id']?.toString() ?? ''));
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
                print('DEBUG: Hydration - set breeding_type from partner: $normalized');
              }
              final semenPartner = partner['semen_used']?.toString();
              if (semenPartner != null && semenPartner.isNotEmpty) {
                _controllers['semen_used']?.text = semenPartner;
                print('DEBUG: Hydration - set semen_used from partner: $semenPartner');
              }
              final techPartner = partner['technician']?.toString();
              if (techPartner != null && techPartner.isNotEmpty) {
                _controllers['technician']?.text = techPartner;
                print('DEBUG: Hydration - set technician from partner: $techPartner');
              }
              // Copy date fields if missing
              final estReturn = (_controllers['estimated_return_date']?.text ?? '').trim();
              if (estReturn.isEmpty) {
                final pEst = partner['estimated_return_date']?.toString();
                if (pEst != null && pEst.isNotEmpty) {
                  _controllers['estimated_return_date']?.text = pEst;
                  print('DEBUG: Hydration - set estimated_return_date from partner: $pEst');
                }
              }
              final breedingDate = (_controllers['breeding_date']?.text ?? '').trim();
              if (breedingDate.isEmpty) {
                final pBreed = partner['breeding_date']?.toString();
                if (pBreed != null && pBreed.isNotEmpty) {
                  _controllers['breeding_date']?.text = pBreed;
                  print('DEBUG: Hydration - set breeding_date from partner: $pBreed');
                }
              }
              final expectedDelivery = (_controllers['expected_delivery_date']?.text ?? '').trim();
              if (expectedDelivery.isEmpty) {
                final pEDD = partner['expected_delivery_date']?.toString();
                if (pEDD != null && pEDD.isNotEmpty) {
                  _controllers['expected_delivery_date']?.text = pEDD;
                  print('DEBUG: Hydration - set expected_delivery_date from partner: $pEDD');
                }
              }
              // For Natural breeding on bull-side, prefill bull dropdown with current bull tag (UI only)
              final btNow = (_controllers['breeding_type']?.text ?? '').trim();
              if (btNow == 'natural_breeding') {
                final bullCtrl = _controllers['bull_tag'];
                if (bullCtrl != null && bullCtrl.text.trim().isEmpty) {
                  final bullTagSelf = _cattleDetails?.tagNo ?? '';
                  if (bullTagSelf.isNotEmpty) {
                    bullCtrl.text = bullTagSelf;
                    print('DEBUG: Hydration - set bull_tag to self for natural breeding UI: $bullTagSelf');
                  }
                }
              }
            } else {
              print('DEBUG: Hydration - no matching partner breeding event found');
              // Fallback: assume Natural on bull-side for completeness in UI
              _controllers['breeding_type']?.text = 'natural_breeding';
              final bullCtrl = _controllers['bull_tag'];
              if (bullCtrl != null && bullCtrl.text.trim().isEmpty) {
                final bullTagSelf = _cattleDetails?.tagNo ?? '';
                if (bullTagSelf.isNotEmpty) {
                  bullCtrl.text = bullTagSelf;
                  print('DEBUG: Hydration Fallback - set breeding_type to natural_breeding and bull_tag to self: $bullTagSelf');
                }
              }
            }
          } else {
            print('DEBUG: Hydration - could not extract partner tag from notes: "$notes"');
          }
        }
      } catch (e) {
        print('DEBUG: Error hydrating bull reciprocal fields from partner: $e');
      }

      // Force UI refresh so dropdowns pick up controller values
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      print('Error loading breeding event data: $e');
    }
  }

  void _handleEventDateSelected(DateTime selectedDate) {
    if (selectedEventType.toLowerCase() == 'breeding') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _eventSpecificFieldsKey.currentState
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

  Future<void> _loadCattleDetails() async {
    // Get cattle tag from either widget.cattleTag or from the event being edited
    String? cattleTag = widget.cattleTag;
    if (cattleTag == null && isEditing && widget.event != null) {
      cattleTag = widget.event!.cattleTag;
    }

    if (cattleTag == null || cattleTag.isEmpty) {
      _showErrorMessage('Invalid cattle tag provided');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cattle = await CattleService.getCattleByTag(cattleTag);

      // Animations are played only after the initial data is fetched.
      _fadeController.forward();
      _slideController.forward();

      if (cattle != null && mounted) {
        setState(() {
          _cattleDetails = cattle;
        });

        if (isEditing && widget.event != null && _cattleDetails != null) {
          await _setEditEventType(_cattleDetails!);
          // Ensure breeding data hydration runs after cattle details are available
          if (widget.event!.eventType == 'Breeding') {
            await _loadBreedingEventData();
          }
        }
      } else {
        if (mounted) {
          _showErrorMessage(
              'Cattle with tag "$cattleTag" not found in the database');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error loading cattle details: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setEditEventType(Cattle cattle) async {
    final editEventType = widget.event!.eventType;
    await Future.delayed(Duration.zero);

    final eventTypes = _getEventTypesForSex(cattle.sex, classification: cattle.classification);

    if (eventTypes.contains(editEventType)) {
      setState(() {
        selectedEventType = editEventType;
      });
    } else {
      setState(() {
        selectedEventType = 'Select type of event';
      });

      if (mounted) {
        _showWarningMessage(
            'Event type "$editEventType" is not valid for ${cattle.sex.toLowerCase()} cattle. Please select a valid event type.');
      }
    }
  }

  List<String> _getEventTypesForSex(String sex, {String? classification}) {
    // Use the centralized utility method instead of duplicating logic
    return EventTypeUtils.getEventTypesForSex(sex, classification: classification);
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


  // Execute calf operations only after successful event save
  Future<bool> _executeCalfOperations() async {
    if (_temporaryCalfData == null || _temporaryCalfData!['fullCalfData'] == null) {
      print('No calf operations to execute');
      return true; // No operations needed
    }

    try {
      final pendingOperation = _temporaryCalfData!['pendingOperation'];
      final calfData = _temporaryCalfData!['fullCalfData'] as Map<String, dynamic>;
      final calfTag = _safeParseString(calfData['tag_no']) ?? '';

      print('Executing calf $pendingOperation for: $calfTag');

      bool success;
      if (pendingOperation == 'update') {
        // Ensure we have the ID for update
        int? calfId = _safeParseInt(calfData['id']) ?? _safeParseInt(_temporaryCalfData!['calfId']);

        if (calfId == null) {
          print('No calf ID found for update, trying to find by tag');
          final existingCalf = await CattleService.getCattleByTag(calfTag);
          if (existingCalf != null) {
            calfId = existingCalf.id;
            calfData['id'] = calfId;
          } else {
            throw Exception('Could not find existing calf with tag: $calfTag');
          }
        }

        success = await CattleService.updateCattleInformation(calfData);
        print('Calf update result: $success for ID: $calfId');
      } else {
        // Create new calf - remove ID if present
        final newCalfData = Map<String, dynamic>.from(calfData);
        newCalfData.remove('id');

        success = await CattleService.storeCattleInformation(newCalfData);
        print('Calf registration result: $success');
      }

      if (success) {
        // Update temporary data to reflect successful operation
        setState(() {
          _temporaryCalfData!['registered'] = true;
        });
      }

      return success;
    } catch (e) {
      print('Error executing calf operations: $e');
      return false;
    }
  }

  Future<bool> _updateMotherStatus() async {
    try {
      if (_cattleDetails != null) {
        final updateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
        updateData['status'] = 'Lactating';
        return await CattleService.updateCattleInformation(updateData);
      }
      return false;
    } catch (e) {
      print('Error updating mother status: $e');
      return false;
    }
  }

  Future<void> _handleGivesBirthEvent() async {
    try {
      bool calfHandled = false;
      bool motherStatusUpdated = false;
      String calfStatus = '';

      // Execute calf operations
      // Prefer multi-calf from EventSpecificFields if available
      final multiCalves = _eventSpecificFieldsKey.currentState?.getCalves();
      if (multiCalves != null && multiCalves.isNotEmpty) {
        bool allOk = true;
        for (final calf in multiCalves) {
          // Expect structure similar to _temporaryCalfData
          final Map<String, dynamic> full = Map<String, dynamic>.from(calf['fullCalfData'] ?? calf);
          // Ensure parent links
          full['mother_tag'] = _cattleDetails?.tagNo ?? full['mother_tag'];
          full['father_tag'] = _controllers['bull_tag']?.text.isNotEmpty == true
              ? _controllers['bull_tag']!.text
              : full['father_tag'];

          // Enforce create or update explicitly
          final String pending = (calf['pendingOperation'] ?? 'create').toString();
          if (pending == 'create') {
            full.remove('id');
          }

          final Map<String, dynamic> op = {
            'pendingOperation': pending,
            'fullCalfData': full,
            'tag_no': full['tag_no'],
            'calfId': full['id'],
            'isEditMode': pending == 'update',
          };
          _temporaryCalfData = op;
          final ok = await _executeCalfOperations();
          allOk = allOk && ok;
        }
        calfHandled = allOk;
      } else {
        calfHandled = await _executeCalfOperations();
      }

      if (_temporaryCalfData != null) {
        final calfTag = _temporaryCalfData!['tag_no'] ?? 'unknown';
        final isEditMode = _temporaryCalfData!['isEditMode'] == true;
        calfStatus = calfHandled
            ? (isEditMode ? 'Calf $calfTag updated successfully' : 'Calf $calfTag registered successfully')
            : (isEditMode ? 'Failed to update calf $calfTag' : 'Failed to register calf $calfTag');
      } else {
        calfStatus = 'No calf data to process';
        calfHandled = true; // No calf to handle
      }

      // Update mother status
      motherStatusUpdated = await _updateMotherStatus();
      final motherStatus = motherStatusUpdated
          ? 'Mother status updated to Lactating'
          : 'Failed to update mother status';

      // Log the results for debugging
      print('Birth event results - Calf: $calfStatus, Mother: $motherStatus');

    } catch (e) {
      // Log any errors that occur during the process
      print('Error in _handleGivesBirthEvent: $e');
    }
  }

  Future<void> _handleCastratedEvent() async {
    try {
      bool cattleClassificationUpdated = false;
      String cattleStatus = '';

      // Update cattle classification to Steer
      if (_cattleDetails != null) {
        final cattleUpdateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
        cattleUpdateData['classification'] = 'Steer';
        cattleClassificationUpdated = await CattleService.updateCattleInformation(cattleUpdateData);
        cattleStatus = cattleClassificationUpdated
            ? 'Cattle ${_cattleDetails!.tagNo} classification updated to Steer'
            : 'Failed to update cattle ${_cattleDetails!.tagNo} classification to Steer';
      }

      // Log the result for debugging
      print('Castrated event result: $cattleStatus');

      // Optional: Show success feedback to user
      if (mounted && cattleClassificationUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cattle classification updated to Steer'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      print('Error in _handleCastratedEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update cattle classification to Steer'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openCalfRegistrationDialog() async {
    // Get cattle tag from either widget.cattleTag or from the event being edited
    String? cattleTag = widget.cattleTag;
    if (cattleTag == null && isEditing && widget.event != null) {
      cattleTag = widget.event!.cattleTag;
    }
    
    final motherTag = cattleTag ?? '';
    final fatherTag = _controllers['bull_tag']?.text ?? '';

    // Prepare existing calf data for the dialog with safe type conversion
    Map<String, dynamic>? existingCalfData;
    if (_temporaryCalfData != null) {
      try {
        existingCalfData = <String, dynamic>{};

        // Copy basic fields with safe conversion
        existingCalfData['tag_no'] = _safeParseString(_temporaryCalfData!['tag_no']);
        existingCalfData['name'] = _safeParseString(_temporaryCalfData!['name']);
        existingCalfData['sex'] = _safeParseString(_temporaryCalfData!['sex']);
        existingCalfData['registered'] = _temporaryCalfData!['registered'] ?? false;
        existingCalfData['isEditMode'] = _temporaryCalfData!['isEditMode'] ?? false;

        // Safely get the calf ID
        int? calfId = _safeParseInt(_temporaryCalfData!['calfId']);
        if (calfId != null) {
          existingCalfData['calfId'] = calfId;
        }

        // Copy fullCalfData if it exists
        if (_temporaryCalfData!['fullCalfData'] != null) {
          final originalFullData = _temporaryCalfData!['fullCalfData'] as Map<String, dynamic>;
          existingCalfData['fullCalfData'] = <String, dynamic>{};

          // Copy each field with safe type conversion
          final fullData = existingCalfData['fullCalfData'] as Map<String, dynamic>;
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
          if (calfId != null) {
            fullData['id'] = calfId;
          } else if (originalFullData['id'] != null) {
            final id = _safeParseInt(originalFullData['id']);
            if (id != null) {
              fullData['id'] = id;
            }
          }
        }

        print('Prepared calf data for dialog: calfId=$calfId, isEditMode=${existingCalfData['isEditMode']}');
      } catch (e) {
        print('Error preparing calf data for dialog: $e');
        existingCalfData = null;
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CalfRegistrationDialog(
        motherTag: motherTag,
        fatherTag: fatherTag,
        existingCalfData: existingCalfData,
        isEditMode: _temporaryCalfData != null,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _temporaryCalfData = result;
        // Update the calf_tag controller
        _controllers['calf_tag']?.text = _safeParseString(result['tag_no']) ?? '';
      });
      print('Calf dialog result: ${result['pendingOperation']} operation prepared for ${result['tag_no']}');
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

    if (selectedEventType == 'Select type of event') {
      _showErrorMessage('Please select an event type.');
      return;
    }

    if (_cattleDetails == null) {
      _showErrorMessage('Cattle information not loaded. Please try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get cattle tag from either widget.cattleTag or from the event being edited
      String? cattleTag = widget.cattleTag;
      if (cattleTag == null && isEditing && widget.event != null) {
        cattleTag = widget.event!.cattleTag;
      }

      // Prepare data with better validation
      final data = <String, dynamic>{
        'cattle_tag': cattleTag?.trim(),
        'event_type': selectedEventType,
        'event_date': _controllers['event_date']!.text.trim(),
        'notes': _controllers['notes']!.text.trim(),
      };

      // Handle calf_tag specially for Gives Birth events with multiple calves
      String calfTagValue = _controllers['calf_tag']!.text.trim();
      if (selectedEventType.toLowerCase() == 'gives birth') {
        final multiCalves = _eventSpecificFieldsKey.currentState?.getCalves();
        if (multiCalves != null && multiCalves.isNotEmpty) {
          // Collect all calf tags from multiple calves
          final calfTags = multiCalves
              .map((calf) => calf['tag_no']?.toString())
              .where((tag) => tag != null && tag.isNotEmpty)
              .toList();
          if (calfTags.isNotEmpty) {
            calfTagValue = calfTags.join(', ');
            print('DEBUG: Multiple calf tags collected: $calfTagValue');
          }
        }
      }

      // Add optional fields only if they have values
      final optionalFields = {
        'bull_tag': _controllers['bull_tag']!.text.trim(),
        'calf_tag': calfTagValue,
        'diagnosis': _controllers['diagnosis']!.text.trim(),
        'technician': _controllers['technician']!.text.trim(),
        'medicine_given': _controllers['medicine_given']!.text.trim(),
        'semen_used': _controllers['semen_used']!.text.trim(),
        'estimated_return_date': _controllers['estimated_return_date']!.text.trim(),
        'breeding_date': _controllers['breeding_date']!.text.trim(),
        'expected_delivery_date': _controllers['expected_delivery_date']!.text.trim(),
        'cause_of_death': _controllers['cause_of_death']!.text.trim(),
        'last_known_location': _controllers['last_known_location']!.text.trim(),
        'disease_type': (() {
          final disease = _controllers['disease_type']!.text.trim();
          final other = _controllers['disease_type_other']!.text.trim();
          if (disease.toLowerCase() == 'other' && other.isNotEmpty) return other;
          return disease;
        })(),
      };

      // Add breeding type for breeding events
      if (selectedEventType.toLowerCase() == 'breeding') {
        final breedingFieldsKey = _eventSpecificFieldsKey.currentState;
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

      // Note: We remove estimated_return_date only from the bull-side payload later,
      // to ensure the partner cow/heifer keeps it when updated.

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

      // Validate required fields
      if (data['cattle_tag'] == null || data['cattle_tag'].toString().isEmpty) {
        throw Exception('Cattle tag is required');
      }

      if (data['event_date'].toString().isEmpty) {
        throw Exception('Event date is required');
      }

      // Validate cause of death for deceased events
      if (selectedEventType.toLowerCase() == 'deceased' &&
          _controllers['cause_of_death']!.text.trim().isEmpty) {
        _showErrorMessage('Cause of death is required for deceased events.');
        setState(() => _isLoading = false);
        return;
      }

      // Additional validation for specific event types
      // If Sick, ensure disease type is provided; if Other, require custom text
      if (selectedEventType.toLowerCase() == 'sick') {
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

      // If Treated, ensure there is at least one prior Sick event for this cattle
      if (selectedEventType.toLowerCase() == 'treated') {
        try {
          final tag = (data['cattle_tag'] ?? '').toString();
          final eventsForTag = await CattleEventService.getCattleEventsByTag(tag);
          final hasSick = eventsForTag.any((e) => (e['event_type']?.toString().toLowerCase() ?? '') == 'sick');
          if (!hasSick) {
            _showErrorMessage('Cannot create Treated event: no prior Sick event found for #$tag.');
            setState(() => _isLoading = false);
            return;
          }
        } catch (_) {
          _showErrorMessage('Unable to verify prior Sick events. Please try again.');
          setState(() => _isLoading = false);
          return;
        }
      }
      // Enforce prerequisite: Pregnant requires latest Breeding
      if (selectedEventType.toLowerCase() == 'pregnant') {
        final latestBreeding = await _getLatestEvent(
          cattleTag: data['cattle_tag'],
          eventType: 'Breeding',
        );
        if (latestBreeding == null) {
          _showErrorMessage('Cannot create Pregnant event: no Breeding event found.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Enforce prerequisite: Gives Birth requires latest Pregnant
      if (selectedEventType.toLowerCase() == 'gives birth') {
        final latestPregnant = await _getLatestEvent(
          cattleTag: data['cattle_tag'],
          eventType: 'Pregnant',
        );
        if (latestPregnant == null) {
          _showErrorMessage('Cannot create Gives Birth event: no Pregnant event found.');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (selectedEventType.toLowerCase() == 'gives birth') {
        final multiCalves = _eventSpecificFieldsKey.currentState?.getCalves();
        final hasMulti = multiCalves != null && multiCalves.isNotEmpty;
        final hasSingle = _controllers['calf_tag']!.text.trim().isNotEmpty || _temporaryCalfData != null;
        if (!hasMulti && !hasSingle) {
          _showErrorMessage('Please add at least one calf for birth events.');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (selectedEventType.toLowerCase() == 'breeding') {
        // Get breeding type from the breeding event fields
        final breedingFieldsKey = _eventSpecificFieldsKey.currentState;
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
          // For natural breeding, require bull_tag only
          if (_controllers['bull_tag']!.text.trim().isEmpty) {
            _showErrorMessage('Bull selection is required for Natural Breeding.');
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      // Log the data being sent (for debugging)
      print('=== FORM SUBMISSION DEBUG ===');
      print('Submitting event data: $data');
      print('Is editing: $isEditing');
      print('Selected event type: $selectedEventType');
      print('Cattle details loaded: ${_cattleDetails != null}');
      if (_temporaryCalfData != null) {
        print('Temporary calf data: $_temporaryCalfData');
      }

      bool eventSuccess;

      try {
        if (isEditing) {
          if (widget.event?.id == null) {
            throw Exception('Event ID is required for editing');
          }
          data['id'] = widget.event!.id;

          // Unified editing: if editing a bull reciprocal breeding, first update the partner cow/heifer event with full details
          final isBullSubject = _cattleDetails?.sex.toLowerCase() == 'male';
          final isBreedingEdit = selectedEventType.toLowerCase() == 'breeding';
          if (isBullSubject && isBreedingEdit && _partnerTagForEdit != null && _partnerEventIdForEdit != null) {
            // Build partner payload mirroring current UI values
            final partnerData = Map<String, dynamic>.from(data);
            partnerData['id'] = _partnerEventIdForEdit;
            partnerData['cattle_tag'] = _partnerTagForEdit;
            // Do not propagate notes into the partner event
            partnerData.remove('notes');
            // Ensure breeding_type mirrors UI selection
            final breedingFieldsKey = _eventSpecificFieldsKey.currentState;
            final partnerBT = breedingFieldsKey?.getBreedingType();
            if (partnerBT != null) {
              partnerData['breeding_type'] = partnerBT;
            }
            // For AI, partner needs semen_used and technician; for Natural, partner needs bull_tag (self)
            if ((partnerBT ?? '').toLowerCase() == 'artificial_insemination') {
              // keep semen_used, technician from current controllers
              partnerData.remove('bull_tag');
            } else if ((partnerBT ?? '').toLowerCase() == 'natural_breeding') {
              // set bull_tag to this bull's tag; remove semen/technician
              final bullSelf = _cattleDetails?.tagNo ?? '';
              if (bullSelf.isNotEmpty) partnerData['bull_tag'] = bullSelf;
              partnerData.remove('semen_used');
              partnerData.remove('technician');
            }
            // Remove return-to-heat only from bull payload (current 'data'), not from partnerData
            data.remove('estimated_return_date');
            // Execute partner update before saving the bull event
            final partnerOk = await CattleEventService.updateCattleEvent(partnerData);
            print('Unified edit: partner update result: $partnerOk');
          }

          // Unified editing: if editing a female breeding event, update the bull reciprocal as well
          final isFemaleSubject = _cattleDetails?.sex.toLowerCase() == 'female';
          if (isFemaleSubject && isBreedingEdit) {
            // Determine partner bull tag based on breeding_type
            final breedingFieldsKey = _eventSpecificFieldsKey.currentState;
            final bt = breedingFieldsKey?.getBreedingType() ?? data['breeding_type']?.toString();
            String? partnerBullTag;
            if ((bt ?? '').toLowerCase() == 'natural_breeding') {
              partnerBullTag = _controllers['bull_tag']?.text.trim();
            } else if ((bt ?? '').toLowerCase() == 'artificial_insemination') {
              // For AI, bull tag is not used; reciprocal exists but without sire fields
              partnerBullTag = null;
            }

            if (partnerBullTag != null && partnerBullTag.isNotEmpty) {
              // Fetch partner bull events and find matching breeding by date
              final allPartnerEvents = await CattleEventService.getCattleEventsByTag(partnerBullTag);
              final partnerEvents = allPartnerEvents.where((e) => (e['cattle_tag']?.toString() ?? '') == partnerBullTag).toList();
              Map<String, dynamic> partner = {};
              try {
                final targetDate = DateTime.parse(data['event_date']);
                partner = partnerEvents.firstWhere(
                  (e) {
                    try {
                      if ((e['event_type']?.toString().toLowerCase() ?? '') != 'breeding') return false;
                      final d = DateTime.parse(e['event_date']?.toString() ?? '');
                      return d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day;
                    } catch (_) { return false; }
                  },
                  orElse: () => {},
                );
              } catch (_) {}

              if (partner.isNotEmpty) {
                // Build bull-side payload with limited fields and explicitly omit return-to-heat
                final bullData = <String, dynamic>{
                  'id': partner['id'],
                  'cattle_tag': partnerBullTag,
                  'event_type': 'Breeding',
                  'event_date': data['event_date'],
                  'breeding_type': 'Natural Breeding',
                  // Do not overwrite partner bull notes
                };
                // Execute bull update
                final bullOk = await CattleEventService.updateCattleEvent(bullData);
                print('Unified edit: bull reciprocal update result: $bullOk');
              }
            }
          }

          print('Updating event with ID: ${widget.event!.id}');
          eventSuccess = await CattleEventService.updateCattleEvent(data);
        } else {
          print('Creating new event');
          eventSuccess = await CattleEventService.storeCattleEvent(data);
        }

        print('Event service result: $eventSuccess');
      } catch (serviceError) {
        print('Service error details: $serviceError');
        print('Service error type: ${serviceError.runtimeType}');

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
        print('Event saved successfully, handling specific event types...');

        // Event saved successfully, now handle specific event types
        try {
          print('🎯 Event type handling - selectedEventType: "$selectedEventType"');
          if (selectedEventType.toLowerCase() == 'gives birth') {
            print('🎯 Handling Gives Birth event');
            await _handleGivesBirthEvent();
          } else if (selectedEventType.toLowerCase() == 'breeding') {
            print('🎯 Handling Breeding event');
            await _handleBreedingEvent();
          } else if (selectedEventType.toLowerCase() == 'pregnant') {
            print('🎯 Handling Pregnant event');
            await _handlePregnantEvent();
          } else if (selectedEventType.toLowerCase() == 'castrated') {
            print('🎯 Handling Castrated event');
            await _handleCastratedEvent();
          } else if (selectedEventType.toLowerCase() == 'deceased') {
            print('🎯 Handling Deceased event');
            await _handleDeceasedEvent();
          } else if (selectedEventType.toLowerCase() == 'lost') {
            print('🎯 Handling Lost event');
            await _handleLostEvent();
          } else if (selectedEventType.toLowerCase() == 'weighed') {
            print('🎯 Handling Weighed event');
            await _handleWeighedEvent();
          } else if (selectedEventType.toLowerCase() == 'sick') {
            print('🎯 Handling Sick event');
            await _handleSickEvent();
          } else {
            print('🎯 No specific event handler for: "$selectedEventType"');
          }
        } catch (eventSpecificError) {
          // Log but don't fail the entire operation for event-specific errors
          print('Warning - Event-specific operation failed: $eventSpecificError');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Event saved, but some related operations may have failed: ${eventSpecificError.toString()}'),
                backgroundColor: Colors.orange[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }

        if (context.mounted) {
          SuccessDialog.show(
            context: context,
            isEditing: isEditing,
            onContinue: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
          );
        }
      } else {
        // More specific error message based on operation
        String errorDetail = isEditing ?
        'Failed to update the cattle event. Please verify your data and try again.' :
        'Failed to create the cattle event. Please check your input data and network connection.';

        throw Exception('$errorDetail The service returned false, which may indicate:\n'
            '• Server validation errors\n'
            '• Network connectivity issues\n'
            '• Authentication problems\n'
            '• Invalid data format\n\n'
            'Check the console logs for more details.');
      }
    } catch (e) {
      print('=== ERROR IN _submitForm ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');

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

      _showErrorMessage(userFriendlyMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _shouldShowReturnToHeatField() {
    return _cattleDetails?.sex.toLowerCase() == 'female' &&
        selectedEventType.toLowerCase() == 'breeding';
  }

  Future<void> _handleBreedingEvent() async {
    print('🚀🚀🚀 _handleBreedingEvent() CALLED! 🚀🚀🚀');
    try {
      bool cowStatusUpdated = false;
      String cowStatus = '';

      // Update cow (mother) status to Breeding
      if (_cattleDetails != null) {
        final cowUpdateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
        cowUpdateData['status'] = 'Breeding';
        cowStatusUpdated = await CattleService.updateCattleInformation(cowUpdateData);
        cowStatus = cowStatusUpdated
            ? 'Cow ${_cattleDetails!.tagNo} status updated to Breeding'
            : 'Failed to update cow ${_cattleDetails!.tagNo} status';
      }

      // Log the results for debugging
      print('Breeding event results:');
      print('- Cow: $cowStatus');

      final returnToHeatText = _controllers['estimated_return_date']?.text ?? '';
      if (returnToHeatText.isNotEmpty) {
        final DateTime? returnToHeatDate = DateTime.tryParse(returnToHeatText);
        final today = DateTime.now();
        if (returnToHeatDate != null &&
            returnToHeatDate.year == today.year &&
            returnToHeatDate.month == today.month &&
            returnToHeatDate.day == today.day) {
          final cowUpdateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
          cowUpdateData['status'] = 'Healthy';
          final updated = await CattleService.updateCattleInformation(cowUpdateData);
          if (updated) {
            print('Cow ${_cattleDetails!.tagNo} status auto-updated to Healthy');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cow ${_cattleDetails!.tagNo} status changed to Healthy (Return to Heat)'),
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

      // Create reciprocal breeding event for the male cattle
      print('DEBUG: About to create reciprocal breeding event');
      print('DEBUG: Current cattle details: ${_cattleDetails?.tagNo}');
      print('DEBUG: Breeding type controller value: ${_controllers['breeding_type']?.text}');
      print('DEBUG: Semen used controller value: ${_controllers['semen_used']?.text}');
      print('DEBUG: Bull tag controller value: ${_controllers['bull_tag']?.text}');
      await _createReciprocalBreedingEvent();

      // Log the results for debugging
      print('Breeding event results:');
      print('- Cow: $cowStatus');

      // Optional: Show a snackbar with summary if needed
      if (mounted && cowStatusUpdated) {

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
      print('Error in _handleBreedingEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Some breeding event operations may have failed'),
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
    print('🔥🔥🔥 _createReciprocalBreedingEvent() CALLED! 🔥🔥🔥');
    try {
      final breedingType = _controllers['breeding_type']?.text ?? '';
      String? partnerCattleTag;
      
      print('DEBUG: Creating reciprocal breeding event');
      print('DEBUG: Breeding type: $breedingType');
      print('DEBUG: All controller values:');
      print('  - breeding_type: ${_controllers['breeding_type']?.text}');
      print('  - semen_used: ${_controllers['semen_used']?.text}');
      print('  - bull_tag: ${_controllers['bull_tag']?.text}');
      print('  - event_date: ${_controllers['event_date']?.text}');
      
      // Determine the partner cattle based on breeding type
      if (breedingType == 'artificial_insemination') {
        final semenUsed = _controllers['semen_used']?.text ?? '';
        print('DEBUG: Semen used: $semenUsed');
        if (semenUsed.isNotEmpty) {
          // We now store pure tag. If any old label format slips through, fall back to parsing.
          if (semenUsed.contains(' Semen')) {
            String tagPart = semenUsed.replaceAll(' Semen', '');
            if (tagPart.contains(' (') && tagPart.contains(')')) {
              partnerCattleTag = tagPart.split(' (')[0];
            } else {
              partnerCattleTag = tagPart;
            }
            print('DEBUG: Extracted bull tag from semen label: $partnerCattleTag');
          } else {
            partnerCattleTag = semenUsed.trim();
            print('DEBUG: Using semen_used as pure tag for partner: $partnerCattleTag');
          }
        }
      } else if (breedingType == 'natural_breeding') {
        partnerCattleTag = _controllers['bull_tag']?.text ?? '';
        print('DEBUG: Bull tag from natural breeding: $partnerCattleTag');
      } else {
        // Fallback: try to determine from available fields
        print('DEBUG: Unknown breeding type, trying fallback detection');
        final semenUsed = _controllers['semen_used']?.text ?? '';
        final bullTag = _controllers['bull_tag']?.text ?? '';
        
        if (semenUsed.isNotEmpty) {
          print('DEBUG: Fallback - using semen field');
          if (semenUsed.contains(' Semen')) {
            String tagPart = semenUsed.replaceAll(' Semen', '');
            if (tagPart.contains(' (') && tagPart.contains(')')) {
              partnerCattleTag = tagPart.split(' (')[0];
            } else {
              partnerCattleTag = tagPart;
            }
          }
        } else if (bullTag.isNotEmpty) {
          print('DEBUG: Fallback - using bull tag field');
          partnerCattleTag = bullTag;
        }
      }
      
      if (partnerCattleTag == null || partnerCattleTag.isEmpty) {
        print('DEBUG: No partner cattle found for reciprocal breeding event');
        print('DEBUG: Breeding type was: $breedingType');
        print('DEBUG: Semen used was: ${_controllers['semen_used']?.text}');
        print('DEBUG: Bull tag was: ${_controllers['bull_tag']?.text}');
        return;
      }
      
      // Find the partner cattle
      final partnerCattle = await CattleService.getCattleByTag(partnerCattleTag);
      if (partnerCattle == null) {
        print('Partner cattle not found: $partnerCattleTag');
        return;
      }
      
      // Check if partner cattle is male (Bull)
      final partnerSex = partnerCattle.sex.toLowerCase().trim();
      if (partnerSex != 'male') {
        print('Partner cattle is not male, skipping reciprocal breeding event');
        return;
      }
      
      // Check if a breeding event already exists for this partner on the same date
      final eventDate = _controllers['event_date']?.text ?? '';
      if (eventDate.isNotEmpty) {
        final existingEvents = await CattleEventService.getCattleEventsByTag(partnerCattleTag);
        print('DEBUG: Checking for existing events for partner: $partnerCattleTag');
        print('DEBUG: Found ${existingEvents.length} events for partner');
        
        // Filter events to only include those for the specific partner cattle
        final partnerEvents = existingEvents.where((event) => 
          event['cattle_tag']?.toString() == partnerCattleTag
        ).toList();
        
        print('DEBUG: Filtered to ${partnerEvents.length} events for partner cattle');
        
        final hasExistingBreedingEvent = partnerEvents.any((event) => 
          event['event_type']?.toString().toLowerCase() == 'breeding' && 
          event['event_date']?.toString() == eventDate
        );
        
        if (hasExistingBreedingEvent) {
          print('DEBUG: Breeding event already exists for partner cattle on this date');
          return;
        } else {
          print('DEBUG: No existing breeding event found for partner on this date');
        }
      }
      
      // Create reciprocal breeding event for the male
      final reciprocalEventData = {
        'cattle_tag': partnerCattleTag,
        // Use proper case to match backend ENUM
        'event_type': 'Breeding',
        'event_date': _controllers['event_date']?.text ?? '',
        // Map to human-readable for backend storage
        'breeding_type': (breedingType == 'artificial_insemination')
            ? 'Artificial Insemination'
            : (breedingType == 'natural_breeding')
                ? 'Natural Breeding'
                : breedingType,
        'notes': 'Breeding with ${_cattleDetails?.tagNo ?? 'unknown'}',
        'user_id': 1, // Use default user ID for now
      };
      
      // Add breeding-specific fields
      if (breedingType == 'artificial_insemination') {
        // Do not include semen_used for reciprocal bull event
        reciprocalEventData['technician'] = _controllers['technician']?.text ?? '';
      } else if (breedingType == 'natural_breeding') {
        reciprocalEventData['bull_tag'] = _controllers['bull_tag']?.text ?? '';
      }
      
      final result = await CattleEventService.storeCattleEvent(reciprocalEventData);
      
      if (result) {
        print('Successfully created reciprocal breeding event for $partnerCattleTag');
        
        // Update partner cattle status to Breeding
        final partnerUpdateData = Map<String, dynamic>.from(partnerCattle.toJson());
        partnerUpdateData['status'] = 'Breeding';
        await CattleService.updateCattleInformation(partnerUpdateData);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reciprocal breeding event created for $partnerCattleTag'),
              backgroundColor: Colors.blue[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('Failed to create reciprocal breeding event for $partnerCattleTag');
      }
      
    } catch (e) {
      print('Error creating reciprocal breeding event: $e');
      // Don't show error to user as this is a secondary operation
    }
  }

  Future<void> _handlePregnantEvent() async {
    try {
      bool cowStatusUpdated = false;
      String cowStatus = '';

      // Update cow (mother) status to Pregnant
      if (_cattleDetails != null) {
        final cowUpdateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
        cowUpdateData['status'] = 'Pregnant';
        cowStatusUpdated = await CattleService.updateCattleInformation(cowUpdateData);
        cowStatus = cowStatusUpdated
            ? 'Cow ${_cattleDetails!.tagNo} status updated to Pregnant'
            : 'Failed to update cow ${_cattleDetails!.tagNo} status to Pregnant';
      }

      // Log the result for debugging
      print('Pregnant event result: $cowStatus');

      // Optional: Show success feedback to user
      if (mounted && cowStatusUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cattle status updated to Pregnant'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      print('Error in _handlePregnantEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update cattle status to Pregnant'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleDeceasedEvent() async {
    try {
      bool cattleStatusUpdated = false;
      String cattleStatus = '';

      // Update cattle status to Deceased
      if (_cattleDetails != null) {
        final cattleUpdateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
        cattleUpdateData['status'] = 'Deceased';
        cattleStatusUpdated = await CattleService.updateCattleInformation(cattleUpdateData);
        cattleStatus = cattleStatusUpdated
            ? 'Cattle ${_cattleDetails!.tagNo} status updated to Deceased'
            : 'Failed to update cattle ${_cattleDetails!.tagNo} status to Deceased';
      }

      // Log the result for debugging
      print('Deceased event result: $cattleStatus');

      // Optional: Show success feedback to user
      if (mounted && cattleStatusUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cattle status updated to Deceased'),
            backgroundColor: Colors.grey[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      print('Error in _handleDeceasedEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update cattle status to Deceased'),
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
      if (_cattleDetails == null) return;

      final weightText = _controllers['weighed_result']?.text.trim() ?? '';
      final latestWeight = double.tryParse(weightText);

      if (latestWeight == null || latestWeight <= 0) {
        print('Weighed event: invalid or empty weight, skipping cattle weight update');
        return;
      }

      final cattleUpdateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
      cattleUpdateData['weight'] = latestWeight;

      final updated = await CattleService.updateCattleInformation(cattleUpdateData);
      print('Cattle weight update result: $updated');

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
      print('Error in _handleWeighedEvent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update cattle weight'),
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
      bool cattleStatusUpdated = false;
      String cattleStatus = '';

      // Update cattle status to Lost
      if (_cattleDetails != null) {
        final cattleUpdateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
        cattleUpdateData['status'] = 'Lost';
        cattleStatusUpdated = await CattleService.updateCattleInformation(cattleUpdateData);
        cattleStatus = cattleStatusUpdated
            ? 'Cattle ${_cattleDetails!.tagNo} status updated to Lost'
            : 'Failed to update cattle ${_cattleDetails!.tagNo} status to Lost';
      }

      // Log the result for debugging
      print('Lost event result: $cattleStatus');

      // Optional: Show success feedback to user
      if (mounted && cattleStatusUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cattle status updated to Lost'),
            backgroundColor: Colors.amber[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      print('Error in _handleLostEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update cattle status to Lost'),
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
      bool cattleStatusUpdated = false;
      String cattleStatus = '';

      // Update cattle status to Sick
      if (_cattleDetails != null) {
        final cattleUpdateData = Map<String, dynamic>.from(_cattleDetails!.toJson());
        cattleUpdateData['status'] = 'Sick';
        cattleStatusUpdated = await CattleService.updateCattleInformation(cattleUpdateData);
        cattleStatus = cattleStatusUpdated
            ? 'Cattle ${_cattleDetails!.tagNo} status updated to Sick'
            : 'Failed to update cattle ${_cattleDetails!.tagNo} status to Sick';
      }

      // Log the result for debugging
      print('Sick event result: $cattleStatus');

      // Optional: Show success feedback to user
      if (mounted && cattleStatusUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cattle status updated to Sick'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Log any errors that occur during the process
      print('Error in _handleSickEvent: $e');

      // Optional: Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Failed to update cattle status to Sick'),
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
      await CattleEventService.deleteCattleEvent(widget.event!.id);
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
          isEditing ? 'Edit Cattle Event' : 'Add Cattle Event',
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
        child: _isLoading && _cattleDetails == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.vibrantGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading cattle information...',
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
                            // Cattle Info Card
                            EventCattleInfoEventCard(
                              cattleDetails: _cattleDetails,
                              cattleTag: widget.cattleTag,
                            ),
                            const SizedBox(height: 30),

                            // Event Type Section
                            EventTypeDropdown(
                              cattleDetails: _cattleDetails,
                              selectedEventType: selectedEventType,
                              controllers: _controllers,
                              onEventTypeChanged: (value) {
                                if (value != null) {
                                  _handleEventTypeChanged(value);
                                }
                              },
                              onEventDateSelected: _handleEventDateSelected,
                            ),
                            const SizedBox(height: 30),

                            // Event-specific fields
                            EventSpecificFields(
                              key: _eventSpecificFieldsKey,
                              selectedEventType: selectedEventType,
                              controllers: _controllers,
                              cattleTag: widget.cattleTag ?? (isEditing && widget.event != null ? widget.event!.cattleTag : null),
                              temporaryCalfData: _temporaryCalfData,
                              onEditCalfPressed: _openCalfRegistrationDialog,
                              showReturnToHeat: _shouldShowReturnToHeatField(),
                            ),

                            // Notes Section
                            EventNotesSection(
                              controller: _controllers['notes']!,
                            ),
                            const SizedBox(height: 40),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading || _cattleDetails == null
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