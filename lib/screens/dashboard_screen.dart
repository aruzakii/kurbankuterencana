import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/hewan_kurban_provider.dart';
import '../providers/penjualan_provider.dart';
import '../models/hewan_kurban.dart';
import '../models/penjualan.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'Pengguna';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('auth_token');
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? 'Pengguna';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            Provider.of<HewanKurbanProvider>(context, listen: false).getHewanKurbanStream().first,
            Provider.of<PenjualanProvider>(context, listen: false).getPenjualanStream().first,
          ]);
          await _loadUserName(); // Refresh nama pengguna saat refresh
        },
        color: const Color(0xFFFFD700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildStokChart(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang, $_userName!',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monitor stok dan penjualan mu',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<List<HewanKurban>>(
      stream: Provider.of<HewanKurbanProvider>(context, listen: false).getHewanKurbanStream(),
      builder: (context, hewanSnapshot) {
        return StreamBuilder<List<Penjualan>>(
          stream: Provider.of<PenjualanProvider>(context, listen: false).getPenjualanStream(),
          builder: (context, penjualanSnapshot) {
            if (hewanSnapshot.connectionState == ConnectionState.waiting ||
                penjualanSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                  strokeWidth: 3,
                ),
              );
            }

            if (hewanSnapshot.hasError || penjualanSnapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (hewanSnapshot.hasError)
                      Text(
                        'Error fetching animals: ${hewanSnapshot.error}',
                        style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
                      ),
                    if (penjualanSnapshot.hasError)
                      Text(
                        'Error fetching sales: ${penjualanSnapshot.error}',
                        style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Try Again',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final hewanList = hewanSnapshot.data ?? [];
            final penjualanList = penjualanSnapshot.data ?? [];
            final penjualanProvider = Provider.of<PenjualanProvider>(context, listen: false);
            final hewanProvider = Provider.of<HewanKurbanProvider>(context, listen: false);
            final totalHewan = hewanList.fold(0, (sum, h) => sum + h.stok);
            final hewanTersedia = hewanList.where((h) => h.status == 'tersedia').fold(0, (sum, h) => sum + h.stok);
            final hewanTerjual = penjualanList.fold(0, (sum, p) => sum + p.jumlah);
            final totalPendapatan = penjualanProvider.getTotalPendapatan();
            final totalNilaiStok = hewanProvider.getTotalNilaiStok();

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildSummaryCard(
                  title: 'Total Hewan',
                  value: totalHewan.toString(),
                  icon: Icons.pets,
                  color: const Color(0xFF10B981),
                ),
                _buildSummaryCard(
                  title: 'Tersedia',
                  value: hewanTersedia.toString(),
                  icon: Icons.inventory,
                  color: const Color(0xFF3B82F6),
                ),
                _buildSummaryCard(
                  title: 'Terjual',
                  value: hewanTerjual.toString(),
                  icon: Icons.sell,
                  color: const Color(0xFFF59E0B),
                ),
                _buildSummaryCard(
                  title: 'Pendapatan',
                  value: _formatCurrency(totalPendapatan),
                  icon: Icons.monetization_on,
                  color: const Color(0xFFEF4444),
                  isSmallText: true,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: isSmallText ? 16 : 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStokChart() {
    return StreamBuilder<List<HewanKurban>>(
      stream: Provider.of<HewanKurbanProvider>(context, listen: false).getHewanKurbanStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
              strokeWidth: 3,
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final hewanProvider = Provider.of<HewanKurbanProvider>(context, listen: false);
        final jenisHewan = hewanProvider.getJenisHewanSummary();
        final total = jenisHewan.values.fold(0, (sum, value) => sum + value);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
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
                'Hewan Yang Tersedia',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (jenisHewan.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No stock available',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...jenisHewan.entries.map((entry) => _buildStokItem(
                  jenis: entry.key,
                  jumlah: entry.value,
                  total: total,
                )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStokItem({
    required String jenis,
    required int jumlah,
    required int total,
  }) {
    final percentage = total > 0 ? (jumlah / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                jenis.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                '$jumlah ekor',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getColorByJenis(jenis),
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<List<Penjualan>>(
      stream: Provider.of<PenjualanProvider>(context, listen: false).getPenjualanStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
              strokeWidth: 3,
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final recentPenjualan = (snapshot.data ?? []).take(5).toList();
        final hewanProvider = Provider.of<HewanKurbanProvider>(context, listen: false);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktivitas Terbaru',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentPenjualan.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No sales activity yet',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentPenjualan.map((penjualan) {
                  final hewan = hewanProvider.hewanKurbanList.firstWhere(
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
                  return _buildActivityItem(
                    nama: penjualan.namaPembeli,
                    jenis: hewan.jenis,
                    jumlah: penjualan.jumlah,
                    harga: penjualan.hargaJual,
                    tanggal: penjualan.tanggalPenjualan,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityItem({
    required String nama,
    required String jenis,
    required int jumlah,
    required double harga,
    required DateTime tanggal,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getColorByJenis(jenis).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconByJenis(jenis),
              color: _getColorByJenis(jenis),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menjual $jumlah $jenis ke $nama',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(tanggal),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(harga * jumlah),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFD700),
            ),
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