// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'package:haru/haru.dart';

@app('example')
class ExampleApp extends App {
  @Flag(abbr: 'l')
  bool loud;

  @command('hello')
  void hello(@flag bool withExclamation) {
    _printMessage('Hello${withExclamation ? '!' : ''}');
  }

  @command('bye')
  void bye() {
    _printMessage('Goodbye');
  }

  void _printMessage(String message) {
    if (loud) {
      message = message.toUpperCase();
    }
    print(message);
  }
}

void main(List<String> args) {
  new ExampleApp()
      .run(args)
      .catchError((error) => print('Error: ${error.toString()}'));
}
