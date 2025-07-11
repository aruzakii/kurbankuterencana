import 'package:flutter/material.dart';
import 'package:kurbanku_terencana/providers/penjualan_provider.dart';
import '../models/hewan_kurban.dart';
import '../models/penjualan.dart';
import '../models/prediksi_permintaan.dart';

class PrediksiProvider with ChangeNotifier {
  List<PrediksiPermintaan> _prediksiList = [];
  Map<String, dynamic> _estimasiData = {};
  bool _isLoading = false;
  String? _error;

  List<PrediksiPermintaan> get prediksiList => _prediksiList;
  Map<String, dynamic> get estimasiData => _estimasiData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> generatePrediksi(
      PenjualanProvider penjualanProvider, {
        required String selectedPeriode,
        required String selectedJenisHewan,
      }) async {
    _isLoading = true;
    _error = null;
    _estimasiData = {};
    _prediksiList = [];
    notifyListeners();

    try {
      final penjualanList = penjualanProvider.penjualanList;
      final hewanKurbanList = penjualanProvider.hewanKurbanList;

      if (penjualanList.isEmpty || hewanKurbanList.isEmpty) {
        _estimasiData = {
          'estimasi': {},
          'periode': selectedPeriode,
          'jenisHewan': selectedJenisHewan,
          'tanggalAnalisis': DateTime.now(),
          'totalJenisAnalisis': 0,
        };
        _error = 'Tidak ada data penjualan atau hewan kurban untuk prediksi';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Struktur data: jenis -> bulan -> jumlah
      final Map<String, Map<String, int>> penjualanPerJenisPerBulan = {};

      for (final penjualan in penjualanList) {
        final hewan = hewanKurbanList.firstWhere(
              (h) => h.id == penjualan.hewanKurbanId,
          orElse: () => HewanKurban(
            id: '',
            jenis: 'Unknown',
            berat: 0.0,
            harga: 0.0,
            status: 'unknown',
            tanggalMasuk: DateTime.now(),
            userId: '',
            stok: 0,
          ),
        );

        if (hewan.jenis != 'Unknown' &&
            (selectedJenisHewan == 'Semua' || hewan.jenis == selectedJenisHewan)) {
          final jenis = hewan.jenis;
          final bulanTahun =
              '${penjualan.tanggalPenjualan.year}-${penjualan.tanggalPenjualan.month.toString().padLeft(2, '0')}';

          penjualanPerJenisPerBulan[jenis] = penjualanPerJenisPerBulan[jenis] ?? {};
          penjualanPerJenisPerBulan[jenis]![bulanTahun] =
              (penjualanPerJenisPerBulan[jenis]![bulanTahun] ?? 0) + penjualan.jumlah;
        }
      }

      _prediksiList = [];

      for (final entry in penjualanPerJenisPerBulan.entries) {
        final jenis = entry.key;
        final dataBulanan = entry.value;

        if (dataBulanan.length >= 3) {
          final Map<int, int> dataTahunan = {};
          for (final bulanEntry in dataBulanan.entries) {
            final tahun = int.parse(bulanEntry.key.split('-')[0]);
            dataTahunan[tahun] = (dataTahunan[tahun] ?? 0) + bulanEntry.value;
          }

          if (dataTahunan.length >= 2) {
            final dataHistoris = dataTahunan.values.map((e) => e.toDouble()).toList();
            final rata2 = dataHistoris.reduce((a, b) => a + b) / dataHistoris.length;

            final prediksi = _calculateARIMAPrediction(dataHistoris);

            _prediksiList.add(PrediksiPermintaan(
              jenis: jenis,
              rata2PenjualanTahunan: rata2,
              prediksiTahunIni: prediksi,
              confidence: _calculateConfidence(dataHistoris),
              dataHistoris: dataHistoris,
            ));
          }
        }
      }

      _estimasiData = _calculateEstimasiPermintaan(
        penjualanList,
        hewanKurbanList,
        selectedPeriode,
        selectedJenisHewan,
      );

      if (_prediksiList.isEmpty && _estimasiData['estimasi'].isEmpty) {
        _error = 'Tidak cukup data historis untuk prediksi (minimal 3 bulan data)';
      }
    } catch (e) {
      _error = 'Gagal menghasilkan prediksi: $e';
      print('Error generating prediksi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _calculateEstimasiPermintaan(
      List<Penjualan> penjualanList,
      List<HewanKurban> hewanKurbanList,
      String selectedPeriode,
      String selectedJenisHewan,
      ) {
    final Map<String, List<Map<String, dynamic>>> dataAnalisis = {};
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    final sixMonthsAgo = now.subtract(const Duration(days: 180));

    for (final penjualan in penjualanList) {
      final hewan = hewanKurbanList.firstWhere(
            (h) => h.id == penjualan.hewanKurbanId,
        orElse: () => HewanKurban(
          id: '',
          jenis: 'Unknown',
          berat: 0.0,
          harga: 0.0,
          status: 'unknown',
          tanggalMasuk: DateTime.now(),
          userId: '',
          stok: 0,
        ),
      );

      if (hewan.jenis != 'Unknown' &&
          (selectedJenisHewan == 'Semua' || hewan.jenis == selectedJenisHewan)) {
        final key = hewan.jenis;
        dataAnalisis[key] = dataAnalisis[key] ?? [];

        String periodKey;
        bool includeData = true;

        switch (selectedPeriode) {
          case 'bulan_depan':
            periodKey =
            '${penjualan.tanggalPenjualan.year}-${penjualan.tanggalPenjualan.month.toString().padLeft(2, '0')}';
            includeData = penjualan.tanggalPenjualan.isAfter(
              now.subtract(const Duration(days: 90)),
            );
            break;
          case '6_bulan':
            final quarter = ((penjualan.tanggalPenjualan.month - 1) ~/ 6) + 1;
            periodKey = '${penjualan.tanggalPenjualan.year}-H$quarter';
            includeData = penjualan.tanggalPenjualan.isAfter(sixMonthsAgo);
            break;
          case 'tahun_depan':
          default:
            periodKey = '${penjualan.tanggalPenjualan.year}';
            break;
        }

        if (includeData) {
          dataAnalisis[key]!.add({
            'periode': periodKey,
            'tanggal': penjualan.tanggalPenjualan,
            'jumlah': penjualan.jumlah,
            'harga': penjualan.hargaJual * penjualan.jumlah,
          });
        }
      }
    }

    print('Data analisis untuk $selectedPeriode: $dataAnalisis');

    final Map<String, Map<String, dynamic>> estimasi = {};

    for (final entry in dataAnalisis.entries) {
      final jenis = entry.key;
      final data = entry.value;

      final Map<String, Map<String, dynamic>> periodData = {};
      for (final item in data) {
        final periodeKey = item['periode'] as String;
        periodData[periodeKey] = periodData[periodeKey] ?? {'jumlah': 0, 'pendapatan': 0.0};
        periodData[periodeKey]!['jumlah'] += item['jumlah'] as int;
        periodData[periodeKey]!['pendapatan'] += item['harga'] as double;
      }

      if (periodData.isNotEmpty) {
        final jumlahList = periodData.values.map((e) => (e['jumlah'] as int).toDouble()).toList();
        final pendapatanList = periodData.values.map((e) => e['pendapatan'] as double).toList();

        final int window = selectedPeriode == 'bulan_depan' ? 2 : 3;
        final actualWindow = window > jumlahList.length ? jumlahList.length : window;

        final estimasiJumlah = _calculateWeightedMovingAverage(jumlahList, actualWindow);
        final estimasiPendapatan = _calculateWeightedMovingAverage(pendapatanList, actualWindow);

        final tren = _calculateTrend(jumlahList);
        final confidence = _calculateConfidence(jumlahList);

        estimasi[jenis] = {
          'estimasiJumlah': estimasiJumlah.round(),
          'estimasiPendapatan': estimasiPendapatan,
          'tren': tren,
          'confidence': confidence,
          'dataHistoris': jumlahList,
          'periodeTerakhir': periodData.keys.last,
          'rataRataHistoris': jumlahList.isNotEmpty ? jumlahList.reduce((a, b) => a + b) / jumlahList.length : 0.0,
        };
      }
    }

    print('Estimasi result untuk $selectedPeriode: $estimasi');

    return {
      'periode': selectedPeriode,
      'jenisHewan': selectedJenisHewan,
      'estimasi': estimasi,
      'tanggalAnalisis': DateTime.now(),
      'totalJenisAnalisis': estimasi.length,
    };
  }

  double _calculateARIMAPrediction(List<double> data) {
    if (data.isEmpty) return 0.0;
    if (data.length == 1) return data[0];

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final n = data.length;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += data[i];
      sumXY += i * data[i];
      sumX2 += i * i;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    final trendPrediction = slope * n + intercept;

    final seasonalAdjustment = _calculateSeasonalAdjustment(data);

    final movingAverage = _calculateWeightedMovingAverage(data, 3);

    final finalPrediction = (trendPrediction * 0.6) + (movingAverage * 0.4) + seasonalAdjustment;

    return finalPrediction.clamp(0.0, double.infinity);
  }

  double _calculateSeasonalAdjustment(List<double> data) {
    if (data.length < 3) return 0.0;

    final recent = data.sublist(data.length - 3);
    final average = recent.reduce((a, b) => a + b) / recent.length;
    final lastValue = data.last;

    if (lastValue > average) {
      return average * 0.1;
    } else if (lastValue < average) {
      return -average * 0.05;
    }

    return 0.0;
  }

  double _calculateWeightedMovingAverage(List<double> data, int window) {
    if (data.isEmpty) return 0.0;
    if (data.length < window) return data.reduce((a, b) => a + b) / data.length;

    final recentData = data.sublist(data.length - window);
    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < recentData.length; i++) {
      final weight = (i + 1).toDouble();
      sum += recentData[i] * weight;
      weightSum += weight;
    }

    return sum / weightSum;
  }

  String _calculateTrend(List<double> data) {
    if (data.length < 2) return 'stabil';

    final recentAvg = data.sublist(data.length - (data.length ~/ 2)).reduce((a, b) => a + b) / (data.length ~/ 2);
    final olderAvg = data.sublist(0, data.length ~/ 2).reduce((a, b) => a + b) / (data.length ~/ 2);

    final diff = recentAvg - olderAvg;
    final threshold = olderAvg * 0.1;

    if (diff > threshold) return 'naik';
    if (diff < -threshold) return 'turun';
    return 'stabil';
  }

  double _calculateConfidence(List<double> data) {
    if (data.length < 2) return 0.5;

    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / data.length;

    if (mean == 0) return 0.5;
    final cv = (variance / (mean * mean));
    return (1.0 / (1.0 + cv)).clamp(0.0, 1.0);
  }
}