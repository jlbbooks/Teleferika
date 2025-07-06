import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/licensing/licence_model.dart';
import 'package:teleferika/licensing/licence_service.dart';
import 'package:teleferika/licensing/licensed_features_loader.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';

import 'project_page.dart';
import 'offline_map_download_page.dart';

class ProjectsListPage extends StatefulWidget {
  final String? appVersion;

  const ProjectsListPage({super.key, this.appVersion});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> with StatusMixin {
  final Logger logger = Logger('ProjectsListPage');
  late Future<List<ProjectModel>> _projectsFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isSelectionMode = false;
  final Set<String> _selectedProjectIdsForMultiSelect = {};
  String? _highlightedProjectId;

  // Keep a local copy of projects to manipulate for instant UI updates
  List<ProjectModel> _currentProjects = [];

  final LicenceService _licenceService =
      LicenceService.instance; // Get LicenceService instance
  Licence? _activeLicence; // To hold the loaded licence status

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
    _licenceService.currentLicence.then((licence) {
      if (!mounted) return;
      setState(() {
        _activeLicence = licence;
      });

      String title =
          S.of(context)?.license_information_title ?? 'Licence Information';
      String contentText;
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
            '\n${S.of(context)?.app_version_label(widget.appVersion!) ?? 'App Version: ${widget.appVersion}'}';
      }

      if (_activeLicence != null && _activeLicence!.isValid) {
        contentText =
            (S
                    .of(context)
                    ?.licence_active_content(
                      _activeLicence!.email,
                      DateFormat.yMMMd().add_Hm().format(
                        _activeLicence!.validUntil.toLocal(),
                      ),
                    ) ??
                'Licensed to: ${_activeLicence!.email}\nStatus: Active\nValid Until: ${DateFormat.yMMMd().add_Hm().format(_activeLicence!.validUntil.toLocal())}') +
            versionInfo;
      } else if (_activeLicence != null && !_activeLicence!.isValid) {
        contentText =
            (S
                    .of(context)
                    ?.licence_expired_content(
                      _activeLicence!.email,
                      DateFormat.yMMMd().add_Hm().format(
                        _activeLicence!.validUntil.toLocal(),
                      ),
                    ) ??
                'Licensed to: ${_activeLicence!.email}\nStatus: Expired\nValid Until: ${DateFormat.yMMMd().add_Hm().format(_activeLicence!.validUntil.toLocal())}\n\nPlease import a valid licence.') +
            versionInfo;
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
      } else {
        contentText =
            (S.of(context)?.licence_none_content ??
                'No active licence found. Please import a licence file to unlock premium features.') +
            versionInfo;
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
            title: Text(title),
            content: Text(contentText),
            actions: actions,
          );
        },
      );
    });
  }

  void _showPremiumFeaturesDialog() {
    final hasLicensedFeatures = LicensedFeaturesLoader.hasLicensedFeatures;
    final availableFeatures = LicensedFeaturesLoader.licensedFeatures;

    // Add version info if available
    String versionInfo = '';
    if (widget.appVersion != null && widget.appVersion!.isNotEmpty) {
      versionInfo =
          '\n${S.of(context)?.app_version_label(widget.appVersion!) ?? 'App Version: ${widget.appVersion}'}';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                hasLicensedFeatures ? Icons.star : Icons.star_border,
                color: hasLicensedFeatures ? Colors.amber : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(S.of(context)?.premium_features_title ?? 'Premium Features'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasLicensedFeatures) ...[
                Text(
                  S.of(context)?.premium_features_available ??
                      'Premium features are available in this build!',
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context)?.available_features ?? 'Available Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...availableFeatures.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Show a sample premium widget
                if (LicensedFeaturesLoader.buildLicensedWidget(
                      'premium_banner',
                    ) !=
                    null)
                  LicensedFeaturesLoader.buildLicensedWidget('premium_banner')!,
              ] else ...[
                Text(
                  S.of(context)?.premium_features_not_available ??
                      'Premium features are not available in this build.',
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context)?.opensource_version ??
                      'This is the opensource version of the app.',
                ),
              ],
              if (versionInfo.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  versionInfo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              child: Text(S.of(context)?.close_button ?? 'Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (hasLicensedFeatures)
              TextButton(
                child: Text(S.of(context)?.try_feature ?? 'Try Feature'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _demonstrateLicensedFeature();
                },
              ),
          ],
        );
      },
    );
  }

  void _demonstrateLicensedFeature() {
    // Demonstrate a licensed function
    try {
      final licenceInfo = LicensedFeaturesLoader.getLicenceStatus();
      if (licenceInfo != null) {
        showSuccessStatus(
          S.of(context)?.licence_status(licenceInfo['status']) ??
              'Licence Status: ${licenceInfo['status']}',
        );
      }
    } catch (e) {
      showErrorStatus(
        S.of(context)?.feature_demo_failed(e.toString()) ??
            'Feature demonstration failed: $e',
      );
    }
  }

  Future<void> _handleImportLicence() async {
    try {
      final importedLicence = await _licenceService.importLicenceFromFile();
      if (mounted) {
        if (importedLicence != null) {
          setState(() {
            _activeLicence = importedLicence; // Update local state
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
        showErrorStatus('Error importing licence: $e');
      }
    }
  }

  void _loadProjects() {
    _projectsFuture = _dbHelper.getAllProjects();
    _projectsFuture
        .then((projects) {
          if (mounted) {
            setState(() {
              _currentProjects = projects;
              // Optionally clear highlight when the whole list reloads,
              // or persist it if needed. For now, let's clear it.
              // _highlightedProjectId = null;
            });
          }
        })
        .catchError((error) {
          // Handle or log error if needed
          logger.severe("Error in _loadProjects: $error");
          if (mounted) {
            setState(() {
              _currentProjects = []; // Clear current projects on error
            });
          }
        });
  }

  // This can be used if you only want to refresh data from DB
  void _refreshProjectsListFromDb() {
    setState(() {
      _highlightedProjectId = null; // Clear highlight on full refresh
      _loadProjects();
    });
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
          builder: (_) => ProjectPage(project: project, isNew: false),
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
        logger.info("ProjectPage returned with no specific ID or action.");
        // Clear global state to ensure fresh data for next navigation
        context.projectState.clearProject();
        return;
      }

      if (action == 'saved') {
        logger.info("ProjectPage returned: project $id was saved.");
        // Refresh from both database and global state to ensure consistency
        _projectsFuture = _dbHelper.getAllProjects();
        _projectsFuture.then((projects) {
          if (mounted) {
            setState(() {
              _currentProjects = projects;
              _highlightedProjectId = id; // Set highlight after data is loaded
            });
            // TODO: Optionally, scroll to the highlighted item
          }
        });

        // Also clear any global state to ensure fresh data on next load
        context.projectState.clearProject();
      } else if (action == 'deleted') {
        logger.info("ProjectPage returned: project $id was deleted.");
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
        logger.info("ProjectPage returned: navigated back from project $id.");
        setState(() {
          _highlightedProjectId = id;
        });
        // Clear global state to ensure fresh data for next navigation
        context.projectState.clearProject();
      } else if (result['action'] == "created" && result['id'] != null) {
        // This is your existing logic path from _onItemTap, let's integrate it.
        logger.info(
          "ProjectPage returned: project ${result['id']} was created (legacy path).",
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
          "ProjectPage returned with result: $result. Refreshing list.",
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
      logger.info("ProjectPage returned generic true. Refreshing list.");
      _refreshProjectsListFromDb();
      // Clear global state for generic success
      context.projectState.clearProject();
    } else if (result == null) {
      logger.info(
        "ProjectPage returned null (e.g. back press without action). No specific action taken on list.",
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
    logger.info("Navigating to ProjectDetailsPage for a new project.");
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
        builder: (context) => ProjectPage(project: newProject, isNew: true),
      ), // Ensure this is your ProjectDetailsPage
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
          await _dbHelper.deleteProject(id);
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
        showSuccessStatus(
          S
                  .of(context)
                  ?.point_deleted_success(
                    _selectedProjectIdsForMultiSelect.length.toString(),
                  ) ??
              '${_selectedProjectIdsForMultiSelect.length} project(s) deleted.',
        );
      } catch (e, stackTrace) {
        logger.severe("Error deleting projects", e, stackTrace);
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

  Future<void> _testImportExampleLicence() async {
    try {
      logger.info('Testing import of demo license...');

      // Create a demo license
      final demoLicence = Licence.createDemo();
      logger.info(
        'Created demo license: ${demoLicence.email}, valid: ${demoLicence.isValid}',
      );

      // Save the license
      final saved = await _licenceService.saveLicence(demoLicence);
      logger.info('License saved: $saved');

      if (saved && mounted) {
        setState(() {
          _activeLicence = demoLicence;
        });
        showSuccessStatus(
          S.of(context)?.demo_license_imported_successfully ??
              'Demo license imported successfully!',
        );
      }
    } catch (e, stackTrace) {
      logger.severe('Error testing demo license import', e, stackTrace);
      showErrorStatus('Error importing demo license: $e');
    }
  }

  Future<void> _clearLicense() async {
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
      showErrorStatus('Error clearing license: $e');
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OfflineMapDownloadPage(),
                        ),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      _activeLicence != null && _activeLicence!.isValid
                          ? Icons.verified_user
                          : Icons.security,
                      color: _activeLicence != null && _activeLicence!.isValid
                          ? Colors.green
                          : (_activeLicence != null && !_activeLicence!.isValid
                                ? Colors.red
                                : Colors.grey),
                    ),
                    tooltip:
                        "Licence Status / Import\n"
                        "License: ${_activeLicence?.email ?? 'None'}\n"
                        "Valid: ${_activeLicence?.isValid ?? 'Unknown'}",
                    onSelected: (String value) {
                      switch (value) {
                        case 'license_info':
                          _showLicenceInfoDialog();
                          break;
                        case 'premium_features':
                          _showPremiumFeaturesDialog();
                          break;
                        case 'test_license':
                          _testImportExampleLicence();
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
                                                !_activeLicence!.isValid
                                            ? Colors.red
                                            : Colors.grey),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('License Status'),
                              ],
                            ),
                          ),
                          // const PopupMenuItem<String>(
                          //   value: 'premium_features',
                          //   child: Row(
                          //     children: [
                          //       Icon(Icons.star, size: 20),
                          //       SizedBox(width: 8),
                          //       Text('Premium Features'),
                          //     ],
                          //   ),
                          // ),
                          PopupMenuItem<String>(
                            value: 'test_license',
                            child: Row(
                              children: [
                                Icon(Icons.bug_report, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  S.of(context)?.install_demo_license ??
                                      'Install Demo License',
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
          FutureBuilder<List<ProjectModel>>(
            future: _projectsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _currentProjects.isEmpty) {
                // Show loader only if _currentProjects is empty (initial load)
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError && _currentProjects.isEmpty) {
                logger.severe(
                  "Error loading projects",
                  snapshot.error,
                  snapshot.stackTrace,
                );
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (_currentProjects.isEmpty) {
                // Use _currentProjects to determine if the list is empty
                return Center(
                  child: Text(
                    S.of(context)?.no_projects_yet ??
                        "No projects yet. Tap '+' to add one!",
                  ),
                );
              }

              // Use _currentProjects for building the list for instant UI updates
              return ListView.builder(
                itemCount: _currentProjects.length,
                itemBuilder: (context, index) {
                  final project = _currentProjects[index];
                  return _buildProjectItem(project);
                },
              );
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
