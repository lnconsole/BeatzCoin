class WorkoutDetails {
  DateTime date;
  int satsEarned;

  WorkoutDetails(this.date, this.satsEarned);

  factory WorkoutDetails.fromJSON(Map<String, dynamic> json) {
    var satsEarned = json['sats_earned'];
    satsEarned ??= 0;
    var date = DateTime.tryParse(json['date']);
    date ??= DateTime.now();

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
}
