import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/hewan_kurban_provider.dart';
import '../models/hewan_kurban.dart';

class AddHewanDialog extends StatefulWidget {
  final HewanKurban? hewan;

  const AddHewanDialog({super.key, this.hewan});

  @override
  State<AddHewanDialog> createState() => _AddHewanDialogState();
}

class _AddHewanDialogState extends State<AddHewanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _beratController = TextEditingController();
  final _hargaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _jumlahController = TextEditingController(text: '1');
  String _selectedJenis = 'sapi';
  String _selectedStatus = 'tersedia';
  bool _isLoading = false;
  bool _isMassInput = false;

  final List<String> _jenisOptions = ['sapi', 'kambing', 'domba'];
  final List<String> _statusOptions = ['tersedia', 'terjual'];

  @override
  void initState() {
    super.initState();
    if (widget.hewan != null) {
      _selectedJenis = widget.hewan!.jenis;
      _beratController.text = widget.hewan!.berat.toString();
      _hargaController.text = widget.hewan!.harga.toString();
      _deskripsiController.text = widget.hewan!.deskripsi ?? '';
      _selectedStatus = widget.hewan!.status;
      _jumlahController.text = widget.hewan!.stok.toString();
      _isMassInput = widget.hewan!.stok > 1;
    }
  }

  @override
  void dispose() {
    _beratController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  Future<void> _saveHewan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<HewanKurbanProvider>(context, listen: false);
      final jumlah = int.parse(_jumlahController.text);

      final hewan = HewanKurban(
        id: widget.hewan?.id ?? '',
        jenis: _selectedJenis,
        berat: double.parse(_beratController.text),
        harga: double.parse(_hargaController.text),
        deskripsi: _deskripsiController.text.isEmpty ? null : _deskripsiController.text,
        status: _selectedStatus,
        tanggalMasuk: widget.hewan?.tanggalMasuk ?? DateTime.now(),
        userId: '',
        stok: _isMassInput ? jumlah : 1,
      );

      if (widget.hewan == null) {
        await provider.addHewanKurban(hewan, jumlah, _isMassInput);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isMassInput
                    ? '$jumlah ${_selectedJenis} berhasil ditambahkan'
                    : '$jumlah ${_selectedJenis} individu berhasil ditambahkan',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await provider.updateHewanKurban(hewan);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Hewan berhasil diupdate',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.hewan != null;

    return Dialog(
      backgroundColor: const Color(0xFF2D3748),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A5568),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit : Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Hewan' : 'Tambah Hewan Baru',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!isEdit) ...[
                  CheckboxListTile(
                    title: Text(
                      'Input Massal (Gabungkan hewan dengan detail sama)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    value: _isMassInput,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                      setState(() {
                        _isMassInput = value!;
                        _jumlahController.text = _isMassInput ? '1' : '1';
                      });
                    },
                    activeColor: const Color(0xFF3B82F6),
                    checkColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Jenis Hewan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedJenis,
                  dropdownColor: const Color(0xFF2D3748),
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF4A5568),
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
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: _jenisOptions.map((jenis) {
                    return DropdownMenuItem(
                      value: jenis,
                      child: Text(
                        jenis.toUpperCase(),
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                    setState(() {
                      _selectedJenis = value!;
                    });
                  },
                  validator: (value) => value == null ? 'Jenis hewan harus dipilih' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Berat (kg)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _beratController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Masukkan berat hewan',
                    hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: const Color(0xFF4A5568),
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
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Berat hewan harus diisi';
                    }
                    final berat = double.tryParse(value);
                    if (berat == null || berat <= 0) {
                      return 'Berat hewan harus berupa angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Harga (Rp)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Masukkan harga hewan',
                    hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: const Color(0xFF4A5568),
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
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga hewan harus diisi';
                    }
                    final harga = double.tryParse(value);
                    if (harga == null || harga <= 0) {
                      return 'Harga hewan harus berupa angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (!isEdit || _isMassInput) ...[
                  Text(
                    'Jumlah Hewan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isMassInput
                          ? 'Masukkan jumlah hewan (misalnya, 20)'
                          : 'Masukkan jumlah entri individu (misalnya, 1)',
                      hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: const Color(0xFF4A5568),
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
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Jumlah hewan harus diisi';
                      }
                      final jumlah = int.tryParse(value);
                      if (jumlah == null || jumlah <= 0) {
                        return 'Jumlah hewan harus berupa angka positif';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Status',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  dropdownColor: const Color(0xFF2D3748),
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF4A5568),
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
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  validator: (value) => value == null ? 'Status harus dipilih' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Deskripsi (Opsional)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _deskripsiController,
                  maxLines: 3,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Masukkan deskripsi hewan (opsional)',
                    hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: const Color(0xFF4A5568),
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
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveHewan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        isEdit ? 'Update' : 'Simpan',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}