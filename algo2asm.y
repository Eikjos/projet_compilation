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
    char* name;
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
%type<int> params
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
          exit(EXIT_FAILURE);
        }
        symbol_table* s = new_symbol_table($2);
        name = s->name;
        if (s == NULL) {
          exit(EXIT_FAILURE);
        }
        s->scope = FUNCTION;
        s->nParams = $3; 
        printf("nbParams : %d - nbLocal : %d\n, nb_params, nb_local");
    }

params : 
  ID | ID ',' params {
    symbol_table* s = search_symbol_table($1);
    if (s != NULL) {
      fprintf(stderr, "la variable is defined");
      exit(EXIT_FAILURE);
    }
    s = new_symbol_table($1);
    s->scope = GLOBAL_VARIABLE
  }

lignes : 
    SET couples {
    }
    | FOR ID ID ID lignes FIN_BOUCLE lignes {

    }
    | FOR ID expr expr lignes FIN_BOUCLE lignes {

    }
    | FOR ID ID expr lignes FIN_BOUCLE lignes{

    }
    | FOR ID expr ID lignes FIN_BOUCLE lignes {

    }
    | IF expr lignes FIN_IF lignes {

    }
    | IF expr lignes ELSE lignes FIN_SI {

    }
    | WHILE expr lignes FIN_BOUCLE {

    }
    | RETURN expr {
      
    }

expr {
  NUMBER {

  }
  | TRUE {

  }
  | FALSE {

  }
  | expr '+' expr {

  }
  | expr TIMES expr {

  }
  | expr DIV expr {

  }
  | expr '-' expr {

  }
  | expr MOD expr {

  }
  | expr EQ expr {

  }
  | expr LE expr {

  }
  | expr GRE expr {

  }
  | expr LEQ expr {

  }
  | expr GEQ expr {

  }
  | NOT expr {

  }
  | expr AND expr {

  }
  | expr OR expr {

  }
}

couples: {
  ID couples expr {
    symbol_table* s;
    s = search_symbol_tablebyNameAndScope($1);
    if (s != NULL && s->scope ) {
        if (s->desc[0] != $3) {
          fprintf(stderr, "impossible de convertir\n");
          exit(EXIT_FAILURE);
        }
    } else {
      s = new_symbol_table($1);
      s->LOCAL_VARIABLE;
      if ($3 == INT_T || $3 == BOOL_T) {
        
      } else {
        fprintf(stderr, "il y a une erreur\n");
        exit(EXIT_FAILURE);
      }
    }
  }
  | ID couples ID {
    symbol_table* s;
    symbol_table* d;
    s = search_symbol_table($3);
    if (s != NULL) {
        d = search_symbol_table($1);
        if (d != NULL) {
          if (s->desc[0] != d->desc[0]) {
            fprintf(stderr, "impossible de convertir\n");
            exit(EXIT_FAILURE);
          }
        } else {
          d = new_symbol_table($1);
          d->scope = LOCAL_VARIABLE;
        }
    } else {
      fprintf(stderr, "undefined\n");
    }
  }
  | ID expr {

  }
  | ID ID {

  }
}
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