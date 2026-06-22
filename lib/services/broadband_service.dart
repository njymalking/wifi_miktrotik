import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/broadband_config.dart';

class LocalBroadbandService {
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  StreamSubscription? _connectivitySubscription;
  BroadbandConfig? _currentConfig;

  BroadbandConfig? get currentConfig => _currentConfig;

  Future<BroadbandConfig> getCurrentStatus() async {
    final result = await _connectivity.checkConnectivity();
    String? wifiIp = await _networkInfo.getWifiIP();
    String? gateway = await _networkInfo.getWifiGatewayIP();

    String status;
    String interfaceName;

    switch (result) {
      case ConnectivityResult.wifi:
        status = 'connected';
        interfaceName = 'WiFi';
        break;
      case ConnectivityResult.mobile:
        status = 'connected';
        interfaceName = 'Mobile Data (4G/5G)';
        break;
      case ConnectivityResult.ethernet:
        status = 'connected';
        interfaceName = 'Ethernet';
        break;
      case ConnectivityResult.vpn:
        status = 'connected';
        interfaceName = 'VPN';
        break;
      case ConnectivityResult.bluetooth:
        status = 'connected';
        interfaceName = 'Bluetooth';
        break;
      case ConnectivityResult.other:
        status = 'connected';
        interfaceName = 'Other';
        break;
      default:
        status = 'disconnected';
        interfaceName = 'N/A';
    }

    _currentConfig = BroadbandConfig(
      interfaceName: interfaceName,
      status: status,
      localIp: wifiIp ?? '',
      remoteIp: gateway ?? '',
      isActive: status == 'connected',
    );

    return _currentConfig!;
  }

  void startMonitoring(Function(BroadbandConfig) onChanged) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((_) async {
      final config = await getCurrentStatus();
      onChanged(config);
    });
  }

  void stopMonitoring() {
    _connectivitySubscription?.cancel();
  }

  void dispose() {
    stopMonitoring();
  }
}
