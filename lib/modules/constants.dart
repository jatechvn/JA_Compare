/// Global application identity and version constants.
library;

const String appId = 'ja_compare';
const String appName = 'JA Compare';
const String appVersion = '2.0.2'; // Bump this before every release
const String appWebsite = 'https://jatechvn.github.io/';
const String appGithub = 'https://github.com/jatechvn/JA_Compare';

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
const List<String> xlsxExtensions = ['xlsx'];
const List<String> pdfExtensions = ['pdf'];

/// All extensions accepted by the file picker, flattened.
List<String> get supportedExtensions => [
  ...textLikeExtensions,
  ...docxExtensions,
  ...xlsxExtensions,
  ...pdfExtensions,
];
