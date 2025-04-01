import 'package:flutter/material.dart';
import '../services/logging_service.dart';

class DashboardScreen extends StatelessWidget {
  static final LoggingService _logger = LoggingService();

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: [
          _buildDashboardCard(
            context,
            'Products',
            Icons.inventory,
            () => _navigateToScreen(context, '/catalog', 'Products'),
          ),
          _buildDashboardCard(
            context,
            'New Bill',
            Icons.receipt_long,
            () => _navigateToScreen(context, '/billing', 'New Bill'),
          ),
          _buildDashboardCard(
            context,
            'History',
            Icons.history,
            () => _navigateToScreen(context, '/history', 'History'),
          ),
          _buildDashboardCard(
            context,
            'Settings',
            Icons.settings,
            () => _navigateToScreen(context, '/settings', 'Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToScreen(BuildContext context, String route, String screenName) async {
    try {
      await Navigator.pushNamed(context, route);
      await _logger.debug('Navigated to $screenName screen');
    } catch (e, stackTrace) {
      await _logger.error('Failed to navigate to $screenName screen', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to $screenName: $e')),
        );
      }
    }
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48.0,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
