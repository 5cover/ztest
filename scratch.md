# Scratch

## Binary operators and brackets

Example with bracketed expressions and string equality:

args|result|note
-|-|-
`=`|0|non-empty string
`= = =`|0|string equality of `=` and `=`
`( = = = )`|0|idem
`( = )`|1|string equality of `(` and `)`, NOT `=` in brackets

How do we parse this?

The current issue is

- If we parse **brackets** before **equality**, we parse `( = )` as `=` &rarr; 0
- If we parse **brackets** after **equality**, we get `( = = = )` as `( = =` &rarr; 1

The issue is that the syntax is inherently ambiguous: brackets have a different meaing depending whether they are the operands of a string equality operation.

It seems more natural to parse bracketed expressions after everything, as a last resort. In this case, the false interpretation of `( = = = )` is caused by the partial parsing of the expression: the `( = =` leading part coincidentally parses as a valid string equality, discarding the rest of the arguments.

When we parse an expression, we need to either fail or parse the whole expresssion.

To implement this, return `null` from each expression parser for which the parse result length is not equal to the length of .the deepest sub-expression that we're in (aka. the one we're parsing).

To know the length of the expression we're parsing, we skim and count arguments until we hit (not including) :

- `-o`
- `-a`
- the end of the argument list

## fix parsing

validation was a mistake

it is impossible to predict bracket structure without doing the parsing itself
