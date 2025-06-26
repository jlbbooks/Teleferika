import 'package:flutter/material.dart';
import 'package:teleferika/logger.dart';
import 'package:teleferika/licensing/feature_registry.dart';
import 'package:teleferika/licensing/licensed_features_loader.dart';
import 'licence_service.dart';

/// Widget that displays current licence status
class LicenceStatusWidget extends StatefulWidget {
  const LicenceStatusWidget({super.key});

  @override
  State<LicenceStatusWidget> createState() => _LicenceStatusWidgetState();
}

class _LicenceStatusWidgetState extends State<LicenceStatusWidget> {
  Map<String, dynamic>? _licenceStatus;
  bool _isLoading = true;
  List<String> _availableFeatures = [];

  @override
  void initState() {
    super.initState();
    _loadLicenceStatus();
  }

  Future<void> _loadLicenceStatus() async {
    try {
      final status = await LicenceService.instance.getLicenceStatus();
      final features = LicensedFeaturesLoader.licensedFeatures;
      
      if (mounted) {
        setState(() {
          _licenceStatus = status;
          _availableFeatures = features;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.severe('Error loading licence status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Loading licence status...'),
            ],
          ),
        ),
      );
    }

    if (_licenceStatus == null) {
      return _buildNoLicenceCard();
    }

    return _buildLicenceCard();
  }

  Widget _buildNoLicenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'No Licence Found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('This app is running in opensource mode.'),
            if (_availableFeatures.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Available Features:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: _availableFeatures.map((feature) => Chip(
                  label: Text(feature),
                  backgroundColor: Colors.green[100],
                )).toList(),
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _importLicence,
              icon: const Icon(Icons.file_upload),
              label: const Text('Import Licence'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenceCard() {
    final status = _licenceStatus!;
    final hasLicence = status['hasLicence'] as bool;
    final isValid = status['isValid'] as bool;
    final expiresSoon = status['expiresSoon'] as bool;
    final daysRemaining = status['daysRemaining'] as int;
    final email = status['email'] as String?;
    final features = (status['features'] as List<dynamic>?)?.cast<String>() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Licence Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (expiresSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Expires Soon',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (email != null) ...[
              Text('Email: $email'),
              const SizedBox(height: 4),
            ],
            Text('Status: ${isValid ? 'Valid' : 'Invalid'}'),
            const SizedBox(height: 4),
            Text('Days Remaining: $daysRemaining'),
            if (features.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Licensed Features:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: features.map((feature) => Chip(
                  label: Text(feature),
                  backgroundColor: Colors.blue[100],
                )).toList(),
              ),
            ],
            if (_availableFeatures.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Available Features:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: _availableFeatures.map((feature) => Chip(
                  label: Text(feature),
                  backgroundColor: Colors.green[100],
                )).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _importLicence,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _removeLicence,
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importLicence() async {
    try {
      final licence = await LicenceService.instance.importLicenceFromFile();
      if (licence != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Licence imported successfully: ${licence.email}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadLicenceStatus(); // Refresh the display
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import licence: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeLicence() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Licence'),
        content: const Text('Are you sure you want to remove the current licence?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await LicenceService.instance.removeLicence();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Licence removed successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadLicenceStatus(); // Refresh the display
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove licence: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 