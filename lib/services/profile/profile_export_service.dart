import 'dart:io';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config.dart';
import '../auth_service.dart';

class ProfileExportService {
  static final String _baseUrl = AppConfig.baseUrl;

  /// Download and share Excel file
  static Future<bool> downloadExcelProfile(String? farmerId) async {
    if (farmerId == null || farmerId.isEmpty) {
      log('❌ ProfileExportService: No farmer ID provided');
      return false;
    }

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        log('❌ ProfileExportService: No token found');
        return false;
      }

      // Clean token: trim and remove only newlines and carriage returns (not spaces)
      // JWT tokens are base64url encoded and should not have newlines
      String cleanedToken = token.trim();
      cleanedToken = cleanedToken.replaceAll('\r', '').replaceAll('\n', '').trim();

      final url = Uri.parse('$_baseUrl/farmer/farmers-profile/export-profile-excel?farmer_id=$farmerId');
      
      log('📥 ProfileExportService: Downloading Excel from $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $cleanedToken',
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
          'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        },
      );

      log('📥 ProfileExportService: Response status: ${response.statusCode}');
      log('📥 ProfileExportService: Response headers: ${response.headers}');
      log('📥 ProfileExportService: Response body length: ${response.bodyBytes.length}');

      if (response.statusCode == 401) {
        log('❌ ProfileExportService: Authentication failed. Token may be expired or invalid.');
        return false;
      }

      if (response.statusCode == 200) {
        // Validate content type or magic bytes (should not be HTML)
        final contentType = response.headers['content-type'] ?? '';
        final bytes = response.bodyBytes;
        final looksLikeHtml = contentType.contains('text/html') ||
            (bytes.length >= 14 &&
                String.fromCharCodes(bytes.take(14)).toLowerCase().contains('<!doctype html')) ||
            (bytes.length >= 6 &&
                String.fromCharCodes(bytes.take(6)).toLowerCase().contains('<html>'));
        // XLSX is a ZIP file: magic bytes 50 4B 03 04 (PK\x03\x04)
        final looksLikeZip = bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04;
        if (looksLikeHtml || !looksLikeZip) {
          log('❌ ProfileExportService: Response is not a real Excel file. Content-Type: $contentType');
          // Fallback: open in external browser to leverage existing web session
          final ok = await _launchExternal(url);
          return ok;
        }

        // Get temporary directory
        final directory = await getTemporaryDirectory();
        
        // Create filename with timestamp
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
        final fileName = 'goatTracer_Profile_$timestamp.xlsx';
        final file = File('${directory.path}/$fileName');
        
        // Write file
        await file.writeAsBytes(response.bodyBytes);
        log('✅ ProfileExportService: Excel file saved to ${file.path}');
        log('✅ ProfileExportService: File size: ${file.lengthSync()} bytes');

        // Also copy to Downloads (Android)
        try {
          if (Platform.isAndroid) {
            final downloadsPath = await _getDownloadsPath();
            if (downloadsPath != null) {
              final downloadsFile = File('$downloadsPath/$fileName');
              await downloadsFile.writeAsBytes(await file.readAsBytes(), flush: true);
              log('✅ ProfileExportService: Copied to Downloads: ${downloadsFile.path}');
            }
          }
        } catch (e) {
          log('⚠️ ProfileExportService: Could not copy to Downloads: $e');
        }

        // Open the file - this will allow user to view or save it
        try {
          final openResult = await OpenFilex.open(file.path);
          log('📂 ProfileExportService: File open result: ${openResult.message}, type: ${openResult.type}');
          return true;
        } catch (openError) {
          log('⚠️ ProfileExportService: Open failed, but file is saved: $openError');
          return true;
        }
      } else {
        log('❌ ProfileExportService: Failed to download Excel. Status: ${response.statusCode}');
        log('❌ ProfileExportService: Response body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('❌ ProfileExportService: Error downloading Excel: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Download and share PDF file
  static Future<bool> downloadPdfProfile(String? farmerId) async {
    if (farmerId == null || farmerId.isEmpty) {
      log('❌ ProfileExportService: No farmer ID provided');
      return false;
    }

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        log('❌ ProfileExportService: No token found');
        return false;
      }

      // Clean token: trim and remove only newlines and carriage returns (not spaces)
      // JWT tokens are base64url encoded and should not have newlines
      String cleanedToken = token.trim();
      cleanedToken = cleanedToken.replaceAll('\r', '').replaceAll('\n', '').trim();

      final url = Uri.parse('$_baseUrl/farmer/farmers-profile/export-profile-pdf?farmer_id=$farmerId');
      
      log('📥 ProfileExportService: Downloading PDF from $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $cleanedToken',
          'X-Auth-Token': cleanedToken, // Workaround for nginx + PHP-FPM
          'Accept': 'application/pdf',
        },
      );

      log('📥 ProfileExportService: Response status: ${response.statusCode}');
      log('📥 ProfileExportService: Response headers: ${response.headers}');
      log('📥 ProfileExportService: Response body length: ${response.bodyBytes.length}');

      if (response.statusCode == 401) {
        log('❌ ProfileExportService: Authentication failed. Token may be expired or invalid.');
        return false;
      }

      if (response.statusCode == 200) {
        // Validate content type or magic bytes (should not be HTML)
        final contentType = response.headers['content-type'] ?? '';
        final bytes = response.bodyBytes;
        final looksLikeHtml = contentType.contains('text/html') ||
            (bytes.length >= 14 &&
                String.fromCharCodes(bytes.take(14)).toLowerCase().contains('<!doctype html')) ||
            (bytes.length >= 6 &&
                String.fromCharCodes(bytes.take(6)).toLowerCase().contains('<html>'));
        // PDF magic bytes: 25 50 44 46 ("%PDF")
        final looksLikePdf = bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;
        if (looksLikeHtml || !looksLikePdf) {
          log('❌ ProfileExportService: Response is not a real PDF. Content-Type: $contentType');
          // Fallback: open in external browser to leverage existing web session
          final ok = await _launchExternal(url);
          return ok;
        }

        // Get temporary directory
        final directory = await getTemporaryDirectory();
        
        // Create filename with timestamp
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
        final fileName = 'goatTracer_Profile_$timestamp.pdf';
        final file = File('${directory.path}/$fileName');
        
        // Write file
        await file.writeAsBytes(response.bodyBytes);
        log('✅ ProfileExportService: PDF file saved to ${file.path}');
        log('✅ ProfileExportService: File size: ${file.lengthSync()} bytes');

        // Also copy to Downloads (Android)
        try {
          if (Platform.isAndroid) {
            final downloadsPath = await _getDownloadsPath();
            if (downloadsPath != null) {
              final downloadsFile = File('$downloadsPath/$fileName');
              await downloadsFile.writeAsBytes(await file.readAsBytes(), flush: true);
              log('✅ ProfileExportService: Copied to Downloads: ${downloadsFile.path}');
            }
          }
        } catch (e) {
          log('⚠️ ProfileExportService: Could not copy to Downloads: $e');
        }

        // Open the file - this will allow user to view or save it
        try {
          final openResult = await OpenFilex.open(file.path);
          log('📂 ProfileExportService: File open result: ${openResult.message}, type: ${openResult.type}');
          return true;
        } catch (openError) {
          log('⚠️ ProfileExportService: Open failed, but file is saved: $openError');
          return true;
        }
      } else {
        log('❌ ProfileExportService: Failed to download PDF. Status: ${response.statusCode}');
        log('❌ ProfileExportService: Response body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      log('❌ ProfileExportService: Error downloading PDF: $e', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<String?> _getDownloadsPath() async {
    try {
      // Primary attempt: /storage/emulated/0/Download
      final primary = Directory('/storage/emulated/0/Download');
      if (await primary.exists()) return primary.path;

      // Fallback via external storage root
      final external = await getExternalStorageDirectory();
      if (external != null) {
        final alt = Directory('${external.path.split('Android')[0]}Download');
        if (await alt.exists()) return alt.path;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> _launchExternal(Uri url) async {
    try {
      final can = await canLaunchUrl(url);
      if (!can) return false;
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      log('🌐 ProfileExportService: Launched external: $launched');
      return launched;
    } catch (e) {
      log('⚠️ ProfileExportService: Failed to launch external URL: $e');
      return false;
    }
  }
}
