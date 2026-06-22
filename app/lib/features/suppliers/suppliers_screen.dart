import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';
import '../../core/sync/sync_service.dart';
import '../stock/stock_models.dart';
import '../stock/stock_repository.dart';

/// Gestion des fournisseurs (MVP) : carnet d'adresses des grossistes/
/// fournisseurs (nom, téléphone, email), utilisé à la réception de stock et
/// dans les bons de commande. Lecture sous `stock.view`, écriture sous
/// `supplier.manage`.
class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  static const demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(syncServiceProvider).isReady;

    return Scaffold(
      appBar: AppBar(title: const Text('Fournisseurs')),
      floatingActionButton: PermissionGate(
        permission: Permissions.supplierManage,
        child: FloatingActionButton(
          onPressed: () => _openSupplierSheet(context),
          child: const Icon(Icons.add),
        ),
      ),
      body: !ready
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Base locale non initialisée sur cette plateforme.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : StreamBuilder<List<Supplier>>(
              stream: ref.read(stockRepositoryProvider).watchSuppliers(),
              builder: (context, snap) {
                final suppliers = snap.data ?? const [];
                if (suppliers.isEmpty) {
                  return const Center(
                    child: Text('Aucun fournisseur pour le moment.'),
                  );
                }
                return ListView.builder(
                  itemCount: suppliers.length,
                  itemBuilder: (context, i) {
                    final supplier = suppliers[i];
                    return ListTile(
                      leading: const Icon(Icons.local_shipping_outlined),
                      title: Text(supplier.name),
                      subtitle: Text([
                        if (supplier.phone != null) supplier.phone!,
                        if (supplier.email != null) supplier.email!,
                      ].join(' · ')),
                      trailing: PermissionGate(
                        permission: Permissions.supplierManage,
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _openSupplierSheet(context, supplier: supplier),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _openSupplierSheet(BuildContext context, {Supplier? supplier}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SupplierSheet(
        tenantId: demoTenantId,
        supplier: supplier,
      ),
    );
  }
}

class _SupplierSheet extends ConsumerStatefulWidget {
  const _SupplierSheet({required this.tenantId, this.supplier});
  final String tenantId;
  final Supplier? supplier;

  @override
  ConsumerState<_SupplierSheet> createState() => _SupplierSheetState();
}

class _SupplierSheetState extends ConsumerState<_SupplierSheet> {
  late final _nameController = TextEditingController(
    text: widget.supplier?.name ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.supplier?.phone ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.supplier?.email ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final repo = ref.read(stockRepositoryProvider);
    if (widget.supplier == null) {
      await repo.createSupplier(
        tenantId: widget.tenantId,
        name: name,
        phone: phone.isEmpty ? null : phone,
        email: email.isEmpty ? null : email,
      );
    } else {
      await repo.updateSupplier(
        widget.supplier!.id,
        name: name,
        phone: phone.isEmpty ? null : phone,
        email: email.isEmpty ? null : email,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.supplier == null ? 'Nouveau fournisseur' : 'Modifier le fournisseur',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
  }
}
