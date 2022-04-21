%{
    #include <limits.h>
    #include <string.h>
    void string_to_int(int *r, const char *s);
    char* strcpy_perso(const char* text);
%}
NUMBER [[:digit:]]+
ID [a-zA-Z]+[[:digit:]a-zA-Z]*
%option noyywrap
%%
{NUMBER} {string_to_int(&yylval.integer, yytext); return NUMBER;}
\\begin\{algo\} {return DEBUT;}
\\end\{algo\} {return FIN;}
\\SET {return SET;}
\\DOFORI {return FOR;}
\\OD {return FIN_BOUCLE;}
\\IF {return IF;}
\\FI {return FIN_IF;}
\\ELSE {return ELSE;}
\\DOWHILE {return WHILE;}
\\RETURN {return RETURN;}
\\NEG {return NOT;}
\\LANG {return AND;}
\\LOR {return OR;}
\\NEG {return NEQ;}
= {return EQ;}
< {return LESSER;}
> {return GREATER;}
\\LEQ {return LESSEREQ;}
\\GEQ {return GREATEREQ;}
\\TIMES {return TIMES;}
\\MOD {return MOD;}
true {return TRUE;}
false {return FALSE;}
{ID} {yylval.id = strcpy_perso(yytext); return ID}
\{
\}
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

int main(void) {
  yylex();
}
