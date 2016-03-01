import 'dart:html';
import 'dart:async';

import 'package:rx/rx.dart';

/// https://github.com/JosephMoniz/dart-throttle
class ThrottleTransformer<S, T> implements StreamTransformer<S, T> {
  final Duration _period;
  const ThrottleTransformer(this._period);

  @override
  Stream<T> bind(Stream<S> stream) {
    var controller = new StreamController();
    var subscription;

    subscription = stream.listen((S data) {
      controller.add(data);
      subscription.pause();
      new Timer(this._period, () {
        subscription.resume();
      });
    }, onError: (error) {
      controller.addError(error);
    }, onDone: () {
      controller.close();
    });
    return controller.stream;
  }
}

class DistinctUntilChangedTransformer<S, T> implements StreamTransformer<S, T> {
  @override
  Stream<T> bind(Stream<S> stream) {
    var controller = new StreamController();
    var subscription;

    S prev;
    bool hasPrev;
    subscription = stream.listen((S data) {
      if (hasPrev) {
        if (prev != data) controller.add(data);
      } else {
        controller.add(data);
        hasPrev = true;
      }
      prev = data;
    }, onError: (error) {
      controller.addError(error);
    }, onDone: () {
      controller.close();
    });

    return controller.stream;
  }
}

// https://github.com/shivanshuag/dart-throttle-debounce/
class DebounceTransformer<S, T> implements StreamTransformer<S, T> {
  final Duration _delay;
  const DebounceTransformer(this._delay);

  @override
  Stream<T> bind(Stream<S> stream) {
    var controller = new StreamController();
    bool enabled = true;
    var dataStamp = 0;
    var dataSentStamp = 0;
    var lastData;

    Timer timer = new Timer.periodic(_delay, (_){
      enabled = true;
      if (dataStamp > dataSentStamp) {
        dataSentStamp = dataStamp = 0;
        controller.add(lastData);
      }
    });

    stream.listen((data){
      dataStamp++;
      lastData = data;
      if (enabled) {
        controller.add(data);
        dataSentStamp++;
      }
      enabled = false;
    }, onDone: () {
      controller.close();
      timer.cancel();
    });

    return controller.stream;
  }
}

class Rx {
  static wrap(Stream stream) {
    new Rx(stream);
  }

  Stream stream;

  Rx(this.stream);

  map(Function mapper) {
    stream = stream.map(mapper);
  }

  filter(Function filter) {
    stream = stream.where(filter);
  }

  throttle(Duration duration) {
    stream = stream.transform(new ThrottleTransformer(duration));
  }

  debounce(Duration duration) {
    stream = stream.transform(new DebounceTransformer(duration));
  }

  distinctUntilChanged() {
    stream = stream.transform(new DistinctUntilChangedTransformer());
  }

  StreamSubscription listen(Function listener) => stream.listen(listener);
}

Rx rx(Stream stream) => new Rx(stream);

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
