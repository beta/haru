# Haru

Haru is an easy-to-use framework for creating command-line applications with Dart.

## Installation

Install Haru with [Pub](https://pub.dartlang.org/). See [this page](https://pub.dartlang.org/packages/haru#-installing-tab-) for instructions.

## Getting started

> This guide is aimed for the 1.0 version of Haru. Documentation for the 0.x versions can be found [here](https://www.dartdocs.org/documentation/haru/0.1.1/).

> Haru is in the progress of refactoring. Changes to this guide are expected.

Haru uses Dart [metadata](https://www.dartlang.org/guides/language/language-tour#metadata) to configure a CLI app. First, create a class for your app with an `@app` metadata. Suppose we are developing a Git command-line client.

```dart
@app('git') // 'git' is the app name users type in console
class GitApp {
  // TODO
}
```

A Haru app is made up of commands. Commands can have flags (`--flag`), options (`--option value`) and positional arguments. For example, in `git add -A src/`,

 - `git` is the app name,
 - `add` is the command,
 - `-A` is (an abbreviation of) a flag for the command, and
 - `src/` is the positional argument, the path to be added.

Global flags and options are also supported.

### Command

Haru uses instance methods for commands.

```dart
@command('add')
void add() {
  // ...
}
```

Commands support flags, options and positional arguments. These values are all defined as method parameters.

```dart
@command('add')
void add(@arg String pathspec, @Flag(abbr: 'A') bool all) {
  // ...
}
```

The metadatas for flags, options and positional arguments come in two forms.

 - The lowercase ones (`@flag`, `@option` and `@arg`) have no parameters. Names of these values are generated automatically from the parameter variable name. For example, parameter `all` will result in `--all`, and `anotherName` -> `--another-name`.
 - The ones starting in uppercase (`@Flag`, `@Option` and `@Arg`) have their parameters. `@Flag` and `@Option` have two named parameters `name` and `abbr`. Example: `@Flag(name: 'flag', abbr: 'f')` will make `--flag` and `-f` work the same. Leading dashes should not be included.

   `@Arg` has one named parameter `name`. This value will be used in command usage, for example `@Arg(name: 'value')` -> `Usage: appname command <value>`.

### Global flags and options

Haru also support global flags and options. These global values can appear anywhere in the command line, for example, `git --verbose add -A src` is equal to `git add -A src --verbose`.

Global flags and options are defined as instance variables. For example:

```dart
@command('git')
class GitApp {
  @flag
  bool verbose;

  @command('add')
  void add(@arg String pathspec, @Flag(abbr: 'A') bool all) {
    if (verbose) {
      // ...
    }
  }
}
```

## More examples

You can find a complete example of a command-line application in [`example/example.dart`](https://github.com/beta/haru/blob/master/example/example.dart).

## License

MIT
