import 'package:basefundi/services/importcatalogo_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/services/navbar_desk.dart';

class VisualizarCatalogoScreen extends StatefulWidget {
  const VisualizarCatalogoScreen({super.key});

  @override
  State<VisualizarCatalogoScreen> createState() =>
      _VisualizarCatalogoScreenState();
}

class _VisualizarCatalogoScreenState extends State<VisualizarCatalogoScreen>
    with SingleTickerProviderStateMixin {
  String categoriaSeleccionada = 'Discos';
  String terminoBusqueda = '';
  final TextEditingController _controladorBusqueda = TextEditingController();
  late TabController _tabController;

  final List<Map<String, dynamic>> categorias = [
    {'nombre': 'Discos', 'icono': Icons.album},
    {'nombre': 'Tambores', 'icono': Icons.radio_button_unchecked},
    {'nombre': 'Bocines', 'icono': Icons.speaker},
    {'nombre': 'Arañas', 'icono': Icons.settings},
    {'nombre': 'Alcantarillado', 'icono': Icons.water_damage},
    {'nombre': 'Sumideros', 'icono': Icons.grid_on},
    {'nombre': 'Rejillas', 'icono': Icons.view_module},
    {'nombre': 'Accesorios', 'icono': Icons.build_circle},
    {'nombre': 'Cocinas', 'icono': Icons.kitchen},
    {'nombre': 'Gimnasio', 'icono': Icons.fitness_center},
    {'nombre': 'Agrícolas', 'icono': Icons.agriculture},
    {'nombre': 'Sistemas', 'icono': Icons.build},
    {'nombre': 'Soporteria', 'icono': Icons.construction},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categorias.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          categoriaSeleccionada =
              categorias[_tabController.index]['nombre'] as String;
          terminoBusqueda = '';
          _controladorBusqueda.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _obtenerProductos(String categoria) {
    return FirebaseFirestore.instance
        .collection('catalogo')
        .doc(categoria)
        .collection('productos')
        .orderBy('referencia')
        .snapshots();
  }

  List<DocumentSnapshot> _filtrarProductos(List<DocumentSnapshot> productos) {
    if (terminoBusqueda.isEmpty) return productos;
    return productos.where((producto) {
      final data = producto.data() as Map<String, dynamic>;
      final referencia = data['referencia']?.toString().toLowerCase() ?? '';
      final nombre = data['nombre']?.toString().toLowerCase() ?? '';
      final termino = terminoBusqueda.toLowerCase();
      return referencia.contains(termino) || nombre.contains(termino);
    }).toList();
  }

  List<String> _obtenerColumnas(String categoria) {
    switch (categoria) {
      case 'Discos':
        return [
          'Referencia',
          'Nombre',
          'Diámetro',
          'Altura T',
          'Bocín',
          'Espesor',
          'Huecos',
          'S/V',
          'PVP',
          '20%',
          'Peso',
          'Acciones',
        ];
      case 'Tambores':
        return [
          'Referencia',
          'Nombre',
          'Diámetro',
          'Hueco',
          'Banda',
          'Bocín',
          'POC',
          'Observaciones',
          'PVP',
          '20%',
          'Peso',
          'Acciones',
        ];
      case 'Soporteria':
        return [
          'Referencia',
          'Nombre',
          'Dimensiones',
          'Peso',
          'PVP',
          'Acciones',
        ];
      case 'Bocines':
        return [
          'Referencia',
          'Nombre',
          'Pista interna',
          'Pista externa',
          'Pernos',
          'Eje',
          'PVP',
          '15%',
          'Peso',
          'Acciones',
        ];
      case 'Rejillas':
        return [
          'Referencia',
          'Nombre',
          'Dimensiones',
          'PVP',
          'Desc',
          'Acciones',
        ];
      case 'Accesorios':
        return [
          'Referencia',
          'Nombre',
          'Dimensiones',
          'Peso',
          'PVP',
          'Acciones',
        ];
      case 'Sumideros':
        return [
          'Referencia',
          'Nombre',
          'Dimensiones',
          'Tapa',
          'Cerco',
          'PVP',
          'Desc',
          'Acciones',
        ];
      case 'Cocinas':
        return ['Referencia', 'Nombre', 'Dimensiones', 'PVP', 'Acciones'];
      default:
        return ['Referencia', 'Nombre', 'Descripción', 'PVP', 'Acciones'];
    }
  }

  String _obtenerValorCelda(
    Map<String, dynamic> data,
    String columna,
    String categoria,
  ) {
    switch (categoria) {
      case 'Discos':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Diámetro':
            return data['diametro']?.toString() ?? '';
          case 'Altura T':
            return data['alturaTotal']?.toString() ?? '';
          case 'Bocín':
            return data['bocin']?.toString() ?? '';
          case 'Espesor':
            return data['espesor']?.toString() ?? '';
          case 'Huecos':
            return data['huecos']?.toString() ?? '';
          case 'S/V':
            return data['tipo']?.toString() ?? '';
          case 'PVP':
            return '\$${data['pvp']?.toString() ?? '0.00'}';
          case '20%':
            return '\$${data['descuento20']?.toString() ?? '0.00'}';
          case 'Peso':
            return '${data['peso']?.toString() ?? '0.00'} kg';
          default:
            return '';
        }
      case 'Tambores':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Diámetro':
            return data['diametro']?.toString() ?? '';
          case 'Hueco':
            return data['hueco']?.toString() ?? '';
          case 'Banda':
            return data['banda']?.toString() ?? '';
          case 'Bocín':
            return data['bocin']?.toString() ?? '';
          case 'POC':
            return data['poc']?.toString() ?? '';
          case 'Observaciones':
            return data['observaciones']?.toString() ?? '';
          case 'PVP':
            return '\$${data['pvp']?.toString() ?? '0.00'}';
          case '20%':
            return '\$${data['descuento20']?.toString() ?? '0.00'}';
          case 'Peso':
            return '${data['peso']?.toString() ?? '0.00'} kg';
          default:
            return '';
        }
      case 'Soporteria':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Dimensiones':
            return data['dimensiones']?.toString() ?? '';
          case 'Peso':
            return '${data['peso']?.toString() ?? '0.00'} kg';
          case 'PVP':
            return '\$${data['pvp']?.toString() ?? '0.00'}';
          default:
            return '';
        }
      case 'Rejillas':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Dimensiones':
            return data['dimensiones']?.toString() ?? '';
          case 'PVP':
            return '\$${data['pvp']?.toString() ?? '0.00'}';
          case 'Desc':
            return '\$${data['descuento']?.toString() ?? '0.00'}';
          default:
            return '';
        }
      case 'Accesorios':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Dimensiones':
            return data['dimensiones']?.toString() ?? '';
          case 'Peso':
            return '${data['peso']?.toString() ?? '0.00'} kg';
          case 'PVP':
            return '\$${data['pvp']?.toString() ?? '0.00'}';
          default:
            return '';
        }
      case 'Sumideros':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Dimensiones':
            return data['dimensiones']?.toString() ?? '';
          case 'Tapa':
            return data['tapa']?.toString() ?? '';
          case 'Cerco':
            return data['cerco']?.toString() ?? '';
          case 'PVP':
            return '\$${data['pvp']?.toString() ?? '0.00'}';
          case 'Desc':
            return '\$${data['descuento']?.toString() ?? '0.00'}';
          default:
            return '';
        }
      case 'Bocines':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Pista interna':
            return data['pistainterna']?.toString() ?? '';
          case 'Pista externa':
            return data['pistaexterna']?.toString() ?? '';
          case 'Pernos':
            return data['pernos']?.toString() ?? '';
          case 'Eje':
            return data['eje']?.toString() ?? '';
          case 'PVP':
            return '\$${data['pvp']?.toString() ?? '0.00'}';
          case '15%':
            return '\$${data['descuento20']?.toString() ?? '0.00'}';
          case 'Peso':
            return '${data['peso']?.toString() ?? '0.00'} kg';
          default:
            return '';
        }
      default:
        return data[columna.toLowerCase()]?.toString() ?? '';
    }
  }

  String _obtenerValorParaEdicion(
    Map<String, dynamic> data,
    String columna,
    String categoria,
  ) {
    switch (categoria) {
      case 'Discos':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Diámetro':
            return data['diametro']?.toString() ?? '';
          case 'Altura T':
            return data['alturaTotal']?.toString() ?? '';
          case 'Bocín':
            return data['bocin']?.toString() ?? '';
          case 'Espesor':
            return data['espesor']?.toString() ?? '';
          case 'Huecos':
            return data['huecos']?.toString() ?? '';
          case 'S/V':
            return data['tipo']?.toString() ?? '';
          case 'PVP':
            return data['pvp']?.toString() ?? '';
          case '20%':
            return data['descuento20']?.toString() ?? '';
          case 'Peso':
            return data['peso']?.toString() ?? '';
          default:
            return '';
        }
      case 'Tambores':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Diámetro':
            return data['diametro']?.toString() ?? '';
          case 'Hueco':
            return data['hueco']?.toString() ?? '';
          case 'Banda':
            return data['banda']?.toString() ?? '';
          case 'Bocín':
            return data['bocin']?.toString() ?? '';
          case 'POC':
            return data['poc']?.toString() ?? '';
          case 'Observaciones':
            return data['observaciones']?.toString() ?? '';
          case 'PVP':
            return data['pvp']?.toString() ?? '';
          case '20%':
            return data['descuento20']?.toString() ?? '';
          case 'Peso':
            return data['peso']?.toString() ?? '';
          default:
            return '';
        }
      case 'Bocines':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Pista interna':
            return data['pistainterna']?.toString() ?? '';
          case 'Pista externa':
            return data['pistaexterna']?.toString() ?? '';
          case 'Pernos':
            return data['pernos']?.toString() ?? '';
          case 'Eje':
            return data['eje']?.toString() ?? '';
          case 'PVP':
            return data['pvp']?.toString() ?? '';
          case '15%':
            return data['descuento20']?.toString() ?? '';
          case 'Peso':
            return data['peso']?.toString() ?? '';
          default:
            return '';
        }
      case 'Soporteria':
      case 'Rejillas':
      case 'Accesorios':
      case 'Sumideros':
        if (columna == 'PVP') return data['pvp']?.toString() ?? '';
        if (columna == 'Desc') return data['descuento']?.toString() ?? '';
        return data[_convertirColumnaNombreCampo(columna)]?.toString() ?? '';
      default:
        return data[_convertirColumnaNombreCampo(columna)]?.toString() ?? '';
    }
  }

  String _convertirColumnaNombreCampo(String columna) {
    switch (columna) {
      case 'Referencia':
        return 'referencia';
      case 'Nombre':
        return 'nombre';
      case 'Diámetro':
        return 'diametro';
      case 'Altura T':
        return 'alturaTotal';
      case 'Bocín':
        return 'bocin';
      case 'Espesor':
        return 'espesor';
      case 'Huecos':
        return 'huecos';
      case 'S/V':
        return 'tipo';
      case 'PVP':
        return 'pvp';
      case '20%':
        return 'descuento20';
      case 'Peso':
        return 'peso';
      case 'Hueco':
        return 'hueco';
      case 'Banda':
        return 'banda';
      case 'POC':
        return 'poc';
      case 'Observaciones':
        return 'observaciones';
      case 'Dimensiones':
        return 'dimensiones';
      case 'Tapa':
        return 'tapa';
      case 'Cerco':
        return 'cerco';
      case 'Desc':
        return 'descuento';
      case 'Descripción':
        return 'descripcion';
      case 'Pista interna':
        return 'pistainterna';
      case 'Pista externa':
        return 'pistaexterna';
      case 'Pernos':
        return 'pernos';
      case 'Eje':
        return 'eje';
      case '15%':
        return 'descuento20';
      default:
        return columna.toLowerCase();
    }
  }

  bool _esNumerico(String columna) {
    const camposNumericos = [
      'Diámetro',
      'Altura T',
      'Espesor',
      'Huecos',
      'Peso',
      'Hueco',
      'Banda',
      'Bocín',
      'POC',
      'PVP',
    ];
    return camposNumericos.contains(columna);
  }

  IconData _obtenerIconoPorNombre(String categoria) {
    return (categorias.firstWhere(
              (c) => c['nombre'] == categoria,
              orElse: () => {'icono': Icons.category},
            )['icono']
            as IconData?) ??
        Icons.category;
  }

  // ── MODAL: VER DETALLE ─────────────────────────────────────────────────────
  void _mostrarModalDetalle(Map<String, dynamic> data, String categoria) {
    final excluir = {'referencia', 'nombre', 'fecha', 'Fecha'};

    // ── ORDEN FIJO POR CATEGORÍA ──────────────────────────
    const Map<String, List<String>> ordenCampos = {
      'Discos': [
        'diametro',
        'alturaTotal',
        'bocin',
        'espesor',
        'huecos',
        'tipo',
        'peso',
        'pvp',
        'descuento20',
      ],
      'Tambores': [
        'diametro',
        'bocin',
        'hueco',
        'banda',
        'poc',
        'observaciones',
        'peso',
        'pvp',
        'descuento20',
      ],
      'Bocines': [
        'pistainterna',
        'pistaexterna',
        'pernos',
        'eje',
        'peso',
        'pvp',
        'descuento20',
      ],
      'Sumideros': ['dimensiones', 'tapa', 'cerco', 'peso', 'pvp', 'descuento'],
      'Rejillas': ['dimensiones', 'peso', 'pvp', 'descuento'],
      'Accesorios': ['dimensiones', 'peso', 'pvp', 'descuento'],
      'Soporteria': ['dimensiones', 'peso', 'pvp'],
      'Cocinas': ['dimensiones', 'peso', 'pvp'],
    };

    // Ordenar campos según el orden definido, luego los que sobren al final
    final ordenDefinido = ordenCampos[categoria] ?? [];

    final camposOrdenados = [
      // Primero los que tienen orden definido
      ...ordenDefinido
          .where(
            (k) =>
                !excluir.contains(k) &&
                data.containsKey(k) &&
                data[k] != null &&
                data[k].toString().isNotEmpty,
          )
          .map((k) => MapEntry(k, data[k])),

      // Luego los que no están en el orden definido
      ...data.entries.where(
        (e) =>
            !excluir.contains(e.key) &&
            !ordenDefinido.contains(e.key) &&
            e.value != null &&
            e.value.toString().isNotEmpty,
      ),
    ];
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header degradado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2C3E50), Color(0xFF4682B4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((data['referencia']?.toString() ?? '')
                                  .isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['referencia'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              Text(
                                data['nombre']?.toString() ?? 'Sin nombre',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                categoria,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Campos
                  Flexible(
                    child:
                        camposOrdenados.isEmpty
                            ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Sin información adicional',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                            : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              itemCount: camposOrdenados.length,
                              separatorBuilder:
                                  (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final entry = camposOrdenados[i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 160,
                                        child: Text(
                                          _formatKey(entry.key),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Color(0xFF4682B4),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value.toString(),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),

                  // Botón cerrar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _formatKey(String key) {
    // Mapeo de claves técnicas a nombres legibles
    const Map<String, String> nombres = {
      'pvp': 'PVP',
      'descuento20': '20%',
      'referencia': 'Referencia',
      'nombre': 'Nombre',
      'diametro': 'Diámetro',
      'alturaTotal': 'Altura Total',
      'bocin': 'Bocín',
      'espesor': 'Espesor',
      'huecos': 'Huecos',
      'tipo': 'S/V',
      'peso': 'Peso',
      'hueco': 'Hueco',
      'banda': 'Banda',
      'poc': 'POC',
      'observaciones': 'Observaciones',
      'dimensiones': 'Dimensiones',
      'tapa': 'Tapa',
      'cerco': 'Cerco',
      'descuento': 'Descuento',
      'descripcion': 'Descripción',
      'pistainterna': 'Pista Interna',
      'pistaexterna': 'Pista Externa',
      'pernos': 'Pernos',
      'eje': 'Eje',
    };

    // Si tiene mapeo directo, usarlo
    if (nombres.containsKey(key)) return nombres[key]!;

    // Si no, formatear automáticamente
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  // ── MODAL: ELIMINAR ────────────────────────────────────────────────────────
  void _mostrarDialogoEliminar(String productoId, String nombreProducto) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (_) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Eliminar producto',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¿Seguro que deseas eliminar "$nombreProducto"?',
                        style: const TextStyle(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
          ),
    );

    if (confirmacion == true) {
      try {
        await FirebaseFirestore.instance
            .collection('catalogo')
            .doc(categoriaSeleccionada)
            .collection('productos')
            .doc(productoId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "$nombreProducto" eliminado exitosamente'),
            backgroundColor: const Color(0xFF2C3E50),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── MODAL: EDITAR ──────────────────────────────────────────────────────────
  void _mostrarDialogoEditar(String productoId, Map<String, dynamic> data) {
    final columnas = _obtenerColumnas(categoriaSeleccionada);
    final Map<String, TextEditingController> controladores = {};

    for (String col in columnas) {
      if (col != 'Acciones') {
        controladores[col] = TextEditingController(
          text: _obtenerValorParaEdicion(data, col, categoriaSeleccionada),
        );
      }
    }

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.55,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF4682B4),
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Editar Producto — $categoriaSeleccionada',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children:
                              columnas
                                  .where((c) => c != 'Acciones')
                                  .map(
                                    (col) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: TextFormField(
                                        controller: controladores[col],
                                        decoration: InputDecoration(
                                          labelText: col,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF4682B4),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        keyboardType:
                                            _esNumerico(col)
                                                ? TextInputType.number
                                                : TextInputType.text,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              Map<String, dynamic> datos = {};
                              for (String col in controladores.keys) {
                                final v = controladores[col]!.text.trim();
                                if (v.isNotEmpty) {
                                  datos[_convertirColumnaNombreCampo(col)] = v;
                                }
                              }
                              await FirebaseFirestore.instance
                                  .collection('catalogo')
                                  .doc(categoriaSeleccionada)
                                  .collection('productos')
                                  .doc(productoId)
                                  .update(datos);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Producto actualizado exitosamente',
                                  ),
                                  backgroundColor: Color(0xFF2C3E50),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al actualizar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4682B4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Actualizar'),
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

  // ── MODAL: AGREGAR ─────────────────────────────────────────────────────────
  void _mostrarDialogoAgregar() {
    final columnas = _obtenerColumnas(categoriaSeleccionada);
    final Map<String, TextEditingController> controladores = {};

    for (String col in columnas) {
      if (col != 'Acciones') {
        controladores[col] = TextEditingController();
      }
    }

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.55,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _obtenerIconoPorNombre(categoriaSeleccionada),
                          color: const Color(0xFF2C3E50),
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Agregar Producto — $categoriaSeleccionada',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children:
                              columnas
                                  .where((c) => c != 'Acciones')
                                  .map(
                                    (col) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: TextFormField(
                                        controller: controladores[col],
                                        decoration: InputDecoration(
                                          labelText: col,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF2C3E50),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        keyboardType:
                                            _esNumerico(col)
                                                ? TextInputType.number
                                                : TextInputType.text,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              Map<String, dynamic> datos = {};
                              for (String col in controladores.keys) {
                                final v = controladores[col]!.text.trim();
                                if (v.isNotEmpty) {
                                  datos[_convertirColumnaNombreCampo(col)] = v;
                                }
                              }
                              if (datos.containsKey('pvp')) {
                                double pvp =
                                    double.tryParse(datos['pvp'].toString()) ??
                                    0.0;
                                datos['descuento20'] = (pvp * 0.8)
                                    .toStringAsFixed(2);
                              }
                              await FirebaseFirestore.instance
                                  .collection('catalogo')
                                  .doc(categoriaSeleccionada)
                                  .collection('productos')
                                  .add(datos);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Producto agregado a $categoriaSeleccionada',
                                  ),
                                  backgroundColor: const Color(0xFF2C3E50),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al agregar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3E50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Guardar'),
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

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ── HEADER ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFF2C3E50),
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 28),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Catálogo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── BARRA DE CONTROLES ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                // Buscador
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 46,
                    child: TextField(
                      controller: _controladorBusqueda,
                      decoration: InputDecoration(
                        hintText: 'Buscar por referencia o nombre...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF2C3E50),
                        ),
                        suffixIcon:
                            terminoBusqueda.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed:
                                      () => setState(() {
                                        terminoBusqueda = '';
                                        _controladorBusqueda.clear();
                                      }),
                                )
                                : null,
                        filled: true,
                        fillColor: const Color(0xFFF0F4F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) => setState(() => terminoBusqueda = v),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Botón Agregar
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _mostrarDialogoAgregar,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3E50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Botón Importar
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed:
                        () => navegarConFade(
                          context,
                          const ImportarCatalogoScreen(),
                        ),
                    icon: const Icon(Icons.file_upload, size: 18),
                    label: const Text('Importar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── TAB BAR FIJA CON SCROLL ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white, // ← movido aquí adentro
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF2C3E50),
              indicatorWeight: 3,
              labelColor: const Color(0xFF2C3E50),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              tabs:
                  categorias
                      .map(
                        (c) => Tab(
                          icon: Icon(c['icono'] as IconData, size: 16),
                          text: c['nombre'] as String,
                        ),
                      )
                      .toList(),
            ),
          ),

          // ── CONTENIDO TABS ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:
                  categorias.map((c) {
                    final categoria = c['nombre'] as String;
                    return _buildTabContenido(categoria);
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB CONTENIDO ──────────────────────────────────────────────────────────
  Widget _buildTabContenido(String categoria) {
    return StreamBuilder<QuerySnapshot>(
      stream: _obtenerProductos(categoria),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar datos',
              style: TextStyle(color: Colors.red[400]),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _obtenerIconoPorNombre(categoria),
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay productos en $categoria',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Importa un archivo Excel para ver los productos aquí',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final todos = snapshot.data!.docs;
        final filtrados = _filtrarProductos(todos);
        final columnas = _obtenerColumnas(categoria);

        if (filtrados.isEmpty && terminoBusqueda.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Sin resultados para "$terminoBusqueda"',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2C3E50).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _obtenerIconoPorNombre(categoria),
                      color: const Color(0xFF2C3E50),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      categoria,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Mostrando ${filtrados.length} de ${todos.length} productos',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tabla
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        const Color(0xFFF0F4F8),
                      ),
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        fontSize: 13,
                      ),
                      dataTextStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      columnSpacing: 20,
                      horizontalMargin: 12,
                      dataRowColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.hovered)) {
                          return const Color(0xFFEBF5FB);
                        }
                        return Colors.white;
                      }),
                      columns:
                          columnas
                              .map((col) => DataColumn(label: Text(col)))
                              .toList(),
                      rows:
                          filtrados.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DataRow(
                              // Clic en la fila → modal detalle
                              onSelectChanged:
                                  (_) => _mostrarModalDetalle(data, categoria),
                              cells:
                                  columnas.map((col) {
                                    if (col == 'Acciones') {
                                      return DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                color: Color(0xFF4682B4),
                                                size: 18,
                                              ),
                                              tooltip: 'Editar',
                                              onPressed:
                                                  () => _mostrarDialogoEditar(
                                                    doc.id,
                                                    data,
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 18,
                                              ),
                                              tooltip: 'Eliminar',
                                              onPressed:
                                                  () => _mostrarDialogoEliminar(
                                                    doc.id,
                                                    data['nombre']
                                                            ?.toString() ??
                                                        data['referencia']
                                                            ?.toString() ??
                                                        'Producto',
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return DataCell(
                                      Text(
                                        _obtenerValorCelda(
                                          data,
                                          col,
                                          categoria,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
