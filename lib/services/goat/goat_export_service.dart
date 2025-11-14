import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config.dart';
import '../auth_service.dart';

class GoatExportService {
  static final String _baseUrl = AppConfig.baseUrl;

  static Future<bool> downloadgoatExcel(String goatId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        log('❌ GoatExportService: No token found');
        return false;
      }

      final url = Uri.parse('$_baseUrl/farmer/goats/export-goat-excel?goat_id=$goatId');
      log('📥 GoatExportService: Downloading goat Excel from $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        },
      );

      log('📥 GoatExportService: Response status: ${response.statusCode}');
      log('📥 GoatExportService: Response headers: ${response.headers}');
      log('📥 GoatExportService: Response body length: ${response.bodyBytes.length}');

      if (response.statusCode == 401) {
        log('❌ GoatExportService: Authentication failed.');
        return false;
      }

      if (response.statusCode != 200) {
        log('❌ GoatExportService: Failed to download Excel.');
        return false;
      }

      final contentType = response.headers['content-type'] ?? '';
      final bytes = response.bodyBytes;
      final looksLikeHtml = contentType.contains('text/html') ||
          (bytes.length >= 14 && String.fromCharCodes(bytes.take(14)).toLowerCase().contains('<!doctype html')) ||
          (bytes.length >= 6 && String.fromCharCodes(bytes.take(6)).toLowerCase().contains('<html>'));
      final looksLikeZip = bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04;
      if (looksLikeHtml || !looksLikeZip) {
        log('❌ GoatExportService: Response is not a real Excel file. Content-Type: $contentType');
        return await _launchExternal(url);
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'goat_Profile_$timestamp.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      log('✅ GoatExportService: Excel saved to ${file.path}');

      try {
        if (Platform.isAndroid) {
          final downloads = await _getDownloadsPath();
          if (downloads != null) {
            final copy = File('$downloads/$fileName');
            await copy.writeAsBytes(await file.readAsBytes(), flush: true);
            log('✅ GoatExportService: Copied to Downloads: ${copy.path}');
          }
        }
      } catch (_) {}

      try {
        await OpenFilex.open(file.path);
      } catch (e) {
        log('⚠️ GoatExportService: Open failed: $e');
      }
      return true;
    } catch (e, st) {
      log('❌ GoatExportService: Error: $e', stackTrace: st);
      return false;
    }
  }

  static Future<bool> downloadgoatPdf(String goatId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        log('❌ GoatExportService: No token found');
        return false;
      }

      final url = Uri.parse('$_baseUrl/farmer/goats/export-goat-pdf?goat_id=$goatId');
      log('📥 GoatExportService: Downloading goat PDF from $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      log('📥 GoatExportService: Response status: ${response.statusCode}');
      log('📥 GoatExportService: Response headers: ${response.headers}');
      log('📥 GoatExportService: Response body length: ${response.bodyBytes.length}');

      if (response.statusCode == 401) {
        log('❌ GoatExportService: Authentication failed.');
        return false;
      }

      if (response.statusCode != 200) {
        log('❌ GoatExportService: Failed to download PDF.');
        return false;
      }

      final contentType = response.headers['content-type'] ?? '';
      final bytes = response.bodyBytes;
      final looksLikeHtml = contentType.contains('text/html') ||
          (bytes.length >= 14 && String.fromCharCodes(bytes.take(14)).toLowerCase().contains('<!doctype html')) ||
          (bytes.length >= 6 && String.fromCharCodes(bytes.take(6)).toLowerCase().contains('<html>'));
      final looksLikePdf = bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;
      if (looksLikeHtml || !looksLikePdf) {
        log('❌ GoatExportService: Response is not a real PDF. Content-Type: $contentType');
        return await _launchExternal(url);
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'goat_Profile_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      log('✅ GoatExportService: PDF saved to ${file.path}');

      try {
        if (Platform.isAndroid) {
          final downloads = await _getDownloadsPath();
          if (downloads != null) {
            final copy = File('$downloads/$fileName');
            await copy.writeAsBytes(await file.readAsBytes(), flush: true);
            log('✅ GoatExportService: Copied to Downloads: ${copy.path}');
          }
        }
      } catch (_) {}

      try {
        await OpenFilex.open(file.path);
      } catch (e) {
        log('⚠️ GoatExportService: Open failed: $e');
      }
      return true;
    } catch (e, st) {
      log('❌ GoatExportService: Error: $e', stackTrace: st);
      return false;
    }
  }

  static Future<bool> downloadgoatListExcel({String? reportType}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        log('❌ GoatExportService: No token found');
        return false;
      }

      final qp = (reportType != null && reportType.isNotEmpty)
          ? '?report_type=${Uri.encodeQueryComponent(reportType)}'
          : '';
      final url = Uri.parse('$_baseUrl/farmer/goats/export-excel$qp');
      log('📥 GoatExportService: Downloading goat List Excel from $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        },
      );

      log('📥 GoatExportService: Response status: ${response.statusCode}');
      if (response.statusCode != 200) return false;

      final bytes = response.bodyBytes;
      final looksLikeZip = bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04;
      if (!looksLikeZip) return false;

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final file = File('${dir.path}/goat_List_$ts.xlsx');
      await file.writeAsBytes(bytes);
      try { await OpenFilex.open(file.path); } catch (_) {}
      return true;
    } catch (e, st) {
      log('❌ GoatExportService: Error list excel: $e', stackTrace: st);
      return false;
    }
  }

  static Future<bool> downloadgoatListPdf({String? reportType}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        log('❌ GoatExportService: No token found');
        return false;
      }

      final qp = (reportType != null && reportType.isNotEmpty)
          ? '?report_type=${Uri.encodeQueryComponent(reportType)}'
          : '';
      final url = Uri.parse('$_baseUrl/farmer/goats/export-pdf$qp');
      log('📥 GoatExportService: Downloading goat List PDF from $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      log('📥 GoatExportService: Response status: ${response.statusCode}');
      if (response.statusCode != 200) return false;

      final bytes = response.bodyBytes;
      final looksLikePdf = bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;
      if (!looksLikePdf) return false;

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final file = File('${dir.path}/goat_List_$ts.pdf');
      await file.writeAsBytes(bytes);
      try { await OpenFilex.open(file.path); } catch (_) {}
      return true;
    } catch (e, st) {
      log('❌ GoatExportService: Error list pdf: $e', stackTrace: st);
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


