import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mahasiswa.dart';

class MahasiswaService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('mahasiswa');

  Stream<List<Mahasiswa>> streamMahasiswa() {
    return _collection
        .orderBy('nama')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Mahasiswa.fromFirestore(doc))
            .toList());
  }

  Future<void> tambahMahasiswa(Mahasiswa mahasiswa) async {
    final nimSudahAda = await _collection
        .where('nim', isEqualTo: mahasiswa.nim.trim())
        .limit(1)
        .get();

    if (nimSudahAda.docs.isNotEmpty) {
      throw Exception('NIM sudah terdaftar. Gunakan NIM yang berbeda.');
    }

    await _collection.add({
      ...mahasiswa.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMahasiswa(Mahasiswa mahasiswa) async {
    final id = mahasiswa.id;
    if (id == null || id.isEmpty) {
      throw Exception('ID mahasiswa tidak valid.');
    }

    final cekNim = await _collection
        .where('nim', isEqualTo: mahasiswa.nim.trim())
        .get();

    final nimDipakaiDokumenLain = cekNim.docs.any((doc) => doc.id != id);
    if (nimDipakaiDokumenLain) {
      throw Exception('NIM sudah dipakai mahasiswa lain.');
    }

    await _collection.doc(id).update({
      ...mahasiswa.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> hapusMahasiswa(String id) async {
    await _collection.doc(id).delete();
  }
}
