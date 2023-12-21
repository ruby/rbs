# Architecture of RBS

## Definition and DefinitionBuilder

`DefinitionBuilder` is a class to build `Definition` that has a list of instance methods and a list of class methods, from the ancestors of the target class or module.

For example, a built-in class `String` has the following ancestors:

* `String` (itself)
* `Comparable`
* `Object`
* `Kernel`
* `BasicObject`

And then, `DefinitionBuilder` gathers instance methods from these ancestors, gathers class methods from them, and builds them up to a `Definition`.

On the building, `DefinitionBuilder` internally uses `DefinitionBuilder::AncestorBuilder` to calculate the list of ancestors.

* `AncestorBuilder#one_singleton_ancestors` calculates nearest ancestors for the singleton methods
* `AncestorBuilder#one_singleton_ancestors` calculates nearest ancestors for the instance methods
* `AncestorBuilder#singleton_ancestors` returns all ancestors (class and modules) for the singleton methods
    * `#singleton_ancestors` internally uses `#one_singleton_ancestors` and calls it recursively
* `AncestorBuilder#instance_ancestors` returns all ancestors for the instance methods
    * `#instance_ancestors` internally uses `#one_instance_ancestors` and calls it recursively
