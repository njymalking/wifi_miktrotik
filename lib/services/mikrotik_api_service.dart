import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mikrotik_models.dart';
import '../models/broadband_config.dart';
import '../models/vpn_config.dart';

class MikroTikApiService {
  final MikroTikConfig config;
  String? _authCookie;

  MikroTikApiService(this.config);

  String get _baseUrl => 'https://${config.ipAddress}:${config.port}/rest';
  String get _baseUrlHttp => 'http://${config.ipAddress}:${config.port}/rest';

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ========== المصادقة الأساسية ==========

  Future<bool> login() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: _headers,
        body: jsonEncode({
          'name': config.username,
          'password': config.password,
        }),
      );
      if (response.statusCode == 200) {
        final cookies = response.headers['set-cookie'];
        if (cookies != null) _authCookie = cookies.split(';')[0];
        return true;
      }
      return false;
    } catch (e) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrlHttp/login'),
          headers: _headers,
          body: jsonEncode({
            'name': config.username,
            'password': config.password,
          }),
        );
        if (response.statusCode == 200) {
          final cookies = response.headers['set-cookie'];
          if (cookies != null) _authCookie = cookies.split(';')[0];
          return true;
        }
      } catch (_) {}
      return false;
    }
  }

  Map<String, String> get _authHeaders => {
    ..._headers,
    if (_authCookie != null) 'cookie': _authCookie!,
  };

  // ========== دوال WiFi Hotspot ==========

  Future<bool> authenticateVoucher(String voucher, String macAddress) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final users = jsonDecode(response.body) as List;
        final user = users.firstWhere(
          (u) => u['name'] == voucher || u['password'] == voucher,
          orElse: () => null,
        );
        if (user != null) {
          await http.post(
            Uri.parse('$_baseUrl/ip/hotspot/user/${user['.id']}/enable'),
            headers: _authHeaders,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<VoucherInfo?> getVoucherInfo(String voucher) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final users = jsonDecode(response.body) as List;
        final user = users.firstWhere(
          (u) => u['name'] == voucher || u['password'] == voucher,
          orElse: () => null,
        );
        if (user != null) {
          return VoucherInfo(
            voucherCode: voucher,
            username: user['name'] ?? voucher,
            password: user['password'] ?? '',
            uptimeSeconds: int.tryParse(user['uptime'] ?? '0') ?? 0,
            bytesIn: int.tryParse(user['bytes-in'] ?? '0') ?? 0,
            bytesOut: int.tryParse(user['bytes-out'] ?? '0') ?? 0,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> disconnectHotspotUser(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/active'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final sessions = jsonDecode(response.body) as List;
        final session = sessions.firstWhere(
          (s) => s['user'] == username,
          orElse: () => null,
        );
        if (session != null) {
          await http.post(
            Uri.parse('$_baseUrl/ip/hotspot/active/${session['.id']}/remove'),
            headers: _authHeaders,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ========== دوال Broadband ==========

  Future<BroadbandConfig?> getBroadbandStatus({String interfaceName = 'pppoe-out1'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/interface/pppoe-client'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final interfaces = jsonDecode(response.body) as List;
        final iface = interfaces.firstWhere(
          (i) => i['name'] == interfaceName,
          orElse: () => null,
        );
        if (iface != null) {
          return BroadbandConfig.fromMikroTikJson(iface);
        }
        final response2 = await http.get(
          Uri.parse('$_baseUrl/interface'),
          headers: _authHeaders,
        );
        if (response2.statusCode == 200) {
          final allIfaces = jsonDecode(response2.body) as List;
          final wan = allIfaces.firstWhere(
            (i) {
              final name = (i['name'] ?? '').toLowerCase();
              return name.contains('wan') || name == 'ether1' || name.contains('pppoe');
            },
            orElse: () => null,
          );
          if (wan != null) {
            return BroadbandConfig(
              interfaceName: wan['name'] ?? '',
              status: wan['running'] == 'true' ? 'connected' : 'disconnected',
              localIp: wan['address'] ?? '',
              isActive: wan['running'] == 'true',
            );
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> enableBroadband({String interfaceName = 'pppoe-out1'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/interface/pppoe-client'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final interfaces = jsonDecode(response.body) as List;
        final iface = interfaces.firstWhere(
          (i) => i['name'] == interfaceName,
          orElse: () => null,
        );
        if (iface != null) {
          if (iface['disabled'] == 'true') {
            await http.patch(
              Uri.parse('$_baseUrl/interface/pppoe-client/${iface['.id']}'),
              headers: _authHeaders,
              body: jsonEncode({'disabled': false}),
            );
            return true;
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disableBroadband({String interfaceName = 'pppoe-out1'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/interface/pppoe-client'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final interfaces = jsonDecode(response.body) as List;
        final iface = interfaces.firstWhere(
          (i) => i['name'] == interfaceName,
          orElse: () => null,
        );
        if (iface != null) {
          await http.patch(
            Uri.parse('$_baseUrl/interface/pppoe-client/${iface['.id']}'),
            headers: _authHeaders,
            body: jsonEncode({'disabled': true}),
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restartBroadband({String interfaceName = 'pppoe-out1'}) async {
    await disableBroadband(interfaceName: interfaceName);
    await Future.delayed(const Duration(seconds: 3));
    return await enableBroadband(interfaceName: interfaceName);
  }

  // ========== دوال VPN ==========

  Future<VpnConfig?> getVpnStatus({String vpnName = 'wg1'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/interface/wireguard'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final interfaces = jsonDecode(response.body) as List;
        final wg = interfaces.firstWhere(
          (i) => i['name'] == vpnName,
          orElse: () => null,
        );
        if (wg != null) {
          final peersResponse = await http.get(
            Uri.parse('$_baseUrl/interface/wireguard/peers'),
            headers: _authHeaders,
          );

          VpnConfig config = VpnConfig(
            name: wg['name'] ?? vpnName,
            type: VpnType.wireguard,
            serverAddress: wg['listen-port'] ?? '51820',
            serverPort: int.tryParse(wg['listen-port'] ?? '51820') ?? 51820,
            localIp: _extractIpFromAddress(wg['address'] ?? ''),
            publicKey: wg['public-key'] ?? '',
            isConnected: wg['running'] == 'true',
          );

          if (peersResponse.statusCode == 200) {
            final peers = jsonDecode(peersResponse.body) as List;
            if (peers.isNotEmpty) {
              config = VpnConfig(
                name: config.name,
                type: VpnType.wireguard,
                serverAddress: peers[0]['endpoint-address'] ?? config.serverAddress,
                serverPort: int.tryParse(peers[0]['endpoint-port'] ?? '${config.serverPort}') ?? config.serverPort,
                localIp: config.localIp,
                publicKey: peers[0]['public-key'] ?? config.publicKey,
                isConnected: config.isConnected,
                handshakeSeconds: _parseHandshakeDuration(peers[0]['last-handshake'] ?? ''),
              );
            }
          }
          return config;
        }
      }

      final ovpnResponse = await http.get(
        Uri.parse('$_baseUrl/interface/ovpn-client'),
        headers: _authHeaders,
      );
      if (ovpnResponse.statusCode == 200) {
        final ovpns = jsonDecode(ovpnResponse.body) as List;
        if (ovpns.isNotEmpty) {
          return VpnConfig.fromMikroTikJson(ovpns.first);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> enableVpn({String vpnName = 'wg1'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/interface/wireguard'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final interfaces = jsonDecode(response.body) as List;
        final wg = interfaces.firstWhere(
          (i) => i['name'] == vpnName,
          orElse: () => null,
        );
        if (wg != null) {
          if (wg['disabled'] == 'true') {
            await http.patch(
              Uri.parse('$_baseUrl/interface/wireguard/${wg['.id']}'),
              headers: _authHeaders,
              body: jsonEncode({'disabled': false}),
            );
          }
          final peersResponse = await http.get(
            Uri.parse('$_baseUrl/interface/wireguard/peers'),
            headers: _authHeaders,
          );
          if (peersResponse.statusCode == 200) {
            final peers = jsonDecode(peersResponse.body) as List;
            for (final peer in peers) {
              if (peer['disabled'] == 'true') {
                await http.patch(
                  Uri.parse('$_baseUrl/interface/wireguard/peers/${peer['.id']}'),
                  headers: _authHeaders,
                  body: jsonEncode({'disabled': false}),
                );
              }
            }
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disableVpn({String vpnName = 'wg1'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/interface/wireguard'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final interfaces = jsonDecode(response.body) as List;
        final wg = interfaces.firstWhere(
          (i) => i['name'] == vpnName,
          orElse: () => null,
        );
        if (wg != null) {
          await http.patch(
            Uri.parse('$_baseUrl/interface/wireguard/${wg['.id']}'),
            headers: _authHeaders,
            body: jsonEncode({'disabled': true}),
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restartVpn({String vpnName = 'wg1'}) async {
    await disableVpn(vpnName: vpnName);
    await Future.delayed(const Duration(seconds: 2));
    return await enableVpn(vpnName: vpnName);
  }

  // ========== دوال مساعدة ==========

  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/system/resource'),
        headers: _authHeaders,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _authCookie = null;
  }

  String _extractIpFromAddress(String address) {
    if (address.contains('/')) {
      return address.split('/')[0];
    }
    return address;
  }

  int _parseHandshakeDuration(String handshake) {
    if (handshake.isEmpty) return 0;
    final regex = RegExp(r'(\d+)([dhms])');
    int seconds = 0;
    for (final match in regex.allMatches(handshake)) {
      final value = int.parse(match.group(1)!);
      switch (match.group(2)) {
        case 'd': seconds += value * 86400; break;
        case 'h': seconds += value * 3600; break;
        case 'm': seconds += value * 60; break;
        case 's': seconds += value; break;
      }
    }
    return seconds;
  }
}
