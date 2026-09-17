part of 'management.dart';

String _commerceMoney(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

String _commercePaymentLabel(String value) => switch (value) {
      'pix' => 'PIX',
      'cash' => 'Dinheiro',
      'credit_card' => 'Cartão de crédito',
      'debit_card' => 'Cartão de débito',
      _ => 'Outro',
    };

class _CashPage extends StatefulWidget {
  const _CashPage();

  @override
  State<_CashPage> createState() => _CashPageState();
}

class _CashPageState extends State<_CashPage> {
  var _showProducts = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();
    if (!session.canManageCommerce) {
      return const _InlineNotice(
        icon: Icons.lock_outline_rounded,
        title: 'Acesso exclusivo do Dono',
        subtitle:
            'O catálogo, o estoque e as vendas são dados comerciais restritos.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          cards: [
            _MetricData(
              'Vendas hoje',
              _commerceMoney(session.productSalesTodayTotal),
              Icons.point_of_sale_rounded,
            ),
            _MetricData(
              'Custo em estoque',
              _commerceMoney(session.inventoryCostValue),
              Icons.inventory_2_rounded,
            ),
            _MetricData(
              'Estoque baixo',
              '${session.lowStockProductCount}',
              Icons.warning_amber_rounded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final selector = SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Vendas'),
                  icon: Icon(Icons.receipt_long_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Produtos'),
                  icon: Icon(Icons.inventory_2_outlined),
                ),
              ],
              selected: {_showProducts},
              showSelectedIcon: false,
              onSelectionChanged: (value) {
                setState(() => _showProducts = value.first);
              },
            );
            final action = CDRButton.primary(
              label: _showProducts ? 'NOVO PRODUTO' : 'NOVA VENDA',
              onPressed: _showProducts
                  ? () => _openProductForm(context)
                  : session.products.any(
                      (product) =>
                          product.isActive &&
                          product.quantity > 0 &&
                          product.salePrice > 0,
                    )
                      ? () => _openSaleForm(context)
                      : null,
              leading: Icon(
                _showProducts
                    ? Icons.add_box_outlined
                    : Icons.add_shopping_cart_rounded,
              ),
              isExpanded: compact,
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  selector,
                  const SizedBox(height: 12),
                  action,
                ],
              );
            }
            return Row(
              children: [
                selector,
                const Spacer(),
                action,
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        if (session.isCommerceLoading && !session._commerceLoaded)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (session.commerceError != null)
          _InlineNotice(
            icon: Icons.cloud_off_rounded,
            title: 'Não foi possível carregar o comercial',
            subtitle: session.commerceError!,
            actionLabel: 'TENTAR NOVAMENTE',
            onAction: session.fetchCommerce,
          )
        else if (_showProducts)
          _ProductCatalog(session: session, onEdit: _openProductForm)
        else
          _ProductSales(session: session, onCancel: _cancelSale),
      ],
    );
  }

  Future<void> _openProductForm(
    BuildContext context, [
    ManagedProduct? product,
  ]) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SharedAppColors.card,
      builder: (_) => _ProductForm(product: product),
    );
  }

  Future<void> _openSaleForm(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SharedAppColors.card,
      builder: (_) => const _ProductSaleForm(),
    );
  }

  Future<void> _cancelSale(BuildContext context, ProductSale sale) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.undo_rounded, color: SharedAppColors.orange),
        title: const Text('Cancelar e estornar venda?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Os produtos voltarão ao estoque e uma saída será registrada no caixa.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Motivo obrigatório'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('VOLTAR'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('CONFIRMAR ESTORNO'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !context.mounted) return;
    try {
      await context.read<ManagementSession>().cancelProductSale(sale, reason);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda cancelada e estoque devolvido.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _ProductCatalog extends StatelessWidget {
  const _ProductCatalog({required this.session, required this.onEdit});

  final ManagementSession session;
  final void Function(BuildContext context, ManagedProduct product) onEdit;

  @override
  Widget build(BuildContext context) {
    final products = session.filteredProducts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: session.setProductSearchQuery,
          decoration: const InputDecoration(
            hintText: 'Buscar por nome, categoria, SKU ou código de barras',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in ProductStatusFilter.values) ...[
                ChoiceChip(
                  label: Text(switch (filter) {
                    ProductStatusFilter.all => 'Todos',
                    ProductStatusFilter.active => 'Ativos',
                    ProductStatusFilter.lowStock => 'Estoque baixo',
                    ProductStatusFilter.inactive => 'Inativos',
                  }),
                  selected: session.productStatusFilter == filter,
                  onSelected: (_) => session.setProductStatusFilter(filter),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionTitle(
          'Catálogo de produtos',
          eyebrow: 'ESTOQUE',
          trailing: '${products.length} itens',
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          const _InlineNotice(
            icon: Icons.inventory_2_outlined,
            title: 'Nenhum produto encontrado',
            subtitle:
                'Cadastre pomadas, balms, bebidas ou qualquer outro item vendido na barbearia.',
          )
        else
          for (final product in products)
            _ProductTile(
              product: product,
              onEdit: () => onEdit(context, product),
              onAdjust: () => _openStockAdjustment(context, product),
            ),
      ],
    );
  }

  Future<void> _openStockAdjustment(
    BuildContext context,
    ManagedProduct product,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SharedAppColors.card,
      builder: (_) => _StockAdjustmentForm(product: product),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onAdjust,
  });

  final ManagedProduct product;
  final VoidCallback onEdit;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: product.isLowStock
              ? SharedAppColors.orange
              : SharedAppColors.stroke,
        ),
      ),
      child: Row(
        children: [
          _IconBadge(
            product.isLowStock
                ? Icons.warning_amber_rounded
                : Icons.inventory_2_rounded,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (!product.isActive)
                      const _CommerceBadge(label: 'INATIVO', muted: true)
                    else if (product.isLowStock)
                      const _CommerceBadge(label: 'REPOR'),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${product.category.isEmpty ? 'Sem categoria' : product.category} • ${_commerceMoney(product.salePrice)} • ${product.quantity} ${product.unit}',
                  style: const TextStyle(color: SharedAppColors.muted),
                ),
                if (product.sku.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'SKU ${product.sku}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Ações do produto',
            onSelected: (value) => value == 'stock' ? onAdjust() : onEdit(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'stock', child: Text('Ajustar estoque')),
              PopupMenuItem(value: 'edit', child: Text('Editar produto')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductSales extends StatelessWidget {
  const _ProductSales({required this.session, required this.onCancel});

  final ManagementSession session;
  final void Function(BuildContext context, ProductSale sale) onCancel;

  @override
  Widget build(BuildContext context) {
    final sales = session.productSales;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!session.products.any(
          (product) =>
              product.isActive && product.quantity > 0 && product.salePrice > 0,
        )) ...[
          const _InlineNotice(
            icon: Icons.inventory_2_outlined,
            title: 'Prepare o catálogo para vender',
            subtitle:
                'Cadastre um produto ativo, informe o preço e adicione estoque.',
          ),
          const SizedBox(height: 18),
        ],
        _SectionTitle(
          'Histórico de vendas',
          eyebrow: 'COMERCIAL',
          trailing: '${sales.length} registros',
        ),
        const SizedBox(height: 12),
        if (sales.isEmpty)
          const _InlineNotice(
            icon: Icons.receipt_long_outlined,
            title: 'Ainda não há vendas',
            subtitle:
                'A primeira venda aparecerá aqui com produtos, pagamento e valor total.',
          )
        else
          for (final sale in sales)
            _SaleTile(
              sale: sale,
              onCancel: sale.isCancelled ? null : () => onCancel(context, sale),
            ),
      ],
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale, required this.onCancel});

  final ProductSale sale;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final when = sale.soldAt?.toLocal();
    final date = when == null
        ? ''
        : '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')} às ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    final itemSummary = sale.items
        .map((item) => '${item.quantity}x ${item.productName}')
        .join(' • ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                sale.isCancelled
                    ? Icons.undo_rounded
                    : Icons.receipt_long_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.customerName.isEmpty
                          ? 'Venda #${sale.id.substring(0, 8)}'
                          : sale.customerName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$date • ${_commercePaymentLabel(sale.paymentMethod)}',
                      style: const TextStyle(color: SharedAppColors.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _commerceMoney(sale.total),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  _CommerceBadge(
                    label: sale.isCancelled ? 'CANCELADA' : 'CONCLUÍDA',
                    muted: sale.isCancelled,
                  ),
                ],
              ),
            ],
          ),
          if (itemSummary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(itemSummary, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (sale.discount > 0) ...[
            const SizedBox(height: 5),
            Text(
              'Desconto: ${_commerceMoney(sale.discount)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: const Text('CANCELAR E ESTORNAR'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommerceBadge extends StatelessWidget {
  const _CommerceBadge({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: muted
            ? SharedAppColors.elevated
            : SharedAppColors.orange.withOpacity(.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: muted ? SharedAppColors.muted : SharedAppColors.orange,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({this.product});

  final ManagedProduct? product;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _sku;
  late final TextEditingController _barcode;
  late final TextEditingController _quantity;
  late final TextEditingController _minimum;
  late final TextEditingController _cost;
  late final TextEditingController _price;
  late String _unit;
  late bool _active;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _category = TextEditingController(text: product?.category ?? '');
    _sku = TextEditingController(text: product?.sku ?? '');
    _barcode = TextEditingController(text: product?.barcode ?? '');
    _quantity = TextEditingController(text: product == null ? '0' : '');
    _minimum = TextEditingController(text: '${product?.minQuantity ?? 0}');
    _cost = TextEditingController(
      text: product == null ? '' : product.unitCost.toStringAsFixed(2),
    );
    _price = TextEditingController(
      text: product == null ? '' : product.salePrice.toStringAsFixed(2),
    );
    _unit = product?.unit ?? 'un';
    _active = product?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _category,
      _sku,
      _barcode,
      _quantity,
      _minimum,
      _cost,
      _price,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;
    final bottom = MediaQuery.viewInsetsOf(context).bottom + 20;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              eyebrow: editing ? 'EDITAR PRODUTO' : 'NOVO PRODUTO',
              title: editing ? 'Dados do produto' : 'Cadastrar produto',
              onClose: _saving ? null : () => Navigator.pop(context),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome do produto'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o nome.'
                  : null,
            ),
            const SizedBox(height: 12),
            _ResponsiveFieldRow(
              children: [
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Pomadas, bebidas...',
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: _unit,
                  decoration: const InputDecoration(labelText: 'Unidade'),
                  items: const [
                    DropdownMenuItem(value: 'un', child: Text('Unidade')),
                    DropdownMenuItem(value: 'ml', child: Text('Mililitro')),
                    DropdownMenuItem(value: 'g', child: Text('Grama')),
                    DropdownMenuItem(value: 'kg', child: Text('Quilograma')),
                    DropdownMenuItem(value: 'cx', child: Text('Caixa')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _unit = value ?? 'un'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ResponsiveFieldRow(
              children: [
                TextFormField(
                  controller: _sku,
                  decoration: const InputDecoration(labelText: 'SKU interno'),
                ),
                TextFormField(
                  controller: _barcode,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Código de barras'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            _ResponsiveFieldRow(
              children: [
                TextFormField(
                  controller: _cost,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Custo unitário'),
                  validator: _validateNonNegativeMoney,
                ),
                TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Preço de venda'),
                  validator: (value) {
                    final parsed = _money(value);
                    return parsed == null || parsed <= 0
                        ? 'Informe um preço maior que zero.'
                        : null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ResponsiveFieldRow(
              children: [
                if (!editing)
                  TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Estoque inicial'),
                    validator: _validateNonNegativeInteger,
                  ),
                TextFormField(
                  controller: _minimum,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Alerta de estoque mínimo',
                  ),
                  validator: _validateNonNegativeInteger,
                ),
              ],
            ),
            if (editing) ...[
              const SizedBox(height: 8),
              const Text(
                'O saldo é alterado somente por “Ajustar estoque”, mantendo o histórico auditável.',
                style: TextStyle(color: SharedAppColors.muted),
              ),
            ],
            const SizedBox(height: 12),
            _CDRToggleTile(
              value: _active,
              title: 'Produto ativo',
              subtitle:
                  'Produtos inativos permanecem no histórico, mas não vendem.',
              onChanged:
                  _saving ? null : (value) => setState(() => _active = value),
            ),
            const SizedBox(height: 16),
            CDRButton.primary(
              label: editing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR PRODUTO',
              onPressed: _saving ? null : _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }

  String? _validateNonNegativeInteger(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 0 ? 'Informe zero ou mais.' : null;
  }

  String? _validateNonNegativeMoney(String? value) {
    final parsed = _money(value);
    return parsed == null || parsed < 0 ? 'Informe um valor válido.' : null;
  }

  double? _money(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<ManagementSession>().saveProduct(
            product: widget.product,
            name: _name.text,
            description: _description.text,
            sku: _sku.text,
            barcode: _barcode.text,
            category: _category.text,
            unit: _unit,
            initialQuantity: int.tryParse(_quantity.text) ?? 0,
            minQuantity: int.parse(_minimum.text.trim()),
            unitCost: _money(_cost.text)!,
            salePrice: _money(_price.text)!,
            isActive: _active,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto salvo com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StockAdjustmentForm extends StatefulWidget {
  const _StockAdjustmentForm({required this.product});

  final ManagedProduct product;

  @override
  State<_StockAdjustmentForm> createState() => _StockAdjustmentFormState();
}

class _StockAdjustmentFormState extends State<_StockAdjustmentForm> {
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  var _entry = true;
  var _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom + 20;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(
            eyebrow: 'MOVIMENTAÇÃO DE ESTOQUE',
            title: widget.product.name,
            onClose: _saving ? null : () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Saldo atual: ${widget.product.quantity} ${widget.product.unit}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Entrada')),
              ButtonSegment(value: false, label: Text('Saída/Ajuste')),
            ],
            selected: {_entry},
            onSelectionChanged: (value) => setState(() => _entry = value.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantidade'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              hintText: 'Compra, perda, contagem de estoque...',
            ),
          ),
          const SizedBox(height: 16),
          CDRButton.primary(
            label: 'CONFIRMAR AJUSTE',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantity.text.trim());
    if (quantity == null || quantity <= 0 || _reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe quantidade e motivo do ajuste.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<ManagementSession>().adjustProductStock(
            widget.product,
            quantityDelta: _entry ? quantity : -quantity,
            reason: _reason.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estoque atualizado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProductSaleForm extends StatefulWidget {
  const _ProductSaleForm();

  @override
  State<_ProductSaleForm> createState() => _ProductSaleFormState();
}

class _ProductSaleFormState extends State<_ProductSaleForm> {
  final _cart = <String, int>{};
  final _discount = TextEditingController(text: '0');
  final _customer = TextEditingController();
  final _notes = TextEditingController();
  String _payment = 'pix';
  String? _selectedProductId;
  var _saving = false;

  @override
  void dispose() {
    _discount.dispose();
    _customer.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();
    final available = session.products
        .where((product) =>
            product.isActive && product.quantity > 0 && product.salePrice > 0)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final lines = [
      for (final entry in _cart.entries)
        if (session.products.any((product) => product.id == entry.key))
          ProductCartLine(
            product: session.products.firstWhere(
              (product) => product.id == entry.key,
            ),
            quantity: entry.value,
          ),
    ];
    final subtotal = lines.fold<double>(0, (total, line) => total + line.total);
    final discount = double.tryParse(_discount.text.replaceAll(',', '.')) ?? 0;
    final total = subtotal - discount;
    final bottom = MediaQuery.viewInsetsOf(context).bottom + 20;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(
            eyebrow: 'PONTO DE VENDA',
            title: 'Nova venda',
            onClose: _saving ? null : () => Navigator.pop(context),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: available.any((item) => item.id == _selectedProductId)
                ? _selectedProductId
                : null,
            decoration: const InputDecoration(labelText: 'Adicionar produto'),
            items: [
              for (final product in available)
                DropdownMenuItem(
                  value: product.id,
                  child: Text(
                    '${product.name} • ${_commerceMoney(product.salePrice)} • ${product.quantity} ${product.unit}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _selectedProductId = value),
          ),
          const SizedBox(height: 8),
          CDRButton.outlined(
            label: 'ADICIONAR AO CARRINHO',
            onPressed: _selectedProductId == null ? null : _addSelected,
            leading: const Icon(Icons.add_rounded),
          ),
          const SizedBox(height: 18),
          if (lines.isEmpty)
            const _InlineNotice(
              icon: Icons.shopping_cart_outlined,
              title: 'Carrinho vazio',
              subtitle: 'Selecione os produtos vendidos.',
            )
          else
            for (final line in lines)
              _CartLineTile(
                line: line,
                onDecrease: () => _changeQuantity(line.product, -1),
                onIncrease: line.quantity < line.product.quantity
                    ? () => _changeQuantity(line.product, 1)
                    : null,
              ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _payment,
            decoration: const InputDecoration(labelText: 'Forma de pagamento'),
            items: const [
              DropdownMenuItem(value: 'pix', child: Text('PIX')),
              DropdownMenuItem(value: 'cash', child: Text('Dinheiro')),
              DropdownMenuItem(
                value: 'credit_card',
                child: Text('Cartão de crédito'),
              ),
              DropdownMenuItem(
                value: 'debit_card',
                child: Text('Cartão de débito'),
              ),
              DropdownMenuItem(value: 'other', child: Text('Outro')),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _payment = value ?? 'pix'),
          ),
          const SizedBox(height: 12),
          _ResponsiveFieldRow(
            children: [
              TextField(
                controller: _discount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Desconto'),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                controller: _customer,
                decoration: const InputDecoration(
                  labelText: 'Cliente (opcional)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Observações'),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SharedAppColors.elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SharedAppColors.stroke),
            ),
            child: Column(
              children: [
                _SaleTotalRow(label: 'Subtotal', value: subtotal),
                if (discount > 0)
                  _SaleTotalRow(label: 'Desconto', value: -discount),
                const Divider(color: SharedAppColors.stroke),
                _SaleTotalRow(label: 'Total', value: total, emphasized: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CDRButton.primary(
            label: 'FINALIZAR VENDA',
            onPressed: _saving || lines.isEmpty || discount < 0 || total < 0
                ? null
                : () => _save(lines, discount),
            isLoading: _saving,
          ),
        ],
      ),
    );
  }

  void _addSelected() {
    final id = _selectedProductId;
    if (id == null) return;
    final session = context.read<ManagementSession>();
    final product = session.products.firstWhere((item) => item.id == id);
    final current = _cart[id] ?? 0;
    if (current >= product.quantity) return;
    setState(() {
      _cart[id] = current + 1;
      _selectedProductId = null;
    });
  }

  void _changeQuantity(ManagedProduct product, int delta) {
    final next = (_cart[product.id] ?? 0) + delta;
    setState(() {
      if (next <= 0) {
        _cart.remove(product.id);
      } else if (next <= product.quantity) {
        _cart[product.id] = next;
      }
    });
  }

  Future<void> _save(List<ProductCartLine> lines, double discount) async {
    setState(() => _saving = true);
    try {
      await context.read<ManagementSession>().registerProductSale(
            items: lines,
            paymentMethod: _payment,
            discount: discount,
            customerName: _customer.text,
            notes: _notes.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda registrada e estoque atualizado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.onDecrease,
    required this.onIncrease,
  });

  final ProductCartLine line;
  final VoidCallback onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SharedAppColors.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  _commerceMoney(line.total),
                  style: const TextStyle(color: SharedAppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text('${line.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _SaleTotalRow extends StatelessWidget {
  const _SaleTotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            _commerceMoney(value),
            style: TextStyle(
              color: emphasized ? SharedAppColors.orange : null,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
              fontSize: emphasized ? 18 : null,
            ),
          ),
        ],
      ),
    );
  }
}
