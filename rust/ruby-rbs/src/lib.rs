include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
use ruby_rbs_sys::bindings::*;

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
