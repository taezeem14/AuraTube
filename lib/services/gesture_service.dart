import 'package:flutter/services.dart';

/// Hardware accelerometer gesture controller (Shake-to-Skip & Flip-to-Pause)
class AuraGestureService {
  AuraGestureService._();

  static const MethodChannel _channel = MethodChannel('com.taezeem.auratube/gestures');

  static VoidCallback? _onShakeSkip;
  static VoidCallback? _onFlipPause;
  static bool _initialized = false;
  static bool _shakeEnabled = false;
  static bool _flipEnabled = false;

  static void init({
    VoidCallback? onShakeSkip,
    VoidCallback? onFlipPause,
  }) {
    _onShakeSkip = onShakeSkip;
    _onFlipPause = onFlipPause;

    if (!_initialized) {
      _channel.setMethodCallHandler(_handleNativeCall);
      _initialized = true;
    }
  }

  static Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onShakeSkip':
        _onShakeSkip?.call();
        break;
      case 'onFlipPause':
        _onFlipPause?.call();
        break;
    }
  }

  static Future<void> configure({
    required bool shakeToSkip,
    required bool flipToPause,
  }) async {
    _shakeEnabled = shakeToSkip;
    _flipEnabled = flipToPause;
    try {
      await _channel.invokeMethod('configureGestures', {
        'shakeToSkip': _shakeEnabled,
        'flipToPause': _flipEnabled,
      });
    } catch (_) {}
  }
}
