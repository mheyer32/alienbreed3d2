[Back To Overview](../README.md)

# Modification Source Format

This document describes the text format used to define the behavioural modification asset files used by the TKG engine.

## Almost Right Simplified Object Notation (ARSON)

In order to provide a convenient, human-editable and structured way of representing the game modification data, the syntax used is based on JSON, with a number of additional modifications:

- Syntax differentiates between _identifier_ names and _key_ names:
    - An _identifier_ is a structural member of some data type.
    - A _key_ is a string that is mapped to some other value in a collection.

- Identifier names may only contain letters, digits and underscore characters.
    - String enclosure quotes are optional.
    - Identifier names must be placed on their own line.

- Key names may contain any valid characters.
    - String enclosure quotes are mandatory.
    - Multiple, comma separated "key": value pairs can be placed on the same line but is discouraged.

- Supports line comments beginning with `//`.
- Permits a trailing comma after the final element of an array or tuple.
- Automatically catenates strings split into multiple segments when separated only by whitespace, allowing long text to be flowed over multiple lines.


**Example:**

```
{
    // Define Fruitbowl as a tuple of name:quantity pairs, with a trailing comma.
    FruitBowl: {
        "Oranges": 5, // Key names must be quoted and can contain any valid characters.
        "Apples": 3,
    },
    LongDescription:
        "This is a pretty long bit of text that "
        "can be broken down over multiple lines in order to make it "
        "more legible.",
}
```

## Document Conventions

Within this document, names for expected values are enclosed in angle brackets `< >`. Where the corresponding type is an integer, `#` is prepended.

## Import Support

Each document can contain a root-level `Import` node, which is used to import definitions from another file to help avoid duplication and support single-point-of-definition. The `Import` node contains a key/value list of identifier/path pairs. On parsing, the file indicated by the path is loaded and parsed. The parsed content of that file is assigned to the corresponding identifier within the `Import` node:

**Example:**

Before parsing:

`main.rson`

```
{
    Import: {
        Fruit: "common/fruit.rson",
    },
}
```

`common/fruit.rson`

```
{
    // Enumerated fruit
    "Apple": 0,
    "Banana": 1,
    "Pear": 2,
    "Orange": 3,
}
```

After parsing:

```
{
    Import: {
        Fruit: {
            "Apple": 0,
            "Banana": 1,
            "Pear": 2,
            "Orange": 3,
        },
    },
}
```

The process is applied recursively so that files which are imported may contain their own import definitions.

- An `Import` node can only appear in the root level of the document structure if it is to be processed as an import.
- A file can import some other file multiple times when the contents are assigned to different keys.
- Imports should not be self-referential or result in circular inclusion.

## Document Header

The main document file includes a `Header` node. This specifies what type of modification data to expect, an optional description, the version of the file and the version of the engine required to load it successfully.

**Structure:**

```
{
    Header: {
        Type: "<file type>",
        Description: "<optional description>",
        Version: "<#major>.<#minor>",
        Requires: "<#major>.<#minor>",
    },

}
```

At the time of writing, the following are supported for the `Type` field:

- `Game` Main game modification definitions.
- `Level` Level modification definitons.

The `Version` field components are expected to be in the range 0 - 65535.

# Defined Files

The following files are defined:

- [Game Modification File](./GameModification.md)
- [Level Modification File](./LevelModification.md)
- [LinkDefs Import File](./LinkDefsImport.md)
