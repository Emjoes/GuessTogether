import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:guesstogether/features/game/domain/game_models.dart';
import 'package:guesstogether/server/question_pack_builder.dart';
import 'package:guesstogether/server/siq_package_importer.dart';

void main() {
  test('SIQ importer converts archive into a playable legacy package', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'guesstogether_siq_test_',
    );
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    final Directory packagesDir = Directory(path.join(root.path, 'packages'));
    final Directory mediaDir = Directory(path.join(root.path, 'media'));
    final SiqPackageImporter importer = SiqPackageImporter(
      packageDirectory: packagesDir,
      mediaDirectory: mediaDir,
    );

    const String contentXml = '''
<?xml version="1.0" encoding="utf-8"?>
<package name="Demo SIQ" version="5" xmlns="https://github.com/VladimirKhil/SI/blob/master/assets/siq_5.xsd">
  <rounds>
    <round name="Round 1">
      <themes>
        <theme name="Movies">
          <questions>
            <question price="100">
              <params>
                <param name="question" type="content">
                  <item>What movie is shown?</item>
                  <item type="image" isRef="True">sample.png</item>
                </param>
              </params>
              <right>
                <answer>The Matrix</answer>
              </right>
            </question>
          </questions>
        </theme>
      </themes>
    </round>
  </rounds>
</package>
''';
    final Uint8List imageBytes = Uint8List.fromList(<int>[0, 1, 2, 3, 4, 5]);

    final Archive archive = Archive()
      ..addFile(
        ArchiveFile(
          'content.xml',
          utf8.encode(contentXml).length,
          utf8.encode(contentXml),
        ),
      )
      ..addFile(
        ArchiveFile(
          'Images/sample.png',
          imageBytes.length,
          imageBytes,
        ),
      );
    final List<int> zipBytes = ZipEncoder().encode(archive);

    final SiqPackageImportResult result = await importer.importArchive(
      originalFileName: 'demo.siq',
      bytes: Uint8List.fromList(zipBytes),
    );

    expect(result.packageName, 'Demo SIQ');
    expect(result.questionCount, 1);
    expect(result.hasMedia, isTrue);

    final File packageFile = File(
      path.join(packagesDir.path, result.packageFileName),
    );
    expect(await packageFile.exists(), isTrue);

    final Map<String, dynamic> packageJson =
        jsonDecode(await packageFile.readAsString()) as Map<String, dynamic>;
    final List<Question> questions = loadQuestionsFromPackageJson(
      packageJson,
      rounds: 1,
    );

    expect(questions, hasLength(1));
    expect(questions.single.text, 'What movie is shown?');
    expect(questions.single.answer, 'The Matrix');
    expect(questions.single.questionMedia, hasLength(1));
    expect(questions.single.questionMedia.single.type, QuestionMediaType.image);

    final Uri mediaUri = Uri.parse(
      questions.single.questionMedia.single.path,
    );
    expect(mediaUri.pathSegments, contains(result.mediaPackageId));
    final String publicFileName = Uri.decodeComponent(mediaUri.pathSegments.last);
    final File? extractedMedia = importer.resolveMediaFile(
      result.mediaPackageId,
      publicFileName,
    );
    expect(extractedMedia, isNotNull);
    expect(await extractedMedia!.readAsBytes(), imageBytes);
  });
}
