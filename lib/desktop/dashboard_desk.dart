import 'package:basefundi/desktop/dash_bajostock_desk.dart';
import 'package:basefundi/desktop/directorio/aceptarpedidosdesk.dart';
import 'package:basefundi/desktop/fundicion/listado_empleados_desk.dart';
import 'package:basefundi/desktop/fundicion/tareasextras_desk.dart';
import 'package:basefundi/desktop/pedidos_sucursales/productos_solicitados.dart';
import 'package:basefundi/desktop/pedidos_sucursales/productos_solicitar.dart';
import 'package:basefundi/desktop/personal/funciones/tareas_empleados_desk.dart';
import 'package:basefundi/desktop/personal/funciones/tareas_realizar_desk.dart';
import 'package:basefundi/desktop/personal/insumos/insumos_desk.dart';
import 'package:basefundi/modulos/administracion.dart';
import 'package:basefundi/modulos/ajustes_desk.dart';
import 'package:basefundi/modulos/directorio_desk.dart';
import 'package:basefundi/modulos/fundicion.dart';
import 'package:basefundi/modulos/inventario_desk.dart';
import 'package:basefundi/modulos/personal_desk.dart';
import 'package:basefundi/modulos/reportes_desk.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:basefundi/desktop/personal/empleados/empleados_activos_desk.dart';

class DashboardDeskScreen extends StatefulWidget {
  const DashboardDeskScreen({super.key});

  @override
  State<DashboardDeskScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardDeskScreen>
    with WidgetsBindingObserver {
  String nombreUsuario = '';
  String rolUsuario = 'Empleado';
  String sedeUsuario = '';

  int totalProductos = 0;
  int ventasRealizadas = 0;
  int productosBajoStock = 0;
  int numeroUsuarios = 0;
  int usuariosPendientes = 0;

  List<FlSpot> ingresosData = [];
  List<FlSpot> egresosData = [];
  List<String> meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  bool get isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarNombreYRolUsuario();
    _cargarDashboardData();
  }

  // Función unificada para cargar datos del gráfico
  Future<void> _cargarDatosGrafico() async {
    final now = DateTime.now();
    final currentYear = now.year;

    // Inicializamos en 0 los 12 meses
    final ingresosMensuales = List<double>.filled(12, 0);
    final egresosMensuales = List<double>.filled(12, 0);

    // 🔹 Cargar INGRESOS desde "proformas"
    final ventasSnapshot =
        await FirebaseFirestore.instance.collection('proformas').get();
    for (var doc in ventasSnapshot.docs) {
      final data = doc.data();
      if (data['fecha'] != null) {
        final fecha = (data['fecha'] as Timestamp).toDate();
        if (fecha.year == currentYear) {
          double totalIngreso = 0.0;
          if (data['total'] != null) {
            totalIngreso = double.tryParse(data['total'].toString()) ?? 0.0;
          } else if (data['items'] != null) {
            final items = data['items'] as List<dynamic>;
            for (var item in items) {
              totalIngreso +=
                  double.tryParse(item['v_total']?.toString() ?? '0') ?? 0.0;
            }
          }
          ingresosMensuales[fecha.month - 1] += totalIngreso;
        }
      }
    }

    // 🔹 Cargar EGRESOS desde "proformasfundicion"
    final egresosSnapshot =
        await FirebaseFirestore.instance.collection('proformasfundicion').get();
    for (var doc in egresosSnapshot.docs) {
      final data = doc.data();
      if (data['fecha'] != null) {
        final fecha = (data['fecha'] as Timestamp).toDate();

        // Solo procesar datos del año actual
        if (fecha.year == currentYear) {
          double totalEgresos = 0.0;

          // Si tiene campo 'monto' directo
          if (data['monto'] != null) {
            totalEgresos = (data['monto'] as num).toDouble();
          }
          // Si tiene items con totales
          else if (data['items'] != null) {
            final items = data['items'] as List<dynamic>;
            for (var item in items) {
              final totalItem =
                  double.tryParse(item['total']?.toString() ?? '0') ?? 0.0;
              totalEgresos += totalItem;
            }
          }

          egresosMensuales[fecha.month - 1] += totalEgresos;
        }
      }
    }

    // 🔹 Convertir a FlSpot (dividimos entre 1000 para mostrar en K)
    setState(() {
      ingresosData = List.generate(
        12,
        (i) => FlSpot(i.toDouble() + 1, ingresosMensuales[i]), // sin / 1000
      );
      egresosData = List.generate(
        12,
        (i) => FlSpot(i.toDouble() + 1, egresosMensuales[i]), // sin / 1000
      );
    });
  }

  Future<void> _cargarNombreYRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(user.uid)
            .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nombreUsuario = data['nombre'] ?? 'Usuario';
        rolUsuario = data['rol'] ?? 'Empleado';
        sedeUsuario =
            (data['sede'] ?? '').toString().trim().isEmpty
                ? 'Sin sede'
                : data['sede'];
      });
    }
  }

  Future<void> _cargarDashboardData() async {
    await Future.wait([
      _cargarTotalProductos(),
      _cargarVentasHoy(),
      _cargarProductosBajoStock(),
      _cargarUsuarios(),
      _cargarUsuariosPendientes(),
      _cargarDatosGrafico(), // Solo esta función para el gráfico
    ]);
  }

  Future<void> _cargarTotalProductos() async {
    final productosSnapshot =
        await FirebaseFirestore.instance.collection('productos').get();
    setState(() {
      totalProductos = productosSnapshot.docs.length;
    });
  }

  Future<void> _cargarVentasHoy() async {
    final proformasSnapshot =
        await FirebaseFirestore.instance.collection('proformas').get();
    setState(() {
      ventasRealizadas = proformasSnapshot.docs.length;
    });
  }

  Future<void> _cargarProductosBajoStock() async {
    // ✅ CAMBIO: Obtener de TODAS las sucursales
    final sucursales = ['Quito', 'Guayaquil', 'Tulcán'];

    // Mapa para acumular cantidades de todas las sucursales
    Map<String, int> stockPorProducto = {};

    // Recorrer todas las sucursales
    for (String sucursal in sucursales) {
      try {
        final bodegaSnapshot =
            await FirebaseFirestore.instance
                .collection('inventarios')
                .doc(sucursal)
                .collection('procesos')
                .doc('bodega')
                .collection('productos')
                .get();

        for (var doc in bodegaSnapshot.docs) {
          final cantidad = doc.data()['cantidad'] ?? 0;
          final referencia = doc.id; // El ID del documento ES la referencia

          // Acumular la cantidad de esta sucursal
          if (cantidad is int) {
            stockPorProducto[referencia] =
                (stockPorProducto[referencia] ?? 0) + cantidad;
          } else if (cantidad is num) {
            stockPorProducto[referencia] =
                (stockPorProducto[referencia] ?? 0) + cantidad.toInt();
          }
        }
      } catch (e) {
        print('Error al cargar inventario de $sucursal: $e');
      }
    }

    // Contar productos con stock total menor a 5
    int bajoStock = 0;
    stockPorProducto.forEach((referencia, cantidadTotal) {
      if (cantidadTotal < 5 && cantidadTotal >= 0) {
        bajoStock++;
      }
    });

    setState(() {
      productosBajoStock = bajoStock;
    });
  }

  Future<void> _cargarUsuarios() async {
    final usuariosSnapshot =
        await FirebaseFirestore.instance.collection('usuarios_activos').get();
    setState(() {
      numeroUsuarios = usuariosSnapshot.docs.length;
    });
  }

  Future<void> _cargarUsuariosPendientes() async {
    final pendientesSnapshot =
        await FirebaseFirestore.instance
            .collection('usuarios_pendientes')
            .get();
    setState(() {
      usuariosPendientes = pendientesSnapshot.docs.length;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 22),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola $nombreUsuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sede $sedeUsuario',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          // ✅ DESPUÉS
                          if (rolUsuario == 'Gerente' ||
                              (rolUsuario == 'Administrador General' &&
                                  sedeUsuario != 'Quito' &&
                                  sedeUsuario != 'Guayaquil'))
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    '$totalProductos',
                                    'Total Productos',
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildMetricCard(
                                    '$ventasRealizadas',
                                    'Ventas',
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildMetricCard(
                                    '$productosBajoStock',
                                    'Bajo Stock',
                                    isClickable: true,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),

                          // ✅ DESPUÉS - solo Gerente y Administrador General ven métricas y gráfico
                          if (rolUsuario == 'Gerente' ||
                              (rolUsuario == 'Administrador General' &&
                                  sedeUsuario != 'Quito' &&
                                  sedeUsuario != 'Guayaquil'))
                            Row(
                              children: [
                                Column(
                                  children: [
                                    SizedBox(
                                      width: 200,
                                      child: _buildMetricCard(
                                        '$numeroUsuarios',
                                        'Usuarios Activos',
                                        isClickable: true,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: 200,
                                      child: _buildMetricCard(
                                        '$usuariosPendientes',
                                        'Usuarios Pendientes',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Expanded(child: _buildFlujoDineroChart()),
                              ],
                            )
                          else
                            // Logo para los demás roles
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: Image.asset(
                                  'lib/assets/logo.png',
                                  width: 400,
                                  height: 400,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          const SizedBox(height: 40),

                          _buildGridFunctions(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String value,
    String label, {
    bool isClickable = false,
  }) {
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
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
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    // ✅ Bajo Stock - Accesible para todos
    if (isClickable && label == 'Bajo Stock') {
      return GestureDetector(
        onTap: () => navegarConFade(context, const BajoStockDeskScreen()),
        child: card,
      );
    }

    // ✅ Usuarios Activos - SOLO para Gerente y Administrador General
    if (isClickable && label == 'Usuarios Activos') {
      // Verificar si el rol tiene acceso
      bool tieneAcceso =
          rolUsuario == 'Gerente' || rolUsuario == 'Administrador General';

      if (tieneAcceso) {
        return GestureDetector(
          onTap:
              () => navegarConFade(context, const EmpleadosActivosDeskScreen()),
          child: card,
        );
      } else {
        // Si no tiene acceso, retornar la tarjeta sin funcionalidad de clic
        return card;
      }
    }

    return card;
  }

  Widget _buildFlujoDineroChart() {
    final double maxY = 100000;

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y leyenda mejorados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Flujo de Dinero ${DateTime.now().year}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  // Leyenda Ingresos
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Ingresos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Leyenda Egresos
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Egresos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7F1D1D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gráfico
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 5,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('0');
                        if (value >= 1000) {
                          return Text(
                            '\$${(value / 1000).toInt()}K',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt() - 1;
                        if (index >= 0 && index < meses.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              meses[index],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                barGroups: List.generate(12, (index) {
                  // Aseguramos que tengamos datos para todos los meses
                  double ingresosValue =
                      index < ingresosData.length ? ingresosData[index].y : 0;
                  double egresosValue =
                      index < egresosData.length ? egresosData[index].y : 0;

                  return BarChartGroupData(
                    x: index + 1,
                    barRods: [
                      // Barra de Ingresos
                      BarChartRodData(
                        toY: ingresosValue,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: Colors.grey.shade100,
                        ),
                      ),
                      // Barra de Egresos
                      BarChartRodData(
                        toY: egresosValue,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBorder: const BorderSide(color: Colors.blueAccent),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String tipo = rodIndex == 0 ? 'Ingresos' : 'Egresos';
                      String valor;

                      // Mostrar el valor real (multiplicado por 1000 porque dividimos por 1000)
                      double valorReal = rod.toY;
                      if (valorReal >= 1000000) {
                        valor =
                            '\$${(valorReal / 1000000).toStringAsFixed(1)}M';
                      } else if (valorReal >= 1000) {
                        valor = '\$${(valorReal / 1000).toInt()}K';
                      } else {
                        valor = '\$${valorReal.toInt()}';
                      }

                      return BarTooltipItem(
                        '$tipo\n$valor',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridFunctions() {
    int crossAxisCount = isDesktop ? 7 : 3;

    List<Widget> botones = [];

    switch (rolUsuario) {
      case 'Gerente':
        botones = [
          _gridButton(
            Icons.inventory_2,
            'Inventario',
            () => navegarConFade(context, const InventarioDeskScreen()),
          ),
          _gridButton(
            Icons.people,
            'Personal',
            () => navegarConFade(context, const PersonalDeskScreen()),
          ),
          _gridButton(
            Icons.calculate,
            'Directorio',
            () => navegarConFade(context, const DirectorioDeskScreen()),
          ),
          _gridButton(
            Icons.account_balance_wallet,
            'Administración',
            () => navegarConFade(context, const AdministracionDeskScreen()),
          ),
          _gridButton(
            Icons.shopping_cart,
            'Solicitudes',
            () =>
                navegarConFade(context, const ProductosSolicitadosScreenWeb()),
          ),
          _gridButton(
            Icons.local_fire_department,
            'Fundición',
            () => navegarConFade(context, const FundicionDeskScreen()),
          ),
          _gridButton(
            Icons.bar_chart,
            'Reportes',
            () => navegarConFade(context, const ReportesDeskScreen()),
          ),
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
        break;

      case 'Administrador General':
        botones = [
          _gridButton(
            Icons.inventory_2,
            'Inventario',
            () => navegarConFade(context, const InventarioDeskScreen()),
          ),
          if (sedeUsuario != 'Quito' && sedeUsuario != 'Guayaquil')
            _gridButton(
              Icons.people,
              'Personal',
              () => navegarConFade(context, const PersonalDeskScreen()),
            ),
          _gridButton(
            Icons.calculate,
            'Directorio',
            () => navegarConFade(context, const DirectorioDeskScreen()),
          ),
          if (sedeUsuario != 'Tulcán')
            _gridButton(
              Icons.location_city,
              'Envíos',
              () => navegarConFade(context, const EnviosTulcanDeskScreen()),
            ),
          if (sedeUsuario == 'Quito' || sedeUsuario == 'Guayaquil')
            _gridButton(
              Icons.shopping_cart,
              'Solicitar Productos',
              () =>
                  navegarConFade(context, const ProductosASolicitarScreenWeb()),
            ),
          if (sedeUsuario != 'Quito' && sedeUsuario != 'Guayaquil')
            _gridButton(
              Icons.account_balance_wallet,
              'Administración',
              () => navegarConFade(context, const AdministracionDeskScreen()),
            ),
          _gridButton(
            Icons.bar_chart,
            'Reportes',
            () => navegarConFade(context, const ReportesDeskScreen()),
          ),
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
        break;

      case 'Vendedor':
        botones = [
          _gridButton(
            Icons.inventory_2,
            'Inventario',
            () => navegarConFade(context, const InventarioDeskScreen()),
          ),
          _gridButton(
            Icons.calculate,
            'Directorio',
            () => navegarConFade(context, const DirectorioDeskScreen()),
          ),
          _gridButton(
            Icons.bar_chart,
            'Reportes',
            () => navegarConFade(context, const ReportesDeskScreen()),
          ),
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
        break;

      case 'Supervisor Fundición':
        botones = [
          _gridButton(
            Icons.assignment_turned_in,
            'Control Actividades',
            () => navegarConFade(context, const OperadoresListDeskScreen()),
          ),
          _gridButton(
            Icons.build_circle,
            'Funciones extra',
            () => navegarConFade(context, const TareasExtrasScreen()),
          ),
          _gridButton(
            Icons.inventory,
            'Insumos',
            () => navegarConFade(context, const InsumosDeskScreen()),
          ),
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
        break;

      case 'Operador Fundición':
        botones = [
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
        break;

      case 'Supervisor Mecanizado':
        botones = [
          _gridButton(
            Icons.inventory_2,
            'Inventario',
            () => navegarConFade(context, const InventarioDeskScreen()),
          ),
          _gridButton(
            Icons.task_alt,
            'Tareas',
            () => navegarConFade(context, const FuncionesDeskScreen()),
          ),
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
        break;

      case 'Operador Mecanizado':
        botones = [
          _gridButton(
            Icons.task_alt,
            'Tareas',
            () => navegarConFade(context, const TareasPendientesDeskScreen()),
          ),
        ];
        break;

      default:
        botones = [
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      children: botones,
    );
  }

  Widget _gridButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF4682B4), size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
