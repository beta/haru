// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

class HaruException implements Exception {
  final String message;

  HaruException(this.message);

  @override
  String toString() => message;
}
