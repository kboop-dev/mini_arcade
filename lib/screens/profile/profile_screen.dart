import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/music_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/fit_appbar_title.dart';
import 'avatar_editor_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final db = context.read<FirestoreService>();
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const FitAppBarTitle('Perfil de jugador')),
      body: StreamBuilder<AppUser>(
        stream: db.watchUser(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data!;
          final rank = PlayerRank.fromXp(user.xp);
          final next = rank.next;
          final progress =
              next == null ? 1.0 : (user.xp - rank.minXp) / (next.minXp - rank.minXp);

          return Center(
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
                      child: AvatarView(config: user.avatar, size: 140),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.brush, size: 16, color: AppColors.cyan),
                      label: const Text('Editar avatar',
                          style: TextStyle(color: AppColors.cyan)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AvatarEditorScreen(initial: user.avatar),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user.username, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(rank.label, style: const TextStyle(color: AppColors.gold, fontSize: 14)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 12,
                        backgroundColor: Colors.white24,
                        color: AppColors.cyan,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      next == null
                          ? '¡Rango máximo alcanzado! (${user.xp} XP)'
                          : '${user.xp} / ${next.minXp} XP para ${next.label}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 28),
                    _RankLadder(currentXp: user.xp),
                    const SizedBox(height: 28),
                    // Música: ahora vive aquí en vez de un botón flotante
                    // que estorbe durante los minijuegos.
                    Consumer<MusicService>(
                      builder: (context, music, _) => SwitchListTile(
                        value: !music.isMuted,
                        onChanged: (_) => music.toggleMute(),
                        activeColor: AppColors.cyan,
                        title: const Text('Música de fondo', style: TextStyle(fontSize: 13)),
                        secondary: Icon(
                          music.isMuted ? Icons.music_off : Icons.music_note,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Cerrar sesión'),
                      onPressed: () => auth.logout(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RankLadder extends StatelessWidget {
  final int currentXp;
  const _RankLadder({required this.currentXp});

  @override
  Widget build(BuildContext context) {
    final currentRank = PlayerRank.fromXp(currentXp);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Rangos', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ),
        const SizedBox(height: 8),
        ...PlayerRank.values.map((r) {
          final reached = currentXp >= r.minXp;
          final isCurrent = r == currentRank;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  reached ? Icons.emoji_events : Icons.lock_outline,
                  size: 16,
                  color: reached ? AppColors.gold : Colors.white24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${r.label} (${r.minXp} XP)',
                    style: TextStyle(
                      fontSize: 12,
                      color: reached ? AppColors.textLight : Colors.white38,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isCurrent)
                  const Text('← tú', style: TextStyle(fontSize: 11, color: AppColors.pink)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
