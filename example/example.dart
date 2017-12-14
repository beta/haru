// Copyright (c) Beta Kuang. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license information.

import 'package:haru/haru.dart';

class ExampleApp extends Haru {
  @command('hello')
  void hello(List<String> args) {
    print('Hello, $args.');
  }

  @command('bye')
  void bye() {
    print('Good bye');
  }
}

void main(List<String> args) {
  new ExampleApp().run(args);
}
