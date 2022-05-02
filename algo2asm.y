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
    static unsigned int new_label_number();
    static void create_label(char *buf, size_t buf_size, const char *format, ...);
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
  symbol_table_entry* s= search_symbol_table($1);
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

}
| expr EQ expr {
  char eq[STACK_CAPACITY];
  char feq[STACK_CAPACITY];
  int nb = new_label_number();
  create_label(eq, STACK_CAPACITY, "%s:%d", "equal", nb);
  create_label(feq, STACK_CAPACITY, "%s:%d", "fequal", nb);
  if ($1 == INT_T && $3 == INT_T) {
    printf("\tpop ax\n");
    printf("\t"pop bx\n");
    printf("\tconst cx,%s\n", eq);
    printf("\tcmp ax,bx\n");
    printf("\tjmp cx\n");
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

}
| expr GRE expr {

}
| expr LEQ expr {

}
| expr GEQ expr {

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
    printf("\jmp ax\n");
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
    printf("\push ax\n");
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