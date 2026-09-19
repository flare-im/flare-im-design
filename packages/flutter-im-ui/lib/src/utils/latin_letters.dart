// Characters other than A-Z / a-z that a contact index files under a Latin
// letter: accented and full-width letters, letter-like and enclosed forms, and
// the mathematical alphanumerics people use in nicknames.
//
// Generated with Node from the Vue kit's rule (packages/vue-im-ui/src/utils/
// contactIndex.ts): a code point whose NFKD form, with combining marks removed
// and upper-cased, is exactly one of A-Z. Regenerate it rather than edit it.

/// Runs of consecutive code points: the first one and one letter per code
/// point from there.
const _runs = <(int, String)>[
  (0x00AA, 'A'),
  (0x00BA, 'O'),
  (0x00C0, 'AAAAAA'),
  (0x00C7, 'CEEEEIIII'),
  (0x00D1, 'NOOOOO'),
  (0x00D9, 'UUUUY'),
  (0x00E0, 'AAAAAA'),
  (0x00E7, 'CEEEEIIII'),
  (0x00F1, 'NOOOOO'),
  (0x00F9, 'UUUUY'),
  (0x00FF, 'YAAAAAACCCCCCCCDD'),
  (0x0112, 'EEEEEEEEEEGGGGGGGGHH'),
  (0x0128, 'IIIIIIIIII'),
  (0x0134, 'JJKK'),
  (0x0139, 'LLLLLL'),
  (0x0143, 'NNNNNN'),
  (0x014C, 'OOOOOO'),
  (0x0154, 'RRRRRRSSSSSSSSTTTT'),
  (0x0168, 'UUUUUUUUUUUUWWYYYZZZZZZS'),
  (0x01A0, 'OO'),
  (0x01AF, 'UU'),
  (0x01CD, 'AAIIOOUUUUUUUUUU'),
  (0x01DE, 'AAAA'),
  (0x01E6, 'GGKKOOOO'),
  (0x01F0, 'J'),
  (0x01F4, 'GG'),
  (0x01F8, 'NNAA'),
  (0x0200, 'AAAAEEEEIIIIOOOORRRRUUUUSSTT'),
  (0x021E, 'HH'),
  (0x0226, 'AAEEOOOOOOOOYY'),
  (0x02B0, 'H'),
  (0x02B2, 'JR'),
  (0x02B7, 'WY'),
  (0x02E1, 'LSX'),
  (0x1D2C, 'A'),
  (0x1D2E, 'B'),
  (0x1D30, 'DE'),
  (0x1D33, 'GHIJKLMN'),
  (0x1D3C, 'O'),
  (0x1D3E, 'PRTUWA'),
  (0x1D47, 'BDE'),
  (0x1D4D, 'G'),
  (0x1D4F, 'KM'),
  (0x1D52, 'O'),
  (0x1D56, 'PTU'),
  (0x1D5B, 'V'),
  (0x1D62, 'IRUV'),
  (0x1D9C, 'C'),
  (0x1DA0, 'F'),
  (0x1DBB, 'Z'),
  (
    0x1E00,
    'AABBBBBBCCDDDDDDDDDDEEEEEEEEEEFFGGHHHHHHHHHHIIIIKKKKKKLLLLLLLLMMMMMMNNNNNNNNOOOOOOOOPPPPRRRRRRRRSSSSSSSSSSTTTTTTTTUUUUUUUUUUVVVVWWWWWWWWWWXXXXYYZZZZZZHTWY',
  ),
  (0x1E9B, 'S'),
  (
    0x1EA0,
    'AAAAAAAAAAAAAAAAAAAAAAAAEEEEEEEEEEEEEEEEIIIIOOOOOOOOOOOOOOOOOOOOOOOOUUUUUUUUUUUUUUYYYYYYYY',
  ),
  (0x2071, 'I'),
  (0x207F, 'N'),
  (0x2090, 'AEOX'),
  (0x2095, 'HKLMNPST'),
  (0x2102, 'C'),
  (0x210A, 'GHHHH'),
  (0x2110, 'IILL'),
  (0x2115, 'N'),
  (0x2119, 'PQRRR'),
  (0x2124, 'Z'),
  (0x2128, 'Z'),
  (0x212A, 'KABC'),
  (0x212F, 'EEF'),
  (0x2133, 'MO'),
  (0x2139, 'I'),
  (0x2145, 'DDEIJ'),
  (0x2160, 'I'),
  (0x2164, 'V'),
  (0x2169, 'X'),
  (0x216C, 'LCDMI'),
  (0x2174, 'V'),
  (0x2179, 'X'),
  (0x217C, 'LCDM'),
  (0x24B6, 'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  (0x2C7C, 'JV'),
  (0xA7F1, 'SCFQ'),
  (0xFF21, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  (0xFF41, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  (0x107A5, 'Q'),
  (0x1CCD6, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  (
    0x1D400,
    'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFG',
  ),
  (
    0x1D456,
    'IJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZA',
  ),
  (0x1D49E, 'CD'),
  (0x1D4A2, 'G'),
  (0x1D4A5, 'JK'),
  (0x1D4A9, 'NOPQ'),
  (0x1D4AE, 'STUVWXYZABCD'),
  (0x1D4BB, 'F'),
  (0x1D4BD, 'HIJKLMN'),
  (
    0x1D4C5,
    'PQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZAB',
  ),
  (0x1D507, 'DEFG'),
  (0x1D50D, 'JKLMNOPQ'),
  (0x1D516, 'STUVWXY'),
  (0x1D51E, 'ABCDEFGHIJKLMNOPQRSTUVWXYZAB'),
  (0x1D53B, 'DEFG'),
  (0x1D540, 'IJKLM'),
  (0x1D546, 'O'),
  (0x1D54A, 'STUVWXY'),
  (
    0x1D552,
    'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZI',
  ),
  (0x1F12B, 'CR'),
  (0x1F130, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
];

/// The Latin letter ('A'..'Z') that [rune] is written with: A-Z and a-z
/// themselves, or the base letter of an accented, full-width or styled form;
/// null for anything else.
String? flareLatinLetter(int rune) {
  if (rune >= 0x41 && rune <= 0x5A) return String.fromCharCode(rune);
  if (rune >= 0x61 && rune <= 0x7A) return String.fromCharCode(rune - 0x20);
  var low = 0;
  var high = _runs.length - 1;
  while (low <= high) {
    final mid = (low + high) >> 1;
    final (start, letters) = _runs[mid];
    if (rune < start) {
      high = mid - 1;
    } else if (rune >= start + letters.length) {
      low = mid + 1;
    } else {
      return letters[rune - start];
    }
  }
  return null;
}
