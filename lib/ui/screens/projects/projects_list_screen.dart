import 'dart:async'; // For Timer
// For jsonDecode

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/core/app_config.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/licensing/licence_service.dart';
import 'package:teleferika/licensing/licence_model.dart' as lm;
import 'package:teleferika/licensing/licence_model.dart' show Licence;
import 'package:teleferika/licensing/licensed_features_loader.dart';
import 'package:teleferika/licensing/device_fingerprint.dart';
import 'package:teleferika/licensing/licence_request_service.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';

import 'project_tabbed_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  final String? appVersion;

  const ProjectsListScreen({super.key, this.appVersion});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen>
    with StatusMixin {
  final Logger logger = Logger('ProjectsListScreen');
  bool _isSelectionMode = false;
  final Set<String> _selectedProjectIdsForMultiSelect = {};
  String? _highlightedProjectId;

  // Keep a local copy of projects to manipulate for instant UI updates
  List<ProjectModel> _currentProjects = [];

  final LicenceService _licenceService =
      LicenceService.instance; // Get LicenceService instance
  final LicenceRequestService _licenceRequestService = LicenceRequestService();
  lm.Licence? _activeLicence; // To hold the loaded licence status

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadActiveLicence();
  }

  Future<void> _loadActiveLicence() async {
    try {
      logger.info('Loading active license...');

      // Ensure the service is initialized first
      await _licenceService.initialize();
      logger.info('License service initialized');

      // Now load the license
      _activeLicence = await _licenceService.currentLicence;
      logger.info('License loaded: ${_activeLicence?.email ?? 'null'}');
      logger.info('License valid: ${_activeLicence?.isValid ?? 'null'}');

      // Check with server if license exists and requires validation
      if (_activeLicence != null &&
          Licence.requiresServerValidation(_activeLicence!.status)) {
        try {
          logger.info('Checking license status with server...');
          final updatedLicence = await _licenceRequestService
              .checkLicenceStatus(_activeLicence!);

          // Save updated license if status changed
          if (updatedLicence.status != _activeLicence!.status) {
            await _licenceService.saveLicence(updatedLicence);
            _activeLicence = updatedLicence;
            logger.info('License status updated: ${updatedLicence.status}');

            // Show status message to user
            if (mounted) {
              final statusMessage = _licenceRequestService.getStatusMessage(
                updatedLicence.status,
              );
              if (_licenceRequestService.needsAdminAction(
                updatedLicence.status,
              )) {
                showInfoStatus(
                  '$statusMessage - Please wait for admin approval.',
                );
              } else if (_licenceRequestService.isPermanentlyInvalid(
                updatedLicence.status,
              )) {
                showErrorStatus('$statusMessage - Please contact support.');
              } else if (updatedLicence.status == Licence.statusActive) {
                showSuccessStatus(statusMessage);
              }
            }
          }
        } catch (e) {
          // Continue with local license if server check fails
          logger.warning('Server check failed, using local license: $e');
        }
      }

      if (mounted) {
        setState(() {
          // Trigger a rebuild to update the UI with license status
        });
      }
    } catch (e, stackTrace) {
      logger.severe('Error loading active license', e, stackTrace);
      if (mounted) {
        setState(() {
          _activeLicence = null;
        });
      }
    }
  }

  void _showLicenceInfoDialog() {
    // Reload to ensure we have the latest
    _licenceService.currentLicence.then((licence) async {
      if (!mounted) return;

      // Check with server if license exists and requires validation
      if (licence != null && Licence.requiresServerValidation(licence.status)) {
        try {
          showInfoStatus('Checking license status with server...');
          final updatedLicence = await _licenceRequestService
              .checkLicenceStatus(licence);

          // Save updated license if status changed
          if (updatedLicence.status != licence.status) {
            await _licenceService.saveLicence(updatedLicence);
            licence = updatedLicence;
          }
        } catch (e) {
          // Continue with local license if server check fails
          logger.warning('Server check failed, using local license: $e');
        }
      }

      setState(() {
        _activeLicence = licence;
      });

      String title =
          S.of(context)?.license_information_title ?? 'Licence Information';
      List<Widget> actions = [
        TextButton(
          child: Text(S.of(context)?.close_button ?? 'Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];

      // Add version info if available
      String versionInfo = '';
      if (widget.appVersion != null && widget.appVersion!.isNotEmpty) {
        versionInfo =
            S.of(context)?.app_version_label(widget.appVersion!) ??
            'App Version: ${widget.appVersion}';
      }

      Widget content;
      if (_activeLicence != null) {
        // Enhanced license information display
        content = _buildLicenceInfo(_activeLicence!, versionInfo);

                          // Always show refresh status option for any license
        actions.insert(
          0,
          TextButton(
            child: Text('Refresh Status'),
            onPressed: () async {
              // Show loading indicator in dialog
              showInfoStatus('Checking license status with server...');
              
              try {
                // Check with server
                final updatedLicence = await _licenceRequestService
                    .checkLicenceStatus(_activeLicence!);

                // Save updated license if status changed
                if (updatedLicence.status != _activeLicence!.status) {
                  await _licenceService.saveLicence(updatedLicence);
                  _activeLicence = updatedLicence;
                  logger.info('License status updated: ${updatedLicence.status}');

                  // Show status message to user
                  final statusMessage = _licenceRequestService.getStatusMessage(
                    updatedLicence.status,
                  );
                  if (_licenceRequestService.needsAdminAction(
                    updatedLicence.status,
                  )) {
                    showInfoStatus(
                      '$statusMessage - Please wait for admin approval.',
                    );
                  } else if (_licenceRequestService.isPermanentlyInvalid(
                    updatedLicence.status,
                  )) {
                    showErrorStatus('$statusMessage - Please contact support.');
                  } else if (updatedLicence.status == Licence.statusActive) {
                    showSuccessStatus(statusMessage);
                  }
                } else {
                  showInfoStatus('License status unchanged: ${updatedLicence.status}');
                }

                // Update the dialog content
                if (mounted) {
                  Navigator.of(context).pop();
                  _showLicenceInfoDialog(); // Reopen dialog with updated info
                }
              } catch (e) {
                // Continue with local license if server check fails
                logger.warning('Server check failed, using local license: $e');
                showErrorStatus('Failed to check with server: $e');
                
                // Still update the dialog to show current local status
                if (mounted) {
                  Navigator.of(context).pop();
                  _showLicenceInfoDialog();
                }
              }
            },
          ),
        );

        // Add action buttons based on license status
        if (_activeLicence!.status == lm.Licence.statusRequested) {
          // For requested licenses, show request new option
          actions.insert(
            1,
            TextButton(
              child: Text('Request New License'),
              onPressed: () {
                Navigator.of(context).pop();
                _requestLicence();
              },
            ),
          );
        } else if (!_activeLicence!.isValid) {
          // For invalid licenses, show import option
          actions.insert(
            0,
            TextButton(
              child: Text(
                S.of(context)?.import_new_licence ?? 'Import New Licence',
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _handleImportLicence();
              },
            ),
          );
        }
      } else {
        // No license found
        content = _buildNoLicenceInfo(versionInfo);
        actions.insert(
          0,
          TextButton(
            child: Text(S.of(context)?.import_licence ?? 'Import Licence'),
            onPressed: () {
              Navigator.of(context).pop();
              _handleImportLicence();
            },
          ),
        );
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  _activeLicence != null &&
                          _activeLicence!.status == lm.Licence.statusRequested
                      ? Icons.pending
                      : (_activeLicence != null && _activeLicence!.isValid
                            ? Icons.verified_user
                            : Icons.security),
                  color:
                      _activeLicence != null &&
                          _activeLicence!.status == lm.Licence.statusRequested
                      ? Colors.blue
                      : (_activeLicence != null && _activeLicence!.isValid
                            ? Colors.green
                            : (_activeLicence != null &&
                                      !_activeLicence!.isValid
                                  ? Colors.red
                                  : Colors.grey)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            content: SingleChildScrollView(child: content),
            actions: actions,
          );
        },
      );
    });
  }

  Widget _buildLicenceInfo(lm.Licence licence, String versionInfo) {
    final isRequested = licence.status == lm.Licence.statusRequested;
    final isExpired = !licence.isValid && !isRequested;
    final isExpiringSoon = licence.expiresSoon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isRequested
                ? Colors.blue.shade50
                : (isExpired
                      ? Colors.red.shade50
                      : (isExpiringSoon
                            ? Colors.orange.shade50
                            : Colors.green.shade50)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isRequested
                  ? Colors.blue.shade200
                  : (isExpired
                        ? Colors.red.shade200
                        : (isExpiringSoon
                              ? Colors.orange.shade200
                              : Colors.green.shade200)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isRequested
                        ? Icons.pending
                        : (isExpired
                              ? Icons.error
                              : (isExpiringSoon
                                    ? Icons.warning
                                    : Icons.check_circle)),
                    color: isRequested
                        ? Colors.blue
                        : (isExpired
                              ? Colors.red
                              : (isExpiringSoon
                                    ? Colors.orange
                                    : Colors.green)),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRequested
                        ? 'License Requested'
                        : (isExpired
                              ? 'License Expired'
                              : (isExpiringSoon
                                    ? 'License Expiring Soon'
                                    : 'License Active')),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isRequested
                          ? Colors.blue
                          : (isExpired
                                ? Colors.red
                                : (isExpiringSoon
                                      ? Colors.orange
                                      : Colors.green)),
                    ),
                  ),
                ],
              ),
              if (isRequested) ...[
                const SizedBox(height: 4),
                Text(
                  'Your license request is pending approval. You will be notified when it is approved or denied.',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ] else if (isExpired || isExpiringSoon) ...[
                const SizedBox(height: 4),
                Text(
                  isExpired
                      ? 'This license has expired and needs to be renewed.'
                      : 'This license will expire soon. Consider renewing.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // License details section
        _buildInfoSection('License Details', Icons.info_outline, [
          _buildInfoRow('Email', licence.email),
          _buildInfoRow('Customer ID', licence.customerId),
          _buildInfoRow('Status', licence.status),
          _buildInfoRow(
            'Issued',
            DateFormat.yMMMd().add_Hm().format(licence.issuedAt.toLocal()),
          ),
          _buildInfoRow(
            'Valid Until',
            DateFormat.yMMMd().add_Hm().format(licence.validUntil.toLocal()),
          ),
          if (!isRequested)
            _buildInfoRow('Days Remaining', '${licence.daysRemaining} days'),
          _buildInfoRow('Max Devices', '${licence.maxDevices}'),
          _buildInfoRow('Version', licence.version),
        ]),

        const SizedBox(height: 16),

        // Features section
        _buildInfoSection(
          isRequested ? 'Requested Features' : 'Available Features',
          Icons.star,
          [
            if (isRequested) ...[
              Text(
                'Features will be available once your license is approved:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
            ],
            ...licence.features.map((feature) => _buildFeatureRow(feature)),
          ],
        ),

        const SizedBox(height: 16),

        // Technical details section
        _buildInfoSection('Technical Details', Icons.security, [
          _buildInfoRow('Algorithm', licence.algorithm),
          _buildInfoRow(
            'Device Fingerprint',
            '${licence.deviceFingerprint.substring(0, 16)}...',
          ),
          _buildInfoRow(
            'Data Hash',
            '${licence.generateDataHash().substring(0, 16)}...',
          ),
        ]),

        if (versionInfo.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInfoSection('App Information', Icons.app_settings_alt, [
            _buildInfoRow('App Version', versionInfo),
          ]),
        ],
      ],
    );
  }

  Widget _buildNoLicenceInfo(String versionInfo) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No License Found',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'No active license found. Please import a license file to unlock premium features.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (versionInfo.isNotEmpty) ...[
          _buildInfoSection('App Information', Icons.app_settings_alt, [
            _buildInfoRow('App Version', versionInfo),
          ]),
        ],
      ],
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(feature, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _handleImportLicence() async {
    try {
      final importedLicence = await _licenceService.importLicenceFromFile();
      if (mounted) {
        if (importedLicence != null) {
          setState(() {
            _activeLicence =
                importedLicence as lm.Licence?; // Update local state
          });
          showSuccessStatus(
            S
                    .of(context)
                    ?.licence_imported_successfully(importedLicence.email) ??
                'Licence for ${importedLicence.email} imported successfully!',
          );
          _showLicenceInfoDialog(); // Show updated info
        } else {
          // User cancelled or import failed without throwing a specific format exception handled below
          showInfoStatus(
            S.of(context)?.licence_import_cancelled ??
                'Licence import cancelled or failed.',
          );
        }
      }
    } on FormatException catch (e) {
      // Catch specific format exception
      if (mounted) {
        showErrorStatus(e.message);
      }
    } catch (e) {
      // Catch general exceptions from importLicenceFromFile
      if (mounted) {
        showErrorStatus(
          S.of(context)?.error_importing_licence(e.toString()) ??
              'Error importing licence: $e',
        );
      }
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await context.projectState.getAllProjects();
      if (mounted) {
        setState(() {
          _currentProjects = projects;
        });
        if (AppConfig.cleanupOrphanedImageFiles) {
          await _cleanupOrphanedPointPhotoDirs(projects);
        }
      }
    } catch (e, stackTrace) {
      logger.severe('Error loading projects', e, stackTrace);
      if (mounted) {
        setState(() {
          _currentProjects = []; // Clear current projects on error
        });
      }
    }
  }

  // This can be used if you only want to refresh data from DB
  Future<void> _refreshProjectsListFromDb() async {
    try {
      final projects = await context.projectState.getAllProjects();
      if (mounted) {
        setState(() {
          _currentProjects = projects;
        });
        if (AppConfig.cleanupOrphanedImageFiles) {
          await _cleanupOrphanedPointPhotoDirs(projects);
        }
      }
    } catch (e, stackTrace) {
      logger.severe('Error refreshing projects', e, stackTrace);
      if (mounted) {
        // No need to update state on error
      }
    }
  }

  /// Delete all point photo folders that do not correspond to any existing point in the DB
  Future<void> _cleanupOrphanedPointPhotoDirs(
    List<ProjectModel> projects,
  ) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final pointPhotosDir = Directory(p.join(appDocDir.path, 'point_photos'));
      if (!await pointPhotosDir.exists()) return;

      // Collect all valid point IDs from all projects
      final validPointIds = <String>{};
      for (final project in projects) {
        for (final point in project.points) {
          validPointIds.add(point.id);
        }
      }

      // For each directory in point_photos, delete if not in validPointIds
      final pointDirs = pointPhotosDir.listSync().whereType<Directory>();
      for (final dir in pointDirs) {
        final dirName = p.basename(dir.path);
        if (!validPointIds.contains(dirName)) {
          try {
            await dir.delete(recursive: true);
            logger.info('Deleted orphaned point photo directory: ${dir.path}');
          } catch (e) {
            logger.warning(
              'Failed to delete orphaned point photo directory: ${dir.path} ($e)',
            );
          }
        }
      }
    } catch (e, stackTrace) {
      logger.warning(
        'Error during orphaned point photo directory cleanup: $e',
        e,
        stackTrace,
      );
    }
  }

  void _toggleSelection(String projectId) {
    setState(() {
      _highlightedProjectId =
          null; // Clear highlight when entering multi-selection
      if (_selectedProjectIdsForMultiSelect.contains(projectId)) {
        _selectedProjectIdsForMultiSelect.remove(projectId);
        if (_selectedProjectIdsForMultiSelect.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedProjectIdsForMultiSelect.add(projectId);
      }
    });
  }

  void _onItemLongPress(ProjectModel project) {
    setState(() {
      _isSelectionMode = true;
      _highlightedProjectId = null; // Clear single highlight
      _toggleSelection(project.id);
    });
  }

  void _onItemTap(ProjectModel project) async {
    if (_isSelectionMode) {
      _toggleSelection(project.id);
    } else {
      logger.info("Navigating to details for project: ${project.name}");
      // Clear any previous highlight before navigating
      setState(() {
        _highlightedProjectId = null;
      });

      // Clear global state to ensure fresh data
      context.projectState.clearProject();

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectTabbedScreen(project: project, isNew: false),
        ),
      );
      _handleNavigationResult(result);
    }
  }

  void _handleNavigationResult(dynamic result) {
    if (result is Map<String, dynamic>) {
      final String? action = result['action'];
      final String? id = result['id'];

      if (id == null) {
        // If ID is null, we probably don't need to do anything specific,
        // or just refresh if any background state might have changed.
        // For now, let's assume a full refresh might be safest if something non-specific happened.
        // _refreshProjectsListFromDb();
        logger.info(
          "ProjectTabbedScreen returned with no specific ID or action.",
        );
        // Clear global state to ensure fresh data for next navigation
        context.projectState.clearProject();
        return;
      }

      if (action == 'saved') {
        logger.info("ProjectTabbedScreen returned: project $id was saved.");
        // Refresh from both database and global state to ensure consistency
        _refreshProjectsListFromDb();
        setState(() {
          _highlightedProjectId = id; // Set highlight after data is loaded
        });

        // Also clear any global state to ensure fresh data on next load
        context.projectState.clearProject();
      } else if (action == 'deleted') {
        logger.info("ProjectTabbedScreen returned: project $id was deleted.");
        setState(() {
          _currentProjects.removeWhere((p) => p.id == id);
          _highlightedProjectId = null; // Ensure no highlight on a deleted item
          // No need to call _dbHelper.getAllProjects() here if we manually update _currentProjects
        });
        // Clear global state after deletion
        context.projectState.clearProject();
        showInfoStatus(
          S.of(context)?.point_deleted_success(id) ?? 'Project deleted.',
        );
      } else if (action == 'navigated_back') {
        // User just came back, potentially from viewing an existing project. Highlight it.
        logger.info(
          "ProjectTabbedScreen returned: navigated back from project $id.",
        );
        setState(() {
          _highlightedProjectId = id;
        });
        // Clear global state to ensure fresh data for next navigation
        context.projectState.clearProject();
      } else if (result['action'] == "created" && result['id'] != null) {
        logger.info(
          "ProjectTabbedScreen returned: project ${result['id']} was created (legacy path).",
        );
        _refreshProjectsListFromDb(); // Refresh to get the new item
        setState(() {
          _highlightedProjectId = result['id'];
        });
        // Clear global state after creation
        context.projectState.clearProject();
      } else {
        // Fallback for your existing conditions, or new unhandled ones
        logger.info(
          "ProjectTabbedScreen returned with result: $result. Refreshing list.",
        );
        _refreshProjectsListFromDb();
        // If an ID is present in a generic success, highlight it
        if (result['id'] is String) {
          setState(() {
            _highlightedProjectId = result['id'];
          });
        }
        // Clear global state for fallback cases
        context.projectState.clearProject();
      }
    } else if (result is bool && result == true) {
      // Generic true, refresh list. Maybe highlight if a context can be inferred.
      logger.info(
        "ProjectTabbedScreen returned generic true. Refreshing list.",
      );
      _refreshProjectsListFromDb();
      // Clear global state for generic success
      context.projectState.clearProject();
    } else if (result == null) {
      logger.info(
        "ProjectTabbedScreen returned null (e.g. back press without action). No specific action taken on list.",
      );
      // Clear global state when user just navigates back without action
      context.projectState.clearProject();
      // Optionally clear highlight or leave as is
      // setState(() {
      //   _highlightedProjectId = null;
      // });
    }
    // Note: Your original _onItemTap had a FIXME to always refresh.
    // This new structure provides more granular control.
  }

  void _navigateToAddProjectPage() async {
    logger.info("Navigating to ProjectTabbedScreen for a new project.");
    ProjectModel newProject = ProjectModel(name: '', note: '');

    // Clear any previous highlight before navigating
    setState(() {
      _highlightedProjectId = null;
    });

    // Clear global state to ensure fresh data for new project
    context.projectState.clearProject();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProjectTabbedScreen(project: newProject, isNew: true),
      ), // Ensure this is your ProjectTabbedScreen
    );

    _handleNavigationResult(result);
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedProjectIdsForMultiSelect.clear();
    });
  }

  Future<void> _deleteSelectedProjects() async {
    if (_selectedProjectIdsForMultiSelect.isEmpty) return;

    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                S.of(context)?.delete_projects_title ?? 'Delete Project(s)?',
              ),
              content: Text(
                S
                        .of(context)
                        ?.delete_projects_content(
                          _selectedProjectIdsForMultiSelect.length,
                        ) ??
                    'Are you sure you want to delete ${_selectedProjectIdsForMultiSelect.length} selected project(s)? This action cannot be undone.',
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context)?.dialog_cancel ?? 'Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text(
                    S.of(context)?.buttonDelete ?? 'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      try {
        final List<String> idsToDelete = List.from(
          _selectedProjectIdsForMultiSelect,
        );
        for (String id in idsToDelete) {
          // ignore: use_build_context_synchronously
          final success = await context.projectState.deleteProject(id);
          if (!success) {
            logger.warning("Failed to delete project $id");
          }
        }
        setState(() {
          _currentProjects.removeWhere(
            (project) => idsToDelete.contains(project.id),
          );
          _isSelectionMode = false;
          _selectedProjectIdsForMultiSelect.clear();
          _highlightedProjectId = null;
        });
        logger.info(
          "${_selectedProjectIdsForMultiSelect.length} project(s) deleted.",
        );
        if (mounted) {
          showSuccessStatus(
            S
                    .of(context)
                    ?.point_deleted_success(
                      _selectedProjectIdsForMultiSelect.length.toString(),
                    ) ??
                '${_selectedProjectIdsForMultiSelect.length} project(s) deleted.',
          );
        }
      } catch (e, stackTrace) {
        logger.severe("Error deleting projects", e, stackTrace);
        if (mounted) {
          showErrorStatus(
            S
                    .of(context)
                    ?.error_deleting_point(
                      _selectedProjectIdsForMultiSelect.length.toString(),
                      e.toString(),
                    ) ??
                'Error deleting projects: $e',
          );
        }
      }
    }
  }

  Future<void> _testImportExampleLicence() async {
    try {
      logger.info('Installing development license...');

      // Install a development license using the new method
      final saved = await _licenceService.installDevelopmentLicense(
        email: 'dev@example.com',
        features: [
          'export_csv',
          'export_basic',
          'map_download',
          'export_advanced',
        ],
        maxDevices: 1,
      );

      if (saved && mounted) {
        // Reload the license to update the UI
        final license = await _licenceService.currentLicence;
        setState(() {
          _activeLicence = license;
        });
        showSuccessStatus(
          S.of(context)?.demo_license_imported_successfully ??
              'Development license installed successfully!',
        );
      } else {
        showErrorStatus(
          S.of(context)?.error_importing_demo_license('Failed to save') ??
              'Error installing development license: Failed to save',
        );
      }
    } catch (e, stackTrace) {
      logger.severe('Error installing development license', e, stackTrace);
      showErrorStatus(
        S.of(context)?.error_importing_demo_license(e.toString()) ??
            'Error installing development license: $e',
      );
    }
  }

  Future<void> _clearLicense() async {
    // Check if there's a license to clear
    if (_activeLicence == null) {
      showInfoStatus(
        S.of(context)?.no_license_to_clear ?? 'No license installed to clear.',
      );
      return;
    }

    // Show confirmation dialog first
    bool confirmClear =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Text(S.of(context)?.clear_license ?? 'Clear License'),
                ],
              ),
              content: Text(
                'Are you sure you want to clear the current license? This action cannot be undone and will remove access to premium features.',
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context)?.dialog_cancel ?? 'Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text(
                    S.of(context)?.clear_license ?? 'Clear License',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmClear) {
      return; // User cancelled
    }

    try {
      logger.info('Clearing license...');

      await _licenceService.removeLicence();

      if (mounted) {
        setState(() {
          _activeLicence = null;
        });
        showInfoStatus(
          S.of(context)?.license_cleared_successfully ??
              'License cleared successfully!',
        );
      }
    } catch (e, stackTrace) {
      logger.severe('Error clearing license', e, stackTrace);
      showErrorStatus(
        S.of(context)?.error_clearing_license(e.toString()) ??
            'Error clearing license: $e',
      );
    }
  }

  // Enhanced Licence Testing Methods
  Future<void> _generateDeviceFingerprint() async {
    try {
      logger.info('Generating device fingerprint...');

      final fingerprint = await DeviceFingerprint.generate();
      final deviceInfo = await DeviceFingerprint.getDeviceInfo();

      // Show fingerprint in dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              S.of(context)?.device_fingerprint_title ?? 'Device Fingerprint',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${S.of(context)?.fingerprint_label ?? 'Fingerprint:'} ${fingerprint.substring(0, 32)}...',
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context)?.device_info_label ?? 'Device Info:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...deviceInfo.entries.map(
                  (entry) => Text('${entry.key}: ${entry.value}'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(S.of(context)?.close_button ?? 'Close'),
              ),
              TextButton(
                onPressed: () {
                  // Copy fingerprint to clipboard
                  // You can add clipboard functionality here
                  Navigator.pop(context);
                  showInfoStatus(
                    S.of(context)?.fingerprint_copied_to_clipboard ??
                        'Fingerprint copied to clipboard',
                  );
                },
                child: Text(S.of(context)?.copy_button ?? 'Copy'),
              ),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.severe('Error generating device fingerprint', e, stackTrace);
      showErrorStatus(
        S.of(context)?.failed_to_generate_fingerprint(e.toString()) ??
            'Failed to generate fingerprint: $e',
      );
    }
  }

  Future<void> _requestLicence() async {
    try {
      // Show license request dialog
      final result = await _showLicenceRequestDialog();
      if (result == null) return; // User cancelled

      final email = result['email'] as String;
      final features = result['features'] as List<String>;
      final maxDevices = result['maxDevices'] as int;

      // Show loading indicator
      showInfoStatus('Requesting license...');

      // Request license from server
      final requestedLicence = await _licenceRequestService.requestLicence(
        email: email,
        requestedFeatures: features,
        maxDevices: maxDevices,
      );

      // Save the requested license
      final saved = await _licenceService.saveLicence(requestedLicence);

      if (saved && mounted) {
        setState(() {
          _activeLicence = requestedLicence;
        });

        showSuccessStatus(
          'License requested successfully! Status: ${requestedLicence.status}',
        );

        // Show license info dialog with status
        _showLicenceInfoDialog();
      }
    } catch (e) {
      if (e is lm.LicenceError) {
        showErrorStatus(e.userMessage);
      } else {
        showErrorStatus('Error requesting license: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> _showLicenceRequestDialog() async {
    final emailController = TextEditingController();
    final maxDevicesController = TextEditingController(text: '1');
    final selectedFeatures = <String>{};

    // Available features for request
    const availableFeatures = [
      'export_csv',
      'export_basic',
      'map_download',
      'export_advanced',
    ];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.request_page, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Request License'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: S.of(context)?.email_label ?? 'Email',
                        hintText: 'your.email@example.com',
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: maxDevicesController,
                      decoration: InputDecoration(
                        labelText: 'Max Devices',
                        hintText: '1-5',
                        prefixIcon: const Icon(Icons.devices),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Requested Features:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...availableFeatures.map(
                      (feature) => CheckboxListTile(
                        title: Text(feature.replaceAll('_', ' ').toUpperCase()),
                        value: selectedFeatures.contains(feature),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedFeatures.add(feature);
                            } else {
                              selectedFeatures.remove(feature);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final email = emailController.text.trim();
                    final maxDevices =
                        int.tryParse(maxDevicesController.text) ?? 1;

                    if (email.isEmpty) {
                      showErrorStatus('Email is required');
                      return;
                    }

                    if (selectedFeatures.isEmpty) {
                      showErrorStatus('Please select at least one feature');
                      return;
                    }

                    Navigator.of(context).pop({
                      'email': email,
                      'features': selectedFeatures.toList(),
                      'maxDevices': maxDevices.clamp(1, 5),
                    });
                  },
                  child: Text('Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _testLicenceValidation() async {
    try {
      logger.info('Testing licence validation...');

      await LicenceService.instance.initialize();

      // Test with invalid licence
      final invalidLicenceJson = '''
{
  "data": {
    "email": "test@invalid.com",
    "deviceFingerprint": "invalid_fingerprint",
    "validUntil": "2020-01-01T00:00:00Z",
    "features": ["test_feature"],
    "maxDevices": 1,
    "issuedAt": "2020-01-01T00:00:00Z",
    "version": "2.0"
  },
  "signature": "invalid_signature",
  "algorithm": "RSA-SHA256"
}
''';

      // Save invalid licence to temp file
      final tempDir = await getTemporaryDirectory();
      final invalidFile = File('${tempDir.path}/invalid_licence.lic');
      await invalidFile.writeAsString(invalidLicenceJson);

      // Try to import invalid licence
      try {
        await LicenceService.instance.importLicenceFromFile();
        showErrorStatus(
          S.of(context)?.invalid_licence_accepted_error ??
              'Invalid licence was accepted - this is wrong!',
        );
      } catch (e) {
        if (e is lm.LicenceError) {
          showInfoStatus(
            S.of(context)?.invalid_licence_correctly_rejected(e.code) ??
                'Invalid licence correctly rejected: ${e.code}',
          );
        } else {
          showErrorStatus(
            S.of(context)?.unexpected_error(e.toString()) ??
                'Unexpected error: $e',
          );
        }
      }
    } catch (e, stackTrace) {
      logger.severe('Error testing licence validation', e, stackTrace);
      showErrorStatus(
        S.of(context)?.validation_test_failed(e.toString()) ??
            'Validation test failed: $e',
      );
    }
  }

  Widget _buildProjectItem(ProjectModel project) {
    // Determine if the item should be highlighted
    bool isHighlighted = project.id == _highlightedProjectId;

    // Build info lines dynamically
    List<Widget> infoLines = [];
    // 1. Name (always shown) - now in title
    Widget projectNameRow = Row(
      children: [
        const Icon(Icons.folder_outlined, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            project.name.isNotEmpty
                ? project.name
                : S.of(context)?.untitled_project ?? 'Untitled Project',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    // 2. Rope length if > 0
    if (project.currentRopeLength > 0) {
      String ropeLengthStr = project.currentRopeLength >= 1000
          ? '${(project.currentRopeLength / 1000).toStringAsFixed(2)} km'
          : '${project.currentRopeLength.toStringAsFixed(1)} m';
      infoLines.add(
        Row(
          children: [
            const Icon(Icons.straighten, size: 18),
            const SizedBox(width: 6),
            Text(ropeLengthStr),
          ],
        ),
      );
    }
    // 3. Number of points if > 0
    if (project.points.isNotEmpty) {
      infoLines.add(
        Row(
          children: [
            const Icon(Icons.scatter_plot, size: 18),
            const SizedBox(width: 6),
            Text('${project.points.length}'),
          ],
        ),
      );
    }
    // 4. Date if available
    if (project.date != null) {
      final locale = Localizations.localeOf(context).toString();
      final DateFormat projectDateFormat = DateFormat.yMMMd(locale);
      infoLines.add(
        Row(
          children: [
            const Icon(Icons.event, size: 18),
            const SizedBox(width: 6),
            Text(projectDateFormat.format(project.date!)),
          ],
        ),
      );
    }
    // 5. Last update if available
    if (project.lastUpdate != null) {
      final locale = Localizations.localeOf(context).toString();
      final DateFormat dateFormat = DateFormat.yMMMd(locale);
      final DateFormat timeFormat = DateFormat.Hm(locale);
      String lastUpdateStr =
          '${dateFormat.format(project.lastUpdate!)} ${timeFormat.format(project.lastUpdate!)}';
      infoLines.add(
        Row(
          children: [
            const Icon(Icons.update, size: 18),
            const SizedBox(width: 6),
            Text(
              S.of(context)?.last_updated_label(lastUpdateStr) ??
                  'Last updated: $lastUpdateStr',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: isHighlighted
          ? Theme.of(context).primaryColorLight.withAlpha(200)
          : null, // Highlight color
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: _selectedProjectIdsForMultiSelect.contains(project.id),
                onChanged: (bool? value) {
                  _toggleSelection(project.id);
                },
              )
            : null,
        title: projectNameRow,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              height: 1,
              color: Colors.black12,
            ),
            const SizedBox(height: 4),
            ...infoLines,
          ],
        ),
        trailing: !_isSelectionMode
            ? const Icon(Icons.arrow_forward_ios, size: 16.0)
            : null,
        onTap: () => _onItemTap(project),
        onLongPress: () => _onItemLongPress(project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String titleText = '${AppConfig.appName} Projects';
    String? version;
    if (widget.appVersion != null && widget.appVersion!.isNotEmpty) {
      version = ' [${widget.appVersion}]';
    }
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Row(
                children: [
                  Icon(Icons.select_all, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    S
                            .of(context)
                            ?.selected_count(
                              _selectedProjectIdsForMultiSelect.length,
                            ) ??
                        '${_selectedProjectIdsForMultiSelect.length} selected',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: S.of(context)?.delete_selected ?? 'Delete Selected',
                  onPressed: _deleteSelectedProjects,
                ),
              ],
            )
          : AppBar(
              title: Row(
                children: [
                  Icon(Icons.folder_open, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titleText,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.map),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.download,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    tooltip: 'Download Offline Maps',
                    onPressed: () async {
                      // Check if map download feature is available
                      if (!LicensedFeaturesLoader.hasLicensedFeature(
                        'map_download',
                      )) {
                        // Show upgrade dialog for opensource version
                        LicensedFeaturesLoader.showMapDownloadUpgradeDialog(
                          context,
                        );
                        return;
                      }

                      // Check if licence is valid
                      final licenceStatus = await _licenceService
                          .getLicenceStatus();
                      if (licenceStatus['status'] != 'valid') {
                        if (context.mounted) {
                          final s = S.of(context);
                          showErrorStatus(
                            s?.mapDownloadRequiresValidLicence ??
                                'Valid licence required for map download',
                          );
                        }
                        return;
                      }

                      // Show map download page
                      if (context.mounted) {
                        await LicensedFeaturesLoader.showMapDownloadPage(
                          context,
                        );
                      }
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      _activeLicence != null && _activeLicence!.isValid
                          ? Icons.verified_user
                          : Icons.security,
                      color: _activeLicence != null && _activeLicence!.isValid
                          ? Colors.green
                          : (_activeLicence != null &&
                                    _activeLicence!.status ==
                                        lm.Licence.statusRequested
                                ? Colors.orange
                                : (_activeLicence != null &&
                                          !_activeLicence!.isValid
                                      ? Colors.red
                                      : Colors.grey)),
                    ),
                    tooltip:
                        "Licence Status / Import\n"
                        "License: ${_activeLicence?.email ?? 'None'}\n"
                        "Status: ${_activeLicence?.status ?? 'None'}",
                    onSelected: (String value) {
                      switch (value) {
                        case 'license_info':
                          _showLicenceInfoDialog();
                          break;
                        case 'import_license':
                          _handleImportLicence();
                          break;
                        case 'request_license':
                          _requestLicence();
                          break;
                        case 'test_license':
                          _testImportExampleLicence();
                          break;

                        case 'generate_fingerprint':
                          _generateDeviceFingerprint();
                          break;
                        case 'test_validation':
                          _testLicenceValidation();
                          break;
                        case 'clear_license':
                          _clearLicense();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'license_info',
                            child: Row(
                              children: [
                                Icon(
                                  _activeLicence != null &&
                                          _activeLicence!.isValid
                                      ? Icons.verified_user
                                      : Icons.security,
                                  color:
                                      _activeLicence != null &&
                                          _activeLicence!.isValid
                                      ? Colors.green
                                      : (_activeLicence != null &&
                                                _activeLicence!.status ==
                                                    lm.Licence.statusRequested
                                            ? Colors.orange
                                            : (_activeLicence != null &&
                                                      !_activeLicence!.isValid
                                                  ? Colors.red
                                                  : Colors.grey)),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    S.of(context)?.license_status_label ??
                                        'License Status',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'import_license',
                            child: Row(
                              children: [
                                Icon(Icons.file_upload, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    S.of(context)?.import_licence ??
                                        'Import License',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'request_license',
                            child: Row(
                              children: [
                                Icon(Icons.request_page, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Request License',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              'Development & Testing',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'test_license',
                            child: Row(
                              children: [
                                Icon(Icons.bug_report, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Install Development License',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              'Technical Tools',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'generate_fingerprint',
                            child: Row(
                              children: [
                                Icon(Icons.fingerprint, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    S
                                            .of(context)
                                            ?.generate_device_fingerprint ??
                                        'Generate Device Fingerprint',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'test_validation',
                            child: Row(
                              children: [
                                Icon(Icons.security, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    S.of(context)?.test_licence_validation ??
                                        'Test Licence Validation',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'clear_license',
                            child: Row(
                              children: [
                                Icon(Icons.clear, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  S.of(context)?.clear_license ??
                                      'Clear License',
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              bottom: version != null
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(20),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
                        child: Text(
                          version,
                          style: const TextStyle(
                            fontSize: 10.0,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
      body: Stack(
        children: [
          if (_currentProjects.isEmpty)
            Center(
              child: Text(
                S.of(context)?.no_projects_yet ??
                    "No projects yet. Tap '+' to add one!",
              ),
            )
          else
            ListView.builder(
              itemCount: _currentProjects.length,
              itemBuilder: (context, index) {
                final project = _currentProjects[index];
                return _buildProjectItem(project);
              },
            ),
          Positioned(
            top: 24,
            right: 24,
            child: StatusIndicator(
              status: currentStatus,
              onDismiss: hideStatus,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'projectPageFAB',
        onPressed: _navigateToAddProjectPage,
        tooltip: S.of(context)?.add_new_project_tooltip ?? 'Add New Project',
        child: const Icon(Icons.add),
      ),
    );
  }
}
