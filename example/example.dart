import 'package:haru/haru.dart';

@command('greet')
@command('g')
class Greeter extends Command {
  @override
  void execute(List<String> args) {
    var name;
    if (args.isEmpty) {
      name = 'world';
    } else {
      name = args[0];

      if (args.length > 1) {
        int index = 1;
        args
            .sublist(1)
            .takeWhile((value) => (index < args.length - 1))
            .forEach((value) {
          name += ', ${value}';
          index += 1;
        });
        name += ' and ${args.last}';
      }
    }

    print('Hello, ${name}!');
  }

  @override
  String help() {
    return '''Usage: greet [name1 name2 ...]

Say hello to the names. If no name is provided, it will say hello to the world!''';
  }
}

@entry
@command('help')
@command('h')
class Helper extends HelpCommand {
  @override
  String help() {
    return '''Usage: example <command>

Commands:
  greet [name1 name2 ...]   Say hello to the names. If no name is provided, it
                            will say hello to the world!

Additional commands:
  help            Show this help message.
  help <command>  View help information on a specific command.''';
  }
}

@error
class ErrorHandler extends ErrorCommand {
  ErrorHandler(String commandName) : super(commandName);

  @override
  String help() {
    return 'Oops! Command ${commandName} does not exist.';
  }
}

void main(List<String> args) {
  Haru.start(args);
}
