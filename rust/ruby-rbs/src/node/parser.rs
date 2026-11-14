use ruby_rbs_sys::bindings::*;
use std::ffi::CStr;
use std::marker::PhantomData;
use std::ops::Range;
use std::os::raw::c_char;
use std::ptr::NonNull;

/// An error from parsing a range of RBS source.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParseError {
    pub message: String,
    /// Byte range in the source: the offending token, or the requested range if it was
    /// invalid or the error has no token.
    pub range: Range<usize>,
}

impl std::fmt::Display for ParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{} at bytes {}..{}",
            self.message, self.range.start, self.range.end
        )
    }
}

impl std::error::Error for ParseError {}

/// Owns a C parser that points into borrowed source and type-variable names. Dropping it
/// frees every node the parser produced.
pub(super) struct OwnedParser<'a> {
    raw: NonNull<rbs_parser_t>,
    range: Range<usize>,
    marker: PhantomData<&'a str>,
}

impl<'a> OwnedParser<'a> {
    pub(super) fn new(
        source: &'a str,
        range: Range<usize>,
        type_variables: &[&'a str],
    ) -> Result<Self, ParseError> {
        let (start, end) = validate_range(source, &range)?;

        let bytes = &source.as_bytes()[..range.end];
        let raw = unsafe {
            let start_ptr = bytes.as_ptr().cast::<c_char>();
            let string = rbs_string_new(start_ptr, start_ptr.add(bytes.len()));
            let encoding = &rbs_encodings[rbs_encoding_type_t::RBS_ENCODING_UTF_8 as usize]
                as *const rbs_encoding_t;
            rbs_parser_new(string, encoding, start, end)
        };

        let Some(raw) = NonNull::new(raw) else {
            return Err(ParseError {
                message: format!("the lexer cannot start at byte {}", range.start),
                range,
            });
        };

        let parser = Self {
            raw,
            range,
            marker: PhantomData,
        };
        parser.declare_type_variables(type_variables)?;
        Ok(parser)
    }

    pub(super) fn raw(&self) -> NonNull<rbs_parser_t> {
        self.raw
    }

    pub(super) fn error(&self) -> Option<ParseError> {
        let error = unsafe { (*self.raw.as_ptr()).error.as_ref() }?;

        let message = if error.message.is_null() {
            String::from("failed to parse")
        } else {
            unsafe { CStr::from_ptr(error.message) }
                .to_string_lossy()
                .into_owned()
        };

        // Non-syntax errors have no meaningful token.
        let range = if error.syntax_error {
            self.token_range(error.token.range)
        } else {
            self.range.clone()
        };

        Some(ParseError { message, range })
    }

    pub(super) fn at_eof(&self) -> bool {
        unsafe { (*self.raw.as_ptr()).next_token.type_ == RBSTokenType_pEOF }
    }

    pub(super) fn expect_eof(&self) -> Result<(), ParseError> {
        let parser = self.raw.as_ptr();
        unsafe { rbs_parser_advance(parser) };

        let token = unsafe { (*parser).current_token };
        if token.type_ == RBSTokenType_pEOF {
            return Ok(());
        }
        Err(ParseError {
            message: String::from("expected a token `pEOF`"),
            range: self.token_range(token.range),
        })
    }

    fn token_range(&self, token: rbs_range_t) -> Range<usize> {
        match (
            usize::try_from(token.start.byte_pos),
            usize::try_from(token.end.byte_pos),
        ) {
            (Ok(start), Ok(end)) if start <= end => start..end,
            _ => self.range.clone(),
        }
    }

    fn declare_type_variables(&self, names: &[&'a str]) -> Result<(), ParseError> {
        let parser = self.raw.as_ptr();
        unsafe { rbs_parser_push_typevar_table(parser, true) };

        for name in names {
            // The names outlive the parser; `insert_owned` would `free()` Rust-allocated memory.
            let id = unsafe {
                rbs_constant_pool_insert_shared(
                    &raw mut (*parser).constant_pool,
                    name.as_ptr(),
                    name.len(),
                )
            };
            // 0 is `RBS_CONSTANT_ID_UNSET`: the pool failed to grow.
            if id == 0 {
                return Err(ParseError {
                    message: format!("failed to intern type variable `{name}`"),
                    range: self.range.clone(),
                });
            }

            if !unsafe { rbs_parser_insert_typevar(parser, id) } {
                return Err(self.error().unwrap_or_else(|| ParseError {
                    message: format!("failed to declare type variable `{name}`"),
                    range: self.range.clone(),
                }));
            }
        }

        Ok(())
    }
}

impl Drop for OwnedParser<'_> {
    fn drop(&mut self) {
        unsafe { rbs_parser_free(self.raw.as_ptr()) };
    }
}

/// Rejects ranges the C parser mishandles, so every parser version fails the same way.
fn validate_range(source: &str, range: &Range<usize>) -> Result<(i32, i32), ParseError> {
    let (start, end) = (range.start, range.end);

    let problem = if start > end {
        "range starts after it ends"
    } else if end > source.len() {
        "range ends past the end of the source"
    } else if !source.is_char_boundary(start) || !source.is_char_boundary(end) {
        "range does not start and end on character boundaries"
    } else if end > i32::MAX as usize {
        "range ends past the parser's `i32::MAX` position limit"
    } else if source.as_bytes()[..start].contains(&0) {
        // The lexer stops at NUL while walking to `start`; v4.1.2 then loops forever.
        "range starts after a NUL byte, which the lexer cannot skip"
    } else {
        return Ok((start as i32, end as i32));
    };

    Err(ParseError {
        message: format!("{problem}: {start}..{end}"),
        range: range.clone(),
    })
}
