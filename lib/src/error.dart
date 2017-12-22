// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'dart:mirrors';

/// Exception to throw when an unexpected error is triggered by the input of
/// user.
class HaruException implements Exception {
  final String message;

  HaruException(this.message);

  @override
  String toString() => message;
}

/// Error to throw when the Haru API is used incorrectly by the developer.
class HaruError extends Error {
  final String message;

  HaruError(this.message);

  @override
  String toString() => message;
}

/// Error to throw when two commands, settings or arguments have the same name
/// or abbreviation.
class DuplicateError extends Error {
  String _name;
  String _type;

  String _target;
  Symbol _symbol;
  bool _hasTarget = false;

  String _parentTarget;
  Symbol _parentSymbol;
  bool _hasParent = false;

  /// Returns an error message with all the information if set.
  String get message =>
      'The $_type "$_name" ' +
      (_hasTarget ? 'for $_target "${MirrorSystem.getName(_symbol)}" ' : '') +
      (_hasParent
          ? 'in $_parentTarget "${MirrorSystem.getName(_parentSymbol)}" '
          : '') +
      'is already in use.';

  /// Specifies the duplicate name.
  void name(String name) {
    _name = name;
    _type = 'name';
  }

  /// Specifies the duplicate abbreviation.
  void abbr(String abbr) {
    _name = abbr;
    _type = 'abbr';
  }

  /// Specifies the target of error.
  ///
  /// [target] is the name of the target object, for example "command" or
  /// "flag". [symbol] is a Dart [Symbol] of the target object.
  void of(String target, Symbol symbol) {
    _target = target;
    _symbol = symbol;
    _hasTarget = true;
  }

  /// Specifies the parent of error target.
  ///
  /// See [of] for explanation of parameters.
  void within(String target, Symbol symbol) {
    _parentTarget = target;
    _parentSymbol = symbol;
    _hasParent = true;
  }
}
