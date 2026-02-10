import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:teleferika/db/database.dart';
import 'package:teleferika/db/drift_database_helper.dart';
import 'package:teleferika/l10n/app_localizations.dart';

/// Screen for managing cable types (add, edit, delete).
///
/// Cable types are used at project level for rope diameter, weight,
/// breaking load, etc. Built-in types are seeded on first run; users
/// can add custom types here.
class CableTypesScreen extends StatefulWidget {
  const CableTypesScreen({super.key});

  @override
  State<CableTypesScreen> createState() => _CableTypesScreenState();
}

class _CableTypesScreenState extends State<CableTypesScreen> {
  final Logger _logger = Logger('CableTypesScreen');
  List<CableType> _cableTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCableTypes();
  }

  Future<void> _loadCableTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list =
          await DriftDatabaseHelper.instance.getAllCableTypes();
      if (mounted) {
        setState(() {
          _cableTypes = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading cable types: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<_CableTypeFormResult>(
      context: context,
      builder: (context) => const _CableTypeFormDialog(),
    );
    if (result != null && mounted) {
      await _saveCableType(result, isEdit: false);
    }
  }

  Future<void> _showEditDialog(CableType cableType) async {
    final result = await showDialog<_CableTypeFormResult>(
      context: context,
      builder: (context) => _CableTypeFormDialog(existing: cableType),
    );
    if (result != null && mounted) {
      await _saveCableType(result, isEdit: true);
    }
  }

  Future<void> _saveCableType(_CableTypeFormResult result,
      {required bool isEdit}) async {
    final s = S.of(context);
    try {
      if (isEdit) {
        final updated = CableType(
          id: result.id!,
          name: result.name,
          diameterMm: result.diameterMm,
          weightPerMeterKg: result.weightPerMeterKg,
          breakingLoadKn: result.breakingLoadKn,
          elasticModulusGPa: result.elasticModulusGPa,
          sortOrder: result.sortOrder,
        );
        await DriftDatabaseHelper.instance.updateCableType(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s?.cableTypeUpdatedSnackbar ?? 'Cable type updated.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await DriftDatabaseHelper.instance.insertCableType(
          name: result.name,
          diameterMm: result.diameterMm,
          weightPerMeterKg: result.weightPerMeterKg,
          breakingLoadKn: result.breakingLoadKn,
          elasticModulusGPa: result.elasticModulusGPa,
          sortOrder: _cableTypes.length,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s?.cableTypeAddedSnackbar ?? 'Cable type added.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      if (mounted) _loadCableTypes();
    } catch (e) {
      _logger.severe('Error saving cable type: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? (s?.errorUpdatingCableType(e.toString()) ??
                      'Error updating cable type: $e')
                  : (s?.errorAddingCableType(e.toString()) ??
                      'Error adding cable type: $e'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(CableType cableType) async {
    final s = S.of(context);
    List<Project> usingProjects = [];
    try {
      usingProjects = await DriftDatabaseHelper.instance
          .getProjectsUsingCableType(cableType.id);
    } catch (e) {
      _logger.warning('Could not fetch projects using cable type: $e');
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteCableTypeConfirmDialog(
        cableTypeName: cableType.name,
        usingProjects: usingProjects,
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await DriftDatabaseHelper.instance.deleteCableType(cableType.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s?.cableTypeDeletedSnackbar ?? 'Cable type deleted.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadCableTypes();
        }
      } catch (e) {
        _logger.severe('Error deleting cable type: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s?.errorDeletingCableType(e.toString()) ??
                    'Error deleting: $e',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.cable, size: 24),
            const SizedBox(width: 12),
            Text(
              s?.cableTypesTitle ?? 'Cable Types',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: _buildBody(s),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _showAddDialog,
        tooltip: s?.cableTypeAddButton ?? 'Add cable type',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(S? s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                s?.errorLoadingCableTypes(_error!) ?? 'Error: $_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadCableTypes,
                icon: const Icon(Icons.refresh),
                label: Text(s?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_cableTypes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cable, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                s?.cableTypesEmpty ?? 'No cable types yet.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                s?.cableTypesEmptyHint ??
                    'Tap + to add a cable type for use in projects.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cableTypes.length,
      itemBuilder: (context, index) {
        final ct = _cableTypes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.cable, color: Colors.blue),
            title: Text(
              ct.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${ct.diameterMm} mm • ${ct.weightPerMeterKg} kg/m • ${ct.breakingLoadKn} kN',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            onTap: () => _showEditDialog(ct),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditDialog(ct),
                  tooltip: s?.cableTypeEditButton ?? 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(ct),
                  tooltip: s?.buttonDelete ?? 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeleteCableTypeConfirmDialog extends StatelessWidget {
  final String cableTypeName;
  final List<Project> usingProjects;

  const _DeleteCableTypeConfirmDialog({
    required this.cableTypeName,
    required this.usingProjects,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(
        s?.cableTypeDeleteConfirmTitle ?? 'Delete Cable Type?',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s?.cableTypeDeleteConfirmMessage(cableTypeName) ??
                  'Delete "$cableTypeName"? Projects using this type will have it cleared. This cannot be undone.',
            ),
            if (usingProjects.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                s?.cableTypeDeleteProjectsLabel ?? 'Projects using this type:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(
                        alpha: 0.3,
                      ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withValues(
                          alpha: 0.5,
                        ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: usingProjects
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s?.buttonCancel ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(s?.buttonDelete ?? 'Delete'),
        ),
      ],
    );
  }
}

class _CableTypeFormResult {
  final String? id;
  final String name;
  final double diameterMm;
  final double weightPerMeterKg;
  final double breakingLoadKn;
  final double? elasticModulusGPa;
  final int sortOrder;

  _CableTypeFormResult({
    this.id,
    required this.name,
    required this.diameterMm,
    required this.weightPerMeterKg,
    required this.breakingLoadKn,
    this.elasticModulusGPa,
    this.sortOrder = 0,
  });
}

class _CableTypeFormDialog extends StatefulWidget {
  final CableType? existing;

  const _CableTypeFormDialog({this.existing});

  @override
  State<_CableTypeFormDialog> createState() => _CableTypeFormDialogState();
}

class _CableTypeFormDialogState extends State<_CableTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _diameterController;
  late final TextEditingController _weightController;
  late final TextEditingController _breakingLoadController;
  late final TextEditingController _elasticModulusController;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _diameterController =
        TextEditingController(text: e?.diameterMm.toString() ?? '');
    _weightController =
        TextEditingController(text: e?.weightPerMeterKg.toString() ?? '');
    _breakingLoadController =
        TextEditingController(text: e?.breakingLoadKn.toString() ?? '');
    _elasticModulusController = TextEditingController(
      text: e?.elasticModulusGPa?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _diameterController.dispose();
    _weightController.dispose();
    _breakingLoadController.dispose();
    _elasticModulusController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final diameter = double.tryParse(_diameterController.text);
    final weight = double.tryParse(_weightController.text);
    final breakingLoad = double.tryParse(_breakingLoadController.text);
    final elasticModulus = double.tryParse(_elasticModulusController.text);

    if (diameter == null || weight == null || breakingLoad == null) return;

    Navigator.of(context).pop(_CableTypeFormResult(
      id: widget.existing?.id,
      name: _nameController.text.trim(),
      diameterMm: diameter,
      weightPerMeterKg: weight,
      breakingLoadKn: breakingLoad,
      elasticModulusGPa: elasticModulus,
      sortOrder: widget.existing?.sortOrder ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEdit
            ? (s?.cableTypeEditTitle ?? 'Edit Cable Type')
            : (s?.cableTypeAddTitle ?? 'Add Cable Type'),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: s?.formFieldCableEquipmentTypeLabel ??
                        'Cable / equipment type',
                    hintText: 'e.g. Skyline 14 mm',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? (s?.required ?? 'Required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _diameterController,
                  decoration: const InputDecoration(
                    labelText: 'Diameter (mm)',
                    hintText: '14',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? (s?.required ?? 'Required') : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg/m)',
                    hintText: '0.96',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? (s?.required ?? 'Required') : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _breakingLoadController,
                  decoration: const InputDecoration(
                    labelText: 'Breaking load (kN)',
                    hintText: '177',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? (s?.required ?? 'Required') : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _elasticModulusController,
                  decoration: const InputDecoration(
                    labelText: 'Elastic modulus (GPa)',
                    hintText: 'Optional',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s?.buttonCancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            isEdit
                ? (s?.buttonSave ?? 'Save')
                : (s?.cableTypeAddButton ?? 'Add'),
          ),
        ),
      ],
    );
  }
}
