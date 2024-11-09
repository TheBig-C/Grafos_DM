import 'dart:ui';

class ModeloNodo {
  double x, y;
  double radio;
  String nombre;
  Color color;
  bool esDegradado;
  List<Color>? colorDegradado;
  double bordeAncho;

  ModeloNodo(this.x, this.y, this.radio, this.color, this.nombre,
      {this.bordeAncho = 1.0, this.esDegradado = false, this.colorDegradado});
}
