import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/hewan_kurban_provider.dart';
import '../providers/penjualan_provider.dart';
import '../models/hewan_kurban.dart';
import '../models/penjualan.dart';
import '../widgets/add_hewan_dialog.dart';

class StokScreen extends StatefulWidget {
  const StokScreen({super.key});

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedJenisFilter = 'semua';
  String _currentTabFilter = 'semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentTabFilter = 'semua';
            break;
          case 1:
            _currentTabFilter = 'tersedia';
            break;
          case 2:
            _currentTabFilter = 'terjual';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A202C),
        elevation: 0,
        title: Text(
          'Manajemen Stok',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddHewanDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Tersedia'),
            Tab(text: 'Terjual'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHewanList('semua'),
                _buildHewanList('tersedia'),
                _buildPenjualanList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedJenisFilter,
                  dropdownColor: const Color(0xFF2D3748),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  items: const [
                    DropdownMenuItem(value: 'semua', child: Text('Semua Jenis')),
                    DropdownMenuItem(value: 'sapi', child: Text('Sapi')),
                    DropdownMenuItem(value: 'kambing', child: Text('Kambing')),
                    DropdownMenuItem(value: 'domba', child: Text('Domba')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedJenisFilter = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHewanList(String tabFilter) {
    return StreamBuilder<List<HewanKurban>>(
      stream: Provider.of<HewanKurbanProvider>(context, listen: false).getHewanKurbanStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7280),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final hewanList = snapshot.data ?? [];
        List<HewanKurban> filteredList = List.from(hewanList);
        if (tabFilter == 'tersedia') {
          filteredList = filteredList.where((h) => h.status == 'tersedia').toList();
        }
        if (_selectedJenisFilter != 'semua') {
          filteredList = filteredList.where((h) => h.jenis == _selectedJenisFilter).toList();
        }

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(tabFilter),
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showAddHewanDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7280),
                  ),
                  child: const Text('Tambah Hewan'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final hewan = filteredList[index];
              return _buildHewanCard(hewan);
            },
          ),
        );
      },
    );
  }

  Widget _buildPenjualanList() {
    return StreamBuilder<List<Penjualan>>(
      stream: Provider.of<PenjualanProvider>(context, listen: false).getPenjualanStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7280),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final penjualanList = snapshot.data ?? [];
        final hewanKurbanList = Provider.of<HewanKurbanProvider>(context, listen: false).hewanKurbanList;
        List<Penjualan> filteredList = List.from(penjualanList);

        if (_selectedJenisFilter != 'semua') {
          filteredList = filteredList.where((p) {
            final hewan = hewanKurbanList.firstWhere(
                  (h) => h.id == p.hewanKurbanId,
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
            return hewan.jenis == _selectedJenisFilter;
          }).toList();
        }

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage('terjual'),
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final penjualan = filteredList[index];
              return _buildPenjualanCard(penjualan, hewanKurbanList);
            },
          ),
        );
      },
    );
  }

  String _getEmptyMessage(String tabFilter) {
    if (_selectedJenisFilter != 'semua') {
      if (tabFilter == 'semua') {
        return 'Belum ada ${_selectedJenisFilter}';
      } else {
        return 'Belum ada ${_selectedJenisFilter} $tabFilter';
      }
    } else {
      if (tabFilter == 'semua') {
        return 'Belum ada hewan';
      } else {
        return 'Belum ada hewan $tabFilter';
      }
    }
  }

  Widget _buildHewanCard(HewanKurban hewan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Row(
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
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hewan.jenis.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${hewan.berat.toStringAsFixed(1)} kg | Stok: ${hewan.stok}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF2D3748),
                onSelected: (value) => _handleMenuAction(value, hewan),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harga',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    _formatCurrency(hewan.harga),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFD700),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(hewan.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hewan.status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(hewan.status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (hewan.deskripsi != null && hewan.deskripsi!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              hewan.deskripsi!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Ditambahkan: ${_formatDate(hewan.tanggalMasuk)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPenjualanCard(Penjualan penjualan, List<HewanKurban> hewanKurbanList) {
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
      margin: const EdgeInsets.only(bottom: 16),
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
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hewan.jenis.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Jumlah: ${penjualan.jumlah}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harga Total',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    _formatCurrency(penjualan.hargaJual * penjualan.jumlah),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFD700),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Berat Total',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '${(hewan.berat * penjualan.jumlah).toStringAsFixed(1)} kg',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pembeli: ${penjualan.namaPembeli}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (penjualan.kontakPembeli != null && penjualan.kontakPembeli!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Kontak: ${penjualan.kontakPembeli}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (penjualan.catatan != null && penjualan.catatan!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan: ${penjualan.catatan}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Dijual: ${_formatDate(penjualan.tanggalPenjualan)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'tersedia':
        return const Color(0xFF10B981);
      case 'terjual':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'tersedia':
        return Icons.check_circle;
      case 'terjual':
        return Icons.sell;
      default:
        return Icons.help;
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
        return const Color(0xFF6B7280);
    }
  }

  IconData _getIconByJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'sapi':
        return Icons.pets;
      case 'kambing':
      case 'domba':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  void _handleMenuAction(String action, HewanKurban hewan) {
    switch (action) {
      case 'edit':
        _showEditHewanDialog(context, hewan);
        break;
      case 'sell':
        _showJualHewanDialog(context, hewan);
        break;
      case 'delete':
        _showDeleteConfirmation(context, hewan);
        break;
    }
  }

  void _showAddHewanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddHewanDialog(),
    );
  }

  void _showEditHewanDialog(BuildContext context, HewanKurban hewan) {
    showDialog(
      context: context,
      builder: (context) => AddHewanDialog(hewan: hewan),
    );
  }

  void _showJualHewanDialog(BuildContext context, HewanKurban hewan) {
    final jumlahController = TextEditingController(text: '1');
    final namaPembeliController = TextEditingController();
    final kontakPembeliController = TextEditingController();
    final catatanController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3748),
        title: Text(
          'Jual ${hewan.jenis}',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan detail penjualan (maks stok: ${hewan.stok})',
              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: namaPembeliController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nama Pembeli',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama pembeli harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: kontakPembeliController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Kontak Pembeli (Opsional)',
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
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: catatanController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Catatan (Opsional)',
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
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Jumlah',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah harus diisi';
                }
                final jumlah = int.tryParse(value);
                if (jumlah == null || jumlah <= 0) {
                  return 'Jumlah harus berupa angka positif';
                }
                if (jumlah > hewan.stok) {
                  return 'Jumlah tidak boleh melebihi stok (${hewan.stok})';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final jumlah = int.tryParse(jumlahController.text);
              final namaPembeli = namaPembeliController.text.trim();
              final kontakPembeli = kontakPembeliController.text.trim();
              final catatan = catatanController.text.trim();
              if (jumlah != null && jumlah > 0 && jumlah <= hewan.stok && namaPembeli.isNotEmpty) {
                final penjualan = Penjualan(
                  id: '', // ID akan dihasilkan oleh Firestore
                  hewanKurbanId: hewan.id,
                  namaPembeli: namaPembeli,
                  kontakPembeli: kontakPembeli,
                  hargaJual: hewan.harga,
                  tanggalPenjualan: DateTime.now(),
                  catatan: catatan.isNotEmpty ? catatan : null,
                  userId: '', // Akan diatur di PenjualanProvider
                  jumlah: jumlah,
                );
                Provider.of<PenjualanProvider>(context, listen: false).addPenjualan(penjualan);
                context.read<HewanKurbanProvider>().sellHewanKurban(
                  hewan.id,
                  jumlah,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$jumlah ${hewan.jenis} dijual kepada $namaPembeli'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              'Jual',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, HewanKurban hewan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3748),
        title: Text(
          'Hapus Hewan',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${hewan.jenis} (Stok: ${hewan.stok}) ini?',
          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HewanKurbanProvider>().deleteHewanKurban(hewan.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${hewan.jenis} (Stok: ${hewan.stok}) berhasil dihapus'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}