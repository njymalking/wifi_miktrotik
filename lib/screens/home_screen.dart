import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mikrotik_models.dart';
import '../models/broadband_config.dart';
import '../models/vpn_config.dart';
import '../services/mikrotik_api_service.dart';

class HomeScreen extends StatefulWidget {
  final String voucher;
  final String username;

  const HomeScreen({
    super.key,
    required this.voucher,
    required this.username,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // WiFi Hotspot
  bool _isWiFiConnected = true;
  int _hotspotSessionSeconds = 0;

  // Broadband
  BroadbandConfig? _broadbandConfig;
  bool _broadbandLoading = false;

  // VPN (على الميكروتيك)
  VpnConfig? _vpnConfig;
  bool _vpnLoading = false;

  // API
  MikroTikApiService? _api;

  String _activeSection = 'wifi';

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    _initApi();
  }

  Future<void> _initApi() async {
    final prefs = await SharedPreferences.getInstance();
    final config = MikroTikConfig(
      ipAddress: prefs.getString('mikrotik_ip') ?? '192.168.88.1',
      username: prefs.getString('mikrotik_user') ?? 'admin',
      password: prefs.getString('mikrotik_pass') ?? '',
    );
    _api = MikroTikApiService(config);
    await _api!.login();

    await _loadBroadbandStatus();
    await _loadVpnStatus();
    if (mounted) setState(() {});
  }

  void _startSessionTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _hotspotSessionSeconds++);
        _startSessionTimer();
      }
    });
  }

  // ========== دوال Broadband ==========

  Future<void> _loadBroadbandStatus() async {
    if (_api == null) return;
    setState(() => _broadbandLoading = true);
    try {
      final config = await _api!.getBroadbandStatus();
      if (mounted) setState(() => _broadbandConfig = config);
    } catch (_) {}
    if (mounted) setState(() => _broadbandLoading = false);
  }

  Future<void> _toggleBroadband() async {
    if (_api == null) return;
    final isActive = _broadbandConfig?.isActive ?? false;
    final success = isActive
        ? await _api!.disableBroadband()
        : await _api!.enableBroadband();

    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      await _loadBroadbandStatus();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (isActive ? 'تم قطع اتصال Broadband' : 'تم تشغيل Broadband')
              : 'فشلت العملية'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restartBroadband() async {
    if (_api == null) return;
    setState(() => _broadbandLoading = true);
    final success = await _api!.restartBroadband();
    await Future.delayed(const Duration(seconds: 3));
    await _loadBroadbandStatus();
    if (mounted) {
      setState(() => _broadbandLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم إعادة تشغيل Broadband' : 'فشلت إعادة التشغيل'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ========== دوال VPN ==========

  Future<void> _loadVpnStatus() async {
    if (_api == null) return;
    setState(() => _vpnLoading = true);
    try {
      final config = await _api!.getVpnStatus();
      if (mounted) setState(() => _vpnConfig = config);
    } catch (_) {}
    if (mounted) setState(() => _vpnLoading = false);
  }

  Future<void> _toggleVpn() async {
    if (_api == null) return;
    final isActive = _vpnConfig?.isConnected ?? false;
    final success = isActive
        ? await _api!.disableVpn()
        : await _api!.enableVpn();

    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      await _loadVpnStatus();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (isActive ? 'تم إيقاف VPN' : 'تم تشغيل VPN')
              : 'فشلت العملية'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restartVpn() async {
    if (_api == null) return;
    setState(() => _vpnLoading = true);
    final success = await _api!.restartVpn();
    await Future.delayed(const Duration(seconds: 3));
    await _loadVpnStatus();
    if (mounted) {
      setState(() => _vpnLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم إعادة تشغيل VPN' : 'فشلت إعادة التشغيل'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ========== دوال WiFi ==========

  Future<void> _disconnectWiFi() async {
    if (_api == null) return;
    final success = await _api!.disconnectHotspotUser(widget.username);
    if (success) setState(() => _isWiFiConnected = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم قطع اتصال WiFi' : 'فشل قطع الاتصال'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkBalance() async {
    if (_api == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم الاتصال بالميكروتيك بعد')),
      );
      return;
    }

    final info = await _api!.getVoucherInfo(widget.voucher);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رصيد الكرت'),
        content: info != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('الوقت المتبقي: '),
                      Expanded(
                        child: Text(info.remainingTime,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.storage, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('البيانات المستهلكة: '),
                      Expanded(
                        child: Text(info.dataUsed,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              )
            : const Text('تعذر الحصول على المعلومات'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_voucher');
    await prefs.remove('last_username');
    await prefs.remove('last_voucher_input');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  String get _hotspotSessionTime {
    final h = _hotspotSessionSeconds ~/ 3600;
    final m = (_hotspotSessionSeconds % 3600) ~/ 60;
    final s = _hotspotSessionSeconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getStatusColor(),
              Colors.white,
            ],
            stops: const [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // شريط التبويب العلوي
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    _buildTabButton('WiFi', 'wifi', Icons.wifi),
                    const SizedBox(width: 8),
                    _buildTabButton('Broadband', 'broadband', Icons.lan),
                    const SizedBox(width: 8),
                    _buildTabButton('VPN', 'vpn', Icons.vpn_lock),
                  ],
                ),
              ),

              // زر الخروج النهائي في AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                      label: const Text(
                        'خروج نهائي',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // المحتوى الرئيسي
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildActiveSection(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String section, IconData icon) {
    final isActive = _activeSection == section;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeSection = section),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: _getSectionColor(section), width: 2) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? _getSectionColor(section) : Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? _getSectionColor(section) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSectionColor(String section) {
    switch (section) {
      case 'wifi': return Colors.blue.shade700;
      case 'broadband': return Colors.orange.shade700;
      case 'vpn': return Colors.green.shade700;
      default: return Colors.blue;
    }
  }

  Color _getStatusColor() {
    switch (_activeSection) {
      case 'wifi': return _isWiFiConnected ? Colors.blue.shade700 : Colors.red.shade700;
      case 'broadband': return (_broadbandConfig?.isActive ?? false) ? Colors.orange.shade700 : Colors.red.shade700;
      case 'vpn': return (_vpnConfig?.isConnected ?? false) ? Colors.green.shade700 : Colors.red.shade700;
      default: return Colors.blue.shade700;
    }
  }

  Widget _buildActiveSection() {
    switch (_activeSection) {
      case 'wifi': return _buildWiFiSection();
      case 'broadband': return _buildBroadbandSection();
      case 'vpn': return _buildVpnSection();
      default: return _buildWiFiSection();
    }
  }

  Widget _buildWiFiSection() {
    return Column(
      children: [
        // أيقونة الحالة
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Icon(
            _isWiFiConnected ? Icons.wifi : Icons.wifi_off,
            size: 60,
            color: _isWiFiConnected ? Colors.blue : Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
          ),
          child: Text(
            _isWiFiConnected ? '🟢 متصل بـ WiFi' : '🔴 غير متصل',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),

        // معلومات الكرت
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.vpn_key, 'رقم الكرت', widget.voucher),
              const Divider(height: 20),
              _buildInfoRow(Icons.person, 'اسم المستخدم', widget.username),
              const Divider(height: 20),
              _buildInfoRow(Icons.timer, 'مدة الجلسة', _hotspotSessionTime),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // أزرار التحكم في WiFi
        Row(
          children: [
            Expanded(child: _buildActionButton(
              icon: Icons.power_settings_new, label: 'قطع WiFi',
              color: Colors.red, onTap: _disconnectWiFi,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(
              icon: Icons.speed, label: 'الرصيد',
              color: Colors.orange, onTap: _checkBalance,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(
              icon: Icons.logout, label: 'خروج',
              color: Colors.grey.shade700, onTap: _logout,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildBroadbandSection() {
    final isActive = _broadbandConfig?.isActive ?? false;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Icon(
            isActive ? Icons.lan : Icons.lan_outlined,
            size: 60,
            color: isActive ? Colors.orange : Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isActive ? Icons.check_circle : Icons.cancel, color: isActive ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Broadband متصل' : 'Broadband غير متصل',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_broadbandConfig != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.link, 'الواجهة', _broadbandConfig!.interfaceName),
                const Divider(height: 20),
                _buildInfoRow(Icons.wifi_tethering, 'IP محلي',
                    _broadbandConfig!.localIp.isEmpty ? '--' : _broadbandConfig!.localIp),
                const Divider(height: 20),
                _buildInfoRow(Icons.router, 'Gateway',
                    _broadbandConfig!.remoteIp.isEmpty ? '--' : _broadbandConfig!.remoteIp),
                if (_broadbandConfig!.uptimeSeconds > 0) ...[
                  const Divider(height: 20),
                  _buildInfoRow(Icons.timer, 'مدة التشغيل', _broadbandConfig!.uptimeFormatted),
                ],
                if (_broadbandConfig!.txBytes + _broadbandConfig!.rxBytes > 0) ...[
                  const Divider(height: 20),
                  _buildInfoRow(Icons.swap_horiz, 'حركة المرور', _broadbandConfig!.totalTraffic),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            icon: isActive ? Icons.power_settings_new : Icons.play_arrow,
            label: isActive ? 'قطع Broadband' : 'تشغيل Broadband',
            color: Colors.orange,
            onTap: _broadbandLoading ? null : _toggleBroadband,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionButton(
              icon: Icons.refresh, label: 'إعادة تشغيل',
              color: Colors.blue,
              onTap: _broadbandLoading ? null : _restartBroadband,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(
              icon: Icons.update, label: 'تحديث',
              color: Colors.grey.shade700,
              onTap: _loadBroadbandStatus,
            )),
          ],
        ),

        if (_broadbandLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            icon: Icons.logout,
            label: 'خروج نهائي',
            color: Colors.red.shade700,
            onTap: _logout,
          ),
        ),
      ],
    );
  }

Widget _buildVpnSection() {
    final isActive = _vpnConfig?.isConnected ?? false;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Icon(
            isActive ? Icons.vpn_lock : Icons.vpn_lock_outlined,
            size: 60,
            color: isActive ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isActive ? Icons.check_circle : Icons.cancel, color: isActive ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Text(
                isActive ? 'VPN متصل' : 'VPN غير متصل',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_vpnConfig != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.vpn_key, 'النوع', _vpnTypeName(_vpnConfig!.type)),
                const Divider(height: 20),
                _buildInfoRow(Icons.dns, 'السيرفر', _vpnConfig!.serverAddress),
                const Divider(height: 20),
                _buildInfoRow(Icons.wifi_tethering, 'IP محلي',
                    _vpnConfig!.localIp.isEmpty ? '--' : _vpnConfig!.localIp),
                if (_vpnConfig!.handshakeSeconds > 0) ...[
                  const Divider(height: 20),
                  _buildInfoRow(Icons.handshake, 'آخر مصافحة', '${_vpnConfig!.handshakeSeconds} ثانية'),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            icon: isActive ? Icons.power_settings_new : Icons.play_arrow,
            label: isActive ? 'إيقاف VPN' : 'تشغيل VPN',
            color: isActive ? Colors.red : Colors.green,
            onTap: _vpnLoading ? null : _toggleVpn,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionButton(
              icon: Icons.refresh, label: 'إعادة تشغيل',
              color: Colors.blue,
              onTap: _vpnLoading ? null : _restartVpn,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(
              icon: Icons.update, label: 'تحديث',
              color: Colors.grey.shade700,
              onTap: _loadVpnStatus,
            )),
          ],
        ),

        if (_vpnLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            icon: Icons.logout,
            label: 'خروج نهائي',
            color: Colors.red.shade700,
            onTap: _logout,
          ),
        ),
      ],
    );
  }

  String _vpnTypeName(VpnType type) {
    switch (type) {
      case VpnType.wireguard: return 'WireGuard';
      case VpnType.openvpn: return 'OpenVPN';
      case VpnType.ipsec: return 'IPSec';
      case VpnType.l2tp: return 'L2TP';
      case VpnType.pptp: return 'PPTP';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text('$label: ', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Expanded(
          child: Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: onTap == null ? Colors.grey : color, size: 28),
              const SizedBox(height: 6),
              Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onTap == null ? Colors.grey : color,
                ),
                textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
