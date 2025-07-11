// models/laporan_penjualan.dart
class LaporanPenjualan {
  final DateTime periode;
  final double totalPendapatan;
  final int totalHewanTerjual;
  final String jenisHewanTerlaris;
  final double beratRataRata;
  final Map<String, double> pendapatanPerJenis;
  final Map<String, int> penjualanPerJenis;

  LaporanPenjualan({
    required this.periode,
    required this.totalPendapatan,
    required this.totalHewanTerjual,
    required this.jenisHewanTerlaris,
    required this.beratRataRata,
    required this.pendapatanPerJenis,
    required this.penjualanPerJenis,
  });

  factory LaporanPenjualan.fromJson(Map<String, dynamic> json) {
    return LaporanPenjualan(
      periode: DateTime.parse(json['periode']),
      totalPendapatan: json['total_pendapatan'].toDouble(),
      totalHewanTerjual: json['total_hewan_terjual'],
      jenisHewanTerlaris: json['jenis_hewan_terlaris'],
      beratRataRata: json['berat_rata_rata'].toDouble(),
      pendapatanPerJenis: Map<String, double>.from(json['pendapatan_per_jenis']),
      penjualanPerJenis: Map<String, int>.from(json['penjualan_per_jenis']),
    );
  }
}