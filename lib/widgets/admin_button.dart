import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../pages/admin_dashboard_page.dart';

class AdminButton extends StatefulWidget {
  const AdminButton({super.key});

  @override
  State<AdminButton> createState() => _AdminButtonState();
}

class _AdminButtonState extends State<AdminButton> {
  final AdminService _adminService = AdminService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _adminService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (!_isAdmin) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      heroTag: "admin_fab",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardPage(),
          ),
        );
      },
      backgroundColor: Colors.red,
      child: const Icon(Icons.admin_panel_settings, color: Colors.white),
    );
  }
}