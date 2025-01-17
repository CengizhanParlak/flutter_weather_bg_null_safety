import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/image_utils.dart';
import '../utils/weather_type.dart';
import 'weather_bg.dart';

//// 雨雪动画层
class WeatherRainSnowBg extends StatefulWidget {
  WeatherRainSnowBg(
      {Key? key,
      required this.weatherType,
      required this.viewWidth,
      required this.viewHeight})
      : super(key: key);
  final WeatherType weatherType;
  final double viewWidth;
  final double viewHeight;

  @override
  _WeatherRainSnowBgState createState() => _WeatherRainSnowBgState();
}

class _WeatherRainSnowBgState extends State<WeatherRainSnowBg>
    with SingleTickerProviderStateMixin {
  final List<ui.Image> _images = [];
  late AnimationController _controller;
  final List<RainSnowParams> _rainSnows = [];
  int count = 0;
  WeatherDataState? _state;

  /// 异步获取雨雪的图片资源和初始化数据
  Future<void> fetchImages() async {
    //weatherprint("开始获取雨雪图片");
    ui.Image image1 = await ImageUtils.getImage('images/rain.webp');
    ui.Image image2 = await ImageUtils.getImage('images/snow.webp');
    _images.clear();
    _images.add(image1);
    _images.add(image2);
    //weatherprint("获取雨雪图片成功： ${_images.length}");
    _state = WeatherDataState.init;
    WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// 初始化雨雪参数
  Future<void> initParams() async {
    _state = WeatherDataState.loading;
    if (widget.viewWidth != 0 && widget.viewHeight != 0 && _rainSnows.isEmpty) {
      //weatherprint(
      // "开始雨参数初始化 ${_rainSnows.length}， weatherType: ${widget.weatherType}, isRainy: ${WeatherUtil.isRainy(widget.weatherType)}")
      if (WeatherUtil.isSnowRain(widget.weatherType)) {
        if (widget.weatherType == WeatherType.lightRainy) {
          count = 70;
        } else if (widget.weatherType == WeatherType.middleRainy) {
          count = 100;
        } else if (widget.weatherType == WeatherType.heavyRainy ||
            widget.weatherType == WeatherType.thunder) {
          count = 200;
        } else if (widget.weatherType == WeatherType.lightSnow) {
          count = 30;
        } else if (widget.weatherType == WeatherType.middleSnow) {
          count = 100;
        } else if (widget.weatherType == WeatherType.heavySnow) {
          count = 200;
        }
        ui.Size? size = SizeInherited.of(context)?.size;
        final width = size?.width ?? double.infinity;
        double height = size?.height ?? double.infinity;
        double widthRatio = width / 392.0;
        double heightRatio = height / 817;
        for (int i = 0; i < count; i++) {
          RainSnowParams rainSnow = RainSnowParams(
              widget.viewWidth, widget.viewHeight, widget.weatherType);
          rainSnow.init(widthRatio, heightRatio);
          _rainSnows.add(rainSnow);
        }
        //weatherprint("初始化雨参数成功 ${_rainSnows.length}");
      }
    }
    _controller.forward();
    _state = WeatherDataState.finish;
  }

  @override
  void didUpdateWidget(WeatherRainSnowBg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherType != widget.weatherType ||
        oldWidget.viewWidth != widget.viewWidth ||
        oldWidget.viewHeight != widget.viewHeight) {
      _rainSnows.clear();
      initParams();
    }
  }

  @override
  void initState() {
    _controller =
        AnimationController(duration: const Duration(minutes: 1), vsync: this);
    CurvedAnimation(parent: _controller, curve: Curves.linear);
    _controller.addListener(() {
      setState(() {});
    });
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _controller.repeat();
      }
    });
    fetchImages();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == WeatherDataState.init) {
      initParams();
    } else if (_state == WeatherDataState.finish) {
      return CustomPaint(
        painter: RainSnowPainter(this),
      );
    }
    return Container();
  }
}

class RainSnowPainter extends CustomPainter {
  RainSnowPainter(this._state);
  ui.Paint _paint = Paint();
  final _WeatherRainSnowBgState _state;

  @override
  void paint(Canvas canvas, Size size) {
    if (WeatherUtil.isSnow(_state.widget.weatherType)) {
      drawSnow(canvas, size);
    } else if (WeatherUtil.isRainy(_state.widget.weatherType)) {
      drawRain(canvas, size);
    }
  }

  void drawRain(Canvas canvas, Size size) {
    if (_state._images.length > 1) {
      ui.Image image = _state._images[0];
      if (_state._rainSnows.isNotEmpty) {
        for (var element in _state._rainSnows) {
          move(element);
          ui.Offset offset = ui.Offset(element.x, element.y);
          canvas.save();
          canvas.scale(element.scale);
          final identity = ColorFilter.matrix(<double>[
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            element.alpha,
            0,
          ]);
          _paint.colorFilter = identity;
          canvas.drawImage(image, offset, _paint);
          canvas.restore();
        }
      }
    }
  }

  void move(RainSnowParams params) {
    params.y = params.y + params.speed;
    if (WeatherUtil.isSnow(_state.widget.weatherType)) {
      double offsetX = sin(params.y / (300 + 50 * params.alpha)) *
          (1 + 0.5 * params.alpha) *
          params.widthRatio;
      params.x += offsetX;
    }
    if (params.y > params.height / params.scale) {
      params.y = -params.height * params.scale;
      if (WeatherUtil.isRainy(_state.widget.weatherType) &&
          _state._images.isNotEmpty) {
        params.y = -_state._images[0].height.toDouble();
      }
      params.reset();
    }
  }

  void drawSnow(Canvas canvas, Size size) {
    if (_state._images.length > 1) {
      ui.Image image = _state._images[1];
      if (_state._rainSnows.isNotEmpty) {
        for (var element in _state._rainSnows) {
          move(element);
          ui.Offset offset = ui.Offset(element.x, element.y);
          canvas.save();
          canvas.scale(element.scale, element.scale);
          ui.ColorFilter identity = ColorFilter.matrix(<double>[
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            element.alpha,
            0,
          ]);
          _paint.colorFilter = identity;
          canvas.drawImage(image, offset, _paint);
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class RainSnowParams {
  RainSnowParams(this.width, this.height, this.weatherType);

  /// x 坐标
  late double x;

  /// y 坐标
  late double y;

  /// 下落速度
  late double speed;

  /// 绘制的缩放
  late double scale;

  /// 宽度
  double width;

  /// 高度
  double height;

  /// 透明度
  late double alpha;

  /// 天气类型
  WeatherType weatherType;

  late double widthRatio;
  late double heightRatio;

  void init(widthRatio, heightRatio) {
    this.widthRatio = widthRatio;
    this.heightRatio = max(heightRatio, 0.65);

    /// 雨 0.1 雪 0.5
    reset();
    y = Random().nextInt(800 ~/ scale).toDouble();
  }

  /// 当雪花移出屏幕时，需要重置参数
  void reset() {
    double ratio = 1.0;

    if (weatherType == WeatherType.lightRainy) {
      ratio = 0.5;
    } else if (weatherType == WeatherType.middleRainy) {
      ratio = 0.75;
    } else if (weatherType == WeatherType.heavyRainy ||
        weatherType == WeatherType.thunder) {
      ratio = 1;
    } else if (weatherType == WeatherType.lightSnow) {
      ratio = 0.5;
    } else if (weatherType == WeatherType.middleSnow) {
      ratio = 0.75;
    } else if (weatherType == WeatherType.heavySnow) {
      ratio = 1;
    }
    if (WeatherUtil.isRainy(weatherType)) {
      double random = 0.4 + 0.12 * Random().nextDouble() * 5;
      scale = random * 1.2;
      speed = 30 * random * ratio * heightRatio;
      alpha = random * 0.6;
      x = Random().nextInt(width * 1.2 ~/ scale).toDouble() -
          width * 0.1 ~/ scale;
    } else {
      double random = 0.4 + 0.12 * Random().nextDouble() * 5;
      scale = random * 0.8 * heightRatio;
      speed = 8 * random * ratio * heightRatio;
      alpha = random;
      x = Random().nextInt(width * 1.2 ~/ scale).toDouble() -
          width * 0.1 ~/ scale;
    }
  }
}
