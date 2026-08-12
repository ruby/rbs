use std::cell::OnceCell;
use std::ops::Range;
use std::path::{Path, PathBuf};

/// A signature file's content with byte position <-> line/column conversion,
/// mirroring `RBS::Buffer`.
///
/// Positions and columns are byte offsets, unlike Ruby's character offsets;
/// they agree on ASCII-only content. Use the parser's `RBSLocationRange` when
/// character offsets are needed.
#[derive(Debug, Clone)]
pub struct Buffer {
    name: PathBuf,
    content: String,
    line_ranges: OnceCell<Vec<Range<usize>>>,
}

impl Buffer {
    pub fn new(name: PathBuf, content: String) -> Self {
        Self {
            name,
            content,
            line_ranges: OnceCell::new(),
        }
    }

    pub fn name(&self) -> &Path {
        &self.name
    }

    pub fn content(&self) -> &str {
        &self.content
    }

    fn line_ranges(&self) -> &[Range<usize>] {
        self.line_ranges
            .get_or_init(|| compute_line_ranges(&self.content))
    }

    pub fn line_count(&self) -> usize {
        self.line_ranges().len()
    }

    /// Returns the 1-origin `line` without its line terminator.
    pub fn line(&self, line: usize) -> Option<&str> {
        let range = self.line_ranges().get(line.checked_sub(1)?)?;
        Some(&self.content[range.clone()])
    }

    /// A position past the end of the content maps to `(line_count + 1, 0)`,
    /// same as the Ruby implementation.
    pub fn pos_to_loc(&self, pos: usize) -> (usize, usize) {
        let ranges = self.line_ranges();
        let index = ranges.partition_point(|range| range.end < pos);
        match ranges.get(index) {
            Some(range) => (index + 1, pos.saturating_sub(range.start)),
            None => (ranges.len() + 1, 0),
        }
    }

    pub fn loc_to_pos(&self, line: usize, column: usize) -> usize {
        let ranges = self.line_ranges();
        let range = match line.checked_sub(1) {
            None => ranges.last(),
            Some(index) => ranges.get(index),
        };
        match range {
            Some(range) => range.start + column,
            None => self.last_position(),
        }
    }

    pub fn last_position(&self) -> usize {
        self.line_ranges().last().map_or(0, |range| range.end)
    }
}

fn compute_line_ranges(content: &str) -> Vec<Range<usize>> {
    let mut ranges = Vec::new();
    let mut offset = 0;

    for line in content.split_inclusive('\n') {
        let without_terminator = match line.strip_suffix('\n') {
            Some(l) => l.strip_suffix('\r').unwrap_or(l),
            None => line.strip_suffix('\r').unwrap_or(line),
        };
        ranges.push(offset..offset + without_terminator.len());
        offset += line.len();
    }

    if content.is_empty() || content.ends_with('\n') {
        ranges.push(offset..offset);
    }

    ranges
}

#[cfg(test)]
mod tests {
    use super::*;

    fn buffer(content: &str) -> Buffer {
        Buffer::new(PathBuf::from("a.rbs"), content.to_string())
    }

    #[test]
    fn lines_of_content_with_trailing_newline() {
        let buffer = buffer("123\nabc\n");
        assert_eq!(buffer.line_count(), 3);
        assert_eq!(buffer.line(1), Some("123"));
        assert_eq!(buffer.line(2), Some("abc"));
        assert_eq!(buffer.line(3), Some(""));
        assert_eq!(buffer.line(4), None);
        assert_eq!(buffer.line(0), None);
    }

    #[test]
    fn lines_of_content_without_trailing_newline() {
        let buffer = buffer("123\nabc");
        assert_eq!(buffer.line_count(), 2);
        assert_eq!(buffer.line(2), Some("abc"));
        assert_eq!(buffer.last_position(), 7);
    }

    #[test]
    fn empty_content_has_one_empty_line() {
        let buffer = buffer("");
        assert_eq!(buffer.line_count(), 1);
        assert_eq!(buffer.line(1), Some(""));
        assert_eq!(buffer.last_position(), 0);
        assert_eq!(buffer.pos_to_loc(0), (1, 0));
    }

    #[test]
    fn crlf_is_excluded_from_line_ranges() {
        let buffer = buffer("abc\r\ndef\r\n");
        assert_eq!(buffer.line(1), Some("abc"));
        assert_eq!(buffer.line(2), Some("def"));
        assert_eq!(buffer.pos_to_loc(5), (2, 0));
    }

    #[test]
    fn pos_to_loc_matches_ruby_buffer_for_ascii() {
        let buffer = buffer("123\nabc\n");
        assert_eq!(buffer.pos_to_loc(0), (1, 0));
        assert_eq!(buffer.pos_to_loc(3), (1, 3));
        assert_eq!(buffer.pos_to_loc(4), (2, 0));
        assert_eq!(buffer.pos_to_loc(7), (2, 3));
        assert_eq!(buffer.pos_to_loc(8), (3, 0));
        assert_eq!(buffer.pos_to_loc(9), (4, 0));
    }

    #[test]
    fn loc_to_pos_matches_ruby_buffer_for_ascii() {
        let buffer = buffer("123\nabc\n");
        assert_eq!(buffer.loc_to_pos(1, 0), 0);
        assert_eq!(buffer.loc_to_pos(2, 3), 7);
        assert_eq!(buffer.loc_to_pos(3, 0), 8);
        assert_eq!(buffer.loc_to_pos(10, 5), 8);
        assert_eq!(buffer.last_position(), 8);
    }

    #[test]
    fn trailing_carriage_return_without_newline_is_chomped() {
        let buffer = buffer("abc\ndef\r");
        assert_eq!(buffer.line(2), Some("def"));
        assert_eq!(buffer.last_position(), 7);
    }

    #[test]
    fn line_zero_maps_to_the_last_line() {
        let buffer = buffer("123\nabc");
        assert_eq!(buffer.loc_to_pos(0, 2), 6);
    }

    #[test]
    fn the_line_table_is_built_only_on_demand() {
        let buffer = buffer("123\nabc\n");
        assert!(buffer.line_ranges.get().is_none());

        buffer.pos_to_loc(4);
        assert!(buffer.line_ranges.get().is_some());
    }
}
