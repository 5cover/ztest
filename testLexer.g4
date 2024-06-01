// $antlr-format alignTrailingComments true, columnLimit 80, minEmptyLines 1, maxEmptyLinesToKeep 1, reflowComments false, useTab false alignSemicolons hanging, alignColons hanging

lexer grammar testLexer;

UNARY_OPERATOR_STRING
    : '-n'
    | '-z';

UNARY_OPERATOR_FILE
    : '-b'
    | '-c'
    | '-d'
    | '-e'
    | '-f'
    | '-g'
    | '-G'
    | '-h'
    | '-k'
    | '-L'
    | '-N'
    | '-O'
    | '-p'
    | '-r'
    | '-s'
    | '-S'
    | '-u'
    | '-w'
    | '-x';

UNARY_OPERATOR_FD
    : '-t';

BINARY_OPERATOR_STRING: '=' | '!=';

BINARY_OPERATOR_INTEGER
    : '-eq'
    | '-ge'
    | '-gt'
    | '-le'
    | '-lt'
    | '-ne';

BINARY_OPERATOR_FILE: '-ef' | '-nt' | '-ot';

STRING: .+?;

FILE: STRING;

FD: [0-9]+;

INTEGER: '-'? [0-9]+ | '-l' STRING;

BANG: '!';

O: '-o';

A: '-a';

RPAREN: '(';

LPAREN: ')';