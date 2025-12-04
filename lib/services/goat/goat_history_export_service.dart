import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../auth_service.dart';

/// Service for exporting goat history reports (per history type) as
/// Excel or PDF, mirroring the backend farmer history report exports.
class GoatHistoryExportService {
  static final String _baseUrl = AppConfig.baseUrl;

  /// Download an Excel history report for the given [historyType].
  ///
  /// [historyType] should match the history_type stored in the database,
  /// e.g. "Vaccinated", "Sick", "Treated", "Breeding", etc.
  static Future<bool> downloadHistoryExcel(String historyType) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        log('❌ GoatHistoryExportService: No token found');
        return false;
      }

      String cleanedToken = token.trim().replaceAll('\r', '').replaceAll('\n', '').trim();

      final url = Uri.parse('$_baseUrl/farmer/reports/history-report/export-excel');
      log('📥 GoatHistoryExportService: Downloading History Excel for "$historyType" from $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $cleanedToken',
          'X-Auth-Token': cleanedToken,
          'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'history_type': historyType,
        },
      );

      log('📥 GoatHistoryExportService: Response status: ${response.statusCode}');
      log('📥 GoatHistoryExportService: Response headers: ${response.headers}');
      log('📥 GoatHistoryExportService: Response body length: ${response.bodyBytes.length}');

      if (response.statusCode == 401) {
        log('❌ GoatHistoryExportService: Authentication failed.');
        return false;
      }

      if (response.statusCode != 200) {
        log('❌ GoatHistoryExportService: Failed to download Excel.');
        return await _launchExternal(url);
      }

      final contentType = response.headers['content-type'] ?? '';
      final bytes = response.bodyBytes;
      final looksLikeHtml = contentType.contains('text/html') ||
          (bytes.length >= 14 && String.fromCharCodes(bytes.take(14)).toLowerCase().contains('<!doctype html')) ||
          (bytes.length >= 6 && String.fromCharCodes(bytes.take(6)).toLowerCase().contains('<html>'));
      final looksLikeZip = bytes.length >= 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          bytes[2] == 0x03 &&
          bytes[3] == 0x04;

      if (looksLikeHtml || !looksLikeZip) {
        log('❌ GoatHistoryExportService: Response is not a real Excel file. Content-Type: $contentType, looksLikeZip: $looksLikeZip');
        return await _launchExternal(url);
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final safeType = historyType.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final fileName = 'Goat_History_${safeType}_$timestamp.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      log('✅ GoatHistoryExportService: Excel saved to ${file.path}');

      try {
        if (Platform.isAndroid) {
          final downloads = await _getDownloadsPath();
          if (downloads != null) {
            final copy = File('$downloads/$fileName');
            await copy.writeAsBytes(await file.readAsBytes(), flush: true);
            log('✅ GoatHistoryExportService: Copied to Downloads: ${copy.path}');
          }
        }
      } catch (_) {}

      try {
        await OpenFilex.open(file.path);
      } catch (e) {
        log('⚠️ GoatHistoryExportService: Open failed: $e');
      }

      return true;
    } catch (e, st) {
      log('❌ GoatHistoryExportService: Error Excel: $e', stackTrace: st);
      return false;
    }
  }

  /// Download a PDF history report for the given [historyType].
  static Future<bool> downloadHistoryPdf(String historyType) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        log('❌ GoatHistoryExportService: No token found');
        return false;
      }

      String cleanedToken = token.trim().replaceAll('\r', '').replaceAll('\n', '').trim();

      final url = Uri.parse('$_baseUrl/farmer/reports/history-report/export-pdf');
      log('📥 GoatHistoryExportService: Downloading History PDF for "$historyType" from $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $cleanedToken',
          'X-Auth-Token': cleanedToken,
          'Accept': 'application/pdf',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'history_type': historyType,
        },
      );

      log('📥 GoatHistoryExportService: Response status: ${response.statusCode}');
      log('📥 GoatHistoryExportService: Response headers: ${response.headers}');
      log('📥 GoatHistoryExportService: Response body length: ${response.bodyBytes.length}');

      if (response.statusCode == 401) {
        log('❌ GoatHistoryExportService: Authentication failed.');
        return false;
      }

      if (response.statusCode != 200) {
        log('❌ GoatHistoryExportService: Failed to download PDF.');
        return await _launchExternal(url);
      }

      final contentType = response.headers['content-type'] ?? '';
      final bytes = response.bodyBytes;
      final looksLikeHtml = contentType.contains('text/html') ||
          (bytes.length >= 14 && String.fromCharCodes(bytes.take(14)).toLowerCase().contains('<!doctype html')) ||
          (bytes.length >= 6 && String.fromCharCodes(bytes.take(6)).toLowerCase().contains('<html>'));
      final looksLikePdf = bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46;

      if (looksLikeHtml || !looksLikePdf) {
        log('❌ GoatHistoryExportService: Response is not a real PDF file. Content-Type: $contentType, looksLikePdf: $looksLikePdf');
        return await _launchExternal(url);
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final safeType = historyType.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final fileName = 'Goat_History_${safeType}_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      log('✅ GoatHistoryExportService: PDF saved to ${file.path}');

      try {
        if (Platform.isAndroid) {
          final downloads = await _getDownloadsPath();
          if (downloads != null) {
            final copy = File('$downloads/$fileName');
            await copy.writeAsBytes(await file.readAsBytes(), flush: true);
            log('✅ GoatHistoryExportService: Copied to Downloads: ${copy.path}');
          }
        }
      } catch (_) {}

      try {
        await OpenFilex.open(file.path);
      } catch (e) {
        log('⚠️ GoatHistoryExportService: Open failed: $e');
      }

      return true;
    } catch (e, st) {
      log('❌ GoatHistoryExportService: Error PDF: $e', stackTrace: st);
      return false;
    }
  }

  static Future<String?> _getDownloadsPath() async {
    try {
      final primary = Directory('/storage/emulated/0/Download');
      if (await primary.exists()) return primary.path;
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
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}


