import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/hewan_kurban.dart';
import '../../models/penjualan.dart';

class PenjualanProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Penjualan> _penjualanList = [];
  List<HewanKurban> _hewanKurbanList = [];
  bool _isLoading = false;
  String? _error;

  List<Penjualan> get penjualanList => _penjualanList;
  List<HewanKurban> get hewanKurbanList => _hewanKurbanList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Penjualan>> getPenjualanStream() {
    final user = _auth.currentUser;
    if (user == null) {
      print('Stream error: User not logged in');
      return Stream.error('User not logged in');
    }

    print('Starting penjualan stream for user: ${user.uid}');
    return _firestore
        .collection('penjualan')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('tanggal_penjualan', descending: true)
        .snapshots()
        .map((querySnapshot) {
      print('Stream received ${querySnapshot.docs.length} documents');
      _penjualanList = querySnapshot.docs.map((doc) {
        try {
          final data = doc.data();
          print('Document data: $data');
          return Penjualan.fromJson({...data, 'id': doc.id});
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
          throw e;
        }
      }).toList();
      print('Stream parsed ${_penjualanList.length} penjualan records');
      notifyListeners();
      return _penjualanList;
    }).handleError((error) {
      print('Stream error: $error');
      _error = 'Failed to stream penjualan: $error';
      notifyListeners();
    });
  }

  Future<void> fetchPenjualan() async {
    print('Starting fetchPenjualan...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'User not logged in';
        print('Error: User not logged in');
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('Fetching penjualan for user: ${user.uid}');
      final querySnapshot = await _firestore
          .collection('penjualan')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('tanggal_penjualan', descending: true)
          .get();

      print('Query returned ${querySnapshot.docs.length} documents');
      _penjualanList = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('Document data: $data');
          final penjualan = Penjualan.fromJson({...data, 'id': doc.id});
          _penjualanList.add(penjualan);
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
        }
      }

      await _fetchHewanKurbanData();
      print('Successfully parsed ${_penjualanList.length} penjualan records');
    } catch (e) {
      _error = 'Failed to fetch penjualan: $e';
      print('Error fetching penjualan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('Finished fetchPenjualan, isLoading: $_isLoading');
    }
  }

  Future<void> _fetchHewanKurbanData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final hewanSnapshot = await _firestore
          .collection('hewan_kurban')
          .where('user_id', isEqualTo: user.uid)
          .get();

      _hewanKurbanList = hewanSnapshot.docs
          .map((doc) => HewanKurban.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      print('Fetched ${_hewanKurbanList.length} hewan kurban records');
    } catch (e) {
      print('Error fetching hewan kurban data: $e');
    }
  }

  Future<void> addPenjualan(Penjualan penjualan) async {
    print('Starting addPenjualan for ${penjualan.namaPembeli}, Jumlah: ${penjualan.jumlah}');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final docRef = await _firestore.collection('penjualan').add({
        ...penjualan.toJson(),
        'user_id': user.uid,
      });

      final newPenjualan = Penjualan(
        id: docRef.id,
        hewanKurbanId: penjualan.hewanKurbanId,
        namaPembeli: penjualan.namaPembeli,
        kontakPembeli: penjualan.kontakPembeli,
        hargaJual: penjualan.hargaJual,
        tanggalPenjualan: penjualan.tanggalPenjualan,
        catatan: penjualan.catatan,
        userId: user.uid,
        jumlah: penjualan.jumlah,
      );

      _penjualanList.insert(0, newPenjualan);
      print('Added penjualan: ${newPenjualan.namaPembeli}, Harga: ${newPenjualan.hargaJual}, Jumlah: ${newPenjualan.jumlah}, ID: ${newPenjualan.id}');
    } catch (e) {
      _error = e.toString();
      print('Error adding penjualan: $e');
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getTotalPendapatan() {
    if (_penjualanList.isEmpty) {
      print('No penjualan data available for calculating total pendapatan');
      return 0.0;
    }

    final total = _penjualanList.fold<double>(
      0.0,
          (sum, penjualan) => sum + (penjualan.hargaJual * penjualan.jumlah),
    );

    print('Calculated total pendapatan: $total from ${_penjualanList.length} records');
    return total;
  }

  List<Penjualan> getPenjualanByPeriode(DateTime startDate, DateTime endDate) {
    final filtered = _penjualanList.where((penjualan) {
      return penjualan.tanggalPenjualan.isAfter(startDate) &&
          penjualan.tanggalPenjualan.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
    print('Filtered ${filtered.length} penjualan between ${startDate.toIso8601String()} and ${endDate.toIso8601String()}');
    return filtered;
  }

  Map<String, double> getPendapatanPerBulan() {
    final Map<String, double> pendapatanBulanan = {};
    for (final penjualan in _penjualanList) {
      final bulan = _formatBulan(penjualan.tanggalPenjualan);
      pendapatanBulanan[bulan] = (pendapatanBulanan[bulan] ?? 0) + (penjualan.hargaJual * penjualan.jumlah);
    }
    print('Pendapatan per bulan: $pendapatanBulanan');
    return pendapatanBulanan;
  }

  Map<String, Map<String, dynamic>> getJenisKurbanTerlaris() {
    final Map<String, List<Map<String, dynamic>>> jenisData = {};

    for (final penjualan in _penjualanList) {
      final hewan = _hewanKurbanList.firstWhere(
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

      if (hewan.jenis != 'Unknown') {
        jenisData[hewan.jenis] = jenisData[hewan.jenis] ?? [];
        // Tambah entri sebanyak jumlah hewan yang dijual
        for (int i = 0; i < penjualan.jumlah; i++) {
          jenisData[hewan.jenis]!.add({
            'berat': hewan.berat,
            'harga': penjualan.hargaJual,
            'tanggal': penjualan.tanggalPenjualan,
          });
        }
      }
    }

    final Map<String, Map<String, dynamic>> result = {};

    for (final entry in jenisData.entries) {
      final jenis = entry.key;
      final data = entry.value;

      if (data.isNotEmpty) {
        data.sort((a, b) => (a['berat'] as double).compareTo(b['berat'] as double));

        final beratList = data.map((e) => e['berat'] as double).toList();
        final minBerat = beratList.first;
        final maxBerat = beratList.last;
        final avgBerat = beratList.reduce((a, b) => a + b) / beratList.length;

        final rangeBoundary1 = minBerat + (maxBerat - minBerat) / 3;
        final rangeBoundary2 = minBerat + 2 * (maxBerat - minBerat) / 3;

        final Map<String, int> rangeCount = {
          'Ringan (${minBerat.toStringAsFixed(0)}-${rangeBoundary1.toStringAsFixed(0)}kg)': 0,
          'Sedang (${rangeBoundary1.toStringAsFixed(0)}-${rangeBoundary2.toStringAsFixed(0)}kg)': 0,
          'Berat (${rangeBoundary2.toStringAsFixed(0)}-${maxBerat.toStringAsFixed(0)}kg)': 0,
        };

        for (final item in data) {
          final berat = item['berat'] as double;
          if (berat <= rangeBoundary1) {
            rangeCount[rangeCount.keys.first] = rangeCount[rangeCount.keys.first]! + 1;
          } else if (berat <= rangeBoundary2) {
            rangeCount[rangeCount.keys.elementAt(1)] = rangeCount[rangeCount.keys.elementAt(1)]! + 1;
          } else {
            rangeCount[rangeCount.keys.last] = rangeCount[rangeCount.keys.last]! + 1;
          }
        }

        final mostPopularRange = rangeCount.entries.reduce((a, b) => a.value > b.value ? a : b);

        result[jenis] = {
          'totalTerjual': data.length,
          'beratMinimum': minBerat,
          'beratMaksimum': maxBerat,
          'beratRataRata': avgBerat,
          'rangeTerlaris': mostPopularRange.key,
          'jumlahRangeTerlaris': mostPopularRange.value,
          'sebaranRange': rangeCount,
          'totalPendapatan': data.fold<double>(0.0, (sum, item) => sum + (item['harga'] as double)),
        };
      }
    }

    final sortedResult = Map.fromEntries(
      result.entries.toList()
        ..sort((a, b) => (b.value['totalTerjual'] as int).compareTo(a.value['totalTerjual'] as int)),
    );
    print('Jenis kurban terlaris: $sortedResult');
    return sortedResult;
  }

  String _formatBulan(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}