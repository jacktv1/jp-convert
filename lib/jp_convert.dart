library jp_convert;

import 'dart:convert';

const PROLONGED_SOUND_MARK = 0x30fc;
const KANA_SLASH_DOT = 0x30fb;
const HIRAGANA_START = 0x3041;
const HIRAGANA_END = 0x3096;
const KATAKANA_START = 0x30a1;
const KATAKANA_END = 0x30fc;
const KANJI_START = 0x4e00;
const KANJI_END = 0x9faf;
const LATIN_LOWERCASE_START = 0x61;
const LATIN_LOWERCASE_END = 0x7a;
const LATIN_UPPERCASE_START = 0x41;
const LATIN_UPPERCASE_END = 0x5a;
const MODERN_ENGLISH = [0x0000, 0x007f];
const HEPBURN_MACRON_RANGES = [
  [0x0100, 0x0101], // Ā ā
  [0x0112, 0x0113], // Ē ē
  [0x012a, 0x012b], // Ī ī
  [0x014c, 0x014d], // Ō ō
  [0x016a, 0x016b], // Ū ū
];
const ROMAJI_RANGES = [MODERN_ENGLISH, ...HEPBURN_MACRON_RANGES];

const SMART_QUOTE_RANGES = [
  [0x2018, 0x2019], // ‘ ’
  [0x201c, 0x201d], // “ ”
];

const EN_PUNCTUATION_RANGES = [
  [0x20, 0x2f],
  [0x3a, 0x3f],
  [0x5b, 0x60],
  [0x7b, 0x7e],
  ...SMART_QUOTE_RANGES,
];

const TO_KANA_METHODS_HIRAGANA = 'toHiragana';
const TO_KANA_METHODS_KATAKANA = 'toKatakana';

var USE_OBSOLETE_KANA_MAP =
    createCustomMapping(customMap: {'wi': 'ゐ', 'we': 'ゑ'});

var customMapping = null;

mergeWithDefaultOptions(options) {
  const DEFAULT_OPTIONS = {
    'useObsoleteKana': false,
    'passRomaji': false,
    'upcaseKatakana': false,
    'ignoreCase': false,
    'IMEMode': false,
    'romanization': 'hepburn',
  };

  var opts = {};
  opts.addAll(DEFAULT_OPTIONS);
  opts.addAll(options);
  return opts;
}

/**
 * Checks if input string is empty
 * @param  {String} input text input
 * @return {Boolean} true if no input
 */
bool isEmpty(input) {
  if ((input is String) != true) {
    return true;
  }
  return input.length <= 0;
}

/**
 * Returns true if char is 'ー'
 * @param  {String} char to test
 * @return {Boolean}
 */
isCharLongDash({char = ''}) {
  if (isEmpty(char)) return false;
  return char.codeUnitAt(0) == PROLONGED_SOUND_MARK;
}

/**
 * Tests if char is '・'
 * @param  {String} char
 * @return {Boolean} true if '・'
 */
isCharSlashDot({char = ''}) {
  if (isEmpty(char)) return false;
  return char.codeUnitAt(0) == KANA_SLASH_DOT;
}

/**
 * Takes a character and a unicode range. Returns true if the char is in the range.
 * @param  {String}  char  unicode character
 * @param  {Number}  start unicode start range
 * @param  {Number}  end   unicode end range
 * @return {Boolean}
 */
bool isCharInRange({char = '', start, end}) {
  if (isEmpty(char)) return false;
  var code = char.codeUnitAt(0);
  return start <= code && code <= end;
}

/**
 * Tests a character. Returns true if the character is [Hiragana](https://en.wikipedia.org/wiki/Hiragana).
 * @param  {String} char character string to test
 * @return {Boolean}
 */
bool isCharHiragana(char) {
  if (char == null) char = '';
  if (isEmpty(char)) return false;
  if (isCharLongDash(char: char)) return true;
  return isCharInRange(char: char, start: HIRAGANA_START, end: HIRAGANA_END);
}

hiraganaToKatakana({input = ''}) {
  var kata = [];
  input.split('').forEach((char) {
    // Short circuit to avoid incorrect codeshift for 'ー' and '・'
    if (isCharLongDash(char: char) || isCharSlashDot(char: char)) {
      kata.add(char);
    } else if (isCharHiragana(char)) {
      // Shift charcode.
      var code = char.codeUnitAt(0) + (KATAKANA_START - HIRAGANA_START);
      var kataChar = String.fromCharCode(code);
      kata.add(kataChar);
    } else {
      // Pass non-hiragana chars through
      kata.add(char);
    }
  });
  return kata.join('');
}

/**
 * Tests if `input` is [Kanji](https://en.wikipedia.org/wiki/Kanji) ([Japanese CJK ideographs](https://en.wikipedia.org/wiki/CJK_Unified_Ideographs))
 * @param  {String} [input=''] text
 * @return {Boolean} true if all [Kanji](https://en.wikipedia.org/wiki/Kanji)
 * @example
 * isKanji('刀')
 * // => true
 * isKanji('切腹')
 * // => true
 * isKanji('勢い')
 * // => false
 * isKanji('あAア')
 * // => false
 * isKanji('🐸')
 * // => false
 */
bool isKanji(input) {
  if (input == null) input = '';
  if (isEmpty(input)) return false;
  var chars = input.split('');
  return chars.every(isCharKanji);
}

bool isCharKanji(char) {
  return isCharInRange(char: char, start: KANJI_START, end: KANJI_END);
}

bool isHiragana(input) {
  if (input == null) input = '';
  if (isEmpty(input)) return false;
  var chars = input.split('');
  return chars.every(isCharHiragana);
}

isKatakana({input = ''}) {
  if (isEmpty(input)) return false;
  var chars = input.split('');
  return chars.every(isCharKatakana);
}

isCharKatakana(char) {
  return isCharInRange(char: char, start: KATAKANA_START, end: KATAKANA_END);
}

bool isRomaji(String input, {allowed}) {
  if (input == null) input = '';
  var augmented = allowed is RegExp;
  if (isEmpty(input)) {
    return false;
  }
  bool status = input.split('').every((char) {
    var isRoma = isCharRomaji(char: char);
    return !augmented ? isRoma : isRoma || allowed.test(char);
  });
  return status;
}

isCharRomaji({char = ''}) {
  if (isEmpty(char)) return false;
  return ROMAJI_RANGES.any((item) {
    return isCharInRange(char: char, start: item[0], end: item[1]);
  });
}

/**
 * Test if `input` contains a mix of [Romaji](https://en.wikipedia.org/wiki/Romaji) *and* [Kana](https://en.wikipedia.org/wiki/Kana), defaults to pass through [Kanji](https://en.wikipedia.org/wiki/Kanji)
 * @param  {String} input text
 * @param  {Object} [options={ passKanji: true }] optional config to pass through kanji
 * @return {Boolean} true if mixed
 * @example
 * isMixed('Abあア'))
 * // => true
 * isMixed('お腹A')) // ignores kanji by default
 * // => true
 * isMixed('お腹A', { passKanji: false }))
 * // => false
 * isMixed('ab'))
 * // => false
 * isMixed('あア'))
 * // => false
 */
isMixed({input = '', options = null}) {
  if (options == null) {
    options = {'passKanji': true};
  }
  var chars = input.split('');
  var hasKanji = false;
  if (!options['passKanji'] == false) {
    hasKanji = chars.any(isKanji);
  }
  return (chars.any(isHiragana) || chars.any(isKatakana)) &&
      chars.any(isRomaji) &&
      !hasKanji;
}

isCharEnglishPunctuation({char = ''}) {
  if (isEmpty(char)) return false;
  return EN_PUNCTUATION_RANGES.any((item) {
    return isCharInRange(char: char, start: item[0], end: item[1]);
  });
}

getRomajiToKanaTree() {
  var romajiToKanaMap = createRomajiToKanaMap();
  return romajiToKanaMap;
}

IME_MODE_MAP(map) {
  // in IME mode, we do not want to convert single ns
  var mapCopy = jsonDecode(jsonEncode(map));
  mapCopy.n.n = {'': 'ん'};
  mapCopy.n[' '] = {'': 'ん'};
  return mapCopy;
}

mergeCustomMapping(map, customMapping) {
  if (!customMapping) {
    return map;
  }
  return customMapping is Function
      ? customMapping(map)
      : createCustomMapping(customMap: customMapping)(map);
}

createRomajiToKanaMap({Map<String, dynamic> options = null}) {
  if (options == null) {
    options = {};
  }
  var map = getRomajiToKanaTree();

  map = options['IMEMode'] ? IME_MODE_MAP(map) : map;
  map = options['useObsoleteKana'] ? USE_OBSOLETE_KANA_MAP(map) : map;
  if (options['customKanaMapping']) {
    if (customMapping == null) {
      customMapping = mergeCustomMapping(map, options['customKanaMapping']);
    }
    map = customMapping;
  }

  return map;
}

isCharUpperCase(char) {
  if (char == null) char = '';
  if (isEmpty(char)) return false;
  return isCharInRange(
      char: char, start: LATIN_UPPERCASE_START, end: LATIN_UPPERCASE_END);
}

toKana({input = '', options = null, map}) {
  if (options == null) {
    options = {};
  }
  var config;
  if (!map) {
    config = mergeWithDefaultOptions(options);
    map = createRomajiToKanaMap(options: config);
  } else {
    config = options;
  }

  // throw away the substring index information and just concatenate all the kana
  return splitIntoConvertedKana(input: input, options: config, map: map)
      .forEach((kanaToken) {
    var start, end, kana;
    if (kanaToken.length > 0) {
      start = kanaToken[0];
    }

    if (kanaToken.length > 1) {
      end = kanaToken[1];
    }
    if (kanaToken.length > 2) {
      kana = kanaToken[2];
    }
    if (kana == null) {
      // haven't converted the end of the string, since we are in IME mode
      return input.slice(start);
    }
    var enforceHiragana = config['IMEMode'] == TO_KANA_METHODS_HIRAGANA;
    var enforceKatakana = config['IMEMode'] == TO_KANA_METHODS_KATAKANA ||
        input.slice(start, end).split('').every(isCharUpperCase);

    return enforceHiragana || !enforceKatakana
        ? kana
        : hiraganaToKatakana(input: kana);
  }).join('');
}

splitIntoConvertedKana({input = '', options = null, map = null}) {
  if (options == null) {
    options = {};
  }
  if (map == null) {
    map = createRomajiToKanaMap(options: options);
  }
  return applyMapping(input.toLowerCase(), map, !options['IMEMode']);
}

nextSubtree(tree, nextChar) {
  var subtree = tree[nextChar];
  if (subtree == null) {
    return null;
  }
  // if the next child node does not have a node value, set its node value to the input
  var object = {
    '': tree[''] + nextChar,
  };
  object.addAll(tree[nextChar]);
  return object;
}

newChunk(remaining, currentCursor, root, convertEnding) {
  // start parsing a new chunk
  var firstChar = remaining.charAt(0);
  var object = {'': firstChar};
  object.addAll(root[firstChar]);
  return parse(object, remaining.slice(1), currentCursor, currentCursor + 1,
      root, convertEnding);
}

parse(tree, remaining, lastCursor, currentCursor, root, convertEnding) {
  if (!remaining) {
    if (convertEnding || tree.keys.length == 1) {
      // nothing more to consume, just commit the last chunk and return it
      // so as to not have an empty element at the end of the result
      return tree['']
          ? [
              [lastCursor, currentCursor, tree['']]
            ]
          : [];
    }
    // if we don't want to convert the ending, because there are still possible continuations
    // return null as the final node value
    return [
      [lastCursor, currentCursor, null]
    ];
  }

  if (tree.keys.length == 1) {
    return [
      [lastCursor, currentCursor, tree['']]
    ].addAll(newChunk(remaining, currentCursor, root, convertEnding));
  }

  var subtree = nextSubtree(tree, remaining.charAt(0));

  if (subtree == null) {
    return [
      [lastCursor, currentCursor, tree['']]
    ].addAll(newChunk(remaining, currentCursor, root, convertEnding));
  }
  // continue current branch
  return parse(subtree, remaining.slice(1), lastCursor, currentCursor + 1, root,
      convertEnding);
}

applyMapping(string, mapping, convertEnding) {
  var root = mapping;
  return newChunk(string, 0, root, convertEnding);
}

createCustomMapping({customMap = null}) {
  if (customMap == null) {
    customMap = {};
  }
  var customTree = {};

  if (customMap is Map) {
    customMap.forEach((roma, kana) {
      var subTree = customTree;
      roma.split('').forEach((char) {
        if (subTree[char] == null) {
          subTree[char] = {};
        }
        subTree = subTree[char];
      });
      subTree[''] = kana;
    });
  }
}

toKatakana({input = '', options = null}) {
  if (options == null) options = {};
  var mergedOptions = mergeWithDefaultOptions(options);
  if (mergedOptions['passRomaji'] == true) {
    return hiraganaToKatakana(input: input);
  }

  if (isMixed(input: input) ||
      isRomaji(input) ||
      isCharEnglishPunctuation(char: input)) {
    var hiragana = toKana(input: input.toLowerCase(), options: mergedOptions);
    return hiraganaToKatakana(input: hiragana);
  }

  return hiraganaToKatakana(input: input);
}
