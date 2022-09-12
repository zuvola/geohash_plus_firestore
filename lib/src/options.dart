// (c) 2022 zuvola.

const defaultbits = 4;
const defaultPrecision = 11;

/// Options for generating Geohash
class GeohashOptions extends _GeohashOptionsBase {
  /// Precision
  final int precision;

  const GeohashOptions({
    this.precision = defaultPrecision,
    super.bits,
    super.alphabet,
  });
}

/// Options for covering Geohash
class GeohashCoverOptions extends _GeohashOptionsBase {
  /// Maximum precision
  final int maxPrecision;

  /// Number to determine the end of search
  final int threshold;

  const GeohashCoverOptions({
    this.maxPrecision = defaultPrecision,
    this.threshold = 5,
    super.bits,
    super.alphabet,
  });
}

class _GeohashOptionsBase {
  /// Bits per char
  final int bits;

  /// Alphabet used for encoding/decoding
  final String? alphabet;

  const _GeohashOptionsBase({
    this.bits = defaultbits,
    this.alphabet,
  });
}
