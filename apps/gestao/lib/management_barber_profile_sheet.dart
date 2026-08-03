part of 'management.dart';

class _BarberProfileSheet extends StatefulWidget {
  const _BarberProfileSheet();

  @override
  State<_BarberProfileSheet> createState() => _BarberProfileSheetState();
}

class _BarberProfileSheetState extends State<_BarberProfileSheet> {
  var _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final barber = context.watch<ManagementSession>().currentBarber;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 560),
      margin: const EdgeInsets.only(top: 24),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              eyebrow: 'PERFIL DO BARBEIRO',
              title: 'Minha foto profissional',
              onClose: _isUploading ? null : () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
            if (barber == null)
              const Text(
                'Não foi possível identificar seu perfil de barbeiro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SharedAppColors.muted),
              )
            else ...[
              Center(child: _BarberPhotoAvatar(barber: barber)),
              const SizedBox(height: 16),
              Text(
                barber.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Essa foto aparece para os clientes ao escolherem um profissional.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SharedAppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isUploading ? null : _pickAndUpload,
                style: FilledButton.styleFrom(
                  backgroundColor: SharedAppColors.orange,
                  foregroundColor: SharedAppColors.onGold,
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: _isUploading
                    ? const CDRLoading.compact(size: 22)
                    : const Icon(Icons.photo_library_outlined),
                label: Text(
                  _isUploading
                      ? 'Enviando foto...'
                      : barber.photoUrl.isEmpty
                          ? 'Adicionar foto'
                          : 'Alterar foto',
                ),
              ),
              if (barber.photoUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _isUploading ? null : _removePhoto,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Remover foto'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    setState(() => _isUploading = true);
    try {
      final file = await pickLogoFile(
        maxWidth: 1024,
        maxHeight: 1024,
        compressionThresholdBytes: 600 * 1024,
        quality: 0.86,
      );
      if (file == null) return;

      final session = context.read<ManagementSession>();
      final url = await session.uploadShopMedia(file, folder: 'barbers');
      await session.updateCurrentBarberPhoto(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profissional salva com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isUploading = true);
    try {
      await context.read<ManagementSession>().updateCurrentBarberPhoto('');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profissional removida.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class _BarberPhotoAvatar extends StatelessWidget {
  const _BarberPhotoAvatar({required this.barber});

  final TeamBarber barber;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 64,
          backgroundColor: SharedAppColors.elevated,
          backgroundImage:
              barber.photoUrl.isEmpty ? null : NetworkImage(barber.photoUrl),
          child: barber.photoUrl.isEmpty
              ? const Icon(
                  Icons.person_rounded,
                  size: 64,
                  color: SharedAppColors.orange,
                )
              : null,
        ),
        const Positioned(
          right: -2,
          bottom: -2,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: SharedAppColors.orange,
            child: Icon(
              Icons.camera_alt_rounded,
              size: 20,
              color: SharedAppColors.onGold,
            ),
          ),
        ),
      ],
    );
  }
}
