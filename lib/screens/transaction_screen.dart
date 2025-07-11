import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/hewan_kurban_provider.dart';
import '../providers/penjualan_provider.dart';
import '../models/penjualan.dart';
import '../models/hewan_kurban.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedHewanId;
  String _namaPembeli = '';
  String _kontakPembeli = '';
  double _hargaJual = 0.0;
  int _jumlah = 1;
  DateTime _tanggalPenjualan = DateTime.now();
  String _catatan = '';
  bool _isSubmitting = false;

  // Debounce untuk mencegah panggilan berulang
  DateTime? _lastSubmitTime;

  void _submitTransaction() async {
    if (_isSubmitting || !_formKey.currentState!.validate() || _selectedHewanId == null) return;

    // Debounce: hanya proses jika sudah 1 detik dari submit terakhir
    final now = DateTime.now();
    if (_lastSubmitTime != null && now.difference(_lastSubmitTime!) < const Duration(seconds: 1)) return;
    _lastSubmitTime = now;

    setState(() => _isSubmitting = true);

    try {
      final hewanProvider = Provider.of<HewanKurbanProvider>(context, listen: false);
      final penjualanProvider = Provider.of<PenjualanProvider>(context, listen: false);

      // Gunakan where() dengan safe check instead of firstWhere()
      final hewanList = hewanProvider.hewanKurbanList.where((h) => h.id == _selectedHewanId).toList();

      if (hewanList.isEmpty) {
        throw Exception('Hewan tidak ditemukan');
      }

      final hewan = hewanList.first;

      // Validate stock availability
      if (hewan.stok < _jumlah) {
        _showSnackBar(
          'Jumlah melebihi stok tersedia (${hewan.stok}) untuk ${hewan.jenis}',
          isError: true,
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final newPenjualan = Penjualan(
        id: '',
        hewanKurbanId: hewan.id,
        namaPembeli: _namaPembeli,
        kontakPembeli: _kontakPembeli,
        hargaJual: _hargaJual,
        tanggalPenjualan: _tanggalPenjualan,
        catatan: _catatan.isNotEmpty ? _catatan : null,
        userId: hewan.userId,
        jumlah: _jumlah,
      );

      // Tambah penjualan terlebih dahulu
      await penjualanProvider.addPenjualan(newPenjualan);

      // Update stok hewan
      await hewanProvider.sellHewanKurban(hewan.id, _jumlah);

      // Verifikasi status setelah update - gunakan safe check
      final updatedHewanList = hewanProvider.hewanKurbanList.where((h) => h.id == _selectedHewanId).toList();
      if (updatedHewanList.isNotEmpty) {
        final updatedHewan = updatedHewanList.first;
        if (updatedHewan.stok < 0) {
          throw Exception('Stok tidak valid setelah update');
        }
      }

      if (!mounted) return;
      _showSnackBar('Transaksi $_jumlah ${hewan.jenis} berhasil disimpan');

      // Reset form dan pastikan dropdown tidak error
      _resetForm();

    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Gagal menyimpan transaksi: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Fungsi terpisah untuk reset form
  void _resetForm() {
    if (!mounted) return;

    _formKey.currentState?.reset();
    setState(() {
      _selectedHewanId = null; // Reset dropdown value
      _namaPembeli = '';
      _kontakPembeli = '';
      _hargaJual = 0.0;
      _jumlah = 1;
      _catatan = '';
      _isSubmitting = false;
    });
  }

  // Fungsi untuk menampilkan snackbar dengan kontrol tunggal
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Hapus snackbar sebelumnya
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildHewanDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Nama Pembeli',
                value: _namaPembeli,
                onChanged: (value) => setState(() => _namaPembeli = value),
                validator: (value) => value!.isEmpty ? 'Nama pembeli harus diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Kontak Pembeli',
                value: _kontakPembeli,
                onChanged: (value) => setState(() => _kontakPembeli = value),
                validator: (value) => value!.isEmpty ? 'Kontak pembeli harus diisi' : null,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Harga Jual',
                value: _hargaJual.toStringAsFixed(0),
                onChanged: (value) => setState(() => _hargaJual = double.tryParse(value) ?? 0.0),
                validator: (value) => (double.tryParse(value!) ?? 0) <= 0 ? 'Harga harus lebih dari 0' : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Jumlah',
                value: _jumlah.toString(),
                onChanged: (value) => setState(() => _jumlah = int.tryParse(value) ?? 1),
                validator: (value) => (int.tryParse(value!) ?? 0) <= 0 ? 'Jumlah harus minimal 1' : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Catatan (Opsional)',
                value: _catatan,
                onChanged: (value) => setState(() => _catatan = value),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  disabledBackgroundColor: const Color(0xFF6B7280),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  'Simpan Transaksi',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Catat transaksi penjualan Anda',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHewanDropdown() {
    return StreamBuilder<List<HewanKurban>>(
      stream: Provider.of<HewanKurbanProvider>(context, listen: false).getHewanKurbanStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
              strokeWidth: 3,
            ),
          );
        }

        final hewanTersedia = snapshot.data!.where((h) => h.status == 'tersedia' && h.stok > 0).toList();

        // Validasi apakah selectedHewanId masih valid
        if (_selectedHewanId != null && !hewanTersedia.any((h) => h.id == _selectedHewanId)) {
          // Jika hewan yang dipilih tidak lagi tersedia, reset pilihan
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedHewanId = null;
                _hargaJual = 0.0;
                _jumlah = 1;
              });
            }
          });
        }

        return DropdownButtonFormField<String>(
          value: _selectedHewanId,
          dropdownColor: const Color(0xFF2D3748),
          decoration: InputDecoration(
            labelText: 'Pilih Hewan',
            labelStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFD700)),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Pilih Hewan'),
            ),
            ...hewanTersedia.map((hewan) => DropdownMenuItem(
              value: hewan.id,
              child: Text(
                  '${hewan.jenis} - ${_formatCurrency(hewan.harga)} - ${hewan.berat.toStringAsFixed(1)} kg - Stok: ${hewan.stok}'),
            )),
          ],
          validator: (value) => value == null ? 'Hewan harus dipilih' : null,
          onChanged: (value) {
            setState(() {
              _selectedHewanId = value;
              if (value != null) {
                // Gunakan safe check untuk mencari hewan
                final hewanList = hewanTersedia.where((h) => h.id == value).toList();
                if (hewanList.isNotEmpty) {
                  final hewan = hewanList.first;
                  _hargaJual = hewan.harga; // Auto-fill sale price from animal price
                  _jumlah = 1; // Reset quantity to 1
                }
              }
            });
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFFD700)),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _tanggalPenjualan,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFFFFD700),
                  onPrimary: Colors.black,
                  surface: Color(0xFF2D3748),
                ),
                dialogBackgroundColor: const Color(0xFF2D3748),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          setState(() => _tanggalPenjualan = pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Tanggal Transaksi',
          labelStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFFD700)),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd MMM yyyy').format(_tanggalPenjualan),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
            const Icon(Icons.calendar_today, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000000) {
      return 'Rp ${(amount / 1000000000000).toStringAsFixed(1)}T';
    } else if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}B';
    } else {
      return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    }
  }
}