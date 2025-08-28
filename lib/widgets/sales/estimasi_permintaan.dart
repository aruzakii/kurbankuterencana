import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/prediksi_provider.dart';

class EstimasiPermintaan extends StatelessWidget {
  final String? selectedPeriode;
  final String? selectedJenisHewan;
  final Function(String?) onPeriodeChanged;
  final Function(String?) onJenisHewanChanged;

  const EstimasiPermintaan({
    super.key,
    required this.selectedPeriode,
    required this.selectedJenisHewan,
    required this.onPeriodeChanged,
    required this.onJenisHewanChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PrediksiProvider>(
      builder: (context, provider, child) {
        print('Membangun EstimasiPermintaan, isLoading: ${provider.isLoading}, error: ${provider.error}, estimasiData: ${provider.estimasiData}');

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Color(0xFF8B5CF6),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Estimasi Permintaan',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'Periode',
                      selectedPeriode ?? 'tahun_depan',
                      [
                        {'value': 'bulan_depan', 'label': 'Bulan Depan'},
                        {'value': '6_bulan', 'label': '6 Bulan'},
                        {'value': 'tahun_depan', 'label': 'Tahun Depan'},
                      ],
                      onPeriodeChanged,
                      context,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      'Jenis Hewan',
                      selectedJenisHewan ?? 'Semua',
                      [
                        {'value': 'Semua', 'label': 'Semua'},
                        {'value': 'sapi', 'label': 'Sapi'},
                        {'value': 'kambing', 'label': 'Kambing'},
                        {'value': 'domba', 'label': 'Domba'},
                      ],
                      onJenisHewanChanged,
                      context,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildContent(provider, context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(PrediksiProvider provider, BuildContext context) {
    if (provider.isLoading) {
      return Container(
        height: 120,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        ),
      );
    }

    if (provider.error != null) {
      return _buildEmptyState(context, customMessage: 'Belum ada data yang cukup untuk estimasi permintaan. Silakan coba lagi nanti.');
    }

    final estimasiData = provider.estimasiData;
    final estimasiEntries = estimasiData['estimasi'] as Map<String, dynamic>?;

    if (estimasiEntries == null || estimasiEntries.isEmpty) {
      return _buildEmptyState(context);
    }

    final filteredEntries = selectedJenisHewan == 'Semua'
        ? estimasiEntries.entries
        : estimasiEntries.entries.where((entry) => entry.key == selectedJenisHewan);

    if (filteredEntries.isEmpty) {
      return _buildNoDataForSelection(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: filteredEntries
          .map((entry) => _buildEstimasiItem(entry.key, entry.value, context))
          .toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String? customMessage}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF8B5CF6).withOpacity(0.2),
                        const Color(0xFF3B82F6).withOpacity(0.2),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    size: 36,
                    color: const Color(0xFF8B5CF6).withOpacity(0.8),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            customMessage ?? 'Belum ada data yang cukup untuk estimasi permintaan',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Mulai dengan menambahkan riwayat penjualan untuk mendapatkan prediksi permintaan.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataForSelection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.filter_alt_outlined,
              size: 28,
              color: const Color(0xFFF59E0B).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada data yang cukup untuk estimasi permintaan',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada data untuk ${selectedJenisHewan ?? 'pilihan ini'} pada periode ${selectedPeriode == 'bulan_depan' ? 'Bulan Depan' : selectedPeriode == '6_bulan' ? '6 Bulan' : 'Tahun Depan'}. Coba ubah filter atau tambah data.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<Map<String, String>> options, Function(String?) onChanged, BuildContext context) {
    final validValue = options.any((option) => option['value'] == value) ? value : options.first['value']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonFormField<String>(
            value: validValue,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              filled: true,
              fillColor: Colors.transparent,
            ),
            dropdownColor: const Color(0xFF6B7280),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
            isExpanded: true,
            items: options.map((option) => DropdownMenuItem<String>(
              value: option['value'],
              child: Text(
                option['label']!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: (value) {
              print('Dropdown dipilih: $label - $value');
              onChanged(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEstimasiItem(String jenis, Map<String, dynamic> data, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  jenis.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getColorByJenis(jenis),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTrenColor(data['tren']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTrenIcon(data['tren']),
                      size: 12,
                      color: _getTrenColor(data['tren']),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data['tren'].toString().toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getTrenColor(data['tren']),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildEstimasiMetric(
                    'Estimasi Jumlah',
                    '${data['estimasiJumlah']} ekor',
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEstimasiMetric(
                    'Estimasi Pendapatan',
                    _formatCurrency(data['estimasiPendapatan']),
                    const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  'Confidence: ${(data['confidence'] * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Rata-rata Historis: ${data['rataRataHistoris'].toStringAsFixed(1)} ekor',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimasiMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getTrenColor(String tren) {
    switch (tren) {
      case 'naik':
        return const Color(0xFF10B981);
      case 'turun':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getTrenIcon(String tren) {
    switch (tren) {
      case 'naik':
        return Icons.trending_up;
      case 'turun':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getColorByJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'sapi':
        return const Color(0xFF10B981);
      case 'kambing':
        return const Color(0xFF3B82F6);
      case 'domba':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }
}