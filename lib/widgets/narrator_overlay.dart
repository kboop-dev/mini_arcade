import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/narrator_service.dart';
import '../theme/app_theme.dart';

/// Llama esto en el initState (o justo después del primer build) de
/// cualquier pantalla de juego para que, SOLO la primera vez, Keyla
/// aparezca narrando cómo se juega y cómo se consiguen los tickets.
///
/// Ejemplo de uso dentro de un State:
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   WidgetsBinding.instance.addPostFrameCallback((_) {
///     showNarratorIfNeeded(
///       context,
///       gameKey: 'trivia',
///       lines: [
///         'Aquí te voy a hacer 10 preguntas al azar sobre nosotros. ¡Tienes 3 corazones!',
///         'Si fallas 3 veces, pierdes. Pero si las aciertas TODAS, te llevas +500 XP y un ticket sorpresa 🎟️',
///       ],
///     );
///   });
/// }
/// ```
Future<void> showNarratorIfNeeded(
  BuildContext context, {
  required String gameKey,
  required List<String> lines,
}) async {
  final narrator = context.read<NarratorService>();
  final alreadySeen = await narrator.hasSeen(gameKey);
  if (alreadySeen || !context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => NarratorDialog(lines: lines),
  );
  await narrator.markSeen(gameKey);
}

class NarratorDialog extends StatefulWidget {
  final List<String> lines;
  const NarratorDialog({super.key, required this.lines});

  @override
  State<NarratorDialog> createState() => _NarratorDialogState();
}

class _NarratorDialogState extends State<NarratorDialog> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isLast = _index == widget.lines.length - 1;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Retrato pixel art de Keyla. Coloca el archivo real en:
            // assets/images/characters/keyla_narrador.png
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyan, width: 3),
                color: AppColors.bgDark2,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/characters/keyla_narrador.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.face_retouching_natural,
                  color: AppColors.cyan,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text('KEYLA',
                style: TextStyle(
                    color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Globo de diálogo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgDark2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.pink, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lines[_index],
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_index + 1}/${widget.lines.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (isLast) {
                            Navigator.of(context).pop();
                          } else {
                            setState(() => _index++);
                          }
                        },
                        child: Text(isLast ? 'ENTENDIDO' : 'SIGUIENTE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
