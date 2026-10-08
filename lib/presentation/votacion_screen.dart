import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/opcion_votacion.dart';
import '../modelos/votacion.dart';
import '../modelos/resultado_opcion.dart';
import '../logica/resultado_voto.dart';
import '../logica/servicio_votacion.dart';
import 'confeti_widget.dart';

class VotacionScreen extends StatefulWidget {
  const VotacionScreen({super.key});
  @override
  State<VotacionScreen> createState() => _VotacionScreenState();
}

class _VotacionScreenState extends State<VotacionScreen> {
  late final Votacion _votacion;
  late final ServicioVotacion _servicio;
  bool _yaVote = false;
  final String _idUsuario =
      'invitado-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _votacion = Votacion(
      pregunta: 'Que obra prioritaria debe realizar el municipio este ano?',
      opciones: [
        OpcionVotacion(id: 'jardin', texto: 'Rehabilitacion del Jardin Principal'),
        OpcionVotacion(id: 'biblioteca', texto: 'Nueva Biblioteca Digital'),
        OpcionVotacion(id: 'alumbrado', texto: 'Alumbrado en el Barrio de Analco'),
        OpcionVotacion(id: 'parque', texto: 'Parque Infantil en la Colonia Guanajuato'),
      ],
      fechaCierre: DateTime.now().add(const Duration(days: 7)),
    );
    _servicio = ServicioVotacion(_votacion);
    _cargarVotosGuardados();
  }

  Future<void> _cargarVotosGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    final votantesGuardados = prefs.getStringList('votantes') ?? [];
    if (!mounted) return;
    setState(() {
      _votacion.votantes.addAll(votantesGuardados);
      for (final op in _votacion.opciones) {
        op.votos = prefs.getInt('votos_${op.id}') ?? op.votos;
      }
      _yaVote = prefs.getBool('ya_vote') ?? _votacion.votantes.contains(_idUsuario);
    });
  }

  Future<void> _guardarVotos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('votantes', _votacion.votantes.toList());
    for (final op in _votacion.opciones) {
      await prefs.setInt('votos_${op.id}', op.votos);
    }
    await prefs.setBool('ya_vote', true);
  }

  void _votar(String idOpcion) async {
    final resultado = _servicio.registrarVoto(
      idUsuario: _idUsuario,
      idOpcion: idOpcion,
    );
    if (resultado == ResultadoVoto.exitoso) {
      setState(() => _yaVote = true);
      await _guardarVotos();
    } else if (resultado == ResultadoVoto.usuarioYaVoto) {
      _mensaje('Ya registramos tu voto en este plebiscito.');
    } else if (resultado == ResultadoVoto.votacionCerrada) {
      _mensaje('Esta votacion ya cerro.');
    } else if (resultado == ResultadoVoto.limiteAlcanzado) {
      _mensaje('Se ha alcanzado el límite máximo de votos.');
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  void _verGanador() {
    final ganadores = _servicio.determinarGanador();
    final bool sinEmpate = ganadores.length == 1;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ganador',
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        Widget dialogo = AlertDialog(
          title: const Text('Resultado del plebiscito'),
          content: Text(
            sinEmpate
                ? 'La opcion ganadora es:\n\n${ganadores.first.texto}'
                : 'Hay un empate entre:\n\n${ganadores.map((g) => g.texto).join('\n')}',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );

        if (sinEmpate) {
          dialogo = ConfetiAnimado(child: dialogo);
        }

        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: FadeTransition(
            opacity: anim1,
            child: dialogo,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultados = _servicio.obtenerResultados();
    return Scaffold(
      appBar: AppBar(title: const Text('Plebiscito Vecinal - Dolores Hidalgo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _votacion.pregunta,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...resultados.map((r) => _BarraOpcion(
                resultado: r,
                puedeVotar: !_yaVote,
                onVotar: () => _votar(r.opcion.id),
              )),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _verGanador,
            icon: const Icon(Icons.emoji_events),
            label: const Text('Ver resultado del plebiscito'),
          ),
        ],
      ),
    );
  }
}

class _BarraOpcion extends StatelessWidget {
  final ResultadoOpcion resultado;
  final bool puedeVotar;
  final VoidCallback onVotar;
  const _BarraOpcion({
    required this.resultado,
    required this.puedeVotar,
    required this.onVotar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  resultado.opcion.texto,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: resultado.porcentaje),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) =>
                    Text('${valor.toStringAsFixed(0)}%'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 18,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: resultado.porcentaje / 100),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, valor, _) => Container(
                      height: 18,
                      width: constraints.maxWidth * valor,
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          if (puedeVotar)
            OutlinedButton(
              onPressed: onVotar,
              child: const Text('Votar por esta opcion'),
            ),
        ],
      ),
    );
  }
}
