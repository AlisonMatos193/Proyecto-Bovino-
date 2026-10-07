import 'dart:math' as math;

/// Cálculo simplificado del coeficiente de consanguinidad (Wright) de una cría hipotética.
///   F = Σ (1/2)^(n1 + n2 + 1)   sobre cada camino a un ancestro común
/// n1 = generaciones del semental al ancestro, n2 = generaciones de la vaca al ancestro.
/// Simplificación: supone que los ancestros comunes no son consanguíneos (puede subestimar F).
class ResultadoCruza {
  final double f; // 0..1
  final List<String> ancestrosComunes;
  const ResultadoCruza(this.f, this.ancestrosComunes);

  double get porcentaje => f * 100;
  String get riesgo => f < 0.03125 ? 'Bajo' : (f < 0.0625 ? 'Moderado' : 'Alto');
}

class Consanguinidad {
  /// [pedigree]: id -> [padre, madre]. Los ids sin registro se tratan como fundadores.
  static ResultadoCruza calcular(
    String sementalId,
    String vacaId,
    Map<String, List<String?>> pedigree, {
    int maxGeneraciones = 6,
  }) {
    final a = _ancestros(sementalId, pedigree, maxGeneraciones);
    final b = _ancestros(vacaId, pedigree, maxGeneraciones);
    var f = 0.0;
    final comunes = <String>[];
    for (final e in a.entries) {
      final otros = b[e.key];
      if (otros == null) continue;
      comunes.add(e.key);
      for (final n1 in e.value) {
        for (final n2 in otros) {
          f += math.pow(0.5, n1 + n2 + 1).toDouble();
        }
      }
    }
    return ResultadoCruza(f, comunes);
  }

  /// id de ancestro -> lista de profundidades (una por cada camino). El propio animal cuenta con 0.
  static Map<String, List<int>> _ancestros(String id, Map<String, List<String?>> ped, int max) {
    final out = <String, List<int>>{};
    void caminar(String? a, int d) {
      if (a == null || a.isEmpty || d > max) return;
      out.putIfAbsent(a, () => []).add(d);
      final padres = ped[a];
      if (padres == null) return;
      caminar(padres[0], d + 1);
      caminar(padres[1], d + 1);
    }

    caminar(id, 0);
    return out;
  }
}
