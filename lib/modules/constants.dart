/// Global application identity and version constants.
library;

const String appId = 'ja_compare';
const String appName = 'JA Compare';
const String appVersion = '1.0.0'; // Bump this before every release
const String appWebsite = 'https://jatechvn.github.io/';

/// File extensions recognized by each document extractor.
const List<String> textLikeExtensions = [
  'txt',
  'md',
  'csv',
  'json',
  'log',
  'xml',
  'html',
  'htm',
  'yaml',
  'yml',
  'ini',
  'dart',
];
const List<String> docxExtensions = ['docx'];
const List<String> xlsxExtensions = ['xlsx', 'xls'];
const List<String> pdfExtensions = ['pdf'];

/// All extensions accepted by the file picker, flattened.
List<String> get supportedExtensions => [
  ...textLikeExtensions,
  ...docxExtensions,
  ...xlsxExtensions,
  ...pdfExtensions,
];
