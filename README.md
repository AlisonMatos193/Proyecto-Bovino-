# Catálogo Digital Bovino · Tizimín

App Flutter offline-first. SQLite local = fuente de verdad; los cambios se encolan en `sync_queue` y se envían a la nube al detectar red.

## Correr
```bash
flutter create . --platforms=android   # genera android/ (una sola vez, no sobrescribe lib/ ni pubspec)
flutter pub get
flutter run
```
Android: agrega en `android/app/src/main/AndroidManifest.xml` el permiso `<uses-permission android:name="android.permission.INTERNET"/>` (release) si usarás sincronización.

## Estructura
- `assets/db/schema.sql` esquema (tablas de tu diagrama ER + `sync_queue`). `seed.sql` = datos de ejemplo (solo debug).
- `lib/db` apertura de SQLite · `lib/data/repository.dart` consultas y escrituras + cola de sync
- `lib/services/consanguinidad.dart` asesor genético · `lib/services/sync_service.dart` sincronización
- `lib/ui` Vitrina (módulo 1), Mi rancho e IATF (módulo 2), Asesor genético (módulo 3)

## Para cambiar el esquema
Sube `version` en `app_database.dart` y agrega la migración en `onUpgrade`. Para reiniciar en desarrollo, desinstala la app.
