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

/// ```rbs
/// String
/// ^^^^^^  name
///
/// Array[String]
/// ^^^^^         name
///      ^^^^^^^^ args
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassSuperLocation {
    pub range: LocationRange,
    pub name_range: LocationRange,
    pub args_range: Option<LocationRange>,
}

/// ```rbs
/// class Foo end
/// ^^^^^         keyword
///       ^^^     name
///           ^^^ end
///
/// class Foo[A] < String end
/// ^^^^^                     keyword
///       ^^^                 name
///          ^^^              type_params
///              ^            lt
///                       ^^^ end
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassDeclarationLocation {
    pub range: LocationRange,
    pub keyword_range: LocationRange,
    pub name_range: LocationRange,
    pub end_range: LocationRange,
    pub type_params_range: Option<LocationRange>,
    pub lt_range: Option<LocationRange>,
}

/// ```rbs
/// _Each[String]
/// ^^^^^         name
///      ^^^^^^^^ args
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ModuleSelfLocation {
    pub range: LocationRange,
    pub name_range: LocationRange,
    pub args_range: Option<LocationRange>,
}

/// ```rbs
/// module Foo end
/// ^^^^^^         keyword
///        ^^^     name
///            ^^^ end
///
/// module Foo[A] : BasicObject end
/// ^^^^^^                          keyword
///        ^^^                      name
///           ^^^                   type_params
///               ^                 colon
///                 ^^^^^^^^^^^     self_types
///                             ^^^ end
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ModuleDeclarationLocation {
    pub range: LocationRange,
    pub keyword_range: LocationRange,
    pub name_range: LocationRange,
    pub end_range: LocationRange,
    pub type_params_range: Option<LocationRange>,
    pub colon_range: Option<LocationRange>,
    pub self_types_range: Option<LocationRange>,
}

/// ```rbs
/// interface _Foo end
/// ^^^^^^^^^          keyword
///           ^^^^     name
///                ^^^ end
///
/// interface _Bar[A, B] end
/// ^^^^^^^^^                keyword
///           ^^^^           name
///               ^^^^^^     type_params
///                      ^^^ end
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct InterfaceDeclarationLocation {
    pub range: LocationRange,
    pub keyword_range: LocationRange,
    pub name_range: LocationRange,
    pub end_range: LocationRange,
    pub type_params_range: Option<LocationRange>,
}

/// ```rbs
/// type loc[T] = Location[T, bot]
/// ^^^^                            keyword
///      ^^^                        name
///         ^^^                     type_params
///             ^                   eq
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct TypeAliasDeclarationLocation {
    pub range: LocationRange,
    pub keyword_range: LocationRange,
    pub name_range: LocationRange,
    pub eq_range: LocationRange,
    pub type_params_range: Option<LocationRange>,
}

/// ```rbs
/// VERSION: String
/// ^^^^^^^         name
///        ^        colon
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ConstantDeclarationLocation {
    pub range: LocationRange,
    pub name_range: LocationRange,
    pub colon_range: LocationRange,
}

/// ```rbs
/// $SIZE: String
/// ^^^^^         name
///      ^        colon
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct GlobalDeclarationLocation {
    pub range: LocationRange,
    pub name_range: LocationRange,
    pub colon_range: LocationRange,
}

/// ```rbs
/// module Foo = Bar
/// ^^^^^^             keyword
///        ^^^         new_name
///            ^       eq
///              ^^^   old_name
///
/// class Foo = Bar
/// ^^^^^              keyword
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AliasDeclarationLocation {
    pub range: LocationRange,
    pub keyword_range: LocationRange,
    pub new_name_range: LocationRange,
    pub eq_range: LocationRange,
    pub old_name_range: LocationRange,
}

/// ```rbs
/// def foo: () -> void
/// ^^^                    keyword
///     ^^^                name
///
/// private def self.bar: () -> void | ...
/// ^^^^^^^                                  visibility
///         ^^^                              keyword
///             ^^^^^                        kind
///                  ^^^                     name
///                                    ^^^   overloading
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct MethodDefinitionLocation {
    pub range: LocationRange,
    pub keyword_range: LocationRange,
    pub name_range: LocationRange,
    pub kind_range: Option<LocationRange>,
    pub overloading_range: Option<LocationRange>,
    pub visibility_range: Option<LocationRange>,
}

/// ```rbs
/// @foo: String
/// ^^^^            name
///     ^           colon
///
/// self.@all: Array[String]
/// ^^^^^                        kind
///      ^^^^                    name
///          ^                   colon
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct VariableMemberLocation {
    pub range: LocationRange,
    pub name_range: LocationRange,
    pub colon_range: LocationRange,
    pub kind_range: Option<LocationRange>,
}

/// ```rbs
/// include Foo
/// ^^^^^^^       keyword
///         ^^^   name
///
/// include Array[String]
/// ^^^^^^^                keyword
///         ^^^^^          name
///              ^^^^^^^^  args
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct MixinMemberLocation {
    pub range: LocationRange,
    pub keyword_range: LocationRange,
    pub name_range: LocationRange,
    pub args_range: Option<LocationRange>,
}

/// ```rbs
/// attr_reader name: String
/// ^^^^^^^^^^^                  keyword
///             ^^^^             name
///                 ^            colon
///
/// public attr_accessor self.name (@foo) : String
/// ^^^^^^                                           visibility
///        ^^^^^^^^^^^^^                             keyword
///                      ^^^^^                       kind
///                           ^^^^                   name
///                                ^^^^^^            ivar
///                                 ^^^^             ivar_name
///                                       ^          colon
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AttributeMemberLocation {
    pub range: LocationRange,
    pub keyword_range: LocationRange,
    pub name_range: LocationRange,
    pub colon_range: LocationRange,
    pub kind_range: Option<LocationRange>,
    pub ivar_range: Option<LocationRange>,
    pub ivar_name_range: Option<LocationRange>,
    pub visibility_range: Option<LocationRange>,
}

/// ```rbs
/// alias foo bar
/// ^^^^^           keyword
///       ^^^       new_name
///           ^^^   old_name
///
/// alias self.foo self.bar
/// ^^^^^                      keyword
///       ^^^^^                new_kind
///            ^^^             new_name
///                ^^^^^       old_kind
///                     ^^^    old_name
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AliasMemberLocation {
    pub range: LocationRange,
    pub keyword_range: LocationRange,
    pub new_name_range: LocationRange,
    pub old_name_range: LocationRange,
    pub new_kind_range: Option<LocationRange>,
    pub old_kind_range: Option<LocationRange>,
}
