// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

/// Converts a camelCase string into a kebab-case one.
///
/// This method also converts all underscores ("_") to dashes ("-").
String camelToKebab(String camel) {
  var regex = new RegExp(r'(.)([A-Z][a-z]+)');
  var kabab =
      camel.replaceAllMapped(regex, (match) => '${match[1]}-${match[2]}');

  regex = new RegExp(r'([a-z0-9])([A-Z])');
  kabab = kabab
      .replaceAllMapped(regex, (match) => '${match[1]}-${match[2]}')
      .replaceAll('_', '-')
      .toLowerCase();

  return kabab;
}
