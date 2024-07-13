# Done

## unified parsing

### Precedence awareness

Parsing a binary int, string, fd : no precedence concern?

- `-lt`
    - int: 5
    - int: 6

Impelementation : linear

Parsing a binary expression : precedence (can be nested)

- `-o`
    - `-a`
        - int: 1
        - int: 1
    - `-lt`
        - int: 5
        - int: 6

Implementation : loop

### Don't specifify the union value type explciitly

What we used to do with `parseUnary` : create the expression in the operand function (which was thus sent the field)

this means that we never had to mention the expresssion union value type explicitly.

But can we do it with binary? Maybe but what field do we give them

For instance : `-lt`: values are ints. and we pass `operandInt`. What is the union field of the operand expressions? `int`

## p.Int i64 &rarr; c_int

for compat

## helper function for valid index

instead of `x < slice.len` do `indexes(x, slice)`

## error handling

how to return the faulty integer

Diagnostic pattern (see zig-clap)

## Parsing result model

Parsing results:

result|description|return value
-|-|-
success|parsing successful|a parse result
missing|parsing failed, but not critically: subsequent parsing may succeed|`null`
syntax error|parsing failed critically: a syntax error was encountered|syntax error
out of memory|a memory allocation failed|out of memory error

Missing happens when another parser down the line will probably find the input valid: try to parse the `-r` option but it's not there. It often happens on failure of the first operation.

Syntax errors are caused when we got so far in the parsing, but found something that disagrees with what we got so far.

Example: try to parse the `-eq` option, but the first operand did not parse as an integer. We know we expect an integer since we found `-eq`: no subsequent parsing should find this valid: this is a syntax error.

`-eq`:

- Parse left operand: *left*
- If next arg doesn't exist or it's not `-eq`
    - return null
- now, we know we have an `-eq` operation.
- unwrap *left* and return `error.InvalidInt` if missing
- parse right operand: *right*
- unwrap *right* and return `error.InvalidInt` if missing

See how misssing-ness turns into syntax errors when we know more about what we're trying to parse?

Does this work?

## Unit tests

Replicate the perl logic in zig.

- Test transformations from the base suite
