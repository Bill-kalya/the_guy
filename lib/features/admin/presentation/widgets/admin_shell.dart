import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminShell extends StatefulWidget {
  final Widget body;
  final String currentRoute;

  const AdminShell({
    super.key,
    required this.body,
    this.currentRoute = 'overview',
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late String _currentRoute;
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.currentRoute;
    ServicesBinding.instance.keyboard.addHandler(_handleKey);
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_handleKey);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.physicalKey == PhysicalKeyboardKey.keyK &&
        (HardwareKeyboard.instance.isControlPressed ||
         HardwareKeyboard.instance.isMetaPressed)) {
      setState(() => _searchOpen = !_searchOpen);
      if (_searchOpen) _searchFocus.requestFocus();
      return true;
    }
    if (event is KeyDownEvent && event.physicalKey == PhysicalKeyboardKey.escape) {
      if (_searchOpen) {
        setState(() => _searchOpen = false);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final shell = ResponsiveLayout(
      mobile: _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );

    return Stack(
      children: [
        shell,
        if (_searchOpen)
          GestureDetector(
            onTap: () => setState(() => _searchOpen = false),
            child: const AdminSearchOverlay(),
          ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Center'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: widget.body,
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: widget.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const Text(
              'THE GUY',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 24),
            _buildSearchTrigger(),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () => context.push('/admin/profile'),
              borderRadius: BorderRadius.circular(18),
              child: Consumer(
                builder: (context, ref, _) {
                  final user = ref.watch(authProvider).user;
                  return UserAvatar(
                    imageUrl: user?.avatar,
                    name: user?.name ?? 'Admin',
                    radius: 18,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTrigger() {
    return GestureDetector(
      onTap: () {
        setState(() => _searchOpen = true);
        _searchFocus.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              'Search...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '⌘K',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Image.asset('assets/icons/icon (2).png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _navItem('overview', 'Overview', Icons.dashboard_rounded, '/admin'),
                const SizedBox(height: 8),
                _sectionLabel('MANAGEMENT'),
                _navItem('users', 'Users', Icons.people_rounded, '/admin/users'),
                _navItem('providers', 'Providers', Icons.handyman_rounded, '/admin/providers'),
                _navItem('jobs', 'Jobs', Icons.work_rounded, '/admin/jobs'),
                const SizedBox(height: 8),
                _sectionLabel('OPERATIONS'),
                _navItem('finance', 'Finance', Icons.account_balance_rounded, '/admin/finance'),
                _navItem('safety', 'Trust & Safety', Icons.shield_rounded, '/admin/trust-safety'),
                const SizedBox(height: 8),
                _sectionLabel('SYSTEM'),
                _navItem('analytics', 'Analytics', Icons.analytics_rounded, '/admin/analytics'),
                _navItem('settings', 'Settings', Icons.settings_rounded, '/admin/settings'),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'Back to App',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _navItem(String route, String label, IconData icon, String path) {
    final isActive = route == _currentRoute;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _currentRoute = route);
            context.go(path);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isActive ? Colors.white : Colors.grey.shade500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade400,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF1A1A2E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1A1A2E)),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.transparent,
                    ),
                    child: Image.asset('assets/icons/icon (2).png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Admin Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem('overview', 'Overview', Icons.dashboard_rounded, '/admin'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('MANAGEMENT', style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.2)),
            ),
            _drawerItem('users', 'Users', Icons.people_rounded, '/admin/users'),
            _drawerItem('providers', 'Providers', Icons.handyman_rounded, '/admin/providers'),
            _drawerItem('jobs', 'Jobs', Icons.work_rounded, '/admin/jobs'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('OPERATIONS', style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.2)),
            ),
            _drawerItem('finance', 'Finance', Icons.account_balance_rounded, '/admin/finance'),
            _drawerItem('safety', 'Trust & Safety', Icons.shield_rounded, '/admin/trust-safety'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('SYSTEM', style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.2)),
            ),
            _drawerItem('analytics', 'Analytics', Icons.analytics_rounded, '/admin/analytics'),
            _drawerItem('settings', 'Settings', Icons.settings_rounded, '/admin/settings'),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(String route, String label, IconData icon, String path) {
    final isActive = route == _currentRoute;
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? Colors.white : Colors.grey.shade400,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey.shade400,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: Colors.white.withValues(alpha: 0.05),
      onTap: () {
        setState(() => _currentRoute = route);
        Navigator.pop(context);
        context.go(path);
      },
    );
  }
}

class AdminSearchOverlay extends StatefulWidget {
  const AdminSearchOverlay({super.key});

  @override
  State<AdminSearchOverlay> createState() => _AdminSearchOverlayState();
}

class _AdminSearchOverlayState extends State<AdminSearchOverlay> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 560,
          margin: const EdgeInsets.only(bottom: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search users, providers, bookings, payouts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (_query.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _searchHint(Icons.person, 'Search users by name or email'),
                      _searchHint(Icons.handyman, 'Search providers by name'),
                      _searchHint(Icons.work, 'Search bookings by ID'),
                      _searchHint(Icons.payment, 'Search payouts'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchHint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}
