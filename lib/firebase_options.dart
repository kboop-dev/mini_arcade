// ============================================================================
// PLANTILLA — este archivo SÍ se sube a GitHub (no tiene llaves reales).
//
// El archivo real `firebase_options.dart` lo genera automáticamente el
// comando `flutterfire configure` (ver README.md, paso 3) y queda
// IGNORADO por git (revisa .gitignore). Cada quien que clone el repo
// debe correr `flutterfire configure` con su propio proyecto de Firebase
// para generar su propio firebase_options.dart local.
// ============================================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC3zPOBqyyzZnMpWSLBLDL686FR7nihQS4',
    appId: '1:597290489866:web:46785ed4d2c7f94b2ce7f3',
    messagingSenderId: '597290489866',
    projectId: 'mini-arcade-63351',
    authDomain: 'mini-arcade-63351.firebaseapp.com',
    storageBucket: 'mini-arcade-63351.firebasestorage.app',
    measurementId: 'G-XNDKQS5HDH',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REEMPLAZA_CON_TU_API_KEY',
    appId: 'REEMPLAZA_CON_TU_APP_ID',
    messagingSenderId: 'REEMPLAZA_CON_TU_SENDER_ID',
    projectId: 'REEMPLAZA_CON_TU_PROJECT_ID',
    storageBucket: 'REEMPLAZA_CON_TU_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REEMPLAZA_CON_TU_API_KEY',
    appId: 'REEMPLAZA_CON_TU_APP_ID',
    messagingSenderId: 'REEMPLAZA_CON_TU_SENDER_ID',
    projectId: 'REEMPLAZA_CON_TU_PROJECT_ID',
    storageBucket: 'REEMPLAZA_CON_TU_STORAGE_BUCKET',
    iosBundleId: 'com.tuusuario.keylaianarcade',
  );
}
