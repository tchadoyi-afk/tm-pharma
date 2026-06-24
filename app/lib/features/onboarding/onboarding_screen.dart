import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/sync/sync_service.dart';
import 'csv_import.dart';
import 'onboarding_repository.dart';

/// Assistant d'onboarding (Sprint 6) : reprise de données guidée en deux
/// étapes — import du catalogue (CSV collé, prévisu + doublons signalés),
/// puis inventaire initial (quantité de départ par produit importé).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _csvController = TextEditingController();
  List<ImportedProductRow> _preview = const [];
  bool _imported = false;
  List<({String id, String name})> _importedProducts = const [];
  final Map<String, int> _quantities = {};
  final Map<String, TextEditingController> _quantityControllers = {};

  @override
  void dispose() {
    _csvController.dispose();
    for (final c in _quantityControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _preview_() async {
    final rows = parseProductCsv(_csvController.text);
    final existing = await ref
        .read(onboardingRepositoryProvider)
        .existingBarcodes();
    setState(() => _preview = markDuplicates(rows, existing));
  }

  Future<void> _import() async {
    final created = await ref
        .read(onboardingRepositoryProvider)
        .importProducts(
          tenantId: OnboardingScreen.demoTenantId,
          rows: _preview,
        );
    setState(() {
      _imported = true;
      _importedProducts = created;
      for (final p in created) {
        _quantityControllers[p.id] = TextEditingController(text: '0');
      }
      _step = 1;
    });
  }

  Future<void> _finishInventory() async {
    for (final entry in _quantityControllers.entries) {
      _quantities[entry.key] = int.tryParse(entry.value.text) ?? 0;
    }
    await ref
        .read(onboardingRepositoryProvider)
        .recordInitialInventory(
          tenantId: OnboardingScreen.demoTenantId,
          quantityByProductId: _quantities,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.of(context).initialInventoryRecorded)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(syncServiceProvider).isReady;
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.onboardingTitle)),
      body: !ready
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.localDbNotInitialized,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stepper(
              currentStep: _step,
              onStepContinue: _step == 0 ? null : () {},
              steps: [
                Step(
                  title: Text(s.stepImportCatalog),
                  isActive: _step == 0,
                  state: _imported ? StepState.complete : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(s.csvImportInstructions),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _csvController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: s.csvHint,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _preview_,
                        child: Text(s.preview),
                      ),
                      if (_preview.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          s.csvPreviewSummary(
                            _preview.length,
                            _preview.where((r) => r.isDuplicate).length,
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _preview.length,
                            itemBuilder: (context, i) {
                              final row = _preview[i];
                              return ListTile(
                                dense: true,
                                leading: row.isDuplicate
                                    ? const Icon(
                                        Icons.warning_amber_outlined,
                                        color: Colors.orange,
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                title: Text(row.name),
                                subtitle: Text(
                                  '${row.barcode ?? s.noCode} · ${row.sellingPrice.toStringAsFixed(0)} XOF',
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _import,
                          child: Text(s.import),
                        ),
                      ],
                    ],
                  ),
                ),
                Step(
                  title: Text(s.stepInitialInventory),
                  isActive: _step == 1,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.importedProductsSummary(_importedProducts.length),
                      ),
                      const SizedBox(height: 12),
                      for (final p in _importedProducts)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(p.name)),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _quantityControllers[p.id],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _importedProducts.isEmpty
                            ? null
                            : _finishInventory,
                        child: Text(s.finishOnboarding),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
