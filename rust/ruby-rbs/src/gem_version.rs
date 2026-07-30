use std::cmp::Ordering;
use std::fmt;

/// A version number compatible with RubyGems' `Gem::Version`.
///
/// Comparison follows `Gem::Version#<=>`: trailing zero segments are ignored
/// (`1.0 == 1.0.0`) and prerelease versions sort before their release
/// (`1.0.b1 < 1.0`). Numeric segments are kept as normalized digit strings
/// and compared by length then lexicographically, equivalent to RubyGems'
/// arbitrary-precision comparison.
#[derive(Debug, Clone)]
pub struct GemVersion {
    segments: Vec<Segment>,
    prerelease: bool,
    version: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum Segment {
    /// Decimal digits with leading zeros stripped (`"0"` for zero), matching
    /// Ruby's `"007".to_i`. Compared by length, then lexicographically.
    Number(String),
    Str(String),
}

impl Segment {
    fn is_zero(&self) -> bool {
        matches!(self, Segment::Number(digits) if digits == "0")
    }
}

impl GemVersion {
    /// Parses a version string. Returns `None` when the string is not a valid
    /// `Gem::Version` (i.e. `Gem::Version.correct?` would return false).
    pub fn parse(source: &str) -> Option<GemVersion> {
        let trimmed = source.trim();
        if !is_correct(trimmed) {
            return None;
        }

        // Same normalization as Gem::Version#initialize.
        let version = if trimmed.is_empty() {
            "0".to_string()
        } else {
            trimmed.replace('-', ".pre.")
        };

        let prerelease = version.bytes().any(|b| b.is_ascii_alphabetic());
        let segments = scan_segments(&version);

        Some(GemVersion {
            segments,
            prerelease,
            version,
        })
    }

    pub fn is_prerelease(&self) -> bool {
        self.prerelease
    }

    /// Returns the release version, dropping prerelease segments
    /// (`1.2.0.a` -> `1.2.0`), same as `Gem::Version#release`.
    pub fn release(&self) -> GemVersion {
        if !self.prerelease {
            return self.clone();
        }

        let end = self
            .segments
            .iter()
            .position(|segment| matches!(segment, Segment::Str(_)))
            .unwrap_or(self.segments.len());
        let segments: Vec<Segment> = self.segments[..end].to_vec();
        let version = segments
            .iter()
            .map(|segment| match segment {
                Segment::Number(digits) => digits.clone(),
                Segment::Str(s) => s.clone(),
            })
            .collect::<Vec<_>>()
            .join(".");

        GemVersion {
            segments,
            prerelease: false,
            version,
        }
    }

    /// Canonical segments for comparison: the numeric prefix and the part
    /// starting at the first string segment, each with trailing zeros removed
    /// (`Gem::Version#canonical_segments`).
    fn canonical_segments(&self) -> Vec<&Segment> {
        let split = self
            .segments
            .iter()
            .position(|segment| matches!(segment, Segment::Str(_)))
            .unwrap_or(self.segments.len());

        let mut result = Vec::new();
        for part in [&self.segments[..split], &self.segments[split..]] {
            let end = part
                .iter()
                .rposition(|segment| !segment.is_zero())
                .map_or(0, |index| index + 1);
            result.extend(&part[..end]);
        }
        result
    }
}

impl fmt::Display for GemVersion {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.version)
    }
}

impl PartialEq for GemVersion {
    fn eq(&self, other: &Self) -> bool {
        self.cmp(other) == Ordering::Equal
    }
}

impl Eq for GemVersion {}

impl PartialOrd for GemVersion {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for GemVersion {
    fn cmp(&self, other: &Self) -> Ordering {
        let zero = Segment::Number("0".to_string());

        let lhs = self.canonical_segments();
        let rhs = other.canonical_segments();

        for i in 0..lhs.len().max(rhs.len()) {
            let l = lhs.get(i).copied().unwrap_or(&zero);
            let r = rhs.get(i).copied().unwrap_or(&zero);

            let ordering = match (l, r) {
                // Digit strings are leading-zero free: longer means larger.
                (Segment::Number(a), Segment::Number(b)) => {
                    (a.len(), a.as_str()).cmp(&(b.len(), b.as_str()))
                }
                (Segment::Str(a), Segment::Str(b)) => a.cmp(b),
                (Segment::Str(_), Segment::Number(_)) => Ordering::Less,
                (Segment::Number(_), Segment::Str(_)) => Ordering::Greater,
            };
            if ordering != Ordering::Equal {
                return ordering;
            }
        }

        Ordering::Equal
    }
}

/// `Gem::Version.correct?`: optional `digits ('.' alnum+)* ('-' pre)?`,
/// surrounded by optional whitespace.
fn is_correct(trimmed: &str) -> bool {
    if trimmed.is_empty() {
        return true;
    }

    let (main, pre) = match trimmed.split_once('-') {
        Some((main, pre)) => (main, Some(pre)),
        None => (trimmed, None),
    };

    let mut parts = main.split('.');
    let first = parts.next().unwrap_or("");
    if first.is_empty() || !first.bytes().all(|b| b.is_ascii_digit()) {
        return false;
    }
    for part in parts {
        if part.is_empty() || !part.bytes().all(|b| b.is_ascii_alphanumeric()) {
            return false;
        }
    }

    if let Some(pre) = pre {
        for part in pre.split('.') {
            if part.is_empty() || !part.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-') {
                return false;
            }
        }
    }

    true
}

/// Splits into numeric and alphabetic runs, like `@version.scan(/[0-9]+|[a-z]+/i)`.
fn scan_segments(version: &str) -> Vec<Segment> {
    let bytes = version.as_bytes();
    let mut segments = Vec::new();
    let mut i = 0;

    while i < bytes.len() {
        if bytes[i].is_ascii_digit() {
            let start = i;
            while i < bytes.len() && bytes[i].is_ascii_digit() {
                i += 1;
            }
            let digits = version[start..i].trim_start_matches('0');
            let digits = if digits.is_empty() { "0" } else { digits };
            segments.push(Segment::Number(digits.to_string()));
        } else if bytes[i].is_ascii_alphabetic() {
            let start = i;
            while i < bytes.len() && bytes[i].is_ascii_alphabetic() {
                i += 1;
            }
            segments.push(Segment::Str(version[start..i].to_string()));
        } else {
            i += 1;
        }
    }

    segments
}

#[cfg(test)]
mod tests {
    use super::*;

    fn v(source: &str) -> GemVersion {
        GemVersion::parse(source).unwrap()
    }

    #[test]
    fn parse_rejects_malformed_versions() {
        let bad = [
            "junk",
            "1.0\n2.0",
            "1..2",
            "1.2 3.4",
            "1.2.3+build",
            "2.3422222.222.222222222.22222.ads0as.dasd0.ddd2222.2.qd3e.",
        ];
        for source in bad {
            assert!(
                GemVersion::parse(source).is_none(),
                "{source:?} should be invalid"
            );
        }

        let good = [
            "",
            "0",
            "1.0",
            "1.0.0-beta",
            "5.2.4",
            "1.0.0.a.1",
            " 1.0 ",
            "1.8.2.a10",
        ];
        for source in good {
            assert!(
                GemVersion::parse(source).is_some(),
                "{source:?} should be valid"
            );
        }
    }

    #[test]
    fn equality_ignores_trailing_zero_segments() {
        assert_eq!(v("1.0"), v("1.0.0"));
        assert_eq!(v("1.0"), v("1.0.0.0"));
        assert_eq!(v(""), v("0"));
        assert_ne!(v("1.0"), v("1.1"));
        assert_ne!(v("1.0"), v("1.0.b1"));
    }

    #[test]
    fn ordering_matches_gem_version() {
        assert!(v("1.0") < v("1.1"));
        assert!(v("1.0.b1") < v("1.0"));
        assert!(v("1.0.a.2") < v("1.0.b1"));
        assert!(v("1.0.beta.1") < v("1.0.beta.2"));
        assert!(v("1.0.beta.2") < v("1.0.rc.1"));
        assert!(v("1.9.3") < v("1.10.0"));
        assert!(v("0.9") < v("1.0.a.2"));
        assert!(v("1.0.a.2") < v("1.0.0"));
        assert_eq!(v("1.0").cmp(&v("1.0.0")), Ordering::Equal);
    }

    #[test]
    fn prerelease_detection() {
        assert!(v("1.2.0.a").is_prerelease());
        assert!(v("1.0.0-beta").is_prerelease());
        assert!(v("2.9.b").is_prerelease());
        assert!(!v("1.2.0").is_prerelease());
        assert!(!v("0").is_prerelease());
    }

    #[test]
    fn release_drops_prerelease_segments() {
        assert_eq!(v("1.2.0.a").release(), v("1.2.0"));
        assert_eq!(v("1.1.rc10").release(), v("1.1"));
        assert_eq!(v("1.0.0-beta").release(), v("1.0.0"));
        assert_eq!(v("1.9.3").release(), v("1.9.3"));
        assert!(!v("1.2.0.a").release().is_prerelease());
    }

    #[test]
    fn numeric_segments_compare_with_arbitrary_precision() {
        // Beyond u64::MAX; RubyGems compares these as bignums.
        assert!(v("18446744073709551616") > v("18446744073709551615"));
        assert!(v("1.99999999999999999999999999") < v("1.100000000000000000000000000"));
        // Leading zeros are normalized like Ruby's `"007".to_i`.
        assert_eq!(v("1.007"), v("1.7.0"));
        assert_eq!(v("1.007.a").release(), v("1.7"));
    }
}
