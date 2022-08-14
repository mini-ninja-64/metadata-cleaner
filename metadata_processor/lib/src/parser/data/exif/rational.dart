class Rational {
  final int dividend;
  final int divisor;

  Rational(this.dividend, this.divisor);

  @override
  String toString() {
    return "$dividend / $divisor";
  }
}
