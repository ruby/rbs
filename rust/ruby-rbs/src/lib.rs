include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
use rbs_encoding_type_t::RBS_ENCODING_UTF_8;
use ruby_rbs_sys::bindings::*;
use std::sync::Once;

static INIT: Once = Once::new();

/// Parse RBS code into an AST.
///
/// ```rust
/// use ruby_rbs::parse;
/// let rbs_code = r#"type foo = "hello""#;
/// let signature = parse(rbs_code.as_bytes());
/// assert!(signature.is_ok(), "Failed to parse RBS signature");
/// ```
pub fn parse(rbs_code: &[u8]) -> Result<*mut rbs_signature_t, String> {
    unsafe {
        INIT.call_once(|| {
            rbs_constant_pool_init(RBS_GLOBAL_CONSTANT_POOL, 26);
        });

        let start_ptr = rbs_code.as_ptr() as *const i8;
        let end_ptr = start_ptr.add(rbs_code.len());

        let raw_rbs_string_value = rbs_string_new(start_ptr, end_ptr);

        let encoding_ptr = &rbs_encodings[RBS_ENCODING_UTF_8 as usize] as *const rbs_encoding_t;
        let parser = rbs_parser_new(raw_rbs_string_value, encoding_ptr, 0, rbs_code.len() as i32);

        let mut signature: *mut rbs_signature_t = std::ptr::null_mut();
        let result = rbs_parse_signature(parser, &mut signature);

        rbs_parser_free(parser);

        if result {
            Ok(signature)
        } else {
            Err(String::from("Failed to parse RBS signature"))
        }
    }
}

pub struct RBSString {
    pointer: *const rbs_string_t,
}

impl RBSString {
    pub fn new(pointer: *const rbs_string_t) -> Self {
        Self { pointer }
    }

    pub fn as_bytes(&self) -> &[u8] {
        unsafe {
            let s = *self.pointer;
            std::slice::from_raw_parts(s.start as *const u8, s.end.offset_from(s.start) as usize)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse() {
        let rbs_code = r#"type foo = "hello""#;
        let signature = parse(rbs_code.as_bytes());
        assert!(signature.is_ok(), "Failed to parse RBS signature");

        let rbs_code2 = r#"class Foo end"#;
        let signature2 = parse(rbs_code2.as_bytes());
        assert!(signature2.is_ok(), "Failed to parse RBS signature");
    }
}
