/// Catálogo fijo de tickets del juego.
class TicketDefinition {
  final String id; // id fijo del catálogo
  final String
      gameKey; // a qué juego pertenece: 'puzzle', 'minesweeper', 'hangman', 'battle_target'
  final String title;
  final String prizeText;
  final String imageAsset;

  const TicketDefinition({
    required this.id,
    required this.gameKey,
    required this.title,
    required this.prizeText,
    required this.imageAsset,
  });
}

const List<TicketDefinition> ticketCatalog = [
  // Rompecabezas (modo cronómetro, 100 piezas) — 3 tickets
  TicketDefinition(
    id: 'ticket1',
    gameKey: 'puzzle',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por una dia de SPA 💆',
    imageAsset: 'assets/images/tickets/ticket1.png',
  ),
  TicketDefinition(
    id: 'ticket2',
    gameKey: 'puzzle',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por un frappesillo.',
    imageAsset: 'assets/images/tickets/ticket2.png',
  ),
  TicketDefinition(
    id: 'ticket3',
    gameKey: 'puzzle',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por una hacer videollamadaa.',
    imageAsset: 'assets/images/tickets/ticket3.png',
  ),

  // Buscaminas (dificultad difícil) — 3 tickets
  TicketDefinition(
    id: 'ticket4',
    gameKey: 'minesweeper',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por una cita romántica con temática.',
    imageAsset: 'assets/images/tickets/ticket4.png',
  ),
  TicketDefinition(
    id: 'ticket5',
    gameKey: 'minesweeper',
    title: '¡Ticket Especial!',
    prizeText: 'Válido porque te haga un postresillo.',
    imageAsset: 'assets/images/tickets/ticket5.png',
  ),
  TicketDefinition(
    id: 'ticket6',
    gameKey: 'minesweeper',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por un día de SI a todoo.',
    imageAsset: 'assets/images/tickets/ticket6.png',
  ),

  // ¿Qué tanto me conoces? (ahorcado) — 2 tickets
  TicketDefinition(
    id: 'ticket7',
    gameKey: 'hangman',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por una pizzaa.',
    imageAsset: 'assets/images/tickets/ticket7.png',
  ),
  TicketDefinition(
    id: 'ticket8',
    gameKey: 'hangman',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por una noche de videojuegos<3',
    imageAsset: 'assets/images/tickets/ticket8.png',
  ),

  // Zona de Combate (dificultad difícil, 400+ puntos) — 2 tickets
  TicketDefinition(
    id: 'ticket9',
    gameKey: 'battle_target',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por un día de fucho.',
    imageAsset: 'assets/images/tickets/ticket10.png',
  ),
  TicketDefinition(
    id: 'ticket10',
    gameKey: 'battle_target',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por cumplir cualquier deseo +18',
    imageAsset: 'assets/images/tickets/ticket9.png',
  ),

  // Solitario (ganar reciclando el mazo 1 vez o menos) — 2 tickets
  TicketDefinition(
    id: 'ticket11',
    gameKey: 'solitaire',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por un pancito de muertos.',
    imageAsset: 'assets/images/tickets/ticket11.png',
  ),
  TicketDefinition(
    id: 'ticket12',
    gameKey: 'solitaire',
    title: '¡Ticket Especial!',
    prizeText: 'Válido por un desayunito.',
    imageAsset: 'assets/images/tickets/ticket12.png',
  ),
];

TicketDefinition? ticketById(String id) {
  for (final t in ticketCatalog) {
    if (t.id == id) return t;
  }
  return null;
}
