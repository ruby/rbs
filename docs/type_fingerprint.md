# Type Fingerprint of RBS Inline AST

Type fingerprint of RBS Inline AST is an object that can be used to detect if the RBS Inline AST is updated and the type checker should type check the whole codebase again.

1. If the AST update is related to the type information, the fingerprint is changed -- adding new type, including new module, changing method type, etc. The type checker should type check the codebase with updated type information.
2. If the AST updated is not related to the type information, the fingerprint keeps the last value -- changing the method implementation, adding a method call in the top level, adding white spaces and new lines, etc. The type checker can skip updating the type information, and type checking only the implementation of the file is sufficient.
3. Documentation comments are considered type related information for now.

## Type Fingerprint Calculation

The type fingerprint is calculated by converting AST nodes to standardized data structures that represent only the type-relevant information. Each AST class implements a `type_fingerprint` method that returns mainly arrays and strings.

We expect not using the values for something other than change detection. Compare old and new fingerprints, and we can detect the change between the RBS inline AST if the fingerprints are different.

The fingerprint methods are implemented across:

- `AST::Ruby::Annotations::*#type_fingerprint` - Returns `untyped` (arrays, strings, or nil)
- `AST::Ruby::Members::*#type_fingerprint` - Returns `untyped` (typically arrays)
- `AST::Ruby::Declarations::*#type_fingerprint` - Returns `untyped` (typically arrays)
- `InlineParser::Result#type_fingerprint` - Returns `untyped` (array of declaration fingerprints)

