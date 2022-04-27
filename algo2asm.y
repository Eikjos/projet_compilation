%{
    #include <ctype.h>
    #include <stdlib.h>
    #include <stdio.h>
    #include <stdarg.h>
    #include <limits.h>
    #include "algo2asm.tab.h"
    #include "types.h"
    #include "stable.h"
    int yylex(void);
    void yyerror(char const *);
    #define STACK_CAPACITY 50
    static int values[STACK_CAPACITY];
    static char* ids[STACK_CAPACITY];
    int size_ids = 0;
    int size_values = 0;
    int nb_params = 0;
    void fail_with(const char *format, ...) {
      va_list ap;
      va_start(ap, format);
      vfprintf(stderr, format, ap);
      va_end(ap);
      exit(EXIT_FAILURE);
    }
  //   static unsigned int new_label_number() {
  //     static unsigned int current_label_number = 0u;
  //     if ( current_label_number == UINT_MAX ) {
  //       fail_with("Error: maximum label number reached!\n");
  //     }
	// 	  return current_label_number++;
  //   }
  // static void create_label(char *buf, size_t buf_size, const char *format, ...) {
	// 	va_list ap;
	// 	va_start(ap, format);
	// 	if ( vsnprintf(buf, buf_size, format, ap) >= buf_size ) {
	// 		va_end(ap);
	// 		fail_with("Error in label generation: size of label exceeds maximum size!\n");
	// 	}
	// 	va_end(ap);
  //}
%}
%union {
  int integer;
  char* id;
}
%token<integer>NUMBER
%token SET
%token<id>ID
%token DEBUT
%token FIN
%token FOR WHILE
%token FIN_BOUCLE
%token IF ELSE FIN_IF
%token TRUE FALSE
%token RETURN 

%type<stype> expr
%left OR AND
%right NOT
%left EQ NEQ LE GRE LEQ GEQ
%left MOD
%left '+' '-'
%left TIMES DIV

%start function
%%
function : 
function '\n' {}
| DEBUT ID params lignes FIN {
    symbol_table* s = search_symbol_table($2);
    if (s != NULL) {
      fprintf(stderr, "la fonction est déjà définie\n");
      exit(EXIT_FAILURE);
    }
    s = new_symbol_table($2);
    if (s == NULL) {
      exit(EXIT_FAILURE);
    }
    s->scope = FUNCTION;
    s->nParams = nb_params; 
}

params : 
ID {
  symbol_table* s = search_symbol_table($1);
  if (s != NULL) {
    fprintf(stderr, "la variable is defined");
    exit(EXIT_FAILURE);
  }
  s = new_symbol_table($1);
  s->scope = GLOBAL_VARIABLE;
  ++nb_params;
}
| ID params {
  symbol_table* s = search_symbol_table($1);
  if (s != NULL) {
    fprintf(stderr, "la variable is defined");
    exit(EXIT_FAILURE);
  }
  s = new_symbol_table($1);
  s->scope = GLOBAL_VARIABLE;
  ++nb_params;
}

lignes : 
lignes '\n' {

}
| lignes SET parameters valeurs {
  if (size_ids != size_values) {
    fprintf(stderr, "bizare\n");
  } else {
    for (int i = 0; i < size_ids; ++i) {
      fprintf(stdout, "%s - %d\n", ids[i], values[i]);
    }
  }
  size_ids = 0;
  size_values = 0;
}
| SET parameters valeurs {
  if (size_ids != size_values) {
    fprintf(stderr, "bizare\n");
  } else {
    for (int i = 0; i < size_ids; ++i) {
      fprintf(stdout, "%s - %d\n", ids[i], values[i]);
    }
  }
  size_ids = 0;
  size_values = 0;
}
| lignes FOR ID expr expr lignes FIN_BOUCLE lignes {

}
| lignes IF expr lignes FIN_IF lignes {

}
| lignes IF expr lignes ELSE lignes FIN_IF {

}
| lignes WHILE expr lignes FIN_BOUCLE {

}
| lignes RETURN expr {

}
| FOR ID expr expr lignes FIN_BOUCLE lignes {

}
| IF expr lignes FIN_IF lignes {

}
| IF expr lignes ELSE lignes FIN_IF {

}
| WHILE expr lignes FIN_BOUCLE {

}
| RETURN expr {

}

expr :
NUMBER {

}
| TRUE {

}
| FALSE {

}
| ID {

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

parameters :
parameters ID {
  printf("id PAS\n");
  ids[size_ids] = $2;
  ++size_ids;
}
| ID {
  printf("ID SEUL\n");
  ids[size_ids] = $1;
  ++size_ids;
}

valeurs :
valeurs NUMBER{
  printf("NUMBER PAS\n");
  values[size_values] = $2;
  ++size_values;
}
| NUMBER {
  printf("NUMBER SEUL\n");
  values[size_values] = $1;
  ++size_values;
}

%%

void yyerror(char const *s) {
  fprintf(stderr, "%s\n", s);
}

int main(void) {
  yyparse();
  return EXIT_SUCCESS;
}