import 'dart:async';
import 'package:flutter/services.dart';

class LocalVpnService {
  static const MethodChannel _channel = MethodChannel('vpn_service');

  bool _isConnected = false;
  Timer? _statusTimer;

  bool get isConnected => _isConnected;

  Future<bool> isVpnAvailable() async {
    try {
      final result = await _channel.invokeMethod('isVpnAvailable');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startLocalVpn(String configFilePath, {String name = 'MyVPN'}) async {
    try {
      final result = await _channel.invokeMethod('startVpn', {
        'configPath': configFilePath,
        'name': name,
      });
      _isConnected = result == true;
      _startMonitoring();
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<bool> stopLocalVpn() async {
    try {
      final result = await _channel.invokeMethod('stopVpn');
      _isConnected = !(result == true);
      _stopMonitoring();
      return !_isConnected;
    } catch (e) {
      return false;
    }
  }

  Future<bool> getVpnStatus() async {
    try {
      final result = await _channel.invokeMethod('getVpnStatus');
      _isConnected = result == 'CONNECTED';
      return _isConnected;
    } catch (e) {
      return false;
    }
  }

  void _startMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      getVpnStatus();
    });
  }

  void _stopMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  void dispose() {
    _stopMonitoring();
  }
}
