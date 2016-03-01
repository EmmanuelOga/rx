import 'dart:html';
import 'dart:async';

import 'package:rx/rx.dart';

main() {
  var input = querySelector('#input');
  var results = querySelector('#results');

  var keyUps = rx(input.onKeyUp)
    ..map((event) => event.target.value)
    ..filter((text) => text.length > 2)
    ..debounce(const Duration(seconds: 1))
    ..distinctUntilChanged();

  keyUps.listen((e) => print(e));
}
