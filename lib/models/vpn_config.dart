enum VpnType { wireguard, openvpn, ipsec, l2tp, pptp }

class VpnConfig {
  final String name;
  final VpnType type;
  final String serverAddress;
  final int serverPort;
  final String localIp;
  final String privateKey;
  final String publicKey;
  final String presharedKey;
  final List<String> dnsServers;
  final List<String> allowedIps;
  final bool isConnected;
  final int handshakeSeconds;

  VpnConfig({
    required this.name,
    this.type = VpnType.wireguard,
    required this.serverAddress,
    this.serverPort = 51820,
    this.localIp = '',
    this.privateKey = '',
    this.publicKey = '',
    this.presharedKey = '',
    this.dnsServers = const ['8.8.8.8', '1.1.1.1'],
    this.allowedIps = const ['0.0.0.0/0'],
    this.isConnected = false,
    this.handshakeSeconds = 0,
  });

  factory VpnConfig.fromMikroTikJson(Map<String, dynamic> json) {
    return VpnConfig(
      name: json['name'] ?? 'VPN',
      type: _parseType(json['type'] ?? 'wireguard'),
      serverAddress: json['connect-to'] ?? '',
      serverPort: int.tryParse(json['port'] ?? '51820') ?? 51820,
      localIp: json['local-address'] ?? '',
      publicKey: json['public-key'] ?? '',
      isConnected: json['running'] == 'true',
      handshakeSeconds: _parseHandshake(json['last-handshake'] ?? '0'),
    );
  }

  static VpnType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'wireguard': return VpnType.wireguard;
      case 'openvpn': return VpnType.openvpn;
      case 'ipsec': return VpnType.ipsec;
      case 'l2tp': return VpnType.l2tp;
      case 'pptp': return VpnType.pptp;
      default: return VpnType.wireguard;
    }
  }

  static int _parseHandshake(String handshake) {
    if (handshake.isEmpty || handshake == '0') return 0;
    int seconds = 0;
    final regex = RegExp(r'(\d+)([ms])');
    for (final match in regex.allMatches(handshake)) {
      final value = int.parse(match.group(1)!);
      if (match.group(2) == 'm') seconds += value * 60;
      else seconds += value;
    }
    return seconds;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'serverAddress': serverAddress,
    'serverPort': serverPort,
    'localIp': localIp,
    'publicKey': publicKey,
    'isConnected': isConnected,
  };
}
