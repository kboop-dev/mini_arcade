import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/avatar_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/fit_appbar_title.dart';

class AvatarEditorScreen extends StatefulWidget {
  final AvatarConfig initial;
  const AvatarEditorScreen({super.key, required this.initial});

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  late AvatarConfig _config;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _config = widget.initial;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    final db = context.read<FirestoreService>();
    await db.saveAvatar(auth.currentUser!.uid, _config.toMap());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const FitAppBarTitle('Crea tu avatar')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgDark2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.pink, width: 2),
                  ),
                  child: AvatarView(config: _config, size: 140),
                ),
                const SizedBox(height: 24),
                _SwatchSection(
                  title: 'Tono de piel',
                  colors: avatarSkinTones,
                  selectedIndex: _config.skinIndex,
                  onSelected: (i) => setState(() => _config = _config.copyWith(skinIndex: i)),
                ),
                _StyleSection(
                  title: 'Estilo de cabello',
                  labels: hairStyleLabels,
                  selectedIndex: _config.hairStyleIndex,
                  onSelected: (i) => setState(() => _config = _config.copyWith(hairStyleIndex: i)),
                ),
                _SwatchSection(
                  title: 'Color de cabello',
                  colors: avatarHairColors,
                  selectedIndex: _config.hairColorIndex,
                  onSelected: (i) => setState(() => _config = _config.copyWith(hairColorIndex: i)),
                ),
                _SwatchSection(
                  title: 'Color de ojos',
                  colors: avatarEyeColors,
                  selectedIndex: _config.eyeColorIndex,
                  onSelected: (i) => setState(() => _config = _config.copyWith(eyeColorIndex: i)),
                ),
                _SwatchSection(
                  title: 'Color de ropa',
                  colors: avatarOutfitColors,
                  selectedIndex: _config.outfitColorIndex,
                  onSelected: (i) => setState(() => _config = _config.copyWith(outfitColorIndex: i)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('GUARDAR AVATAR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwatchSection extends StatelessWidget {
  final String title;
  final List<Color> colors;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const _SwatchSection({
    required this.title,
    required this.colors,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(colors.length, (i) {
              final selected = i == selectedIndex;
              return GestureDetector(
                onTap: () => onSelected(i),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.gold : Colors.black45,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 18, color: Colors.black87)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StyleSection extends StatelessWidget {
  final String title;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const _StyleSection({
    required this.title,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(labels.length, (i) {
              final selected = i == selectedIndex;
              return ChoiceChip(
                label: Text(labels[i]),
                selected: selected,
                onSelected: (_) => onSelected(i),
              );
            }),
          ),
        ],
      ),
    );
  }
}
