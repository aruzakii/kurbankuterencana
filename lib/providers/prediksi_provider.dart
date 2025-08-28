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

      // =========================
      // 🔍 DEBUG: CEK DATA MENTAH
      // =========================
      print('=== DEBUG FULL DATA ===');
      print('Periode: $selectedPeriode');
      print('Jenis: $selectedJenisHewan');
      print('Total penjualan records: ${penjualanList.length}');
      print('Total hewan records: ${hewanKurbanList.length}');

      print('\n=== RAW PENJUALAN DATA ===');
      for (final p in penjualanList) {
        final hewan = hewanKurbanList.firstWhere(
                (h) => h.id == p.hewanKurbanId,
            orElse: () => HewanKurban(
              id: '', jenis: 'Unknown', berat: 0.0, harga: 0.0,
              status: 'unknown', tanggalMasuk: DateTime.now(), userId: '', stok: 0,
            )
        );
        print('Tanggal: ${p.tanggalPenjualan} | Jenis: ${hewan.jenis} | Jumlah: ${p.jumlah}');
      }

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

      print('\n=== PENJUALAN PER JENIS PER BULAN ===');
      print(penjualanPerJenisPerBulan);

      _prediksiList = [];

      for (final entry in penjualanPerJenisPerBulan.entries) {
        final jenis = entry.key;
        final dataBulanan = entry.value;

        print('\n=== PROCESSING $jenis ===');
        print('Data bulanan: $dataBulanan');

        if (dataBulanan.length >= 3) {
          final Map<int, int> dataTahunan = {};
          for (final bulanEntry in dataBulanan.entries) {
            final tahun = int.parse(bulanEntry.key.split('-')[0]);
            dataTahunan[tahun] = (dataTahunan[tahun] ?? 0) + bulanEntry.value;
          }

          print('Data tahunan: $dataTahunan');

          if (dataTahunan.length >= 2) {
            // ✅ FIX: Urutkan tahun secara kronologis
            final sortedYears = dataTahunan.keys.toList()..sort();
            final dataHistoris = sortedYears.map((year) => dataTahunan[year]!.toDouble()).toList();

            print('Sorted years: $sortedYears');
            print('Data historis (kronologis): $dataHistoris');

            final rata2 = dataHistoris.reduce((a, b) => a + b) / dataHistoris.length;

            final prediksi = _calculateARIMAPrediction(dataHistoris);

            print('Rata-rata: $rata2');
            print('Prediksi ARIMA: $prediksi');

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
    final threeYearsAgo = DateTime(now.year - 3, now.month, now.day);

    print('\n=== ESTIMASI CALCULATION ===');
    print('Current date: $now');
    print('Three years ago: $threeYearsAgo');
    print('Selected periode: $selectedPeriode');

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
            includeData = penjualan.tanggalPenjualan.isAfter(
              now.subtract(const Duration(days: 180)),
            );
            break;
          case 'tahun_depan':
            periodKey = '${penjualan.tanggalPenjualan.year}';
            includeData = penjualan.tanggalPenjualan.isAfter(threeYearsAgo);
            print('Checking ${penjualan.tanggalPenjualan} > $threeYearsAgo = $includeData');
            break;
          default:
            periodKey = '${penjualan.tanggalPenjualan.year}';
            includeData = penjualan.tanggalPenjualan.isAfter(threeYearsAgo);
            break;
        }

        if (includeData) {
          dataAnalisis[key]!.add({
            'periode': periodKey,
            'tanggal': penjualan.tanggalPenjualan,
            'jumlah': penjualan.jumlah,
            'harga': penjualan.hargaJual * penjualan.jumlah,
          });
          print('Added to analysis: ${hewan.jenis} - $periodKey - ${penjualan.jumlah}');
        } else {
          print('Filtered out: ${hewan.jenis} - ${penjualan.tanggalPenjualan}');
        }
      }
    }

    print('\nData analisis hasil filter: $dataAnalisis');

    final Map<String, Map<String, dynamic>> estimasi = {};

    for (final entry in dataAnalisis.entries) {
      final jenis = entry.key;
      final data = entry.value;

      print('\n=== PROCESSING ESTIMASI $jenis ===');

      final Map<String, Map<String, dynamic>> periodData = {};
      for (final item in data) {
        final periodeKey = item['periode'] as String;
        periodData[periodeKey] = periodData[periodeKey] ?? {'jumlah': 0, 'pendapatan': 0.0};
        periodData[periodeKey]!['jumlah'] += item['jumlah'] as int;
        periodData[periodeKey]!['pendapatan'] += item['harga'] as double;
      }

      print('Period data: $periodData');

      if (periodData.isNotEmpty) {
        // ✅ FIX: Urutkan periode secara kronologis
        final sortedPeriods = periodData.keys.toList()..sort();
        print('Sorted periods: $sortedPeriods');

        final jumlahList = sortedPeriods.map((periode) =>
            (periodData[periode]!['jumlah'] as int).toDouble()).toList();
        final pendapatanList = sortedPeriods.map((periode) =>
        periodData[periode]!['pendapatan'] as double).toList();

        print('Jumlah list (kronologis): $jumlahList');
        print('Pendapatan list: $pendapatanList');

        final int window = selectedPeriode == 'bulan_depan' ? 2 : 3;
        final actualWindow = window > jumlahList.length ? jumlahList.length : window;

        print('Window size: $window, Actual window: $actualWindow');

        final estimasiJumlah = _calculateWeightedMovingAverage(jumlahList, actualWindow);
        final estimasiPendapatan = _calculateWeightedMovingAverage(pendapatanList, actualWindow);

        final tren = _calculateTrend(jumlahList);
        final confidence = _calculateConfidence(jumlahList);

        print('WMA result: $estimasiJumlah');
        print('Trend: $tren');
        print('Confidence: $confidence');

        estimasi[jenis] = {
          'estimasiJumlah': estimasiJumlah.round(),
          'estimasiPendapatan': estimasiPendapatan,
          'tren': tren,
          'confidence': confidence,
          'dataHistoris': jumlahList,
          'periodeTerakhir': sortedPeriods.last,
          'rataRataHistoris': jumlahList.isNotEmpty ? jumlahList.reduce((a, b) => a + b) / jumlahList.length : 0.0,
        };
      }
    }

    print('\n=== FINAL ESTIMASI RESULT ===');
    print(estimasi);

    return {
      'periode': selectedPeriode,
      'jenisHewan': selectedJenisHewan,
      'estimasi': estimasi,
      'tanggalAnalisis': DateTime.now(),
      'totalJenisAnalisis': estimasi.length,
    };
  }

  double _calculateARIMAPrediction(List<double> data) {
    print('\n=== ARIMA CALCULATION ===');
    print('Input data: $data');

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
    print('Trend prediction: $trendPrediction (slope: $slope, intercept: $intercept)');

    final seasonalAdjustment = _calculateSeasonalAdjustment(data);
    print('Seasonal adjustment: $seasonalAdjustment');

    final movingAverage = _calculateWeightedMovingAverage(data, 3);
    print('Moving average: $movingAverage');

    final finalPrediction = (trendPrediction * 0.6) + (movingAverage * 0.4) + seasonalAdjustment;
    print('Final prediction: ($trendPrediction * 0.6) + ($movingAverage * 0.4) + $seasonalAdjustment = $finalPrediction');

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
    print('\n--- WMA Calculation ---');
    print('Input data: $data');
    print('Window: $window');

    if (data.isEmpty) return 0.0;
    if (data.length < window) {
      print('Data length ${data.length} < window $window, using simple average');
      final result = data.reduce((a, b) => a + b) / data.length;
      print('Simple average result: $result');
      return result;
    }

    // ✅ FIX: Ambil data terakhir (terbaru) dan beri bobot tertinggi
    final recentData = data.sublist(data.length - window);
    print('Recent data (last $window): $recentData');

    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < recentData.length; i++) {
      final weight = (i + 1).toDouble(); // Bobot 1,2,3 untuk urutan kronologis
      sum += recentData[i] * weight;
      weightSum += weight;
      print('Data[${data.length - window + i}] = ${recentData[i]}, Weight = $weight');
    }

    final result = sum / weightSum;
    print('WMA result: $sum / $weightSum = $result');
    return result;
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