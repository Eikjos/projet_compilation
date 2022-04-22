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
    int nb_params = 0;
    int nb_local = 0;
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

function : 
    BEGIN ID params lignes END {
        symbol_table* s = search_symbol_table($2);
        if (s != NULL) {
          fprintf(stderr, "la fonction est déjà définie\n");
        }
        symbol_table* s = new_symbol_table($2);
        if (s == NULL) {
          exit(EXIT_FAILURE);
        }
        s->scope = FUNCTION;
        s->nParams = nb_params;
        s->nLocalVariables = nb_local;
        printf("nbParams : %d - nbLocal : %d\n, nb_params, nb_local");
    }

params : 
  ID | ID, params {
    ++nb_params;
    symbol_table* s = search_symbol_table($1, LOCAL_VARIABLE);
    if (s != NULL) {
      fprintf(stderr, "la variable is defined");
    }
    s = new_symbol_table($1);
  }
lignes : 
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