import 'package:flutter/material.dart';

import '../models/mahasiswa.dart';
import '../services/mahasiswa_service.dart';

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
        await _service.updateMahasiswa(
          hasil.copyWith(
            id: mahasiswa.id,
            createdAt: mahasiswa.createdAt,
          ),
        );
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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.mahasiswa?.nama ?? '');
    _nimController = TextEditingController(text: widget.mahasiswa?.nim ?? '');
    _jurusanController =
        TextEditingController(text: widget.mahasiswa?.jurusan ?? '');
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

    setState(() {
      _isLoading = true;
    });

    final data = Mahasiswa(
      id: widget.mahasiswa?.id,
      nama: _namaController.text,
      nim: _nimController.text,
      jurusan: _jurusanController.text,
      prodi: _prodiController.text,
      createdAt: widget.mahasiswa?.createdAt,
      updatedAt: widget.mahasiswa?.updatedAt,
    );

    Navigator.pop(context, data);
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
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'NIM',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NIM wajib diisi';
                  }
                  if (value.trim().length < 5) {
                    return 'NIM terlalu pendek';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jurusanController,
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.done,
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _simpan,
          child: Text(isEdit ? 'Update' : 'Simpan'),
        ),
      ],
    );
  }
}
