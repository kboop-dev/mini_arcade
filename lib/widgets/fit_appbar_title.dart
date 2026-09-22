import 'package:flutter/material.dart';

/// Título de AppBar que se reduce automáticamente si no cabe, en vez de
/// cortarse con "...". Úsalo así: `AppBar(title: FitAppBarTitle('Mi título'))`
class FitAppBarTitle extends StatelessWidget {
  final String text;
  const FitAppBarTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}
