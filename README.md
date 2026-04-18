# Template Flutter Firebase CRUD Mahasiswa

File ini berisi contoh sederhana aplikasi Flutter untuk CRUD data mahasiswa dengan Firebase Cloud Firestore.

## Langkah setup

1. Buat project Flutter.
2. Tambahkan package:
   - `flutter pub add firebase_core`
   - `flutter pub add cloud_firestore`
3. Install dan login CLI:
   - `firebase login`
   - `dart pub global activate flutterfire_cli`
4. Dari root project Flutter, jalankan:
   - `flutterfire configure`
5. Copy file `lib/` dari template ini ke project kamu.
6. Copy file `firebase_options.dart` hasil generate FlutterFire ke folder `lib/` project kamu.
7. Jalankan `flutter run`.

## Struktur data Firestore

Collection: `mahasiswa`

Contoh dokumen:

```json
{
  "nama": "Budi Santoso",
  "nim": "2300012345",
  "jurusan": "Teknik Informatika",
  "prodi": "S1 Informatika",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

## Catatan keamanan

Rule yang disediakan hanya untuk development/testing lokal. Jangan pakai rule `allow read, write: if true;` untuk production.
