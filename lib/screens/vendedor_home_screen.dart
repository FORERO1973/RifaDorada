import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/rifa_provider.dart';
import '../models/participante.dart';
import 'selector_numeros_screen.dart';

class VendedorHomeScreen extends StatefulWidget {
  const VendedorHomeScreen({super.key});

  @override
  State<VendedorHomeScreen> createState() => _VendedorHomeScreenState();
}

class _VendedorHomeScreenState extends State<VendedorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RifaProvider>().loadRifas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<RifaProvider>();
    final user = auth.currentUser;
    final rifasActivas = provider.rifas.where((r) => r.activa).toList();
    final misParticipantes = provider.participantes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Ventas', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGreeting(user?.nombre ?? 'Vendedor'),
          const SizedBox(height: 24),
          _buildQuickStats(misParticipantes),
          const SizedBox(height: 24),
          if (rifasActivas.isNotEmpty) ...[
            _buildSectionTitle('Rifas Activas'),
            const SizedBox(height: 12),
            ...rifasActivas.map((rifa) => _buildRifaCard(context, rifa, provider)),
          ],
          const SizedBox(height: 24),
          if (misParticipantes.isNotEmpty) ...[
            _buildSectionTitle('Últimas Ventas'),
            const SizedBox(height: 12),
            ...misParticipantes.take(5).map((p) => _buildVentaItem(context, p, provider)),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildGreeting(String nombre) {
    final hour = DateTime.now().hour;
    final saludo = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withValues(alpha: 0.15), AppTheme.surfaceColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'V',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$saludo,', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text(nombre, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<Participante> participantes) {
    final hoy = DateTime.now();
    final ventasHoy = participantes.where((p) =>
        p.fechaRegistro.year == hoy.year &&
        p.fechaRegistro.month == hoy.month &&
        p.fechaRegistro.day == hoy.day).length;
    final pagados = participantes.where((p) => p.estaPagado).length;
    final totalNumeros = participantes.fold<int>(0, (s, p) => s + p.numeros.length);

    return Row(
      children: [
        Expanded(child: _buildStatChip('$ventasHoy', 'Hoy', Icons.today, AppTheme.primaryColor)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatChip('$pagados', 'Pagados', Icons.check_circle, AppTheme.secondaryColor)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatChip('$totalNumeros', 'Números', Icons.confirmation_number, Colors.blue)),
      ],
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5));
  }

  Widget _buildRifaCard(BuildContext context, rifa, RifaProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.confirmation_number, color: AppTheme.primaryColor),
        ),
        title: Text(rifa.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${AppConstants.formatCurrencyCOP(rifa.precioNumero)} por número'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          provider.setRifaSeleccionada(rifa);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SelectorNumerosScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVentaItem(BuildContext context, Participante p, RifaProvider provider) {
    final isPaid = p.estaPagado;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: (isPaid ? AppTheme.secondaryColor : AppTheme.errorColor).withValues(alpha: 0.2),
          child: Text(
            p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
            style: TextStyle(fontWeight: FontWeight.bold, color: isPaid ? AppTheme.secondaryColor : AppTheme.errorColor),
          ),
        ),
        title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${p.numeros.join(", ")} • ${p.whatsapp}', style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isPaid ? AppTheme.secondaryColor : AppTheme.errorColor).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(isPaid ? 'PAGADO' : 'PENDIENTE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isPaid ? AppTheme.secondaryColor : AppTheme.errorColor)),
        ),
      ),
    );
  }
}
