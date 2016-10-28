# Haru

Haru is an easy-to-use framework for creating command-line applications written in Dart, supporting syntax like `$ your-app <command> [arguments]`.

## Installation

Haru is published as a library package in [pub.dartlang.org](https://pub.dartlang.org/). Before starting to use Haru, make sure you [have Pub installed and configured](https://www.dartlang.org/tools/pub/get-started).

 1. Add Haru as a dependency into your project's `pubspec.yaml` like this:
    
    ```
    ...
    dependencies:
      ...
      haru: ^0.1.0
    ```
    
 2. Run `pub get` in your project's directory.

 3. Import Haru into your code with
    
    ```dart
    import 'package:haru/haru.dart';
    ```

## Getting started

 1. Create a command
    
    Write a class that's derived from `Command` to create a command. Use `@command` annotation to set the command's name.
    
    ```dart
    @command('greet')
    class Greet {
    ```
    
 2. Add actions for your command

    You can override the `execute` method to provide actions for your command. This method comes with a list of arguments.
    
    ```dart
      @override
      void execute(List<String> args) {
        var name = args.isEmpty ? 'world' : args[0];
        print('Hello, ${name}!');
      }
    }
    ```
    
 3. Run your application
    
    The last step is to make Haru take over the application for you. Add a `main` function to your code which looks like:
    
    ```dart
    void main(List<String> args) {
      Haru.start(args);
    }
    ```
    
    Now you are ready to test it. Assume the file is named `hello.dart`.
    
    ```
    $ dart hello.dart greet
    Hello, world!
    $ dart hello.dart Natsu
    Hello, Natsu!
    ```
    
    Congratulations! You've written a command-line application!

## Adding a `help` to your application

Time to add some help info to your application. In Haru, every commands comes with a piece of help message, returned by the `help` method. Let's add some help info to our `greet` command.

```dart
@command('greet')
class Greeter extends Command {
  ...
  @override
  String help() {
    return '''Usage: greet [name]

Say hello to the name. If no name is provided, it will say hello to the world!''';
  }
}
```

So how to display the help message? You may want to manually create another class derived from `Command` to add a `help` command. However, Haru provided a simpler way to do the trick, which is to make your help command extending `HelpCommand`.

```dart
@command('help')
class Helper extends HelpCommand {
}
```

And now you can have a try:

```
$ dart hello.dart help greet
Usage: greet [name]

Say hello to the name. If no name is provided, it will say hello to the world!
```

It works! You may also want to display help info for the entire application. Simply override the `help` method for your `Helper` class to make it happen.

```dart
@command('help')
class Helper extends HelpCommand {
    @override
  String help() {
    return '''Usage: hello <command>

Commands:
  greet [name]    Say hello to the names. If no name is provided, it will say
                  hello to the world!

Additional commands:
  help            Show this help message.
  help <command>  View help information on a specific command.''';
  }
}
```

And it looks like:

```
$ dart hello.dart help
Usage: hello <command>

Commands:
  greet [name]    Say hello to the names. If no name is provided, it will say
                  hello to the world!

Additional commands:
  help            Show this help message.
  help <command>  View help information on a specific command.
```

Also:

```
$ dart hello.dart help greet foo
Error: too many arguments.
```

That's how the default `HelpCommand` work. When provided with a valid command name, it prints out the help info of the command. And when no command name is provided, it displays the help message of the application. But if there are more than one arguments, it will report an error.

If you need to customize how the `help` command works, feel free to reimplement the `execute` method.

Note that though `help` is a common name, you may also use whatever name you like for the helper job. It's just a simple command.

## Adding a custom error handler

You may have noticed something like:

```
$ dart hello.dart foo
Error: cannot find command "foo".
Use command "help" for usages.
$ dart hello.dart help foo
Error: cannot find command "foo".
Use command "help" for usages.
```

If encountering a non-existent command, Haru will use a default error handler command which will print out the messages above. If you want to customize the error handler, you can derive a class from `ErrorCommand` and override the `help` method. Remember to add an `@error` annotation to it.

```dart
@error
class ErrorHandler extends ErrorCommand {
  ErrorHandler(String commandName) : super(commandName);

  @override
  String help() {
    return 'Oops! Command ${commandName} does not exist.';
  }
}
```

Now you will get:

```
$ dart hello.dart foo
Oops! Command foo does not exist.
$ dart hello.dart help foo
Oops! Command foo does not exist.
```

## Setting an entry command

If you want to set an entry command (the default command if no command name is provided), you can add `@entry` to the command class you would like to use.

```dart
@entry
@command('help')
class Helper extends HelpCommand {
  ...
```

Now it will work like:

```
$ dart hello.dart
Usage: hello <command>

Commands:
  ...
```

## Adding aliases for commands

You can add as many names to a command as you like, in order to add aliases or abbreviations for a command.

```dart
@command('help')
@command('h')
class Helper extends HelpCommand {
  ...
```

Now commands `help` and `h` will do the same job.

## More examples

You can find a complete example of a command-line application in `example/example.dart`.

## License

MIT
