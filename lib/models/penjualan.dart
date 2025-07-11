import 'package:cloud_firestore/cloud_firestore.dart';

class Penjualan {
  final String id;
  final String hewanKurbanId;
  final String namaPembeli;
  final String kontakPembeli;
  final double hargaJual;
  final DateTime tanggalPenjualan;
  final String? catatan;
  final String userId;
  final int jumlah; // Field baru untuk jumlah hewan yang dijual

  Penjualan({
    required this.id,
    required this.hewanKurbanId,
    required this.namaPembeli,
    required this.kontakPembeli,
    required this.hargaJual,
    required this.tanggalPenjualan,
    this.catatan,
    required this.userId,
    this.jumlah = 1, // Default jumlah 1
  });

  factory Penjualan.fromJson(Map<String, dynamic> json) {
    return Penjualan(
      id: json['id'] ?? '',
      hewanKurbanId: json['hewan_kurban_id'] ?? '',
      namaPembeli: json['nama_pembeli'] ?? '',
      kontakPembeli: json['kontak_pembeli'] ?? '',
      hargaJual: (json['harga_jual'] as num).toDouble(),
      tanggalPenjualan: (json['tanggal_penjualan'] as Timestamp).toDate(),
      catatan: json['catatan'],
      userId: json['user_id'] ?? '',
      jumlah: json['jumlah'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hewan_kurban_id': hewanKurbanId,
      'nama_pembeli': namaPembeli,
      'kontak_pembeli': kontakPembeli,
      'harga_jual': hargaJual,
      'tanggal_penjualan': Timestamp.fromDate(tanggalPenjualan),
      'catatan': catatan,
      'user_id': userId,
      'jumlah': jumlah,
    };
  }
}