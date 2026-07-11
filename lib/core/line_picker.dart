class LinePicker {
  static String pick(List<String> lines, int seed, {required String fallback}) {
    if (lines.isEmpty) {
      return fallback;
    }
    return lines[seed % lines.length];
  }
}
