import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/ticket_catalog.dart';
import '../../theme/app_theme.dart';

class TicketsGalleryScreen extends StatelessWidget {
  const TicketsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final db = context.read<FirestoreService>();
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Galería de tickets 🎟️')),
      body: StreamBuilder<AppUser>(
        stream: db.watchUser(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // ticketsUnlocked: id -> canjeado?(bool). Si un ticket del catálogo
          // no está en este mapa, sigue bloqueado (no lo ha encontrado).
          final unlocked = snapshot.data!.ticketsUnlocked;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.gridColumns(context),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: ticketCatalog.length,
            itemBuilder: (context, i) {
              final def = ticketCatalog[i];
              final found = unlocked.containsKey(def.id);
              final redeemed = unlocked[def.id] == true;
              return _TicketCard(
                def: def,
                found: found,
                redeemed: redeemed,
                onRedeem: () => db.redeemTicket(uid, def.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketDefinition def;
  final bool found;
  final bool redeemed;
  final VoidCallback onRedeem;
  const _TicketCard({
    required this.def,
    required this.found,
    required this.redeemed,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          found ? () => _openDetail(context) : () => _showLockedHint(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgDark2,
          border: Border.all(
            color: !found
                ? Colors.white24
                : (redeemed ? Colors.white38 : AppColors.gold),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (found)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Opacity(
                    opacity: redeemed ? 0.5 : 1,
                    child: Image.asset(
                      def.imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.card_giftcard,
                        size: 40,
                        color: redeemed ? Colors.white38 : AppColors.gold,
                      ),
                    ),
                  ),
                ),
              )
            else
              const Expanded(
                child: Icon(Icons.lock, size: 36, color: Colors.white24),
              ),
            const SizedBox(height: 6),
            Text(
              !found
                  ? '¿?'
                  : (redeemed
                      ? 'Ticket canjeado'
                      : '¡Ticket especial!\nToca para abrir'),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Todavía no encuentras este ticket 👀 ¡sigue jugando!')),
    );
  }

  void _openDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          _TicketDetailDialog(def: def, redeemed: redeemed, onRedeem: onRedeem),
    );
  }
}

class _TicketDetailDialog extends StatelessWidget {
  final TicketDefinition def;
  final bool redeemed;
  final VoidCallback onRedeem;
  const _TicketDetailDialog({
    required this.def,
    required this.redeemed,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgDark2,
      child: ConstrainedBox(
        // Límite de alto para que nunca se desborde, sin importar el
        // tamaño real de la imagen del ticket (arregla el warning de overflow).
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(def.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Image.asset(
                  def.imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: AppColors.bgDark,
                    child: const Icon(Icons.card_giftcard,
                        size: 64, color: AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                def.prizeText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              if (redeemed)
                Text('Ya canjeaste este ticket 💕',
                    style: const TextStyle(fontSize: 12, color: Colors.white54))
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCELAR'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        onRedeem();
                        Navigator.pop(context);
                      },
                      child: const Text('CANJEAR (+200 XP)'),
                    ),
                  ],
                ),
              if (redeemed)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CERRAR'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
