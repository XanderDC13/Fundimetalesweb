import 'package:basefundi/services/importar%20catalogo/accecocina.dart';
import 'package:basefundi/services/importar%20catalogo/agricolas.dart';
import 'package:basefundi/services/importar%20catalogo/alcantarillado.dart';
import 'package:basefundi/services/importar%20catalogo/ara%C3%B1as.dart';
import 'package:basefundi/services/importar%20catalogo/bocines.dart';
import 'package:basefundi/services/importar%20catalogo/cocinas.dart';
import 'package:basefundi/services/importar%20catalogo/discos.dart';
import 'package:basefundi/services/importar%20catalogo/gimnasio.dart';
import 'package:basefundi/services/importar%20catalogo/rejillas.dart';
import 'package:basefundi/services/importar%20catalogo/sistemas.dart';
import 'package:basefundi/services/importar%20catalogo/soporteria.dart';
import 'package:basefundi/services/importar%20catalogo/sumideros.dart';
import 'package:basefundi/services/importar%20catalogo/tambores.dart';
import 'package:basefundi/services/transition.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ImportarCatalogoScreen extends StatefulWidget {
  const ImportarCatalogoScreen({super.key});

  @override
  State<ImportarCatalogoScreen> createState() => _ImportarCatalogoScreenState();
}

class _ImportarCatalogoScreenState extends State<ImportarCatalogoScreen> {
  // Lista de categorías
  final List<String> categorias = [
    'Discos',
    'Tambores',
    'Bocines',
    'Arañas',
    'Alcantarillado',
    'Sumideros Rejillas',
    'Rejillas',
    'Cocinas',
    'Accesorios Cocinas',
    'Gimnasio',
    'Agrícolas',
    'Sistemas',
    'Soportería',
  ];

  void _navegarAImportacion(String categoria) {
    switch (categoria) {
      case 'Discos':
        navegarConFade(context, const ImportarDiscosScreen());
        break;
      case 'Tambores':
        navegarConFade(context, const ImportarTamboresScreen());
        break;
      case 'Arañas':
        navegarConFade(context, const ImportarAranasScreen());
        break;
      case 'Bocines':
        navegarConFade(context, const ImportarBocinesScreen());
        break;
      case 'Cocinas':
        navegarConFade(context, const ImportarCocinasScreen());
        break;
      case 'Soporteria':
        navegarConFade(context, const ImportarSoporteriaScreen());
        break;
      case 'Rejillas':
        navegarConFade(context, const ImportarRejillasScreen());
        break;
      case 'Accesorios Cocinas':
        navegarConFade(context, const ImportarAccesoriosScreen());
        break;
      case 'Sumideros Rejillas':
        navegarConFade(context, const ImportarSumiderosScreen());
        break;
      case 'Alcantarillado':
        navegarConFade(context, const ImportarAlcantarilladoScreen());
        break;
      case 'Gimnasio':
        navegarConFade(context, const ImportarGimnasioScreen());
        break;
      case 'Agrícolas':
        navegarConFade(context, const ImportarAgricolasScreen());
        break;
      case 'Sistemas':
        navegarConFade(context, const ImportarSistemasScreen());
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay pantalla definida para $categoria')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // Header
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Seleccionar Categoría para Importar',
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
          ),

          // Contenido principal con botones de categorías
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona la categoría que deseas importar:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Grid de botones de categorías
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 columnas
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio:
                                2.5, // Proporción ancho/alto de los botones
                          ),
                      itemCount: categorias.length,
                      itemBuilder: (context, index) {
                        final categoria = categorias[index];
                        return _construirBotonCategoria(categoria);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBotonCategoria(String categoria) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navegarAImportacion(categoria),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF4682B4),
                const Color(0xFF4682B4).withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _obtenerIconoCategoria(categoria),
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  categoria,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Función para obtener iconos según la categoría
  IconData _obtenerIconoCategoria(String categoria) {
    switch (categoria) {
      case 'Discos':
        return Icons.album;
      case 'Tambores':
        return Icons.circle;
      case 'Bocines':
        return Icons.speaker;
      case 'Arañas':
        return Icons.settings;
      case 'Alcantarillado':
        return Icons.water_damage;
      case 'Sumideros Rejillas':
        return Icons.grid_on;
      case 'Rejillas':
        return Icons.view_module;
      case 'Accesorios Cocinas':
        return Icons.kitchen;
      case 'Cocinas':
        return Icons.kitchen;
      case 'Gimnasio':
        return Icons.fitness_center;
      case 'Agrícolas':
        return Icons.agriculture;
      case 'Sistemas':
        return Icons.build;
      case 'Soportería':
        return Icons.construction;
      default:
        return Icons.category;
    }
  }
}
