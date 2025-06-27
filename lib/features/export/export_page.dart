// lib/ui/export_page.dart
import 'package:flutter/material.dart';
import 'package:teleferika/core/logger.dart';
import 'package:teleferika/db/database_helper.dart'; // To fetch points
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';

import 'export_utils.dart'; // Import your S class

class ExportPage extends StatefulWidget {
  final ProjectModel project;

  const ExportPage({super.key, required this.project});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  ExportFormat _selectedFormat = ExportFormat.kml; // Default format
  List<PointModel> _points = [];
  bool _isLoadingPoints = true;
  bool _isExporting = false;
  final ExportService _exportService = ExportService();
  late DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper.instance;
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    setState(() => _isLoadingPoints = true);
    try {
      final points = await _dbHelper.getPointsForProject(widget.project.id);
      setState(() {
        _points = points;
        _isLoadingPoints = false;
      });
    } catch (e) {
      logger.severe("Error loading points for export: $e");
      setState(() => _isLoadingPoints = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Assuming 'error_loading_points' is a simple string in your .arb file
          SnackBar(
            content: Text(
              S.of(context)?.error_loading_points ?? 'Error loading points: $e',
            ),
          ),
        );
      }
    }
  }

  ExportStrategy _getStrategy(ExportFormat format) {
    switch (format) {
      case ExportFormat.kml:
        return KmlExportStrategy();
      case ExportFormat.csv:
        return CsvExportStrategy();
      // Add more cases as you add formats
    }
  }

  Future<void> _performExport(
    Future<void> Function(ExportStrategy) exportAction,
  ) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final strategy = _getStrategy(_selectedFormat);
      await exportAction(strategy);
    } catch (e) {
      logger.severe("Export failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Assuming 'export_failed' is a simple string
          SnackBar(
            content: Text(S.of(context)?.export_failed ?? 'Export failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use S.of(context) for localizations
    // The null check S.of(context)? is good practice if S can ever be null,
    // though with proper setup it usually isn't within a MaterialApp context.
    // If you are certain S.of(context) will not be null, you can use S.of(context)!
    final l = S.of(context);
    if (l == null) {
      // Fallback or error handling if localizations aren't loaded
      // This should ideally not happen if your app is set up correctly.
      logger.warning(
        "S.of(context) is null in ExportPage. Falling back to default strings.",
      );
      // You might want to return a loading indicator or an error message widget here.
      // For simplicity, we'll proceed but strings won't be localized.
    }

    return Scaffold(
      appBar: AppBar(
        // Use the generated accessor directly
        title: Text(l?.export_project_data_title ?? 'Export Project Data'),
      ),
      body: _isLoadingPoints
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Example if 'export_page_project_name_label' needs a parameter
                    // In your .arb: "export_page_project_name_label": "Project: {projectName}"
                    // In your S class, it might be: String export_page_project_name_label(String projectName)
                    // Then you'd call: l.export_page_project_name_label(widget.project.name)
                    // For this example, assuming a simple string or you handle parameters as needed:
                    l?.export_page_project_name_label(widget.project.name) ??
                        'Project: ${widget.project.name}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // Example with a number placeholder (common with flutter_gen-l10n)
                    // In your .arb: "export_page_points_count_label": "{count, plural, =0{No points found.} =1{{count} point found.} other{{count} points found.}}"
                    // In S class, it might be: String export_page_points_count_label(int count)
                    l?.export_page_points_count_label(_points.length) ??
                        '${_points.length} points found.',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l?.export_page_select_format_label ??
                        'Select Export Format:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  DropdownButtonFormField<ExportFormat>(
                    value: _selectedFormat,
                    items: ExportFormat.values.map((ExportFormat format) {
                      return DropdownMenuItem<ExportFormat>(
                        value: format,
                        child: Text(
                          format.name,
                        ), // Format name itself is not typically localized here unless the enum names are keys
                      );
                    }).toList(),
                    onChanged: (ExportFormat? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFormat = newValue;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                      ),
                      labelText: l?.export_format_dropdown_label ?? 'Format',
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isExporting)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: Text(l?.export_page_share_button ?? 'Share File'),
                      onPressed: _points.isEmpty
                          ? null
                          : () {
                              _performExport((strategy) async {
                                await _exportService.exportAndShare(
                                  widget.project,
                                  _points,
                                  strategy,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l?.file_shared_successfully ??
                                            'File prepared for sharing.',
                                      ),
                                    ),
                                  );
                                }
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt),
                      label: Text(
                        l?.export_page_save_locally_button ?? 'Save Locally',
                      ),
                      onPressed: _points.isEmpty
                          ? null
                          : () {
                              _performExport((strategy) async {
                                final savedFile = await _exportService
                                    .exportAndSave(
                                      widget.project,
                                      _points,
                                      strategy,
                                    );
                                if (mounted) {
                                  if (savedFile) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l?.file_saved_successfully ??
                                              'File saved successfully',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l?.file_save_cancelled_or_failed ??
                                              'File save cancelled or failed.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    l?.export_page_note_text ??
                        'Note: Ensure you have granted necessary storage permissions if saving locally on mobile devices.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
