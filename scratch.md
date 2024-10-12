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

- If we parse **brackets** before **equality**, we parse `( = )` as `=` and return 0 when 1 was expected
- If we parse **brackets** after **equality**, we get `( = = = )` as `( = =` and return 1 when 0 was expected

The issue is that the syntax is inherently ambiguous: brackets have a different meaing depending whether they are the operands of a string equality operation.

It seems more natural to parse bracketed expressions after everything, as a last resort. In this case, the false interpretation of `( = = = )` is caused by the partial parsing of the expression: the `( = =` leading part coincidentally parses as a valid string equality, discarding the rest of the arguments.

When we parse an expression, we need to either fail or parse the whole sub-expresssion.

**Solution**: use the same approach as in the GNU impl. Know how many arguments must be parsed at any given time

>The parser is implemented using a set of mutually recursive functions, each of which parses a different part of the syntax. The top-level function is `posixtest`, which parses the entire command line. It takes an argument nargs that specifies the number of arguments to parse.
>
>The `posixtest` function first checks the number of arguments to determine which syntax rule to apply. If there is only one argument, it calls `one_argument` to parse it. If there are two arguments, it calls `two_arguments`. If there are three arguments, it calls `three_arguments`. If there are more than three arguments, it calls `expr`, which is the most general syntax rule.
>
>The `one_argument` function simply checks whether the argument is non-empty. The `two_arguments` function checks whether the first argument is a unary operator or a string, and then calls unary_operator or `one_argument` accordingly. The `three_arguments` function checks whether the second argument is a binary operator, and if so, calls `binary_operator`. If not, it checks whether the first argument is a negation or a subexpression, and calls `two_arguments` or `expr` accordingly.
>
>The unary_operator function checks whether the operator is one of the file test operators (`-e`, `-f`, `-d`, etc.), and if so, performs the appropriate file test. If not, it checks whether the operator is the negation operator (`!`), and if so, calls two_arguments to parse the negated expression.
>
>The expr function implements the most general syntax rule, which allows for arbitrary combinations of expressions using the `-a` (and) and `-o` (or) operators. It uses the recursive descent technique to parse subexpressions and combine them using the boolean operators.
