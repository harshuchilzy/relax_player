class YoutubeIDs {
  String youtubeID;
  int id = 0;

  YoutubeIDs(String youtubeID) {
    this.youtubeID = youtubeID;
    this.id = id;
  }

  YoutubeIDs.fromJson(Map json) : youtubeID = json['youtubeID'];

  Map toJson() {
    return {'youtubeID': youtubeID};
  }
}
