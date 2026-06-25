class MikroTikConfig {
  final String ipAddress;
  final String username;
  final String password;
  final int port;

  MikroTikConfig({
    required this.ipAddress,
    this.username = 'admin',
    this.password = '',
    this.port = 8729,
  });

  Map<String, dynamic> toJson() => {
    'ipAddress': ipAddress,
    'username': username,
    'password': password,
    'port': port,
  };

  factory MikroTikConfig.fromJson(Map<String, dynamic> json) => MikroTikConfig(
    ipAddress: json['ipAddress'] ?? '10.0.0.1',
    username: json['username'] ?? 'admin',
    password: json['password'] ?? 'Adminmikro10001#',
    port: json['port'] ?? 8729,
  );
}

class VoucherInfo {
  final String voucherCode;
  final String username;
  final String password;
  final int uptimeSeconds;
  final int bytesIn;
  final int bytesOut;
  final bool isValid;

  VoucherInfo({
    required this.voucherCode,
    required this.username,
    required this.password,
    this.uptimeSeconds = 0,
    this.bytesIn = 0,
    this.bytesOut = 0,
    this.isValid = true,
  });

  String get remainingTime {
    final hours = uptimeSeconds ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    final seconds = uptimeSeconds % 60;
    if (hours > 0) return '$hours ساعة $minutes دقيقة';
    if (minutes > 0) return '$minutes دقيقة $seconds ثانية';
    return '$seconds ثانية';
  }

  String get dataUsed {
    final totalBytes = bytesIn + bytesOut;
    if (totalBytes > 1073741824) {
      return '${(totalBytes / 1073741824).toStringAsFixed(2)} GB';
    }
    if (totalBytes > 1048576) {
      return '${(totalBytes / 1048576).toStringAsFixed(2)} MB';
    }
    if (totalBytes > 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(2)} KB';
    }
    return '$totalBytes B';
  }
}

class SavedVoucher {
  final String voucher;
  final String username;
  final DateTime dateUsed;
  final bool isActive;

  SavedVoucher({
    required this.voucher,
    required this.username,
    required this.dateUsed,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() => {
    'voucher': voucher,
    'username': username,
    'dateUsed': dateUsed.toIso8601String(),
    'isActive': isActive,
  };

  factory SavedVoucher.fromJson(Map<String, dynamic> json) => SavedVoucher(
    voucher: json['voucher'] ?? '',
    username: json['username'] ?? '',
    dateUsed: DateTime.parse(json['dateUsed'] ?? DateTime.now().toIso8601String()),
    isActive: json['isActive'] ?? false,
  );
}

class CustomerServiceInfo {
  final String phoneNumber;
  final String whatsappNumber;
  final String website;

  CustomerServiceInfo({
    this.phoneNumber = '775710500',
    this.whatsappNumber = '775710500',
    this.website = '',
  });
}
