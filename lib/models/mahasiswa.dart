import 'package:cloud_firestore/cloud_firestore.dart';

class Mahasiswa {
  final String? id;
  final String nama;
  final String nim;
  final String jurusan;
  final String prodi;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Mahasiswa({
    this.id,
    required this.nama,
    required this.nim,
    required this.jurusan,
    required this.prodi,
    this.createdAt,
    this.updatedAt,
  });

  factory Mahasiswa.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return Mahasiswa(
      id: doc.id,
      nama: data['nama'] as String? ?? '',
      nim: data['nim'] as String? ?? '',
      jurusan: data['jurusan'] as String? ?? '',
      prodi: data['prodi'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama.trim(),
      'nim': nim.trim(),
      'jurusan': jurusan.trim(),
      'prodi': prodi.trim(),
    };
  }

  Mahasiswa copyWith({
    String? id,
    String? nama,
    String? nim,
    String? jurusan,
    String? prodi,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Mahasiswa(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nim: nim ?? this.nim,
      jurusan: jurusan ?? this.jurusan,
      prodi: prodi ?? this.prodi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
