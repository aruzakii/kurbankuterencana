import 'package:cloud_firestore/cloud_firestore.dart';

class HewanKurban {
  final String id;
  final String jenis;
  final double berat;
  final double harga;
  final String? deskripsi;
  final String status;
  final DateTime tanggalMasuk;
  final String userId;
  final int stok;

  HewanKurban({
    required this.id,
    required this.jenis,
    required this.berat,
    required this.harga,
    this.deskripsi,
    required this.status,
    required this.tanggalMasuk,
    required this.userId,
    this.stok = 1,
  });

  factory HewanKurban.fromJson(Map<String, dynamic> json) {
    return HewanKurban(
      id: json['id'] ?? '',
      jenis: json['jenis'] ?? '',
      berat: (json['berat'] as num).toDouble(),
      harga: (json['harga'] as num).toDouble(),
      deskripsi: json['deskripsi'],
      status: json['status'] ?? 'tersedia',
      tanggalMasuk: (json['tanggal_masuk'] as Timestamp).toDate(),
      userId: json['user_id'] ?? '',
      stok: json['stok'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jenis': jenis,
      'berat': berat,
      'harga': harga,
      'deskripsi': deskripsi,
      'status': status,
      'tanggal_masuk': Timestamp.fromDate(tanggalMasuk),
      'user_id': userId,
      'stok': stok,
    };
  }

  HewanKurban copyWith({
    String? id,
    String? jenis,
    double? berat,
    double? harga,
    String? deskripsi,
    String? status,
    DateTime? tanggalMasuk,
    String? userId,
    int? stok,
  }) {
    return HewanKurban(
      id: id ?? this.id,
      jenis: jenis ?? this.jenis,
      berat: berat ?? this.berat,
      harga: harga ?? this.harga,
      deskripsi: deskripsi ?? this.deskripsi,
      status: status ?? this.status,
      tanggalMasuk: tanggalMasuk ?? this.tanggalMasuk,
      userId: userId ?? this.userId,
      stok: stok ?? this.stok,
    );
  }
}