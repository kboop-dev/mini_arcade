import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/narrator_overlay.dart';
import '../../../widgets/fit_appbar_title.dart';

const String kAnniversaryDate = '22/09/2023';

const String kAnniversaryLetter =
    'Aquí va la carta de su aniversario. Reemplaza este texto por el mensaje real 💌';

class SafeScreen extends StatefulWidget {
  const SafeScreen({super.key});
  @override
  State<SafeScreen> createState() => _SafeScreenState();
}

class _SafeScreenState extends State<SafeScreen> {
  final _dayCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  bool _open = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showNarratorIfNeeded(
        context,
        gameKey: 'safe',
        lines: [
          'Esta cajita guarda un secreto 🔒. Tienes que adivinar una fecha muy especial para nosotros y escribirla.',
          'Si aciertas, se abre y te lleva +300 XP. Este juego no tiene ticket escondido, ¡es un extra especial solo para ti!',
        ],
      );
    });
  }

  Future<void> _tryOpen() async {
    final entered =
        '${_dayCtrl.text.padLeft(2, '0')}/${_monthCtrl.text.padLeft(2, '0')}/${_yearCtrl.text}';
    if (entered == kAnniversaryDate) {
      setState(() {
        _open = true;
        _error = null;
      });
      final auth = context.read<AuthService>();
      final db = context.read<FirestoreService>();
      await db.addXp(auth.currentUser!.uid, 300);
    } else {
      setState(() => _error =
          '¿Cómo vas a creer? esa no eess... ¡tienes otra oportunidad!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: FitAppBarTitle('Caja fuerte')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _open ? _buildLetter() : _buildLock(),
        ),
      ),
    );
  }

  Widget _buildLock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock, size: 72, color: AppColors.gold),
        const SizedBox(height: 16),
        const Text('Ingresa la fecha especial (DD / MM / AAAA)'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _numField(_dayCtrl, 'DD', 2),
            const SizedBox(width: 8),
            _numField(_monthCtrl, 'MM', 2),
            const SizedBox(width: 8),
            _numField(_yearCtrl, 'AAAA', 4, width: 70),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.heartRed)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _tryOpen, child: const Text('ABRIR')),
      ],
    );
  }

  Widget _numField(TextEditingController c, String hint, int maxLen,
      {double width = 55}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: c,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: maxLen,
        decoration: InputDecoration(counterText: '', hintText: hint),
      ),
    );
  }

  Widget _buildLetter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sello de cera (decorativo) sobre la carta
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.heartRed,
            boxShadow: [
              BoxShadow(
                  color: AppColors.heartRed.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1),
            ],
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 26),
        ),
        Transform.translate(
          offset: const Offset(0, -12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                // Look de hoja de papel/carta antigua, no de caja de juego
                color: const Color(0xFFFBF3E1),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black45,
                      blurRadius: 16,
                      offset: Offset(0, 8)),
                ],
                border: Border.all(color: const Color(0xFFD9C79A), width: 6),
              ),
              child: Column(
                children: [
                  const Text('✦ ✦ ✦',
                      style: TextStyle(color: Color(0xFFB8955C), fontSize: 12)),
                  const SizedBox(height: 12),
                  Text(
                    kAnniversaryLetter,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      color: Color(0xFF3D2B1F),
                      fontSize: 11,
                      height: 1.9,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(' Keyla 💕',
                      style: TextStyle(color: Color(0xFF3D2B1F), fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('VOLVER AL ARCADE'),
        ),
      ],
    );
  }
}
