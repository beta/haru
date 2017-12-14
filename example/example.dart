// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'package:haru/haru.dart';

class ExampleApp extends Haru {
  @command('hello')
  @flag('loud', abbr: 'l')
  void hello(String name, {bool loud = false}) {
    var message = 'Hello, $name.';
    if (loud) {
      message = message.toUpperCase();
    }
    print(message);
  }

  @command('bye')
  void bye() {
    print('Good bye');
  }
}

void main(List<String> args) {
  new ExampleApp().run(args);
}
