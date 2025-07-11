// models/stok_summary.dart
class StokSummary {
  final int totalHewan;
  final int hewanTersedia;
  final int hewanTerjual;
  final double totalNilaiStok;
  final double totalPendapatan;
  final Map<String, int> jenisHewan;

  StokSummary({
    required this.totalHewan,
    required this.hewanTersedia,
    required this.hewanTerjual,
    required this.totalNilaiStok,
    required this.totalPendapatan,
    required this.jenisHewan,
  });

  factory StokSummary.fromJson(Map<String, dynamic> json) {
    return StokSummary(
      totalHewan: json['total_hewan'],
      hewanTersedia: json['hewan_tersedia'],
      hewanTerjual: json['hewan_terjual'],
      totalNilaiStok: json['total_nilai_stok'].toDouble(),
      totalPendapatan: json['total_pendapatan'].toDouble(),
      jenisHewan: Map<String, int>.from(json['jenis_hewan']),
    );
  }
}
