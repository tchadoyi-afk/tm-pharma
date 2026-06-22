import 'package:powersync/powersync.dart';

/// Schéma SQLite local synchronisé par PowerSync.
/// La colonne `id` (UUID) est implicite sur chaque table PowerSync.
/// Doit rester cohérent avec les tables Postgres et `supabase/sync_rules.yaml`.
final powerSyncSchema = Schema([
  Table(
    'products',
    [
      Column.text('tenant_id'),
      Column.text('barcode'),
      Column.text('name'),
      Column.text('dci_name'),
      Column.text('unit'),
      Column.text('category'),
      Column.text('reference_id'),
      Column.real('selling_price'),
      Column.integer('low_stock_threshold'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('deleted_at'),
    ],
    indexes: [
      Index('product_tenant', [IndexedColumn('tenant_id')]),
      Index('product_barcode', [IndexedColumn('barcode')]),
    ],
  ),
  Table(
    'reference_products',
    [
      Column.text('dci_name'),
      Column.text('barcode'),
      Column.text('unit'),
      Column.text('category'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index('reference_product_barcode', [IndexedColumn('barcode')]),
    ],
  ),
  Table(
    'lots',
    [
      Column.text('tenant_id'),
      Column.text('product_id'),
      Column.text('lot_number'),
      Column.text('expiration_date'),
      Column.integer('quantity'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('deleted_at'),
    ],
    indexes: [
      Index('lot_product', [IndexedColumn('product_id')]),
    ],
  ),
  Table('sales', [
    Column.text('tenant_id'),
    Column.text('user_id'),
    Column.text('cash_session_id'),
    Column.real('total_amount'),
    Column.text('status'),
    Column.text('payment_method'),
    Column.text('sold_at'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('deleted_at'),
  ]),
  Table(
    'sale_items',
    [
      Column.text('tenant_id'),
      Column.text('sale_id'),
      Column.text('lot_id'),
      Column.integer('quantity'),
      Column.real('unit_price'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('deleted_at'),
    ],
    indexes: [
      Index('item_sale', [IndexedColumn('sale_id')]),
    ],
  ),
  Table('pharmacy_settings', [
    Column.text('tenant_id'),
    Column.text('legal_name'),
    Column.text('logo_path'),
    Column.text('currency'),
    Column.text('invoice_prefix'),
    Column.integer('invoice_next_number'),
  ]),
  Table(
    'suppliers',
    [
      Column.text('tenant_id'),
      Column.text('name'),
      Column.text('phone'),
      Column.text('email'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('deleted_at'),
    ],
    indexes: [
      Index('supplier_tenant', [IndexedColumn('tenant_id')]),
    ],
  ),
  Table(
    'stock_movements',
    [
      Column.text('tenant_id'),
      Column.text('product_id'),
      Column.text('lot_id'),
      Column.text('supplier_id'),
      Column.text('type'),
      Column.integer('quantity_delta'),
      Column.text('reason'),
      Column.text('created_by'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('deleted_at'),
    ],
    indexes: [
      Index('movement_product', [IndexedColumn('product_id')]),
      Index('movement_lot', [IndexedColumn('lot_id')]),
    ],
  ),
  Table(
    'cash_sessions',
    [
      Column.text('tenant_id'),
      Column.text('user_id'),
      Column.text('status'),
      Column.real('opening_amount'),
      Column.real('closing_amount'),
      Column.text('opened_at'),
      Column.text('closed_at'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index('cash_session_tenant', [IndexedColumn('tenant_id')]),
    ],
  ),
  Table(
    'invoices',
    [
      Column.text('tenant_id'),
      Column.text('sale_id'),
      Column.text('invoice_number'),
      Column.text('issued_at'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('deleted_at'),
    ],
    indexes: [
      Index('invoice_sale', [IndexedColumn('sale_id')]),
    ],
  ),
  Table(
    'promotions',
    [
      Column.text('tenant_id'),
      Column.text('product_id'),
      Column.real('discount_percent'),
      Column.text('starts_at'),
      Column.text('ends_at'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('deleted_at'),
    ],
    indexes: [
      Index('promotion_product', [IndexedColumn('product_id')]),
    ],
  ),
  Table(
    'purchase_orders',
    [
      Column.text('tenant_id'),
      Column.text('supplier_id'),
      Column.text('status'),
      Column.text('created_by'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('deleted_at'),
    ],
    indexes: [
      Index('purchase_order_tenant', [IndexedColumn('tenant_id')]),
    ],
  ),
  Table(
    'audit_log',
    [
      Column.text('tenant_id'),
      Column.text('user_id'),
      Column.text('action'),
      Column.text('entity'),
      Column.text('entity_id'),
      Column.text('before'),
      Column.text('after'),
      Column.text('device_ts'),
      Column.text('server_ts'),
      Column.text('prev_hash'),
      Column.text('hash'),
      Column.text('created_at'),
    ],
    indexes: [
      Index('audit_tenant', [IndexedColumn('tenant_id')]),
      Index('audit_entity', [IndexedColumn('entity'), IndexedColumn('entity_id')]),
    ],
  ),
  Table(
    'purchase_order_items',
    [
      Column.text('tenant_id'),
      Column.text('purchase_order_id'),
      Column.text('product_id'),
      Column.integer('quantity'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('deleted_at'),
    ],
    indexes: [
      Index('po_item_order', [IndexedColumn('purchase_order_id')]),
    ],
  ),
]);
