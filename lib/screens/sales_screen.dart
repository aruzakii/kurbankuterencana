import 'package:flutter/material.dart';
import 'package:kurbanku_terencana/providers/prediksi_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/penjualan_provider.dart';
import '../models/penjualan.dart';
import '../widgets/sales/header.dart';
import '../widgets/sales/total_pendapatan_card.dart';
import '../widgets/sales/jenis_kurban_terlaris.dart';
import '../widgets/sales/estimasi_permintaan.dart';
import '../widgets/sales/recent_sales.dart';
import '../widgets/sales/monthly_summary.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedPeriode = 'tahun_depan'; // Default ke tahun_depan
  String _selectedJenisHewan = 'Semua'; // Default ke Semua

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final penjualanProvider = Provider.of<PenjualanProvider>(context, listen: false);
      // Panggil generatePrediksi dengan nilai default
      Provider.of<PrediksiProvider>(context, listen: false).generatePrediksi(
        penjualanProvider,
        selectedPeriode: _selectedPeriode,
        selectedJenisHewan: _selectedJenisHewan,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: RefreshIndicator(
        onRefresh: () async {
          final penjualanProvider = Provider.of<PenjualanProvider>(context, listen: false);
          await penjualanProvider.fetchPenjualan();
          await Provider.of<PrediksiProvider>(context, listen: false).generatePrediksi(
            penjualanProvider,
            selectedPeriode: _selectedPeriode,
            selectedJenisHewan: _selectedJenisHewan,
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Header(),
              const SizedBox(height: 24),
              TotalPendapatanCard(),
              const SizedBox(height: 24),
              JenisKurbanTerlaris(),
              const SizedBox(height: 24),
              EstimasiPermintaan(
                selectedPeriode: _selectedPeriode,
                selectedJenisHewan: _selectedJenisHewan,
                onPeriodeChanged: (value) {
                  setState(() {
                    _selectedPeriode = value ?? 'tahun_depan';
                    Provider.of<PrediksiProvider>(context, listen: false).generatePrediksi(
                      Provider.of<PenjualanProvider>(context, listen: false),
                      selectedPeriode: _selectedPeriode,
                      selectedJenisHewan: _selectedJenisHewan,
                    );
                  });
                },
                onJenisHewanChanged: (value) {
                  setState(() {
                    _selectedJenisHewan = value ?? 'Semua';
                    Provider.of<PrediksiProvider>(context, listen: false).generatePrediksi(
                      Provider.of<PenjualanProvider>(context, listen: false),
                      selectedPeriode: _selectedPeriode,
                      selectedJenisHewan: _selectedJenisHewan,
                    );
                  });
                },
              ),
              const SizedBox(height: 24),
              RecentSales(),
              const SizedBox(height: 24),
              MonthlySummary(),
            ],
          ),
        ),
      ),
    );
  }
}