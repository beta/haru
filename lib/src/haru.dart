// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'dart:mirrors';

import 'command.dart';
import 'errors.dart';

class Haru {
  static void start(List<String> args) {
    if (args.isEmpty) {
      Haru.entryCommand.execute([]);
    } else {
      Command command = Haru.createCommand(args[0]);

      List<String> arguments = [];
      for (var i = 1; i < args.length; i += 1) {
        arguments.add(args[i]);
      }

      command.execute(arguments);
    }
  }

  static List<ClassMirror> _getCommandClassMirrors() {
    final ClassMirror commandClassMirror = reflectClass(Command);

    return currentMirrorSystem().libraries.values.fold([],
        (List<ClassMirror> mirrors, LibraryMirror libraryMirror) {
      mirrors.addAll(libraryMirror.declarations.values.where((declaration) =>
          (declaration is ClassMirror &&
              declaration.isSubclassOf(commandClassMirror))));
      return mirrors;
    });
  }

  static List<ClassMirror> _getErrorCommandClassMirrors() {
    final ClassMirror errorClassMirror = reflectClass(ErrorCommand);

    return currentMirrorSystem().libraries.values.fold([],
        (List<ClassMirror> mirrors, LibraryMirror libraryMirror) {
      mirrors.addAll(libraryMirror.declarations.values.where((declaration) =>
          (declaration is ClassMirror &&
              declaration.isSubclassOf(errorClassMirror))));
      return mirrors;
    });
  }

  static Command createCommand(commandName) {
    final ClassMirror commandAnnotationMirror = reflectClass(command);

    List<ClassMirror> commandClassMirrors = _getCommandClassMirrors();
    for (var classMirror in commandClassMirrors) {
      for (var metadata in classMirror.metadata) {
        if (metadata.type == commandAnnotationMirror &&
            metadata.reflectee.commandName == commandName) {
          return classMirror.newInstance(new Symbol(''), []).reflectee;
        }
      }
    }

    return _getErrorCommand(commandName);
  }

  static get entryCommand {
    final ClassMirror entryAnnotationMirror = reflectClass(_entryAnnotation);

    ClassMirror entryClassMirror;

    List<ClassMirror> commandClassMirrors = _getCommandClassMirrors();
    for (var classMirror in commandClassMirrors) {
      for (var metadata in classMirror.metadata) {
        if (metadata.type == entryAnnotationMirror) {
          if (entryClassMirror == null) {
            entryClassMirror = classMirror;
          } else {
            throw new MultipleEntryCommandError();
          }
        }
      }
    }

    if (entryClassMirror != null) {
      return entryClassMirror.newInstance(new Symbol(''), []).reflectee;
    } else {
      return new Command();
    }
  }

  static ErrorCommand _getErrorCommand(commandName) {
    final ClassMirror errorAnnotationMirror = reflectClass(_errorAnnotation);

    ClassMirror errorClassMirror;

    List<ClassMirror> commandClassMirrors = _getErrorCommandClassMirrors();
    for (var classMirror in commandClassMirrors) {
      for (var metadata in classMirror.metadata) {
        if (metadata.type == errorAnnotationMirror) {
          if (errorClassMirror == null) {
            errorClassMirror = classMirror;
          } else {
            throw new MultipleErrorCommandError();
          }
        }
      }
    }

    if (errorClassMirror != null) {
      return errorClassMirror
          .newInstance(new Symbol(''), [commandName]).reflectee;
    } else {
      return new DefaultErrorCommand(commandName);
    }
  }
}

/// Annotation class for commands.
class command {
  final String commandName;

  const command(this.commandName);
}

/// Annotation class for commands used when an error occurs.
class _errorAnnotation {
  const _errorAnnotation();
}

const error = const _errorAnnotation();

/// Annotation class for the default command.
class _entryAnnotation {
  const _entryAnnotation();
}

const entry = const _entryAnnotation();
