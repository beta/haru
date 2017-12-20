// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'dart:async';
import 'dart:mirrors';

import 'error.dart';
import 'meta.dart' as meta;
import 'util.dart' as util;

/// Base class for CLI apps.
abstract class App {
  _AppInfo _info;
  Commands _commands = new Commands();
  Settings _settings = new Settings();

  /// Builds this app.
  ///
  /// This method builds up
  ///
  ///  - app info (name, version, ...),
  ///  - global settings (fields annotated with [meta.Flag] and [meta.Option]),
  ///  - commands (methods with [meta.command]), and
  ///  - positional arguments ([meta.Arg]) settings for each command.
  ///
  /// After building, this app is still not ready to run. Use [_parse] to parse
  /// the command-line args and make it runnable.
  void _build() {
    /// Builds info of this app from the [meta.app] metadata.
    ///
    /// If the number of [meta.app] metadata is 0 or more than 1, a
    /// [HaruException] will be thrown.
    void buildAppInfo() {
      try {
        meta.app appMeta = reflect(this)
            .type
            .metadata
            .singleWhere((metadata) => metadata.type == meta.AppMeta)
            .reflectee;
        _info = new _AppInfo(appMeta.name, appMeta.version);
      } on StateError {
        throw new _HaruError(
            'Class ${MirrorSystem.getName(reflect(this).type.simpleName)} must '
            'have one and only one @app metadata.');
      }
    }

    /// Collects all global settings.
    ///
    /// Global settings are defined as member variables annotated with
    /// [meta.Flag] or [meta.Option] metadata.
    void buildGlobalSettings() {
      bool isSetting(DeclarationMirror variable) =>
          variable is VariableMirror &&
          variable.metadata.any((metadata) =>
              metadata.type == meta.FlagMeta ||
              metadata.type == meta.OptionMeta);

      bool isSettingMeta(InstanceMirror metadata) =>
          metadata.type == meta.FlagMeta || metadata.type == meta.OptionMeta;

      dynamic getSettingMeta(VariableMirror variable) {
        if (variable.metadata.where(isSettingMeta).length != 1) {
          throw new _HaruError(
              'Field "${MirrorSystem.getName(variable.simpleName)}" can only '
              'have one @flag or @option metadata.');
        }

        return variable.metadata.firstWhere(isSettingMeta).reflectee;
      }

      Map<Symbol, dynamic> addToSymbolMetaMap(
          Map<Symbol, dynamic> map, VariableMirror settingVariable) {
        map[settingVariable.simpleName] = getSettingMeta(settingVariable);
        return map;
      }

      void handleSetting(Symbol symbol, dynamic metadata) {
        if (metadata is meta.flag) {
          _settings.add(new Flag.fromMeta(symbol, metadata as meta.flag));
        } else if (metadata is meta.option) {
          _settings.add(new Option.fromMeta(symbol, metadata as meta.option));
        }
      }

      final clazz = reflect(this).type;
      clazz.declarations.values
          .where(isSetting)
          .fold({}, addToSymbolMetaMap).forEach(handleSetting);
    }

    /// Builds all commands.
    ///
    /// Commands are defined as instance methods annotated with [meta.command]
    /// metadata.
    void buildCommands() {
      bool isCommand(DeclarationMirror declaration) =>
          declaration is MethodMirror &&
          declaration.metadata
              .any((metadata) => metadata.type == meta.CommandMeta);

      void handleCommand(MethodMirror method) {
        var command = new Command.fromMethod(method);
        _commands.add(command);
      }

      final clazz = reflect(this).type;
      clazz.declarations.values
          .where(isCommand)
          .map((declaration) => declaration as MethodMirror)
          .forEach(handleCommand);
    }

    buildAppInfo();
    buildGlobalSettings();
    buildCommands();
  }

  /// Parses the command-line arguments for this app.
  ///
  /// From the args, this method figures out which command is called, and fills
  /// the settings and positional arguments for the called command, as well as
  /// global settings.
  ///
  /// TODO
  void _parse(List<String> args) {}

  /// Starts the Haru app with command-line args.
  Future run(List<String> args) {
    _build();

    try {
      _parse(args);
    } on HaruException catch (e) {
      return new Future.error(e);
    }

    /// TODO: Executes the command.

    return new Future.value(0);
  }
}

class _AppInfo {
  final String name;

  final String version;
  bool get hasVersion => version != null && version.isNotEmpty;

  _AppInfo(this.name, this.version);
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
///  - settings (flags and options), and
///  - positional arguments.
class Command {
  String _name;
  String get name => _name;

  String _abbr;
  String get abbr => _abbr;
  bool get hasAbbr => abbr != null && abbr.isNotEmpty;

  final Symbol _symbol;
  Symbol get symbol => _symbol;

  Settings _settings = new Settings();
  Settings get settings => _settings;

  Command.fromMethod(MethodMirror method) : this._symbol = method.simpleName {
    meta.command commandMeta = method.metadata
        .firstWhere((metadata) => metadata.type == meta.CommandMeta)
        .reflectee;
    _name = commandMeta.name;
    _abbr = commandMeta.abbr;

    _buildSettings(method.parameters);
  }

  void _buildSettings(List<ParameterMirror> params) {
    params.forEach((param) {
      var metadataList = param.metadata;

      var metadataCount = metadataList
          .where((metadata) => [meta.FlagMeta, meta.OptionMeta, meta.ArgMeta]
              .contains(metadata.type))
          .length;
      if (metadataCount == 0) {
        throw new _HaruError(
            'Parameter "${MirrorSystem.getName(param.simpleName)}" of '
            'method "${MirrorSystem.getName(_symbol)}" must have a '
            '@flag, @option or @arg metadata.');
      } else if (metadataCount > 1) {
        throw new _HaruError(
            'Parameter "${MirrorSystem.getName(param.simpleName)}" of '
            'method "${MirrorSystem.getName(_symbol)}" can only have '
            'one @flag, @option or @arg metadata.');
      }

      var metadata = metadataList.firstWhere((metadata) => [
            meta.FlagMeta,
            meta.OptionMeta,
            meta.ArgMeta
          ].contains(metadata.type));
      if (metadata.type == meta.FlagMeta) {
        // Add flag.
        var flag = new Flag.fromMeta(param.simpleName, metadata.reflectee);
        _settings.add(flag);
      } else if (metadata.type == meta.OptionMeta) {
        // TODO: Add option.
      } else if (metadata.type == meta.ArgMeta) {
        // TODO: Add positional argument.
      }
    });
  }

  @override
  String toString() =>
      'Command {name: $name, ${hasAbbr ? 'abbr: $abbr, ' : ''} symbol: '
      '$symbol, settings: $_settings}';
}

/// Container for [Command]s.
class Commands {
  Map<String, Command> _commands = {};
  Map<String, String> _abbrs = {};

  bool get isNotEmpty => _commands.isNotEmpty;

  bool contains(String name) => _commands.containsKey(name);
  bool containsAbbr(String abbr) => _abbrs.containsKey(abbr);

  /// Returns a [Command] instance with command name.
  Command find(String name) => _commands[name];

  /// Returns a [Command] instance with command abbreviation.
  Command findWithAbbr(String abbr) => _commands[_abbrs[abbr]];

  /// Adds a new [Command].
  ///
  /// If a command with the same name alreay exists, throw a
  /// [NameDuplicateError]. If a command with the same abbreviation already
  /// exists, throw a [AbbrDuplicateError].
  void add(Command command) {
    if (contains(command.name)) {
      throw new NameDuplicateError(command.name);
    }
    _commands[command.name] = command;

    if (command.hasAbbr) {
      if (containsAbbr(command.abbr)) {
        throw new AbbrDuplicateError(command.abbr);
      }
      _abbrs[command.abbr] = command.name;
    }
  }

  @override
  String toString() =>
      _commands.values
          .fold('Commands [', (str, command) => str += command.toString()) +
      ']';
}

/// A setting item for a command (or the global app).
///
/// This class is the base class for [Flag] and [Option]. A setting is an item
/// with a name, an optional abbreviation, a corresponding variable name as
/// [Symbol] and one or more calculated value. For flags, there is only one
/// value type of which is [bool], and for options the number and type may vary.
abstract class Setting {
  /// Setting name.
  final String _name;
  String get name => _name;

  /// Setting abbreviation.
  final String _abbr;
  String get abbr => _abbr;
  bool get hasAbbr => _abbr != null && _abbr.isNotEmpty;

  /// Symbol of variable.
  final Symbol _symbol;
  Symbol get symbol => _symbol;

  Setting(Symbol symbol, {String name = null, String abbr = null})
      : _name = util.camelToKebab(MirrorSystem.getName(symbol)),
        _symbol = symbol,
        _abbr = abbr;

  /// Number of command-line arguments needed.
  int get numOfArgs;

  /// Calculates a value from command-line args.
  void calculate(List<String> args);

  /// Returns the calculated value.
  dynamic get value;
}

/// A flag is a boolean setting for a command.
///
/// The value of a flag is `true` if it's provided in the command-line
/// arguments. Otherwise the value is `false`.
class Flag extends Setting {
  Flag(Symbol symbol, {String name = null, String abbr = null})
      : super(symbol, name: name, abbr: abbr);

  Flag.fromMeta(Symbol symbol, meta.flag flagMeta)
      : this(symbol, name: flagMeta.name, abbr: flagMeta.abbr);

  /// A flag does not need any arguments.
  @override
  int get numOfArgs => 0;

  bool _calculated = false;

  /// Calculated a value from command-line args.
  ///
  /// Calling this method means the flag appears in the command-line arguments.
  /// The calculated value is therefore `true`.
  @override
  void calculate(List<String> args) {
    _calculated = true;
  }

  @override
  bool get value => _calculated;

  @override
  String toString() {
    return 'Flag {name: $name, ${'abbr: $abbr, ' ?? ''} symbol: $symbol}';
  }
}

/// An option is a setting item for a command.
///
/// TODO
class Option extends Setting {
  Option(Symbol symbol, {String name = null, String abbr = null})
      : super(symbol, name: name, abbr: abbr);

  Option.fromMeta(Symbol symbol, meta.option optionMeta)
      : this(symbol, name: optionMeta.name, abbr: optionMeta.abbr);

  /// An option may have multiple arguments.
  ///
  /// Only 1 argument is supported now. TODO: Support multiple args.
  @override
  int get numOfArgs => 1;

  /// Calculate a value from command-line args.
  ///
  /// TODO: Calculate the value.
  void calculate(List<String> args) {
    return null;
  }

  /// TODO: Returns the calculated value.
  @override
  dynamic get value => null;

  @override
  String toString() {
    return 'Option {name: $name, ${'abbr: $abbr, ' ?? ''} symbol: $symbol}';
  }
}

/// Container for [Setting]s.
class Settings {
  Map<String, Setting> _settings = {};
  Map<String, String> _abbrs = {};

  bool get isNotEmpty => _settings.isNotEmpty;

  bool get hasFlags => _settings.values.any((setting) => setting is Flag);

  bool get hasOptions => _settings.values.any((setting) => setting is Option);

  bool contains(String name) => _settings.containsKey(name);
  bool containsAbbr(String abbr) => _abbrs.containsKey(abbr);

  /// Returns a [Setting] instance with setting name.
  Setting find(String name) => _settings[name];

  /// Returns a [Setting] instance with setting abbreviation.
  Setting findWithAbbr(String abbr) => _settings[_abbrs[abbr]];

  /// Adds a new [Setting].
  ///
  /// If a setting with the same name already exists, throw a
  /// [NameDuplicateError]. If a setting with the same abbreviation
  /// already exists, throw a [AbbrDuplicateError].
  void add(Setting setting) {
    if (contains(setting.name)) {
      throw new NameDuplicateError(setting.name);
    }
    _settings[setting.name] = setting;

    if (setting.hasAbbr) {
      if (containsAbbr(setting.abbr)) {
        throw new AbbrDuplicateError(setting.abbr);
      }
      _abbrs[setting.abbr] = setting.name;
    }
  }

  @override
  String toString() =>
      _settings.values
          .fold('Settings [', (str, setting) => str += setting.toString()) +
      ']';
}

/// Error to throw when two commands or settings have the same name.
class NameDuplicateError extends Error {
  final String name;

  NameDuplicateError(this.name);
}

/// Error to throw when two commands or settings have the same abbreviation.
class AbbrDuplicateError extends Error {
  final String abbr;

  AbbrDuplicateError(this.abbr);
}
