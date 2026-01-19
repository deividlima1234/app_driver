import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateScreen extends StatefulWidget {
  final String downloadUrl;
  final String version;
  final String? releaseNotes;

  const UpdateScreen({
    super.key,
    required this.downloadUrl,
    required this.version,
    this.releaseNotes,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = "";
  final Dio _dio = Dio();

  Future<void> _startDownload() async {
    // 1. Request permissions (Android 12/13 might need different handling for install packages)
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        await Permission.requestInstallPackages.request();
      }
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = "Iniciando descarga...";
      _progress = 0.0;
    });

    try {
      // 2. Prepare path
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();

      final String savePath = "${dir.path}/update_${widget.version}.apk";

      // 3. Download
      await _dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              _statusMessage =
                  "Descargando: ${(_progress * 100).toStringAsFixed(0)}%";
            });
          }
        },
      );

      setState(() {
        _statusMessage = "Instalando...";
      });

      // 4. Open File (Triggers Install Intent)
      final result = await OpenFile.open(
        savePath,
        type: "application/vnd.android.package-archive",
      );
      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.system_update, size: 80, color: Color(0xFF0D47A1)),
            const SizedBox(height: 32),
            const Text(
              "¡Actualización Requerida!",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Versión ${widget.version} disponible.\nEs necesario actualizar para continuar.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            if (widget.releaseNotes != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.releaseNotes!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 48),
            if (_isDownloading) ...[
              LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xFF0D47A1)),
              const SizedBox(height: 12),
              Text(_statusMessage,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("ACTUALIZAR AHORA",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
