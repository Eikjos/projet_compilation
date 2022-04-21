%{
    #include <ctype.h>
    #include <stdlib.h>
    #include <stdio.h>
    #include <stdarg.h>
    #include <limits.h>
    #include "types.h"
    #include "stable.h"
    int yylex(void);
    void yyerror(char const *c);
    void fail_with(const char *format, ...);
    static unsigned int new_label_number();
    static void create_label(char *buf, size_t buf_size, const char *format, ...);
%}

%union{
  int integer;
  char* id;
  type stype;
}

%token<id> ID
%token<integer> NUMBER
%token SET
%token FOR WHILE
%token FIN_BOUCLE
%token IF ELSE FIN_IF
%token TRUE FALSE NOT AND OR
%token EQ NEQ LESSER GREATER LESSEREQ GREATEREQ
%token TIMES MOD

%type<stype> expr
%left OR AND
%right NOT
%left EQ NEQ LESSER GREATER LESSEREQ GREATEREQ
%left MOD
%left '+' '-'
%left TIMES '/'

%start function
%%
%%


 void fail_with(const char *format, ...) {
		va_list ap;
		va_start(ap, format);
		vfprintf(stderr, format, ap);
		va_end(ap);
		exit(EXIT_FAILURE);
    }
    static unsigned int new_label_number() {
		static unsigned int current_label_number = 0u;
		if ( current_label_number == UINT_MAX ) {
			fail_with("Error: maximum label number reached!\n");
		}
		return current_label_number++;
    }
    static void create_label(char *buf, size_t buf_size, const char *format, ...) {
        va_list ap;
        va_start(ap, format);
        if ( vsnprintf(buf, buf_size, format, ap) >= buf_size ) {
            va_end(ap);
            fail_with("Error in label generation: size of label exceeds maximum size!\n");
        }
        va_end(ap);
    }