// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'dart:mirrors';

import 'meta.dart';

/// Base class for CLI apps.
abstract class Haru {
  Map<String, _Command> _commands = {};

  /// Builds [_commands] from all command methods in this Haru instance.
  ///
  /// A command method is a method annotated with [command] metadata.
  void _buildCommands() {
    final commandMeta = reflectClass(command);
    final clazz = reflect(this).type;

    clazz.declarations.values
        .where(
            (method) => method.metadata.any((meta) => meta.type == commandMeta))
        .forEach((method) {
      var commandName = method.metadata
          .firstWhere((meta) => meta.type == commandMeta)
          .reflectee
          .name;
      _commands[commandName] = new _Command(commandName, method);
    });
  }

  /// Starts the Haru app with command-line args.
  void run(List<String> args) {
    _buildCommands();

    if (args.isEmpty) {
      // Todo: show usage.
    } else {
      if (_commands.containsKey(args[0])) {
        reflect(this).invoke(_commands[args[0]].methodName, args.sublist(1));
      }
    }
  }
}

/// A [_Command] wraps all the information about a command.
///
/// Information about a command includes:
///  - [name],
///  - [methodName] as Dart [Symbol],
///  - abbreviation,
///  - flags,
///  - options, and
///  - positional arguments.
class _Command {
  final String _name;
  String get name => _name;

  final Symbol _methodName;
  Symbol get methodName => _methodName;

  _Command(String name, DeclarationMirror method)
      : this._name = name,
        this._methodName = method.simpleName;
}

/// A flag is a boolean option for a command.
///
/// If the flag is provided in the argument list, the value is [true].
/// Otherwise the value is [false].
class _Flag {
  final String _name;
  String get name => _name;

  final String _abbr;
  String get abbr => _abbr;
  bool get hasAbbr => _abbr != null && _abbr.isNotEmpty;

  _Flag(String name, {String abbr})
      : this._name = name,
        this._abbr = abbr;
}
