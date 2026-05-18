import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

// ignore_for_file: avoid_catching_errors

import 'package:guesstogether/features/game/domain/game_models.dart';

class SiqPackageImportResult {
  const SiqPackageImportResult({
    required this.packageFileName,
    required this.packageName,
    required this.questionCount,
    required this.hasMedia,
    required this.mediaPackageId,
  });

  final String packageFileName;
  final String packageName;
  final int questionCount;
  final bool hasMedia;
  final String mediaPackageId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'packageFileName': packageFileName,
        'packageName': packageName,
        'questionCount': questionCount,
        'hasMedia': hasMedia,
        'mediaPackageId': mediaPackageId,
      };
}

class SiqPackageImporter {
  SiqPackageImporter({
    required Directory packageDirectory,
    required Directory mediaDirectory,
  })  : _packageDirectory = packageDirectory,
        _mediaDirectory = mediaDirectory;

  final Directory _packageDirectory;
  final Directory _mediaDirectory;

  Future<SiqPackageImportResult> importArchive({
    required String originalFileName,
    required Uint8List bytes,
  }) async {
    final Directory tempDirectory = await Directory.systemTemp.createTemp(
      'guesstogether_siq_import_',
    );
    try {
      final File archiveFile = File(path.join(tempDirectory.path, 'upload.siq'));
      await archiveFile.writeAsBytes(bytes, flush: true);
      return await importArchiveFile(
        originalFileName: originalFileName,
        archiveFile: archiveFile,
      );
    } finally {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    }
  }

  Future<SiqPackageImportResult> importArchiveFile({
    required String originalFileName,
    required File archiveFile,
  }) async {
    final InputFileStream inputStream = InputFileStream(archiveFile.path);
    final Archive archive = ZipDecoder().decodeStream(inputStream);
    try {
      return await _importDecodedArchive(
        originalFileName: originalFileName,
        archiveFile: archiveFile,
        archive: archive,
      );
    } finally {
      for (final ArchiveFile file in archive.files) {
        file.closeSync();
      }
      inputStream.closeSync();
    }
  }

  Future<SiqPackageImportResult> _importDecodedArchive({
    required String originalFileName,
    required File archiveFile,
    required Archive archive,
  }) async {
    final ArchiveFile contentEntry = archive.files.firstWhere(
      (ArchiveFile file) =>
          file.isFile &&
          path.basename(file.name).toLowerCase() == 'content.xml',
      orElse: () =>
          throw StateError('The SIQ archive does not contain content.xml.'),
    );
    final List<int>? contentBytes = contentEntry.readBytes();
    if (contentBytes == null) {
      throw StateError('The SIQ archive content.xml could not be read.');
    }
    final String contentXml = _decodeXmlBytes(contentBytes);
    final XmlDocument document = XmlDocument.parse(contentXml);
    final XmlElement root = document.rootElement;

    final String packageName = _normalizedText(root.getAttribute('name')) ??
        _fileStem(originalFileName);
    final String mediaPackageId = await _buildMediaPackageId(
      originalFileName: originalFileName,
      packageName: packageName,
      archiveFile: archiveFile,
    );

    await _packageDirectory.create(recursive: true);
    await _mediaDirectory.create(recursive: true);
    final Directory mediaTargetDirectory =
        Directory(path.join(_mediaDirectory.path, mediaPackageId));
    if (await mediaTargetDirectory.exists()) {
      await mediaTargetDirectory.delete(recursive: true);
    }
    await mediaTargetDirectory.create(recursive: true);

    final Set<String> referencedMediaNames =
        _collectReferencedMediaNames(root).map(_normalizeMediaKey).toSet();
    final Map<String, _ResolvedMedia> resolvedMedia = <String, _ResolvedMedia>{};
    int mediaIndex = 0;

    for (final ArchiveFile file
        in archive.files.where((ArchiveFile item) => item.isFile)) {
      final String rawBaseName = path.basename(file.name);
      final String decodedBaseName = _decodeUriComponent(rawBaseName);
      final Set<String> candidateKeys = <String>{
        _normalizeMediaKey(rawBaseName),
        _normalizeMediaKey(decodedBaseName),
      };
      if (!candidateKeys.any(referencedMediaNames.contains)) {
        continue;
      }

      final String extension = path.extension(decodedBaseName).toLowerCase();
      final QuestionMediaType? mediaType = _mediaTypeForExtension(extension);
      if (mediaType == null) {
        continue;
      }
      final String publicFileName =
          'm${(++mediaIndex).toString().padLeft(4, '0')}$extension';
      final File target =
          File(path.join(mediaTargetDirectory.path, publicFileName));
      final OutputFileStream outputStream = OutputFileStream(target.path);
      try {
        file.writeContent(outputStream);
      } finally {
        outputStream.closeSync();
      }

      final _ResolvedMedia resolved = _ResolvedMedia(
        type: mediaType,
        relativeUrlPath:
            '/api/packages/media/$mediaPackageId/${Uri.encodeComponent(publicFileName)}',
        label: decodedBaseName,
      );
      for (final String key in candidateKeys) {
        resolvedMedia[key] = resolved;
      }
    }

    int questionCount = 0;
    final List<Map<String, dynamic>> rounds = <Map<String, dynamic>>[];
    final Iterable<XmlElement> roundElements = _childElements(root, 'rounds')
        .expand((XmlElement roundsElement) =>
            _childElements(roundsElement, 'round'));

    int roundNumber = 0;
    for (final XmlElement roundElement in roundElements) {
      roundNumber += 1;
      final List<Map<String, dynamic>> themes = <Map<String, dynamic>>[];
      final Iterable<XmlElement> themeElements = _childElements(
        roundElement,
        'themes',
      ).expand(
        (XmlElement themesElement) => _childElements(themesElement, 'theme'),
      );

      int themeIndex = 0;
      for (final XmlElement themeElement in themeElements) {
        themeIndex += 1;
        final String themeName =
            _normalizedText(themeElement.getAttribute('name')) ??
                'Theme $themeIndex';
        final List<Map<String, dynamic>> questions = <Map<String, dynamic>>[];
        final Iterable<XmlElement> questionElements = _childElements(
          themeElement,
          'questions',
        ).expand(
          (XmlElement questionsElement) =>
              _childElements(questionsElement, 'question'),
        );

        int questionIndex = 0;
        for (final XmlElement questionElement in questionElements) {
          questionIndex += 1;
          final int value = int.tryParse(
                questionElement.getAttribute('price')?.trim() ?? '',
              ) ??
              0;
          final String rawType =
              (questionElement.getAttribute('type') ?? '').trim().toLowerCase();
          final String questionTypeName = switch (rawType) {
            'cat' => QuestionType.catInBag.name,
            'auction' => QuestionType.auction.name,
            _ => QuestionType.normal.name,
          };
          final _ContentBundle prompt = _contentBundleForParam(
            questionElement,
            paramName: 'question',
            mediaLookup: resolvedMedia,
          );
          final _ContentBundle answerBundle = _contentBundleForParam(
            questionElement,
            paramName: 'answer',
            mediaLookup: resolvedMedia,
          );
          final String answerText = _answerText(questionElement);
          questions.add(
            <String, dynamic>{
              'id': _questionId(
                roundNumber: roundNumber,
                themeIndex: themeIndex,
                questionIndex: questionIndex,
              ),
              'text': prompt.text,
              'answer': answerText,
              'category': themeName,
              'value': value,
              'type': questionTypeName,
              'questionMedia': prompt.media
                  .map((QuestionMedia item) => item.toJson())
                  .toList(),
              'answerMedia': answerBundle.media
                  .map((QuestionMedia item) => item.toJson())
                  .toList(),
            },
          );
          questionCount += 1;
        }

        if (questions.isNotEmpty) {
          themes.add(
            <String, dynamic>{
              'title': themeName,
              'questions': questions,
            },
          );
        }
      }

      if (themes.isNotEmpty) {
        rounds.add(
          <String, dynamic>{
            'round': roundNumber,
            'name': _normalizedText(roundElement.getAttribute('name')) ??
                'Round $roundNumber',
            'themes': themes,
          },
        );
      }
    }

    if (questionCount == 0) {
      throw StateError('The SIQ archive does not contain playable questions.');
    }

    final String slug = _slugify(packageName);
    final String packageFileName = '${slug}_$mediaPackageId.json';
    final File packageFile =
        File(path.join(_packageDirectory.path, packageFileName));
    final Map<String, dynamic> packageJson = <String, dynamic>{
      'name': packageName,
      'sourceFormat': 'siq',
      'mediaPackageId': mediaPackageId,
      'rounds': rounds,
    };
    await packageFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(packageJson),
      encoding: utf8,
      flush: true,
    );

    return SiqPackageImportResult(
      packageFileName: packageFileName,
      packageName: packageName,
      questionCount: questionCount,
      hasMedia: resolvedMedia.isNotEmpty,
      mediaPackageId: mediaPackageId,
    );
  }

  File? resolveMediaFile(String mediaPackageId, String publicFileName) {
    final String sanitizedFileName = path.basename(publicFileName.trim());
    if (sanitizedFileName.isEmpty) {
      return null;
    }
    final File file = File(
      path.join(_mediaDirectory.path, mediaPackageId, sanitizedFileName),
    );
    return file.existsSync() ? file : null;
  }

  Iterable<XmlElement> _childElements(XmlElement parent, String localName) {
    return parent.childElements.where(
      (XmlElement element) => element.name.local == localName,
    );
  }

  Set<String> _collectReferencedMediaNames(XmlElement root) {
    final Set<String> refs = <String>{};
    for (final XmlElement el in root.descendants.whereType<XmlElement>()) {
      switch (el.name.local) {
        // v4/v5 format: <item isRef="True">filename</item>
        case 'item':
          final bool isReference =
              (el.getAttribute('isRef') ?? '').trim().toLowerCase() == 'true';
          if (isReference) {
            final String? text = _normalizedText(el.innerText);
            if (text != null) {
              refs.add(text);
            }
          }
        // v3 format: <atom type="image|audio|video">@filename</atom>
        case 'atom':
          final String atomType =
              (el.getAttribute('type') ?? 'text').trim().toLowerCase();
          if (atomType == 'image' ||
              atomType == 'audio' ||
              atomType == 'video') {
            final String raw = el.innerText.trim();
            final String name = raw.startsWith('@') ? raw.substring(1) : raw;
            final String? text = _normalizedText(name);
            if (text != null) {
              refs.add(text);
            }
          }
      }
    }
    return refs;
  }

  _ContentBundle _contentBundleForParam(
    XmlElement questionElement, {
    required String paramName,
    required Map<String, _ResolvedMedia> mediaLookup,
  }) {
    // v4/v5 format: <params><param name="question|answer">
    final XmlElement param = questionElement.descendants
        .whereType<XmlElement>()
        .firstWhere(
          (XmlElement element) =>
              element.name.local == 'param' &&
              (element.getAttribute('name') ?? '').trim() == paramName,
          orElse: () => XmlElement(XmlName('missing')),
        );
    if (param.name.local != 'missing') {
      return _bundleFromItems(
        _childElements(param, 'item'),
        mediaLookup: mediaLookup,
      );
    }

    // v3 format: <scenario> for question atoms, <right><answer> for answers
    if (paramName == 'question') {
      final XmlElement? scenario = questionElement.descendants
          .whereType<XmlElement>()
          .where((XmlElement el) => el.name.local == 'scenario')
          .firstOrNull;
      if (scenario != null) {
        return _bundleFromAtoms(
          _childElements(scenario, 'atom'),
          mediaLookup: mediaLookup,
        );
      }
    }

    return const _ContentBundle(text: '', media: <QuestionMedia>[]);
  }

  _ContentBundle _bundleFromItems(
    Iterable<XmlElement> items, {
    required Map<String, _ResolvedMedia> mediaLookup,
  }) {
    final List<String> textParts = <String>[];
    final List<QuestionMedia> media = <QuestionMedia>[];
    for (final XmlElement item in items) {
      final String itemType =
          (item.getAttribute('type') ?? 'text').trim().toLowerCase();
      final String? value = _normalizedText(item.innerText);
      if (value == null) {
        continue;
      }
      switch (itemType) {
        case 'image':
        case 'audio':
        case 'video':
          final _ResolvedMedia? resolved =
              mediaLookup[_normalizeMediaKey(value)];
          if (resolved == null) {
            continue;
          }
          media.add(
            QuestionMedia(
              type: resolved.type,
              path: resolved.relativeUrlPath,
              label: resolved.label,
              isBackground:
                  (item.getAttribute('placement') ?? '').trim().toLowerCase() ==
                      'background',
            ),
          );
        default:
          textParts.add(value);
      }
    }
    return _ContentBundle(
      text: textParts
          .map(_collapseWhitespace)
          .where((String value) => value.isNotEmpty)
          .join('\n\n'),
      media: List<QuestionMedia>.unmodifiable(media),
    );
  }

  _ContentBundle _bundleFromAtoms(
    Iterable<XmlElement> atoms, {
    required Map<String, _ResolvedMedia> mediaLookup,
  }) {
    final List<String> textParts = <String>[];
    final List<QuestionMedia> media = <QuestionMedia>[];
    for (final XmlElement atom in atoms) {
      final String atomType =
          (atom.getAttribute('type') ?? 'text').trim().toLowerCase();
      final String raw = atom.innerText.trim();
      if (raw.isEmpty) {
        continue;
      }
      switch (atomType) {
        case 'image':
        case 'audio':
        case 'video':
          final String name = raw.startsWith('@') ? raw.substring(1) : raw;
          final _ResolvedMedia? resolved =
              mediaLookup[_normalizeMediaKey(name)];
          if (resolved == null) {
            continue;
          }
          media.add(
            QuestionMedia(
              type: resolved.type,
              path: resolved.relativeUrlPath,
              label: resolved.label,
              isBackground: false,
            ),
          );
        default:
          final String? value = _normalizedText(raw);
          if (value != null) {
            textParts.add(value);
          }
      }
    }
    return _ContentBundle(
      text: textParts
          .map(_collapseWhitespace)
          .where((String value) => value.isNotEmpty)
          .join('\n\n'),
      media: List<QuestionMedia>.unmodifiable(media),
    );
  }

  String _answerText(XmlElement questionElement) {
    final Iterable<XmlElement> answers = questionElement.descendants
        .whereType<XmlElement>()
        .where((XmlElement element) => element.name.local == 'answer');
    final List<String> values = answers
        .map((XmlElement answer) => _collapseWhitespace(answer.innerText))
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
    return values.join(' / ');
  }

  String _questionId({
    required int roundNumber,
    required int themeIndex,
    required int questionIndex,
  }) {
    return 'siq_r${roundNumber}_t${themeIndex}_q$questionIndex';
  }

  Future<String> _buildMediaPackageId({
    required String originalFileName,
    required String packageName,
    required File archiveFile,
  }) async {
    final _DigestSink digestSink = _DigestSink();
    final ByteConversionSink input = sha256.startChunkedConversion(digestSink);
    input.add(
      utf8.encode(
        '$originalFileName|$packageName|${await archiveFile.length()}|',
      ),
    );
    await for (final List<int> chunk in archiveFile.openRead()) {
      input.add(chunk);
    }
    input.close();
    return digestSink.value.toString().substring(0, 12);
  }

  String _fileStem(String fileName) {
    final String baseName = path.basename(fileName);
    final String extension = path.extension(baseName);
    return extension.isEmpty
        ? baseName
        : baseName.substring(0, baseName.length - extension.length);
  }

  String _slugify(String value) {
    final String lower = value.toLowerCase();
    final String transliterated = lower
        .replaceAll(RegExp(r'[а-я]'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return transliterated.isEmpty ? 'siq_package' : transliterated;
  }

  String _decodeXmlBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on Object {
      // Fall back for Windows-1251 or other non-UTF-8 encodings; replace
      // unrecognised bytes with the replacement character rather than throwing.
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  String? _normalizedText(String? value) {
    final String normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _collapseWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeMediaKey(String value) {
    return _decodeUriComponent(value).trim().toLowerCase();
  }

  String _decodeUriComponent(String value) {
    try {
      return Uri.decodeComponent(value);
    } on Object {
      return value;
    }
  }

  QuestionMediaType? _mediaTypeForExtension(String extension) {
    switch (extension) {
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.webp':
      case '.bmp':
        return QuestionMediaType.image;
      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.m4a':
      case '.aac':
      case '.flac':
        return QuestionMediaType.audio;
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.webm':
      case '.mkv':
        return QuestionMediaType.video;
      default:
        return null;
    }
  }
}

class _ResolvedMedia {
  const _ResolvedMedia({
    required this.type,
    required this.relativeUrlPath,
    required this.label,
  });

  final QuestionMediaType type;
  final String relativeUrlPath;
  final String label;
}

class _DigestSink implements Sink<Digest> {
  Digest? _value;

  Digest get value {
    final Digest? digest = _value;
    if (digest == null) {
      throw StateError('Digest has not been computed.');
    }
    return digest;
  }

  @override
  void add(Digest data) {
    _value = data;
  }

  @override
  void close() {}
}

class _ContentBundle {
  const _ContentBundle({
    required this.text,
    required this.media,
  });

  final String text;
  final List<QuestionMedia> media;
}
