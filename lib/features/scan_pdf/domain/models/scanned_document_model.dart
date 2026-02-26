class ScannedDocumentModel {
  final String filePath;
  final int pageCount;
  final DateTime createdAt;

  ScannedDocumentModel({
    required this.filePath,
    required this.pageCount,
    required this.createdAt,
  });
}