import 'package:intl/intl.dart';

class WorkoutDetails {
  DateTime date;
  int satsEarned;

  WorkoutDetails(this.date, this.satsEarned);

  factory WorkoutDetails.fromJSON(Map<String, dynamic> json) {
    var satsEarned = json['sats_earned'];
    satsEarned ??= 0;
    var date = DateFormat('yyyy/MM/dd').parse(json['date']);

    return WorkoutDetails(date, satsEarned);
  }
}

class BeatzcoinEventContent {
  List<WorkoutDetails> workout;

  BeatzcoinEventContent(this.workout);

  factory BeatzcoinEventContent.fromJSON(Map<String, dynamic> json) {
    var w = json['workout'] as List<dynamic>;

    return BeatzcoinEventContent(
      w.map((e) => WorkoutDetails.fromJSON(e)).toList(),
    );
  }
}

class NostrProfile {
  String name;
  String pictureUrl;
  String lud16;

  NostrProfile(
    this.name,
    this.pictureUrl,
    this.lud16,
  );

  factory NostrProfile.empty() {
    return NostrProfile("", "", "");
  }

  Map<String, dynamic> toJSON() {
    return {
      'display_name': name,
      'picture': pictureUrl,
      'lud16': lud16,
    };
  }
}
