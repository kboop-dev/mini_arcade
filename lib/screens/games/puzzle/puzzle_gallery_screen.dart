import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import 'puzzle_game_screen.dart';

enum PuzzleMode { cronometro, creativo }

final List<String> officialPuzzlePhotos = [
  'assets/images/puzzles/foto1.jpeg',
  'assets/images/puzzles/foto2.jpeg',
  'assets/images/puzzles/foto3.jpeg',
  'assets/images/puzzles/foto4.jpeg',
  'assets/images/puzzles/foto5.jpeg',
  'assets/images/puzzles/foto6.jpeg',
  'assets/images/puzzles/foto7.jpeg',
  'assets/images/puzzles/foto8.jpeg',
  'assets/images/puzzles/foto9.jpeg',
  'assets/images/puzzles/foto10.jpeg',
];

class PuzzleGalleryScreen extends StatelessWidget {
  const PuzzleGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rompecabezas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Elige una de nuestras fotos:'),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.gridColumns(context),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: officialPuzzlePhotos.length,
                itemBuilder: (context, i) => _PhotoTile(
                  puzzleId: 'official_$i',
                  assetPath: officialPuzzlePhotos[i],
                ),
              ),
            ),
            const Divider(height: 32, color: Colors.white24),
            OutlinedButton.icon(
              icon:
                  const Icon(Icons.add_photo_alternate, color: AppColors.cyan),
              label: const Text('Subir una foto propia'),
              onPressed: () => _pickCustomPhoto(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !context.mounted) return;

    // IMPORTANTE: se leen los BYTES de la imagen (funciona en web, celular
    // y escritorio) en vez de usar la ruta del archivo, que en Flutter Web
    // no se puede abrir con dart:io y era la causa de que "no jalara".
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;

    _openConfig(
      context,
      puzzleId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      customImageBytes: bytes,
    );
  }

  void _openConfig(
    BuildContext context, {
    required String puzzleId,
    String? assetPath,
    Uint8List? customImageBytes,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDark2,
      isScrollControlled: true,
      builder: (_) => _PuzzleConfigSheet(
        puzzleId: puzzleId,
        assetPath: assetPath,
        customImageBytes: customImageBytes,
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String puzzleId;
  final String assetPath;
  const _PhotoTile({required this.puzzleId, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.bgDark2,
        isScrollControlled: true,
        builder: (_) =>
            _PuzzleConfigSheet(puzzleId: puzzleId, assetPath: assetPath),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.pink, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                color: AppColors.magenta,
                child: const Icon(Icons.image, color: Colors.white54))),
      ),
    );
  }
}

class _PuzzleConfigSheet extends StatefulWidget {
  final String puzzleId;
  final String? assetPath;
  final Uint8List? customImageBytes;
  const _PuzzleConfigSheet({
    required this.puzzleId,
    this.assetPath,
    this.customImageBytes,
  });

  @override
  State<_PuzzleConfigSheet> createState() => _PuzzleConfigSheetState();
}

class _PuzzleConfigSheetState extends State<_PuzzleConfigSheet> {
  int _pieces = 35;
  PuzzleMode _mode = PuzzleMode.creativo;

  @override
  Widget build(BuildContext context) {
    // Vista previa de la foto elegida, para que quede claro cuál vas a armar
    final ImageProvider preview = widget.customImageBytes != null
        ? MemoryImage(widget.customImageBytes!)
        : AssetImage(widget.assetPath!) as ImageProvider;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image(image: preview, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Número de piezas'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [35, 50, 100].map((p) {
                return ChoiceChip(
                  label: Text('$p'),
                  selected: _pieces == p,
                  onSelected: (_) => setState(() => _pieces = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Modo de juego'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                label: const Text('Cronómetro (2 min)'),
                selected: _mode == PuzzleMode.cronometro,
                onSelected: (_) =>
                    setState(() => _mode = PuzzleMode.cronometro),
              ),
              ChoiceChip(
                label: const Text('Chill / Creativo'),
                selected: _mode == PuzzleMode.creativo,
                onSelected: (_) => setState(() => _mode = PuzzleMode.creativo),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PuzzleGameScreen(
                        puzzleId: widget.puzzleId,
                        assetPath: widget.assetPath,
                        customImageBytes: widget.customImageBytes,
                        pieceCount: _pieces,
                        mode: _mode,
                      ),
                    ),
                  );
                },
                child: const Text('EMPEZAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
