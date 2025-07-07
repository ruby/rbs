#![allow(
    clippy::useless_transmute,
    clippy::missing_safety_doc,
    clippy::ptr_offset_with_cast,
    dead_code,
    non_camel_case_types,
    non_upper_case_globals,
    non_snake_case
)]
pub mod bindings {
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

#[cfg(test)]
mod tests {
    use super::bindings::*;
    use std::sync::Once;

    use rbs_encoding_type_t::RBS_ENCODING_UTF_8;

    static INIT: Once = Once::new();

    fn setup() {
        INIT.call_once(|| unsafe {
            rbs_constant_pool_init(RBS_GLOBAL_CONSTANT_POOL, 26);
        });
    }

    #[test]
    fn test_rbs_parser_bindings() {
        setup();

        let rbs_code = r#"
                class User
                  attr_reader name: String
                  def initialize: (String) -> void
                end

                module Authentication
                  def authenticate: (String, String) -> bool
                end
            "#;

        let bytes = rbs_code.as_bytes();
        let start_ptr = bytes.as_ptr() as *const i8;
        let end_ptr = unsafe { start_ptr.add(bytes.len()) } as *const i8;

        let rbs_string = unsafe { rbs_string_new(start_ptr, end_ptr) };
        let encoding_ptr =
            unsafe { &rbs_encodings[RBS_ENCODING_UTF_8 as usize] as *const rbs_encoding_t };
        let parser = unsafe { rbs_parser_new(rbs_string, encoding_ptr, 0, bytes.len() as i32) };

        let mut signature: *mut rbs_signature_t = std::ptr::null_mut();
        let result = unsafe { rbs_parse_signature(parser, &mut signature) };

        assert!(result, "Failed to parse RBS signature");
        assert!(!signature.is_null(), "Signature should not be null");

        unsafe { rbs_parser_free(parser) };
    }
}
