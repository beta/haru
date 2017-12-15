// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'dart:mirrors';

/// Metadata class for CLI apps.
class app {
  final String name;

  const app(this.name);
}

/// Class mirror for [app] metadata.
final AppMeta = reflectClass(app);

/// Metadata class for commands.
class command {
  final String name;

  final String abbr;
  bool get hasAbbr => abbr != null && abbr.isNotEmpty;

  const command(this.name, {this.abbr = null});
}

/// Class mirror for [command] metadata.
final CommandMeta = reflectClass(command);

/// Metadata class for flags.
///
/// If the flag is provided in the argument list, the value is [true].
/// Otherwise the value is [false].
///
/// The name of a flag should be in kabab-case, which means all characters are
/// in lowercase, and words should be separated with a dash ("-"). Do not add
/// the leading dashes ("--") as they will be added automatically. For example,
/// the following flag names are correct:
///
///  - flag
///  - another-flag
///
/// While these are wrong names:
///
///  - Flag
///  - FLAG
///  - another_flag
///  - -flag
///
/// If no name is provided, a name will be generated based on the parameter name
/// that is annotated by this metadata. For example, flag name for parameter
/// "aParameter" will be "a-parameter", and "aVery_complicatedName" will result
/// in "a-very-complicated-name".
///
/// Abbreviation of a flag usually comes in one or two lower characters. Mostly
/// abbreviations are selected based on the first one or two characters of the
/// flag. For example, the abbreviation for "flag" can be "f". The leading dash
/// ("-") should not be added as it will be added automatically.
///
/// The name and abbreviation of a flag must be unique. If a flag with the same
/// name or abbreviation of an existing one is found, a [HaruException] will be
/// thrown.
class Flag {
  final String name;
  bool get hasName => name != null && name.isNotEmpty;

  final String abbr;
  bool get hasAbbr => abbr != null && abbr.isNotEmpty;

  const Flag({this.name = null, this.abbr = null});
}

/// A simplified version of [Flag] metadata for flags with no abbreviations and
/// the default name generated from variable name.
const flag = const Flag();

/// Class mirror for [Flag] metadata.
final FlagMeta = reflectClass(Flag);

/// Metadata class for options.
///
/// TODO
class Option {
  const Option();
}

/// A simplified version of [Option] metadata for options with no abbreviations
/// and the default name generated from variable name.
const option = const Option();

/// Class mirror for [Option] metadata.
final OptionMeta = reflectClass(Option);

/// Metadata class for positional arguments.
///
/// TODO
class Arg {
  const Arg();
}

/// A simplified version of [Arg] metadata for arguments with the default name
/// generated from variable name.
const arg = const Arg();

/// Class mirror for [Arg] metadata.
final ArgMeta = reflectClass(Arg);
