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
