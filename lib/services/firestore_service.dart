import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/ticket_catalog.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<AppUser> watchUser(String uid) {
    return _userDoc(uid).snapshots().map(
          (snap) => AppUser.fromMap(uid, snap.data() ?? {}),
        );
  }

  Future<AppUser> getUser(String uid) async {
    final snap = await _userDoc(uid).get();
    return AppUser.fromMap(uid, snap.data() ?? {});
  }

  /// Suma XP de forma atómica (segura contra condiciones de carrera)
  Future<void> addXp(String uid, int amount) {
    return _userDoc(uid).update({'xp': FieldValue.increment(amount)});
  }

  /// Marca un ticket como desbloqueado (sin canjear todavía)
  Future<void> unlockTicket(String uid, String ticketId) {
    return _userDoc(uid).update({'ticketsUnlocked.$ticketId': false});
  }

  /// Canjea un ticket ya desbloqueado y otorga +200 XP una sola vez
  Future<void> redeemTicket(String uid, String ticketId) async {
    final snap = await _userDoc(uid).get();
    final data = snap.data() ?? {};
    final unlocked = Map<String, dynamic>.from(data['ticketsUnlocked'] ?? {});
    if (unlocked[ticketId] == true) return; // ya canjeado, evita XP duplicado

    await _userDoc(uid).update({
      'ticketsUnlocked.$ticketId': true,
      'xp': FieldValue.increment(200),
    });
  }

  /// Marca un rompecabezas oficial (1-10) como completado en modo supervivencia
  Future<void> completePuzzleSurvival(String uid, String puzzleId) async {
    final snap = await _userDoc(uid).get();
    final data = snap.data() ?? {};
    final list = List<String>.from(data['puzzlesCompletedSurvival'] ?? []);
    if (list.contains(puzzleId)) return; // ya contaba, evita XP duplicado

    await _userDoc(uid).update({
      'puzzlesCompletedSurvival': FieldValue.arrayUnion([puzzleId]),
    });

    // Si con este ya completó los 10, otorga el bonus de +1000 XP una sola vez
    if (list.length + 1 >= 10) {
      await addXp(uid, 1000);
    }
  }

  /// Guarda el avance de un rompecabezas en modo creativo (para poder salir y volver)
  Future<void> savePuzzleCreativeProgress(
    String uid,
    String puzzleId,
    Map<String, dynamic> boardState,
  ) {
    return _userDoc(uid)
        .collection('puzzle_progress')
        .doc(puzzleId)
        .set(boardState);
  }

  Future<Map<String, dynamic>?> loadPuzzleCreativeProgress(
    String uid,
    String puzzleId,
  ) async {
    final snap =
        await _userDoc(uid).collection('puzzle_progress').doc(puzzleId).get();
    return snap.data();
  }

  /// Desbloquea UN ticket del catálogo que pertenezca a [gameKey] y que el
  /// jugador todavía NO tenga, para que cada victoria dé un ticket distinto
  /// en vez de repetir siempre el mismo. Si ya tiene todos los de ese juego,
  /// no hace nada (ya se los ganó todos).
  Future<void> unlockRandomTicketForGame(String uid, String gameKey) async {
    final snap = await _userDoc(uid).get();
    final data = snap.data() ?? {};
    final unlocked = Map<String, dynamic>.from(data['ticketsUnlocked'] ?? {});

    final poolIds = ticketCatalog
        .where((t) => t.gameKey == gameKey)
        .map((t) => t.id)
        .toList();
    final available = poolIds.where((id) => !unlocked.containsKey(id)).toList();
    if (available.isEmpty) return; // ya tiene todos los tickets de este juego

    available.shuffle();
    final chosenId = available.first;
    await _userDoc(uid).update({'ticketsUnlocked.$chosenId': false});
  }
}
