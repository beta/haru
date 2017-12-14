// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'dart:mirrors';

/// Base class for CLI apps.
abstract class Haru {
  /// Finds all command methods from this Haru instance.
  ///
  /// A command method is a method annotated with metadata [command].
  Map<String, DeclarationMirror> _findCommands() {
    final commandMeta = reflectClass(command);
    final clazz = reflect(this).type;

    var commands = <String, DeclarationMirror>{};
    clazz.declarations.values
        .where(
            (method) => method.metadata.any((meta) => meta.type == commandMeta))
        .forEach((method) {
      commands[method.metadata
          .firstWhere((meta) => meta.type == commandMeta)
          .reflectee
          .name] = method;
    });
    return commands;
  }

  /// Starts the Haru app with command-line args.
  void run(List<String> args) {
    var commands = _findCommands();

    if (args.isEmpty) {
      // Todo: show usage.
    } else {
      if (commands.containsKey(args[0])) {
        reflect(this).invoke(commands[args[0]].simpleName, args.sublist(1));
      }
    }
  }
}

/// Metadata class for commands.
class command {
  final String name;

  const command(this.name);
}
