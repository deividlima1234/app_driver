import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';

class VersionStatus {
  final bool canUpdate;
  final String? localVersion;
  final String? remoteVersion;
  final String? downloadUrl;
  final String? releaseNotes;

  VersionStatus({
    required this.canUpdate,
    this.localVersion,
    this.remoteVersion,
    this.downloadUrl,
    this.releaseNotes,
  });
}

class VersionCheckService {
  final Dio _dio = Dio();

  // URL del archivo versión en tu repositorio (Raw)
  final String _versionUrl =
      'https://raw.githubusercontent.com/deividlima1234/app_driver/main/version.json';

  Future<VersionStatus> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 1. Fetch remote version info
      final response = await _dio.get(_versionUrl);

      // Expected JSON:
      // {
      //   "version": "1.0.1",
      //   "downloadUrl": "https://github.com/EddamCore/app_driver/releases/download/v1.0.1/app-release.apk",
      //   "notes": "Corrección de errores críticos"
      // }

      if (response.statusCode == 200) {
        // Parse raw JSON (Dio does it auto if header is json, else use jsonDecode)
        final Map<String, dynamic> data =
            response.data is String ? jsonDecode(response.data) : response.data;

        final String remoteVersion = data['version'];
        final String downloadUrl = data['downloadUrl'];
        final String? notes = data['notes'];

        final bool canUpdate = _compareVersions(currentVersion, remoteVersion);

        return VersionStatus(
          canUpdate: canUpdate,
          localVersion: currentVersion,
          remoteVersion: remoteVersion,
          downloadUrl: downloadUrl,
          releaseNotes: notes,
        );
      }

      return VersionStatus(canUpdate: false, localVersion: currentVersion);
    } catch (e) {
      // Fail silently or log
      return VersionStatus(canUpdate: false);
    }
  }

  bool _compareVersions(String current, String remote) {
    try {
      if (current == remote) return false;

      List<int> c = current.split('.').take(3).map(int.parse).toList();
      List<int> r = remote.split('.').take(3).map(int.parse).toList();

      // Pad with zeros if needed (e.g. "1.0" -> "1.0.0")
      while (c.length < 3) {
        c.add(0);
      }
      while (r.length < 3) {
        r.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (r[i] > c[i]) return true;
        if (r[i] < c[i]) return false;
      }
    } catch (e) {
      // Version format error
    }
    return false;
  }
}
