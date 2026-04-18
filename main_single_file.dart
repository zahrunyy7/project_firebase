import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Data Mahasiswa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MahasiswaPage(),
    );
  }
}

class Mahasiswa {
  final String? id;
  final String nama;
  final String nim;
  final String jurusan;
  final String prodi;

  const Mahasiswa({
    this.id,
    required this.nama,
    required this.nim,
    required this.jurusan,
    required this.prodi,
  });

  factory Mahasiswa.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Mahasiswa(
      id: doc.id,
      nama: data['nama'] as String? ?? '',
      nim: data['nim'] as String? ?? '',
      jurusan: data['jurusan'] as String? ?? '',
      prodi: data['prodi'] as String? ?? '',
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
  }) {
    return Mahasiswa(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nim: nim ?? this.nim,
      jurusan: jurusan ?? this.jurusan,
      prodi: prodi ?? this.prodi,
    );
  }
}

class MahasiswaService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('mahasiswa');

  Stream<List<Mahasiswa>> streamMahasiswa() {
    return _collection.orderBy('nama').snapshots().map(
          (snapshot) => snapshot.docs.map(Mahasiswa.fromFirestore).toList(),
        );
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

class MahasiswaPage extends StatefulWidget {
  const MahasiswaPage({super.key});

  @override
  State<MahasiswaPage> createState() => _MahasiswaPageState();
}

class _MahasiswaPageState extends State<MahasiswaPage> {
  final MahasiswaService _service = MahasiswaService();

  Future<void> _bukaForm({Mahasiswa? mahasiswa}) async {
    final hasil = await showDialog<Mahasiswa>(
      context: context,
      builder: (_) => MahasiswaFormDialog(mahasiswa: mahasiswa),
    );

    if (hasil == null) return;

    try {
      if (mahasiswa == null) {
        await _service.tambahMahasiswa(hasil);
        _showMessage('Data mahasiswa berhasil ditambahkan.');
      } else {
        await _service.updateMahasiswa(hasil.copyWith(id: mahasiswa.id));
        _showMessage('Data mahasiswa berhasil diperbarui.');
      }
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _hapusData(Mahasiswa mahasiswa) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Yakin ingin menghapus data ${mahasiswa.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (setuju != true || mahasiswa.id == null) return;

    try {
      await _service.hapusMahasiswa(mahasiswa.id!);
      _showMessage('Data mahasiswa berhasil dihapus.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Mahasiswa'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Mahasiswa>>(
        stream: _service.streamMahasiswa(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Terjadi error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final daftarMahasiswa = snapshot.data ?? [];

          if (daftarMahasiswa.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data mahasiswa.\nTekan tombol + untuk menambah data.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: daftarMahasiswa.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final mahasiswa = daftarMahasiswa[index];

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    mahasiswa.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NIM      : ${mahasiswa.nim}'),
                        Text('Jurusan  : ${mahasiswa.jurusan}'),
                        Text('Prodi    : ${mahasiswa.prodi}'),
                      ],
                    ),
                  ),
                  trailing: SizedBox(
                    width: 96,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () => _bukaForm(mahasiswa: mahasiswa),
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () => _hapusData(mahasiswa),
                          icon: const Icon(Icons.delete),
                          tooltip: 'Hapus',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bukaForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MahasiswaFormDialog extends StatefulWidget {
  final Mahasiswa? mahasiswa;

  const MahasiswaFormDialog({super.key, this.mahasiswa});

  @override
  State<MahasiswaFormDialog> createState() => _MahasiswaFormDialogState();
}

class _MahasiswaFormDialogState extends State<MahasiswaFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _nimController;
  late final TextEditingController _jurusanController;
  late final TextEditingController _prodiController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.mahasiswa?.nama ?? '');
    _nimController = TextEditingController(text: widget.mahasiswa?.nim ?? '');
    _jurusanController = TextEditingController(text: widget.mahasiswa?.jurusan ?? '');
    _prodiController = TextEditingController(text: widget.mahasiswa?.prodi ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _jurusanController.dispose();
    _prodiController.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      Mahasiswa(
        id: widget.mahasiswa?.id,
        nama: _namaController.text,
        nim: _nimController.text,
        jurusan: _jurusanController.text,
        prodi: _prodiController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mahasiswa != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Mahasiswa' : 'Tambah Mahasiswa'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nimController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'NIM',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NIM wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jurusanController,
                decoration: const InputDecoration(
                  labelText: 'Jurusan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jurusan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prodiController,
                decoration: const InputDecoration(
                  labelText: 'Prodi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Prodi wajib diisi';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _simpan,
          child: Text(isEdit ? 'Update' : 'Simpan'),
        ),
      ],
    );
  }
}
