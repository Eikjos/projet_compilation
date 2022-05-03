%{
    #include <ctype.h>
    #include <stdlib.h>
    #include <stdio.h>
    #include <stdarg.h>
    #include <limits.h>
    #include "stable.h"
    #include "stypes.h"
    int yylex(void);
    void yyerror(char const *);
    #define STACK_CAPACITY 50
    static int values[STACK_CAPACITY];
    static char* ids[STACK_CAPACITY];
    static int stack[STACK_CAPACITY];
    int stack_size = 0;
    int size_ids = 0;
    int size_values = 0;
    int nb_params = 0;
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
      if (vsnprintf(buf, buf_size, format, ap) >= buf_size ) {
        va_end(ap);
        fail_with("Error in label generation: size of label exceeds maximum size!\n");
      }
      va_end(ap);
    }
%}

%union {
  int integer;
  stypes t;
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

%type<t> expr
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
;

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
    printf("\tpop ax\n");
    printf("\tconst bx,var:%s\n", $1);
    printf("\tstorew ax,bx\n");
  }
  | params ID {
    symbol_table* s = search_symbol_table($2);
    if (s != NULL) {
      fprintf(stderr, "la variable is defined");
      exit(EXIT_FAILURE);
    }
    s = new_symbol_table($2);
    s->scope = GLOBAL_VARIABLE;
    ++nb_params;
    printf("\tpop ax\n");
    printf("\tconst bx,var:%s\n", $2);
    printf("\tstorew ax,bx\n");
  }
;

lignes : 
  lignes '\n' 
  | lignes SET parameters valeurs {
    if (size_ids != size_values) {
      fprintf(stderr, "invalid parameter\n");
    } else {
      for (int i = 0 i < size_ids; ++i) {
        // si les expressions possèdent une erreur
        if (values[i] != INT_T && values[i] != BOOL_T) {
          fprintf(stderr, "il y a une erreur dans l'expression\n");
          exit(EXIT_FAILURE);
        }
        symbol_table *s = search_symbol_table(ids[i]);
        // le cas ou la variable existe déjà
        if (s != NULL) {
            if (s->desc[0] != values[i]) {
              fprintf(stderr, "incompatible type\n");
              exit(EXIT_FAILURE);
            } 
            printf("\tconst ax,var:%s\n", ids[i]);
            printf("\tpop bx\n")
            printf("\tstorew bx,ax\n");
        } else {
          // le cas où la variable n'existe pas
          s = new_symbol_table(ids[id]);
          s->desc[0] = values[i];
          s->scope = LOCAL_VARIABLE;
          printf("\tconst ax,var:%s\n", ids[i]);
          printf("pop bx\n");
          printf("\tstorew bx,ax\n");
        }
      }
    }
  }
  | SET parameters valeurs {
    if (size_ids != size_values) {
      fprintf(stderr, "invalid parameter\n");
    } else {
      for (int i = 0 i < size_ids; ++i) {
        // si les expressions possèdent une erreur
        if (values[i] != INT_T && values[i] != BOOL_T) {
          fprintf(stderr, "il y a une erreur dans l'expression\n");
          exit(EXIT_FAILURE);
        }
        symbol_table *s = search_symbol_table(ids[i]);
        // le cas ou la variable existe déjà
        if (s != NULL) {
            if (s->desc[0] != values[i]) {
              fprintf(stderr, "incompatible type\n");
              exit(EXIT_FAILURE);
            } 
            printf("\tconst ax,var:%s\n", ids[i]);
            printf("\tpop bx\n")
            printf("\tstorew bx,ax\n");
        } else {
          // le cas où la variable n'existe pas
          s = new_symbol_table(ids[id]);
          s->desc[0] = values[i];
          s->scope = LOCAL_VARIABLE;
          printf("\tconst ax,var:%s\n", ids[i]);
          printf("pop bx\n");
          printf("\tstorew bx,ax\n");
        }
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
    if ($3 != INT_T && $3 != BOOL_T) {
      fprintf(stderr, "il y a une erreur dans l'expression retourné\n");
      exit(EXIT_FAILURE);
    }
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
    if ($2 != INT_T && $2 != BOOL_T) {
      fprintf(stderr, "il y a une erreur dans l'expression retourné\n");
      exit(EXIT_FAILURE);
    }
  }
;
expr :
  NUMBER {
    printf("\tconst ax,%d\n", $1);
    printf("\tpush ax\n");
    $$ = INT_T; 
  }
  | TRUE {
    printf("\tconst ax,1\n");
    printf("\tpush ax\n");
    $$ = BOOL_T;
  }
  | FALSE {
    printf("\tconst ax,0\n");
    printf("\tpush ax\n");
    $$ = BOOL_T;
  }
  | ID {
    symbol_table* s= search_symbol_table($1);
    if (s == NULL) {
      fprintf(stderr, "symbol not found\n");
    } else {
      printf("\tconst ax,var:%s\n", $1);
      printf("\tloadw bx,ax\n");
      printf("\tpush bx\n");
      $$ = s->desc[0];
    }
  }
  | expr '+' expr {
    if ($1 == INT_T && $3 == INT_T) {
      printf("\tpop ax\n");
      printf("\tpop bx\n");
      printf("\tmul ax,bx\n");
      printf("\tpush ax\n");
        $$ = INT_T;
    } else {
        if ($1 == BOOL_T || $3 == BOOL_T) {
          $$ = ERR_T;
        } else if ($1 != INT_T) {
          $$ = $1;
        } else {
          $$ = $3;
        }
    }
  }
  | expr TIMES expr {
    if ($1 == INT_T && $3 == INT_T) {
      printf("\tpop ax\n");
      printf("\tpop bx\n");
      printf("\tmul ax,bx\n");
      printf("\tpush ax\n");
        $$ = INT_T;
    } else {
      if ($1 == BOOL_T || $3 == BOOL_T) {
        $$ = ERR_T;
      } else if ($1 != INT_T) {
        $$ = $1;
      } else {
        $$ = $3;
      }
    }
  }
  | expr DIV expr {
    if ($1 == INT_T && $3 == INT_T) {
      char div0[STACK_CAPACITY];
      char ndiv0[STACK_CAPACITY];
      int nb = new_label_number();
      create_label(div0, STACK_CAPACITY, "%s:%d", "div0", nb);
      create_label(ndiv0, STACK_CAPACITY, "%s:%d", "ndiv0", nb);
      printf("\tpop bx\n");
      printf("\tpop ax\n");
      printf("\tconst cx,%s\n", div0);
      printf("\tdiv ax,bx\n");
      printf("\tjmpe cx\n");
      printf("\tpush ax\n");
      printf("\tconst ax,%s\n", ndiv0);
      printf(":%s\n", div0);
      printf("\tconst ax,err0\n");
      printf("\tcallprintfs ax\n");
      printf("\tend\n");
      printf(":%s\n", ndiv0);
      $$ = INT_T;
    } else {
      if (stack[stack_size - 1] == 0) {
        $$ = ERR_0;
      }
      if ($1 == BOOL_T || $3 == BOOL_T) {
        $$ = ERR_T;
      } else if ($1 != INT_T) {
        $$ = $1;
      } else {
          $$ = $3;
      }
    }
  }
  | expr '-' expr {
    if ($1 == INT_T && $3 == INT_T) {
      printf("\tpop bx\n");
      printf("\tpop ax\n");
      printf("\tsub ax,bx\n");
      printf("\tpush ax\n");
      $$ = INT_T;
    } else {
      if ($1 == BOOL_T || $3 == BOOL_T) {
        $$ = ERR_T;
      } else if ($1 != INT_T) {
        $$ = $1;
      } else {
        $$ = $3;
      }
    }
  }
  | expr MOD expr {
    int nb = new_label_number();
    char div0[STACK_CAPACITY];
    char ndiv0[STACK_CAPACITY];
    create_label(div0, STACK_CAPACITY, "%s:%d", "div0", nb);
    create_label(ndiv0, STACK_CAPACITY, "%s:%d", "ndiv0", nb);
    if ($1 == INT_T && $2 == INT_T) {
      printf("\tpop bx\n");
      printf("\tpop ax\n");
      printf("\tconst dx,ax\n");
      printf("\tconst cx,%s\n", div0);
      printf("\tdiv ax,bx\n");
      printf("\tjmpe cx\n");
      printf("\tmul ax,bx\n");
      printf("\tsub dx,ax\n");
      printf("\tpush dx\n");
      printf("\tconst ax,%s\n", ndiv0);
      printf(":‰s\n", div0);
      printf("\tconst ax,err0\n");
      printf("\tcallprintfs ax\n");
      printf("\tend\n");
      printf(":%s\n", ndiv0);
    } else {
      if ($1 == BOOL_T || $3 == BOOL_T) {
        $$ = ERR_T;
      } else if ($1 != INT_T) {
        $$ = $1;
      } else {
        $$ = $3;
      }
    }
  }
  | expr EQ expr {
    char eq[STACK_CAPACITY];
    char feq[STACK_CAPACITY];
    int nb = new_label_number();
    create_label(eq, STACK_CAPACITY, "%s:%d", "equal", nb);
    create_label(feq, STACK_CAPACITY, "%s:%d", "fequal", nb);
    if ($1 == INT_T && $3 == INT_T) {
      printf("\tpop ax\n");
      printf("\tpop bx\n");
      printf("\tconst cx,%s\n", eq);
      printf("\tcmp ax,bx\n");
      printf("\tjmpc cx\n");
      printf("const ax,0\n");
      printf("\tpush ax\n");
      printf("\tconst ax,%s\n", feq);
      printf("\tjmp ax\n");
      printf(":%s\n", eq);
      printf("\tconst ax,1\n");
      printf("\tpush ax\n");
      printf(":%s\n", feq);
      $$ = BOOL_T;
    } else if ($1 == BOOL_T && $3 == BOOL_T) {
      printf("\tpop ax\n");
      printf("\tpop bx\n");
      printf("const cx,%s\n", eq);
      printf("\tcmp ax,bx\n");
      printf("\tjmpc cx\n");
      printf("\tconst ax,0\n");
      printf("\tpush ax\n");
      printf("\tconst ax,%s\n", feq);
      printf("\tjmp ax\n");
      printf(":%s\n", eq);
      printf("\tconst ax,1\n");
      printf("\tpush ax\n");
      printf(":%s\n", feq);
      $$ = BOOL_T;
    } else {
      if (($1 == INT_T && $3 == BOOL_T) || ($1 == BOOL_T && $3 == INT_T)) {
        $$ = ERR_T;
      } else if ($1 != INT_T && $1 != BOOL_T) {
        $$ = $1;
      } else {
        $$ = $3;
      }
    }
  }
  | expr LE expr {
    int nb = new_label_number();
    char finf[STACK_CAPACITY];
    char inf[STACK_CAPACITY];
    create_label(finf, STACK_CAPACITY, "%s:%d", "finf", nb);
    create_label(inf, STACK_CAPACITY, "%s:%d", "inf", nb);
    if ($1 == INT_T && $3 == INT_T) {
      printf("\tpop ax\n");
      printf("\tpop bx\n");
      printf("\tconst cx,%s\n", inf);
      printf("\tsless bx,ax\n");
      printf("\tjmpc cx\n");
      printf("\tconst ax,0\n");
      printf("\tpush ax\n");
      printf("\tconst ax,%s\n", finf);
      printf("\tjmp ax\n");
      printf(":%s\n", inf);
      printf("\tconst ax,1\n");
      printf("\tpush ax\n");
      printf(":%s\n", finf);
    } else {
      if (($1 == INT_T && $3 == BOOL_T) || ($1 == BOOL_T && $3 == INT_T)) {
        $$ = ERR_T;
      } else if ($1 != INT_T && $1 != BOOL_T) {
        $$ = $1;
      } else {
        $$ = $3;
      }
    }
  }
  | expr GRE expr {
    nt nb = new_label_number();
    char fgeq[STACK_CAPACITY];
    char geq[STACK_CAPACITY];
    create_label(fgeq, STACK_CAPACITY, "%s:%d", "fgeq", nb);
    create_label(geq, STACK_CAPACITY, "%s:%d", "geq", nb);
    if ($1 == INT_T && $3 == INT_T) {
      printf("\tpop ax\n");
      printf("\tpop bx\n");
      printf("\tconst cx,%s\n", geq);
      printf("\tsless ax,bx\n");
      printf("\tjmpc cx\n");
      printf("\tconst ax,0\n");
      printf("\tpush ax\n");
      printf("\tconst ax,%s\n", fgeq);
      printf("\tjmp ax\n");
      printf(":%s\n", inf);
      printf("\tconst ax,1\n");
      printf("\tpush ax\n");
      printf(":%s\n", fgeq);
    } else {
      if (($1 == INT_T && $3 == BOOL_T) || ($1 == BOOL_T && $3 == INT_T)) {
        $$ = ERR_T;
      } else if ($1 != INT_T && $1 != BOOL_T) {
        $$ = $1;
      } else {
        $$ = $3;
      }
    }
  }
  | expr LEQ expr {
    int nb = new_label_number();
    char finf[STACK_CAPACITY];
    char inf[STACK_CAPACITY];
    create_label(finf, STACK_CAPACITY, "%s:%d", "finf", nb);
    create_label(inf, STACK_CAPACITY, "%s:%d", "inf", nb);
    if ($1 == INT_T && $3 == INT_T) {
      printf("\tpop ax\n");
      printf("\tpop bx\n");
      printf("\tconst cx,%s\n", inf);
      printf("\tsless bx,ax\n");
      printf("\tjmpc cx\n");
      printf("\tcmp ax,bx\n");
      printf("\tjmpc cx\n");
      printf("\tconst ax,0\n");
      printf("\tpush ax\n");
      printf("\tconst ax,%s\n", finf);
      printf("\tjmp ax\n");
      printf(":%s\n", inf);
      printf("\tconst ax,1\n");
      printf("\tpush ax\n");
      printf(":%s\n", finf);
    } else {
      if (($1 == INT_T && $3 == BOOL_T) || ($1 == BOOL_T && $3 == INT_T)) {
        $$ = ERR_T;
      } else if ($1 != INT_T && $1 != BOOL_T) {
        $$ = $1;
      } else {
        $$ = $3;
      }
    }
  }
  | expr GEQ expr {
    int nb = new_label_number();
    char fgeq[STACK_CAPACITY];
    char geq[STACK_CAPACITY];
    create_label(fgeq, STACK_CAPACITY, "%s:%d", "fgeq", nb);
    create_label(geq, STACK_CAPACITY, "%s:%d", "geq", nb);
    if ($1 == INT_T && $3 == INT_T) {
      printf("\tpop ax\n");
      printf("\tpop bx\n");
      printf("\tconst cx,%s\n", geq);
      printf("\tsless ax,bx\n");
      printf("\tjmpc cx\n");
      printf("\tcmp ax,bx\n");
      printf("\tjmpc cx\n");
      printf("\tconst ax,0\n");
      printf("\tpush ax\n");
      printf("\tconst ax,%s\n", fgeq);
      printf("\tjmp ax\n");
      printf(":%s\n", inf);
      printf("\tconst ax,1\n");
      printf("\tpush ax\n");
      printf(":%s\n", fgeq);
    } else {
      if (($1 == INT_T && $3 == BOOL_T) || ($1 == BOOL_T && $3 == INT_T)) {
        $$ = ERR_T;
      } else if ($1 != INT_T && $1 != BOOL_T) {
        $$ = $1;
      } else {
        $$ = $3;
      }
    }
  }
  | NOT expr {
    if ($2 == BOOL_T) {
      char buf[STACK_CAPACITY];
      char buf2[STACK_CAPACITY];
      int nb = new_label_number();
      printf("\tpop ax\n");
      create_label(buf2, STACK_CAPACITY, "%s:%d", "end_not", nb);
      create_label(buf, STACK_CAPACITY, "%s:%d", "not", nb);
      printf("\tconst cx,%s\n", buf);
      printf("\tcmp ax, 0\n");
      printf("\tjmpc cx\n");
      printf("\tconst ax,0\n");
      printf("\tpush ax\n");
      printf("\tconst ax,%s\n", buf2);
      printf("\tjmp ax\n");
      printf(":%s\n", buf);
      printf("\tconst ax,1\n");
      printf("\tpush ax\n");
      printf(":%s\n", buf);
      $$ = BOOL_T;
    } else {
      if ($2 == ERR_0) {
        $$ = $2;
      } else {
        $$ = ERR_T;
      }
    }
  }
  | expr AND expr {
    if ($1 == BOOL_T && $3 == BOOL_T) {
      printf("\tpop ax\n");
      printf("\tpop bx\n");
      printf("\tand ax,bx\n");
      printf("\tpush ax\n");
      $$ = BOOL_T;
    } else {
      if (($1 == BOOL_T && $3 == INT_T) || ($1 == INT_T && $3 == BOOL_T)) {
        $$ = ERR_T;
      } else if ($1 != INT_T && $1 != BOOL_T) {
        $$ = $1;
      } else {
        $$ = $3;
      }
    }
  }
  | expr OR expr {
    if ($1 == BOOL_T && $3 == BOOL_T) {
      printf("\tpop ax\n");
      printf("\tpop bx\n");
      printf("\tor ax,bx\n");
      printf("\tpush ax\n");
      $$ = BOOL_T;
    } else {
      if (($1 == BOOL_T && $3 == INT_T) || ($1 == INT_T && $3 == BOOL_T)) {
        $$ = ERR_T;
      }  else if ($1 != INT_T && $1 != BOOL_T) {
        $$ = $1;
      } else {
        $$ = $3;
      }
    }
  }
;
parameters :
  parameters ID {
    ids[size_ids] = $2;
    ++size_ids;
  }
  | ID {
    ids[size_ids] = $1;
    ++size_ids;
  }
;

valeurs :
  valeurs expr{
    values[size_values] = $2;
    ++size_values;
  }
  | expr {
    values[size_values] = $1;
    ++size_values;
  }
;

%%

void yyerror(char const *s) {
  fprintf(stderr, "%s\n", s);
}

int main(void) {
  yyparse();
  return EXIT_SUCCESS;
}


