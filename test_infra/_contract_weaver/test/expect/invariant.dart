// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'contracts.dart';

@Invariant('balance >= 0')
class Account {
  int balance;

  Account(this.balance);

  void deposit(int amount) {
    balance += amount;
  }

  void close() {
    _reset();
  }

  set overdraft(int amount) {
    balance -= amount;
  }

  // Not checked: getters, private methods and toString.
  bool get isEmpty => balance == 0;

  void _reset() {
    balance = 0;
  }

  @override
  String toString() => 'Account($balance)';
}
