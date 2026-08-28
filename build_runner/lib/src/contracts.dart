class Pre {
  final String c1;
  final String? c2;
  final String? c3;
  final String? c4;
  final String? c5;

  const Pre(this.c1, [this.c2, this.c3, this.c4, this.c5]);
}

class Post {
  final String c1;
  final String? c2;
  final String? c3;
  final String? c4;
  final String? c5;

  const Post(this.c1, [this.c2, this.c3, this.c4, this.c5]);
}

class Invariant {
  final String c1;
  final String? c2;
  final String? c3;
  final String? c4;
  final String? c5;

  const Invariant(this.c1, [this.c2, this.c3, this.c4, this.c5]);
}

class Contracts {
  static bool enabled = false;
}

class ContractViolation implements Exception {
  final String message;

  ContractViolation(this.message);

  @override
  String toString() => 'ContractViolation: $message';
}
