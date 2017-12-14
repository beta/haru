// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'error.dart';

/// Metadata class for commands.
class command {
  final String name;

  const command(this.name);
}

/// Metadata class for flags.
///
/// If the flag is provided in the argument list, the value is [true].
/// Otherwise the value is [false].
///
/// The name of a flag should be in lowercase, and words should be
/// separated with a dash ("-"). Do not add the leading dashes ("--") as they
/// will be added automatically. For example, the following flag names are
/// correct:
///  - flag
///  - another-flag
/// While these are wrong names:
///  - Flag
///  - FLAG
///  - another_flag
///  - -flag
///
/// Abbreviation of a flag usually comes in one or two lower characters. Mostly
/// abbreviations are selected based on the first one or two characters of the
/// flag. For example, the abbreviation for "flag" can be "f". The leading dash
/// ("-") should not be added as it will be added automatically.
///
/// The name and abbreviation of a flag must be unique. If a flag with the same
/// name or abbreviation of an existing one is found, a [HaruException] will be
/// thrown.
class flag {
  final String name;
  final String abbr;

  const flag(this.name, {String abbr = ''}) : this.abbr = abbr;
}
