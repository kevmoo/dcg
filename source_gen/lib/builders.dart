// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/src/utils.dart';
import 'package:stream_transform/stream_transform.dart';
import 'src/builder.dart';

const _outputExtensions = '.g.dart';
const _partFiles = '.g.part';

/// A [Builder] which combines part files generated from [SharedPartBuilder].
///
/// This will glob all files of the form `.*.g.part`.
class CombiningBuilder extends Builder {
  @override
  final Map<String, List<String>> buildExtensions = const {
    '.dart': const [_outputExtensions]
  };

  final String _header;

  /// [header] is used to specify the content at the top of each generated file.
  /// If `null`, the content of [defaultFileHeader] is used.
  /// If [header] is an empty `String` no header is added.
  CombiningBuilder({String header})
      : this._header = header ?? defaultFileHeader;

  @override
  Future build(BuildStep buildStep) async {
    var pattern = buildStep.inputId.changeExtension('.*$_partFiles').path;
    var assets = await buildStep
        .findAssets(new Glob(pattern))
        .transform(concurrentAsyncMap(buildStep.readAsString))
        .join('\n');
    if (assets.isEmpty) return;
    var partOf = nameOfPartial(await buildStep.inputLibrary, buildStep.inputId);
    var output = '';
    if (_header.isNotEmpty) output += '$_header\n\n';
    output += 'part of $partOf\n$assets';
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(_outputExtensions), output);
  }
}
