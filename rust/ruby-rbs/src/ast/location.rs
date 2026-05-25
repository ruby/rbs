/// A byte and character range in the source buffer.
#[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
pub struct LocationRange {
    pub start_char: u32,
    pub start_byte: u32,
    pub end_char: u32,
    pub end_byte: u32,
}

impl LocationRange {
    #[must_use]
    pub fn new(start_char: u32, start_byte: u32, end_char: u32, end_byte: u32) -> Self {
        Self {
            start_char,
            start_byte,
            end_char,
            end_byte,
        }
    }
}

/// ```rbs
/// foo
/// ^^^ name
///
/// foo[bar, baz]
/// ^^^           name
///    ^^^^^^^^^^ args
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AliasLocation {
    pub range: LocationRange,
    pub name_range: LocationRange,
    pub args_range: Option<LocationRange>,
}

/// ```rbs
/// Foo
/// ^^^ name
///
/// Foo[Bar, Baz]
/// ^^^           name
///    ^^^^^^^^^^ args
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassInstanceLocation {
    pub range: LocationRange,
    pub name_range: LocationRange,
    pub args_range: Option<LocationRange>,
}

/// ```rbs
/// singleton(::Foo)
///           ^^^^^  name
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassSingletonLocation {
    pub range: LocationRange,
    pub name_range: LocationRange,
    pub args_range: Option<LocationRange>,
}

/// ```rbs
/// String name
///        ^^^^ name
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct FunctionParamLocation {
    pub range: LocationRange,
    pub name_range: Option<LocationRange>,
}

/// ```rbs
/// _Foo
/// ^^^^ name
///
/// _Foo[Bar, Baz]
/// ^^^^           name
///     ^^^^^^^^^^ args
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct InterfaceLocation {
    pub range: LocationRange,
    pub name_range: LocationRange,
    pub args_range: Option<LocationRange>,
}

/// ```rbs
/// () -> void
/// ^^^^^^^^^^     type
///
/// [A] () { () -> A } -> A
/// ^^^                      type_params
///     ^^^^^^^^^^^^^^^^^^^  type
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct MethodTypeLocation {
    pub range: LocationRange,
    pub type_range: LocationRange,
    pub type_params_range: Option<LocationRange>,
}

/// ```rbs
/// Key
/// ^^^ name
///
/// unchecked out Elem < _ToJson > bot = untyped
/// ^^^^^^^^^                                        unchecked
///           ^^^                                    variance
///               ^^^^                               name
///                    ^^^^^^^^^                     upper_bound
///                              ^^^^^               lower_bound
///                                      ^^^^^^^^    default
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct TypeParamLocation {
    pub range: LocationRange,
    pub name_range: LocationRange,
    pub variance_range: Option<LocationRange>,
    pub unchecked_range: Option<LocationRange>,
    pub upper_bound_range: Option<LocationRange>,
    pub lower_bound_range: Option<LocationRange>,
    pub default_range: Option<LocationRange>,
}
