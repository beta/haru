// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'haru.dart';

/// Base class for all commands.
class Command {
  /// Executes what the command should do.
  void execute(List<String> args) {}

  /// Returns help message for the command.
  String help() {
    return '';
  }
}

/// Base class for commands that displays help.
abstract class HelpCommand extends Command {
  @override
  void execute(List<String> args) {
    if (args.isEmpty) {
      print(help());
    } else if (args.length == 1) {
      print(Haru.createCommand(args[0]).help());
    } else {
      print('Error: too many arguments.');
    }
  }
}

/// Base class for commands used when an error occurs.
abstract class ErrorCommand extends Command {
  String commandName;

  ErrorCommand(this.commandName);

  @override
  void execute(List<String> args) {
    print(help());
  }
}

/// Default implementation of ErrorCommand.
class DefaultErrorCommand extends ErrorCommand {
  DefaultErrorCommand(String commandName) : super(commandName);

  @override
  void execute(List<String> args) {
    print(help());
  }

  @override
  String help() {
    return '''Error: cannot find command "${commandName}".
Use command "help" for usages.''';
  }
}
