import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/arcade_background.dart';
import 'games/puzzle/puzzle_gallery_screen.dart';
import 'games/safe/safe_screen.dart';
import 'games/minesweeper/minesweeper_screen.dart';
import 'games/hangman/hangman_screen.dart';
import 'games/battle_target/battle_target_screen.dart';
import 'tickets/tickets_gallery_screen.dart';

class GameEntry {
  final String title;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const GameEntry(this.title, this.icon, this.color, this.builder);
}

class HomeArcadeScreen extends StatelessWidget {
  const HomeArcadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final db = context.read<FirestoreService>();
    final uid = auth.currentUser!.uid;

    final games = <GameEntry>[
      GameEntry('¿Qué tanto\nme conoces?', Icons.psychology, AppColors.magenta,
          (_) => const HangmanScreen()),
      GameEntry('Rompecabezas', Icons.extension, AppColors.cyan,
          (_) => const PuzzleGalleryScreen()),
      GameEntry(
          'Caja fuerte', Icons.lock, AppColors.gold, (_) => const SafeScreen()),
      GameEntry('Buscaminas', Icons.favorite, AppColors.heartRed,
          (_) => const MinesweeperScreen()),
      GameEntry('Zona de\nCombate', Icons.gps_fixed, AppColors.pink,
          (_) => const BattleTargetScreen()),
    ];

    return ArcadeBackground(
      imagePath: 'assets/images/backgrounds/bg_home.jpeg',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: StreamBuilder<AppUser>(
                stream: db.watchUser(uid),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _Header(user: user)),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Responsive.gridColumns(context),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.95,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _GameCard(entry: games[i]),
                            childCount: games.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.card_giftcard,
                                color: AppColors.gold),
                            label: const Text('Galería de tickets'),
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const TicketsGalleryScreen())),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextButton(
                            onPressed: () => auth.logout(),
                            child: const Text('Cerrar sesión',
                                style: TextStyle(color: AppColors.textLight)),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppUser? user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    final xp = user?.xp ?? 0;
    final rank = PlayerRank.fromXp(xp);
    final next = rank.next;
    final progress =
        next == null ? 1.0 : (xp - rank.minXp) / (next.minXp - rank.minXp);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgDark2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.pink, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¡Hola, ${user?.username ?? '...'}!',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(rank.label,
                style: const TextStyle(color: AppColors.gold, fontSize: 14)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 10,
                backgroundColor: Colors.white24,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              next == null
                  ? '¡Rango máximo alcanzado! ($xp XP)'
                  : '$xp / ${next.minXp} XP para ${next.label}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameEntry entry;
  const _GameCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: entry.builder)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgDark2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: entry.color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(entry.icon, size: 40, color: entry.color),
            const SizedBox(height: 12),
            Text(
              entry.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
