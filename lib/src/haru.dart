// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'dart:async';
import 'dart:mirrors';

import 'error.dart';
import 'meta.dart' as meta;
import 'util.dart' as util;

/// Base class for CLI apps.
abstract class App extends Flags {
  String _appName;
  String get appName => _appName;

  Map<String, Command> _commands = {};
  Map<String, String> _commandAbbrs = {};

  /// Starts the Haru app with command-line args.
  Future run(List<String> args) {
    // Gets app name from the @app metadata.
    _appName = _getAppName();

    // Build global flags from instance members with @flag metadata.
    _buildGlobalFlagsAndOptions();

    // Builds the command map from methods with @command metadata.
    _buildCommands();

    // Parses the command-line args.
    _Parsed parsed;
    try {
      parsed = _parseArgs(args);
    } on HaruException catch (e) {
      return new Future.error(e);
    }
    // Sets the flags into app.
    if (parsed.hasGlobalFlags) {
      var instance = reflect(this);
      parsed.globalFlags.forEach(instance.setField);
    }

    // Executes the command.
    if (parsed.hasCommand) {
      reflect(this).invoke(parsed.command.symbol,
          parsed.command.params.map((param) {
        if (param is Flag) {
          return parsed.commandFlags[(param as Flag).symbol];
        }
      }));
    } else {
      /// TODO: Execute entry command.
    }

    return new Future.value(0);
  }

  /// Returns the app name set with [meta.app] metadata.
  ///
  /// If the number of [meta.app] metadata is 0 or more than 1, a
  /// [HaruException] will be thrown.
  String _getAppName() {
    try {
      meta.app appMeta = reflect(this)
          .type
          .metadata
          .singleWhere((metadata) => metadata.type == meta.AppMeta)
          .reflectee;
      return appMeta.name;
    } on StateError {
      throw new _HaruError(
          'Class ${MirrorSystem.getName(reflect(this).type.simpleName)} must '
          'have one and only one @app metadata.');
    }
  }

  /// Collects all global flags.
  ///
  /// Global flags are defined as member variables annotated with [meta.Flag]
  /// metadata.
  void _buildGlobalFlagsAndOptions() {
    final boolType = reflectType(bool);

    bool isFlag(DeclarationMirror declaration) =>
        declaration is VariableMirror &&
        declaration.type == boolType &&
        declaration.metadata.any((metadata) => metadata.type == meta.FlagMeta);

    bool isOption(DeclarationMirror declaration) =>
        declaration is VariableMirror &&
        declaration.metadata
            .any((metadata) => metadata.type == meta.OptionMeta);

    bool isFlagOrOption(DeclarationMirror declaration) =>
        isFlag(declaration) || isOption(declaration);

    bool isFlagMeta(InstanceMirror metadata) => metadata.type == meta.FlagMeta;

    bool isOptionMeta(InstanceMirror metadata) =>
        metadata.type == meta.OptionMeta;

    bool isFlagOrOptionMeta(InstanceMirror metadata) =>
        isFlagMeta(metadata) || isOptionMeta(metadata);

    final clazz = reflect(this).type;

    // Iterate instance members in class and find flags and options.
    clazz.declarations.values.where(isFlagOrOption).forEach((variable) {
      var metadataList = variable.metadata;

      var metadataCount = metadataList
          .where(
              (metadata) => [meta.FlagMeta, meta.OptionMeta].contains(metadata))
          .length;
      if (metadataCount > 1) {
        throw new _HaruError(
            'Field "${MirrorSystem.getName(variable.simpleName)}" of class '
            '"${MirrorSystem.getName(clazz.simpleName)}" can only have one '
            '@flag or @option metadata.');
      }

      var metadata = metadataList.firstWhere(isFlagOrOptionMeta);
      if (metadata.type == meta.FlagMeta) {
        // Add flag.
        _addFlag(new Flag.fromMeta(variable.simpleName, metadata.reflectee));
      }
    });
  }

  /// Builds [_commands] from all command methods in this Haru instance.
  ///
  /// [_commands] is a map with command name (specified with [meta.command]) as
  /// key and [_Command] instance as value.
  ///
  /// A command method is a method annotated with [meta.command] metadata.
  void _buildCommands() {
    final clazz = reflect(this).type;

    clazz.declarations.values
        .where((method) => method.metadata
            .any((metadata) => metadata.type == meta.CommandMeta))
        .forEach((commandMethod) => _addCommand(commandMethod as MethodMirror));
  }

  /// Adds a new command into [_commands].
  ///
  /// A new [_Command] instance is created for every command method, with
  /// flags, options and positional arguments.
  void _addCommand(MethodMirror commandMethod) {
    var command = new Command(commandMethod);
    _commands[command.name] = command;

    if (command.hasAbbr) {
      _commandAbbrs[command.abbr] = command.name;
    }
  }

  _Parsed _parseArgs(List<String> args) {
    bool isCommandAbbr(String arg) => _commandAbbrs.containsKey(arg);

    bool isCommandFullName(String arg) => _commands.containsKey(arg);

    bool isCommand(String arg) => isCommandAbbr(arg) || isCommandFullName(arg);

    Command getCommand(String arg) =>
        isCommandAbbr(arg) ? _commandAbbrs[arg] : _commands[arg];

    bool isFlagAbbr(String arg, Flags flags) =>
        flags.hasFlags &&
        arg.startsWith('-') &&
        !arg.startsWith('--') &&
        flags.flagAbbrs.containsKey(arg.substring(1));

    bool isFlagFullName(String arg, Flags flags) =>
        flags.hasFlags &&
        arg.startsWith('--') &&
        flags.flags.containsKey(arg.substring(2));

    bool isFlag(String arg, Flags flags) =>
        isFlagAbbr(arg, flags) || isFlagFullName(arg, flags);

    Flag getFlag(String arg, Flags flags) => isFlagAbbr(arg, flags)
        ? flags.flags[flags.flagAbbrs[arg.substring(1)]]
        : flags.flags[arg.substring(2)];

    bool isGlobalFlag(String arg) => isFlag(arg, this);

    Flag getGlobalFlag(String arg) => getFlag(arg, this);

    var parsed = new _Parsed(this);

    var iter = args.iterator;
    while (iter.moveNext()) {
      var arg = iter.current;
      if (arg.startsWith('-')) {
        // This arg is a flag or option.
        if (parsed.hasCommand && isFlag(arg, parsed.command)) {
          // This arg is a flag for current command.
          parsed.addCommandFlag(getFlag(arg, parsed.command));
        } else if (isGlobalFlag(arg)) {
          // This arg is a global flag.
          parsed.addGlobalFlag(getGlobalFlag(arg));
        } else {
          // This arg is not a flag.
          throw new HaruException('No flag named $arg is found.');
        }
      } else if (isCommand(arg)) {
        // This arg is a command.
        parsed.command = getCommand(arg);
      } else {
        /// TODO: Check if the command has positional arguments.
        throw new HaruException('"$arg" is not a valid command.');
      }
    }

    return parsed;
  }
}

class _Parsed {
  _Parsed(App app) {
    app.flags.values.forEach((flag) => globalFlags[flag.symbol] = false);
  }

  Command _command;
  Command get command => _command;
  void set command(Command command) {
    _command = command;
    commandFlags.clear();
    _command.flags.values.forEach((flag) => commandFlags[flag.symbol] = false);
  }

  bool get hasCommand => _command != null;

  Map<Symbol, bool> globalFlags = {};
  bool get hasGlobalFlags => globalFlags.isNotEmpty;
  void addGlobalFlag(Flag flag) => globalFlags[flag.symbol] = true;

  Map<Symbol, bool> commandFlags = {};
  bool get hasCommandFlags => commandFlags.isNotEmpty;
  void addCommandFlag(Flag flag) => commandFlags[flag.symbol] = true;
}

/// Error class to thrown when the Haru API is used incorrectly by the
/// developer, instead of the user.
class _HaruError extends Error {
  final String message;

  _HaruError(this.message);

  @override
  String toString() => message;
}

/// A [Command] wraps all the information about a command.
///
/// Information about a command includes:
///  - name,
///  - method name as a Dart [Symbol],
///  - abbreviation,
///  - flags,
///  - options, and
///  - positional arguments.
class Command extends Flags {
  String _name;
  String get name => _name;

  String _abbr;
  String get abbr => _abbr;
  bool get hasAbbr => abbr != null && abbr.isNotEmpty;

  final Symbol _symbol;
  Symbol get symbol => _symbol;

  List<dynamic> _params = [];
  List<dynamic> get params => _params;

  Command(MethodMirror method) : this._symbol = method.simpleName {
    meta.command commandMeta = method.metadata
        .firstWhere((metadata) => metadata.type == meta.CommandMeta)
        .reflectee;
    _name = commandMeta.name;
    _abbr = commandMeta.abbr;

    // Iterate parameters and find flags, options and arguments.
    method.parameters.forEach((parameter) {
      var metadataList = parameter.metadata;

      var metadataCount = metadataList
          .where((metadata) => [meta.FlagMeta, meta.OptionMeta, meta.ArgMeta]
              .contains(metadata.type))
          .length;
      if (metadataCount == 0) {
        throw new _HaruError(
            'Parameter "${MirrorSystem.getName(parameter.simpleName)}" of '
            'method "${MirrorSystem.getName(method.simpleName)}" must have a '
            '@flag, @option or @arg metadata.');
      } else if (metadataCount > 1) {
        throw new _HaruError(
            'Parameter "${MirrorSystem.getName(parameter.simpleName)}" of '
            'method "${MirrorSystem.getName(method.simpleName)}" can only have '
            'one @flag, @option or @arg metadata.');
      }

      var metadata = metadataList.firstWhere((metadata) => [
            meta.FlagMeta,
            meta.OptionMeta,
            meta.ArgMeta
          ].contains(metadata.type));
      if (metadata.type == meta.FlagMeta) {
        // Add flag.
        var flag = new Flag.fromMeta(parameter.simpleName, metadata.reflectee);
        _addFlag(flag);
        _params.add(flag);
      } else if (metadata.type == meta.OptionMeta) {
        // TODO: Add option.
      } else if (metadata.type == meta.ArgMeta) {
        // TODO: Add positional argument.
      }
    });
  }

  @override
  String toString() {
    return 'Command {name: $name, ${hasAbbr ? 'abbr: $abbr, ' : ''}'
        'symbol: $symbol, flags: $_flags}';
  }
}

/// A flag is a boolean option for a command.
///
/// The value of a flag is `true` if it's provided in the command-line
/// arguments. Otherwise the value is `false`.
class Flag {
  final String _name;
  String get name => _name;

  final String _abbr;
  String get abbr => _abbr;
  bool get hasAbbr => _abbr != null && _abbr.isNotEmpty;

  final Symbol _symbol;
  Symbol get symbol => _symbol;

  Flag(Symbol symbol, {String name = null, String abbr = null})
      : _symbol = symbol,
        _name = name ?? util.camelToKebab(MirrorSystem.getName(symbol)),
        _abbr = abbr;

  Flag.fromMeta(Symbol symbol, meta.Flag flagMeta)
      : this(symbol, name: flagMeta.name, abbr: flagMeta.abbr);

  @override
  String toString() {
    return 'Flag {name: $name, ${'abbr: $abbr, ' ?? ''}symbol: $symbol}';
  }
}

/// Base class for classes that can own [Flag]s.
abstract class Flags {
  Map<String, Flag> _flags = {};
  Map<String, Flag> get flags => _flags;

  Map<String, String> _flagAbbrs = {};
  Map<String, String> get flagAbbrs => _flagAbbrs;

  bool get hasFlags => _flags.isNotEmpty;

  /// Returns a [Flag] instance from flag name.
  Flag getFlag(String flagName) => _flags[flagName];

  /// Returns a [Flag] instance from flag abbreviation.
  Flag getFlagFromAbbr(String flagAbbr) => _flags[_flagAbbrs[flagAbbr]];

  /// Adds a new [Flag].
  void _addFlag(Flag flag) {
    _flags[flag.name] = flag;
    if (flag.hasAbbr) {
      _flagAbbrs[flag.abbr] = flag.name;
    }
  }
}
