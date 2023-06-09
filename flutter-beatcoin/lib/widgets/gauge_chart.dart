import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

SfRadialGauge buildDistanceTrackerExample(int markerValue) {
  return SfRadialGauge(
    enableLoadingAnimation: true,
    axes: <RadialAxis>[
      RadialAxis(
        showLabels: false,
        showTicks: false,
        radiusFactor: 0.8,
        minimum: 40,
        maximum: 195,
        axisLineStyle: const AxisLineStyle(
          cornerStyle: CornerStyle.startCurve,
          thickness: 5,
        ),
        annotations: <GaugeAnnotation>[
          GaugeAnnotation(
            angle: 90,
            widget: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  markerValue.toStringAsFixed(0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                  child: Text(
                    'bpm',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
              ],
            ),
          ),
          GaugeAnnotation(
            angle: 124,
            positionFactor: 1.1,
            widget: Text(
              '40',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
          GaugeAnnotation(
            angle: 54,
            positionFactor: 1.1,
            widget: Text(
              '195',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
        pointers: <GaugePointer>[
          RangePointer(
            value: markerValue + 3,
            width: 18,
            pointerOffset: -6,
            cornerStyle: CornerStyle.bothCurve,
            color: Color(0xffef476f),
          ),
          MarkerPointer(
            value: markerValue.toDouble(),
            color: Colors.white,
            markerType: MarkerType.circle,
          ),
        ],
      ),
    ],
  );
}
