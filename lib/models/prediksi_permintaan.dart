// models/prediksi_permintaan.dart
class PrediksiPermintaan {
  final String jenis;
  final double rata2PenjualanTahunan;
  final double prediksiTahunIni;
  final double confidence;
  final List<double> dataHistoris;

  PrediksiPermintaan({
    required this.jenis,
    required this.rata2PenjualanTahunan,
    required this.prediksiTahunIni,
    required this.confidence,
    required this.dataHistoris,
  });

  factory PrediksiPermintaan.fromJson(Map<String, dynamic> json) {
    return PrediksiPermintaan(
      jenis: json['jenis'],
      rata2PenjualanTahunan: json['rata2_penjualan_tahunan'].toDouble(),
      prediksiTahunIni: json['prediksi_tahun_ini'].toDouble(),
      confidence: json['confidence'].toDouble(),
      dataHistoris: List<double>.from(json['data_historis']),
    );
  }
}