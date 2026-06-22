class BroadbandConfig {
  final String interfaceName;
  final String status;
  final String localIp;
  final String remoteIp;
  final int uptimeSeconds;
  final int txBytes;
  final int rxBytes;
  final String user;
  final bool isActive;

  BroadbandConfig({
    required this.interfaceName,
    this.status = 'disconnected',
    this.localIp = '',
    this.remoteIp = '',
    this.uptimeSeconds = 0,
    this.txBytes = 0,
    this.rxBytes = 0,
    this.user = '',
    this.isActive = false,
  });

  factory BroadbandConfig.fromMikroTikJson(Map<String, dynamic> json) {
    return BroadbandConfig(
      interfaceName: json['name'] ?? '',
      status: json['status'] ?? 'disconnected',
      localIp: json['local-address'] ?? '',
      remoteIp: json['remote-address'] ?? '',
      uptimeSeconds: _parseUptime(json['uptime'] ?? '0s'),
      txBytes: int.tryParse(json['tx-byte'] ?? '0') ?? 0,
      rxBytes: int.tryParse(json['rx-byte'] ?? '0') ?? 0,
      user: json['user'] ?? '',
      isActive: json['status'] == 'connected',
    );
  }

  static int _parseUptime(String uptime) {
    int seconds = 0;
    final regex = RegExp(r'(\d+)([dhms])');
    for (final match in regex.allMatches(uptime)) {
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

  String get uptimeFormatted {
    final h = uptimeSeconds ~/ 3600;
    final m = (uptimeSeconds % 3600) ~/ 60;
    final s = uptimeSeconds % 60;
    if (h > 0) return '$h ساعة $m دقيقة $s ثانية';
    if (m > 0) return '$m دقيقة $s ثانية';
    return '$s ثانية';
  }

  String get totalTraffic {
    final total = txBytes + rxBytes;
    if (total > 1073741824) return '${(total / 1073741824).toStringAsFixed(2)} GB';
    if (total > 1048576) return '${(total / 1048576).toStringAsFixed(2)} MB';
    if (total > 1024) return '${(total / 1024).toStringAsFixed(2)} KB';
    return '$total B';
  }

  Map<String, dynamic> toJson() => {
    'interfaceName': interfaceName,
    'status': status,
    'localIp': localIp,
    'remoteIp': remoteIp,
    'uptimeSeconds': uptimeSeconds,
    'txBytes': txBytes,
    'rxBytes': rxBytes,
    'user': user,
    'isActive': isActive,
  };
}
