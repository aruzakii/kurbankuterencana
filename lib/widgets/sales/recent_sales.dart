import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/penjualan_provider.dart';
import '../../models/penjualan.dart';
import '../../models/hewan_kurban.dart';

class RecentSales extends StatelessWidget {
  const RecentSales({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PenjualanProvider>(
      builder: (context, provider, child) {
        final recentSales = provider.penjualanList.take(5).toList();

        return Container(
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Penjualan Terbaru',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
              else if (recentSales.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada penjualan',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...recentSales.map((penjualan) => _buildSalesItem(context, penjualan, provider.hewanKurbanList)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalesItem(BuildContext context, Penjualan penjualan, List<HewanKurban> hewanKurbanList) {
    final hewan = hewanKurbanList.firstWhere(
          (h) => h.id == penjualan.hewanKurbanId,
      orElse: () => HewanKurban(
        id: '',
        jenis: 'Tidak Diketahui',
        berat: 0.0,
        harga: 0.0,
        status: 'unknown',
        tanggalMasuk: DateTime.now(),
        userId: '',
        stok: 0,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getColorByJenis(hewan.jenis).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconByJenis(hewan.jenis),
              color: _getColorByJenis(hewan.jenis),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  penjualan.namaPembeli,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Jenis: ${penjualan.jumlah} ${hewan.jenis}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Berat: ${(hewan.berat * penjualan.jumlah).toStringAsFixed(1)} kg',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(penjualan.tanggalPenjualan),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(penjualan.hargaJual * penjualan.jumlah),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFD700),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
        return const Color(0xFF6B7280);
    }
  }

  IconData _getIconByJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'sapi':
        return Icons.receipt;
      case 'kambing':
      case 'domba':
        return Icons.receipt;
      default:
        return Icons.receipt;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000000) {
      return 'Rp ${(amount / 1000000000000).toStringAsFixed(1)}T'; // Triliun
    } else if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M'; // Miliar
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}Jt'; // Juta
    } else {
      return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
      )}';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}