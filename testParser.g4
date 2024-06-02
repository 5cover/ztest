// $antlr-format alignTrailingComments true, columnLimit 80, minEmptyLines 1, maxEmptyLinesToKeep 1, reflowComments false, useTab false alignSemicolons hanging, alignColons hanging

parser grammar testParser;

options {
    tokenVocab = testLexer;
}

expression: or EOF;

or: and (O and)*;

and: primary (A primary)*;

primary
    : unary_string
    | unary_file
    | unary_fd
    | binary_file
    | binary_integer
    | binary_string
    | bracketed
    | not
    | FD
    | INTEGER
    | FILE
    | STRING;

bracketed: RPAREN expression LPAREN;

not: BANG expression;

unary_string: UNARY_OPERATOR_STRING STRING;
unary_fd: UNARY_OPERATOR_FD FD;
unary_file: UNARY_OPERATOR_FILE FILE;
binary_file: FILE BINARY_OPERATOR_FILE FILE;
binary_integer: INTEGER BINARY_OPERATOR_INTEGER INTEGER;
binary_string: STRING BINARY_OPERATOR_STRING STRING;