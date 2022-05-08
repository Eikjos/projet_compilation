%{
    #include <limits.h>
    #include <string.h>
    #include <stdarg.h>
    #include "stypes.h"
    #include "algo2asm.tab.h"
    void string_to_int(int *r, const char *s);
    char* strcpy_perso(const char* text);
%}
ID [a-zA-Z]+[[:digit:]a-zA-Z]*
%s BOUCLE_FOR
%s BOUCLE_WHILE
%option stack
%option noyywrap
%%
[[:digit:]]+ {string_to_int(&yylval.integer, yytext); return NUMBER;}
\\SET {return SET;}
{ID} {yylval.id = strcpy_perso(yytext); return ID;}
\\begin\{algo\} {return DEBUT;}
\\end\{algo\} {return FIN;}
\\SET {return SET;}
\\DOFORI {yy_push_state(BOUCLE_FOR); return FOR;}
<BOUCLE_FOR>\\OD {yy_pop_state(); return FIN_BOUCLE;}
<BOUCLE_WHILE>\\OD {yy_pop_state(); return FIN_BOUCLE_WHILE;}
\\IF {return IF;}
\\FI {return FIN_IF;}
\\ELSE {return ELSE;}
\\DOWHILE {yy_push_state(BOUCLE_WHILE); return WHILE;}
\\RETURN {return RETURN;}
\\NEG {return NOT;}
\\LANG {return AND;}
\\LOR {return OR;}
\\NEG {return NEQ;}
= {return EQ;}
\< {return LE;}
\> {return GRE;}
\\LEQ {return LEQ;}
\\GEQ {return GEQ;}
\\TIMES {return TIMES;}
\\MOD {return MOD;}
\\DIV {return DIV;}
true {return TRUE;}
false {return FALSE;}
\{
\}
,
[[:blank:]]
.|\n {printf("%c", yytext[0]);}
%%

void string_to_int(int *r, const char *s) {
  char *p;
  long v;
  errno = 0;
  v = strtol(s, &p, 10);
  if ( ( *p != '\0' || ( errno == ERANGE 
                     && ( v == LONG_MIN || v == LONG_MAX ) ) ) 
       || ( v < INT_MIN || v > INT_MAX ) ) {
    fprintf(stderr, "Error converting string to int\n");
    exit(EXIT_FAILURE);
  } 
  *r = v;
}

char* strcpy_perso(const char*text) {
	char* name = malloc(sizeof(*name) * (strlen(text) + 1));
	if (name == NULL) {
		fprintf(stderr, "Error allocation\n");
		exit(EXIT_FAILURE);
	}
	strcpy(name, text);
	return name;
}

