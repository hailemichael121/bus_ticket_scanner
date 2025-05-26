import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:bus_ticket_scanner/models/ticket.dart';
// import 'package:bus_ticket_scanner/providers/scanner_provider.dart';
import 'package:bus_ticket_scanner/screens/ticket_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: [BarcodeFormat.qrCode],
  );

  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _isDetecting = false;
  Timer? _detectionTimer;
  bool _showCaptureButton = false;

  @override
  void initState() {
    super.initState();
    developer.log('Scanner screen initialized', name: 'Scanner');
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermissions());
    _startDetectionTimer();
  }

  void _startDetectionTimer() {
    developer.log('Starting detection timer', name: 'Scanner');
    _detectionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isDetecting && mounted) {
        developer.log('No QR detected recently, showing capture button',
            name: 'Scanner');
        setState(() => _showCaptureButton = true);
      }
      _isDetecting = false;
    });
  }

  Future<void> _checkPermissions() async {
    developer.log('Checking camera permissions', name: 'Scanner');
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;

    if (!cameraStatus.isGranted || !photosStatus.isGranted) {
      developer.log('Requesting camera permissions', name: 'Scanner');
      final results = await [
        Permission.camera,
        Permission.photos,
      ].request();

      if (!mounted) return;
      setState(() {
        _hasPermission = results[Permission.camera]?.isGranted == true &&
            results[Permission.photos]?.isGranted == true;
      });
      developer.log('Permission results: $_hasPermission', name: 'Scanner');
    } else {
      if (!mounted) return;
      setState(() => _hasPermission = true);
    }
  }

  Future<void> _processQRCode(String rawValue) async {
    if (_isProcessing || !mounted) return;

    developer.log('Starting QR processing', name: 'Scanner');
    setState(() => _isProcessing = true);

    try {
      developer.log('Raw QR data: $rawValue', name: 'Scanner');

      if (!rawValue.startsWith('{')) {
        developer.log('Invalid QR format detected', name: 'Scanner');
        throw FormatException('Invalid QR format - does not contain JSON data');
      }

      final decoded = jsonDecode(rawValue);
      developer.log('Successfully decoded QR data', name: 'Scanner');

      final ticket = Ticket.fromJson(decoded);
      developer.log('Created ticket with ID: ${ticket.bookingId}',
          name: 'Scanner');

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(
            ticket: ticket,
            initialStatus: TicketStatus.pending,
          ),
        ),
      );

      developer.log('Navigated to ticket details', name: 'Scanner');
    } catch (e) {
      developer.log('QR processing failed: $e', name: 'Scanner', error: e);
      _showToast('Failed to process QR code');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      developer.log('QR processing completed', name: 'Scanner');
    }
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;
    developer.log('Starting gallery scan', name: 'Scanner');

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        developer.log('No image selected', name: 'Scanner');
        return;
      }

      developer.log('Image selected from gallery', name: 'Scanner');
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop QR Code',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop QR Code',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile == null) {
        developer.log('Image cropping cancelled', name: 'Scanner');
        return;
      }

      developer.log('Image cropped successfully', name: 'Scanner');
      final success = await _controller.analyzeImage(croppedFile.path);
      if (success) {
        developer.log('Image analysis started', name: 'Scanner');
        await for (final capture in _controller.barcodes) {
          if (capture.barcodes.isNotEmpty) {
            final barcode = capture.barcodes.first;
            if (barcode.rawValue != null) {
              developer.log('QR code found in image', name: 'Scanner');
              await _processQRCode(barcode.rawValue!);
              break;
            }
          }
        }
      }
    } catch (e) {
      developer.log('Gallery scan failed: $e', name: 'Scanner', error: e);
      _showToast('Error scanning image');
    }
  }

  Future<void> _captureAndScan() async {
    if (_isProcessing) return;
    developer.log('Manual capture initiated', name: 'Scanner');

    try {
      setState(() => _isProcessing = true);
      developer.log('Waiting for QR capture...', name: 'Scanner');

      final BarcodeCapture capture = await _controller.barcodes.first;
      developer.log('Capture received', name: 'Scanner');

      if (capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        if (barcode.rawValue != null) {
          developer.log('QR code captured: ${barcode.rawValue}',
              name: 'Scanner');
          await _processQRCode(barcode.rawValue!);
        } else {
          developer.log('Captured QR has no data', name: 'Scanner');
          _showToast('QR code has no data');
        }
      } else {
        developer.log('No QR code found in capture', name: 'Scanner');
        _showToast('No QR code found');
      }
    } catch (e) {
      developer.log('Capture failed: $e', name: 'Scanner', error: e);
      _showToast('Error capturing image');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showToast(String message) {
    developer.log('Showing toast: $message', name: 'Scanner');
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  @override
  void dispose() {
    developer.log('Scanner screen disposed', name: 'Scanner');
    _detectionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permissions Required')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'Camera and storage permissions are required to scan tickets',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                  onPressed: openAppSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;

              final barcode = capture.barcodes.first;
              final code = barcode.rawValue;

              if (!_isProcessing && code != null && code.isNotEmpty) {
                setState(() => _isDetecting = true);
                developer.log('QR detected: $code', name: 'Scanner');
                _processQRCode(code);
              }
            },
          ),
          _buildScannerOverlay(),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'gallery',
                  onPressed: _isProcessing ? null : _scanFromGallery,
                  tooltip: 'Scan from Gallery',
                  child: const Icon(Icons.photo_library),
                ),
                if (_showCaptureButton && !_isProcessing)
                  FloatingActionButton.extended(
                    heroTag: 'capture',
                    onPressed: _captureAndScan,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('CAPTURE'),
                  ),
                FloatingActionButton(
                  heroTag: 'flash',
                  onPressed: _controller.toggleTorch,
                  tooltip: 'Toggle Flash',
                  child: ValueListenableBuilder(
                    valueListenable: _controller.torchState,
                    builder: (context, state, child) {
                      return Icon(
                        state == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isDetecting
                    ? Colors.green
                    : Theme.of(context).primaryColor.withOpacity(0.8),
                width: _isDetecting ? 4 : 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isDetecting
                ? const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 30),
          Text(
            _isDetecting
                ? 'QR Code Detected!'
                : 'Align QR code within the frame',
            style: TextStyle(
              color: _isDetecting ? Colors.green : Colors.white,
              fontSize: 16,
              fontWeight: _isDetecting ? FontWeight.bold : FontWeight.normal,
              shadows: const [
                Shadow(
                  blurRadius: 10,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
