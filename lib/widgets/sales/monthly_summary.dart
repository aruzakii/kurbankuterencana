import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/penjualan_provider.dart';

class MonthlySummary extends StatefulWidget {
  const MonthlySummary({super.key});

  @override
  State<MonthlySummary> createState() => _MonthlySummaryState();
}

class _MonthlySummaryState extends State<MonthlySummary> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Set default ke tahun berjalan (Januari - Desember)
    final now = DateTime.now();
    _startDate = DateTime(now.year, 1, 1);
    _endDate = DateTime(now.year, 12, 31);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PenjualanProvider>(
      builder: (context, provider, child) {
        final monthlyData = _getMonthlyDataByPeriod(provider);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ringkasan Bulanan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDatePicker(context),
                    icon: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatPeriodText(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              if (monthlyData.isEmpty)
                Center(
                  child: Text(
                    'Belum ada data pada periode ini',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                )
              else
                ...monthlyData.entries.map((entry) =>
                    _buildMonthlyItem(entry.key, entry.value)),
            ],
          ),
        );
      },
    );
  }

  Map<String, double> _getMonthlyDataByPeriod(PenjualanProvider provider) {
    if (_startDate == null || _endDate == null) {
      return {};
    }

    // Ambil data penjualan berdasarkan periode
    final penjualanPeriod = provider.getPenjualanByPeriode(_startDate!, _endDate!);

    // Grup berdasarkan bulan
    final Map<String, double> monthlyData = {};
    for (final penjualan in penjualanPeriod) {
      final bulan = _formatBulan(penjualan.tanggalPenjualan);
      monthlyData[bulan] = (monthlyData[bulan] ?? 0) + (penjualan.hargaJual * penjualan.jumlah);
    }

    // Hanya tampilkan bulan yang ada data (> 0)
    final filteredData = Map<String, double>.from(monthlyData);
    filteredData.removeWhere((key, value) => value <= 0);

    // Urutkan berdasarkan tanggal
    final sortedEntries = filteredData.entries.toList()
      ..sort((a, b) {
        final dateA = _parseMonthYear(a.key);
        final dateB = _parseMonthYear(b.key);
        return dateA.compareTo(dateB);
      });

    return Map.fromEntries(sortedEntries);
  }

  DateTime _parseMonthYear(String monthYear) {
    final parts = monthYear.split(' ');
    final monthName = parts[0];
    final year = int.parse(parts[1]);

    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'Mei': 5, 'Jun': 6,
      'Jul': 7, 'Agu': 8, 'Sep': 9, 'Okt': 10, 'Nov': 11, 'Des': 12
    };

    final month = months[monthName] ?? 1;
    return DateTime(year, month, 1);
  }

  String _formatBulan(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatPeriodText() {
    if (_startDate == null || _endDate == null) {
      return '';
    }

    final startMonth = _formatBulan(_startDate!);
    final endMonth = _formatBulan(_endDate!);

    if (startMonth == endMonth) {
      return startMonth;
    }

    return '$startMonth - $endMonth';
  }

  void _showDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime tempStartDate = _startDate ?? DateTime.now();
        DateTime tempEndDate = _endDate ?? DateTime.now();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(
                'Pilih Periode',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick select buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickSelectButton(
                        'Tahun Ini',
                            () {
                          final now = DateTime.now();
                          tempStartDate = DateTime(now.year, 1, 1);
                          tempEndDate = DateTime(now.year, 12, 31);
                          setDialogState(() {});
                        },
                      ),
                      _buildQuickSelectButton(
                        'Tahun Lalu',
                            () {
                          final now = DateTime.now();
                          tempStartDate = DateTime(now.year - 1, 1, 1);
                          tempEndDate = DateTime(now.year - 1, 12, 31);
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Date pickers
                  ListTile(
                    title: Text(
                      'Tanggal Mulai',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    subtitle: Text(
                      _formatDate(tempStartDate),
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7)),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.white),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempStartDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFFFFD700),
                                onPrimary: Colors.black,
                                surface: Color(0xFF1E1E1E),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        tempStartDate = picked;
                        setDialogState(() {});
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      'Tanggal Akhir',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    subtitle: Text(
                      _formatDate(tempEndDate),
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7)),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.white),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempEndDate,
                        firstDate: tempStartDate,
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFFFFD700),
                                onPrimary: Colors.black,
                                surface: Color(0xFF1E1E1E),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        tempEndDate = picked;
                        setDialogState(() {});
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update state dan trigger rebuild secara realtime
                    setState(() {
                      _startDate = tempStartDate;
                      _endDate = tempEndDate;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    'Terapkan',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickSelectButton(String text, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildMonthlyItem(String month, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            month,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          Text(
            _formatCurrency(amount),
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

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}