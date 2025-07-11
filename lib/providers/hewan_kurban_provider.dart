import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/hewan_kurban.dart';

class HewanKurbanProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<HewanKurban> _hewanKurbanList = [];
  bool _isLoading = false;
  String? _error;

  List<HewanKurban> get hewanKurbanList => _hewanKurbanList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<HewanKurban> get hewanTersedia => _hewanKurbanList.where((h) => h.status == 'tersedia' && h.stok > 0).toList();
  List<HewanKurban> get hewanTerjual => _hewanKurbanList.where((h) => h.status == 'terjual' || h.stok == 0).toList();

  Stream<List<HewanKurban>> getHewanKurbanStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not logged in');
    }

    return _firestore
        .collection('hewan_kurban')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('tanggal_masuk', descending: true)
        .snapshots()
        .map((querySnapshot) {
      _hewanKurbanList = querySnapshot.docs
          .map((doc) => HewanKurban.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      notifyListeners();
      return _hewanKurbanList;
    });
  }

  Future<void> addHewanKurban(HewanKurban hewan, int jumlah, bool isMassInput) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      if (isMassInput) {
        final snapshot = await _firestore
            .collection('hewan_kurban')
            .where('user_id', isEqualTo: user.uid)
            .where('jenis', isEqualTo: hewan.jenis)
            .where('berat', isEqualTo: hewan.berat)
            .where('harga', isEqualTo: hewan.harga)
            .where('deskripsi', isEqualTo: hewan.deskripsi)
            .where('status', isEqualTo: hewan.status)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final existingDoc = snapshot.docs.first;
          final existingHewan = HewanKurban.fromJson({...existingDoc.data(), 'id': existingDoc.id});
          final newStok = existingHewan.stok + jumlah;

          await _firestore.collection('hewan_kurban').doc(existingHewan.id).update({
            'stok': newStok,
          });

          final index = _hewanKurbanList.indexWhere((h) => h.id == existingHewan.id);
          if (index != -1) {
            _hewanKurbanList[index] = existingHewan.copyWith(stok: newStok);
          }
        } else {
          final docRef = _firestore.collection('hewan_kurban').doc();
          final newHewan = hewan.copyWith(id: docRef.id, userId: user.uid, stok: jumlah);
          await docRef.set({
            ...newHewan.toJson(),
            'user_id': user.uid,
          });
          _hewanKurbanList.insert(0, newHewan);
        }
      } else {
        final batch = _firestore.batch();
        final List<HewanKurban> newHewanList = [];

        for (int i = 0; i < jumlah; i++) {
          final docRef = _firestore.collection('hewan_kurban').doc();
          final newHewan = hewan.copyWith(id: docRef.id, userId: user.uid, stok: 1);
          batch.set(docRef, {
            ...newHewan.toJson(),
            'user_id': user.uid,
          });
          newHewanList.add(newHewan);
        }

        await batch.commit();
        _hewanKurbanList.insertAll(0, newHewanList);
      }
    } catch (e) {
      _error = e.toString();
      print('Error adding hewan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateHewanKurban(HewanKurban hewan) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (hewan.id.isEmpty) throw Exception('ID hewan tidak valid');

      print('Updating hewan with ID: ${hewan.id}, Harga: ${hewan.harga}');
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Ambil data lama untuk mempertahankan user_id
      final existingDoc = await _firestore.collection('hewan_kurban').doc(hewan.id).get();
      if (!existingDoc.exists) throw Exception('Hewan tidak ditemukan');

      final updatedData = {
        ...hewan.toJson(),
        'user_id': existingDoc.data()?['user_id'] ?? user.uid, // Pastikan user_id dipertahankan
      };

      await _firestore.collection('hewan_kurban').doc(hewan.id).update(updatedData);

      // Sinkronisasi ulang dari Firestore
      final updatedDoc = await _firestore.collection('hewan_kurban').doc(hewan.id).get();
      if (updatedDoc.exists) {
        final updatedHewan = HewanKurban.fromJson({...updatedDoc.data()!, 'id': hewan.id});
        final index = _hewanKurbanList.indexWhere((h) => h.id == hewan.id);
        if (index != -1) {
          _hewanKurbanList[index] = updatedHewan;
        } else {
          _hewanKurbanList.insert(0, updatedHewan);
        }
      } else {
        print('Document with ID ${hewan.id} not found after update');
      }
    } catch (e) {
      _error = e.toString();
      print('Error updating hewan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteHewanKurban(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('hewan_kurban').doc(id).delete();
      _hewanKurbanList.removeWhere((h) => h.id == id);
    } catch (e) {
      _error = e.toString();
      print('Error deleting hewan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sellHewanKurban(String id, int jumlah) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final index = _hewanKurbanList.indexWhere((h) => h.id == id);
      if (index == -1) throw Exception('Hewan tidak ditemukan');

      final hewan = _hewanKurbanList[index];
      final newStok = hewan.stok - jumlah;

      if (newStok < 0) throw Exception('Jumlah penjualan melebihi stok tersedia');

      await _firestore.collection('hewan_kurban').doc(id).update({
        'stok': newStok,
        'status': newStok > 0 ? 'tersedia' : 'terjual',
      });

      _hewanKurbanList[index] = hewan.copyWith(
        stok: newStok,
        status: newStok > 0 ? 'tersedia' : 'terjual',
      );

      final updatedDoc = await _firestore.collection('hewan_kurban').doc(id).get();
      if (updatedDoc.exists) {
        _hewanKurbanList[index] = HewanKurban.fromJson({...updatedDoc.data()!, 'id': id});
      }
    } catch (e) {
      _error = e.toString();
      print('Error selling hewan: $e');
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, int> getJenisHewanSummary() {
    final Map<String, int> summary = {};
    for (final hewan in hewanTersedia) {
      summary[hewan.jenis] = (summary[hewan.jenis] ?? 0) + hewan.stok;
    }
    return summary;
  }

  double getTotalNilaiStok() {
    return hewanTersedia.fold(0.0, (sum, hewan) => sum + (hewan.harga * hewan.stok));
  }
}