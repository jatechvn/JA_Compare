/// One past comparison, persisted so the user can revisit it later.
class HistoryEntry {
  final String leftPath;
  final String rightPath;
  final String leftName;
  final String rightName;
  final DateTime comparedAt;
  final int added;
  final int removed;
  final int modified;
  final bool isFolder;

  const HistoryEntry({
    required this.leftPath,
    required this.rightPath,
    required this.leftName,
    required this.rightName,
    required this.comparedAt,
    required this.added,
    required this.removed,
    required this.modified,
    this.isFolder = false,
  });

  Map<String, dynamic> toJson() => {
    'leftPath': leftPath,
    'rightPath': rightPath,
    'leftName': leftName,
    'rightName': rightName,
    'comparedAt': comparedAt.toIso8601String(),
    'added': added,
    'removed': removed,
    'modified': modified,
    'isFolder': isFolder,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    leftPath: json['leftPath'] as String,
    rightPath: json['rightPath'] as String,
    leftName: json['leftName'] as String,
    rightName: json['rightName'] as String,
    comparedAt: DateTime.parse(json['comparedAt'] as String),
    added: json['added'] as int,
    removed: json['removed'] as int,
    modified: json['modified'] as int,
    isFolder: json['isFolder'] as bool? ?? false,
  );
}
