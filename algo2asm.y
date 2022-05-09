%{
    #include <ctype.h>
    #include <stdlib.h>
    #include <stdio.h>
    #include <stdarg.h>
    #include <string.h>
    #include <limits.h>
    #include <sys/types.h>
    #include <sys/stat.h>
    #include <fcntl.h>
    #include <unistd.h>
    #include "stable.h"
    #include "stypes.h"
    int yylex(void);
    void yyerror(char const *);
    #define STACK_CAPACITY 50
    static int values[STACK_CAPACITY];
    static char* ids[STACK_CAPACITY];
    static int stack[STACK_CAPACITY];
    static char* boucle[STACK_CAPACITY];
    static char* boucleEnd[STACK_CAPACITY];
    static char* varBoucle[STACK_CAPACITY];
    static char* finsi[STACK_CAPACITY];
    static char* ifelse[STACK_CAPACITY];
    int size_else = 0;
    int size_fi = 0;
    int size_end = 0;
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
  comp c;
}

%token<integer>NUMBER
%token SET
%token<id>ID
%token DEBUT
%token FIN
%token FOR WHILE
%token FIN_BOUCLE FIN_BOUCLE_WHILE
%token IF ELSE FIN_IF
%token TRUE FALSE
%token RETURN 

%type<t> expr
%type<c> comparaison
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
      char path[STACK_CAPACITY];
      create_label(path, STACK_CAPACITY, "%s.%s", $2, "asm");
      int fd = open(path, O_CREAT | O_WRONLY);
      if (fd == -1) {
        fprintf(stderr, "open()");
        exit(EXIT_FAILURE);
      }
      if (dup2(STDOUT_FILENO, fd) == -1) {
        fprintf(stderr, "dup2()");
        exit(EXIT_FAILURE);
      }
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
      for (int i = 0; i < size_ids; ++i) {
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
            printf("\tpop bx\n");
            printf("\tstorew bx,ax\n");
        } else {
          // le cas où la variable n'existe pas
          s = new_symbol_table(ids[i]);
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
      for (int i = 0; i < size_ids; ++i) {
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
            printf("\tpop bx\n");
            printf("\tstorew bx,ax\n");
        } else {
          // le cas où la variable n'existe pas
          s = new_symbol_table(ids[i]);
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
  | FOR ID expr expr lignes {
    if ($3 == INT_T && $4 == INT_T) {
      int nb = new_label_number();
      char pour[STACK_CAPACITY] ;
      char endFor[STACK_CAPACITY];
      char var[STACK_CAPACITY];
      char varEnd[STACK_CAPACITY];
      create_label(pour, STACK_CAPACITY, "%s:%d", "for", nb);
      create_label(endFor, STACK_CAPACITY, "%s:%d", "endfor", nb);
      create_label(var, STACK_CAPACITY, "%s:%d", "ifor", nb);
      create_label(varEnd, STACK_CAPACITY, "%s:%d", "iendfor", nb);
      symbol_table* s = search_symbol_table($2);
      if (s != NULL) {
        if (s->desc[0] != INT_T) {
          fprintf(stderr, "erreur de typage\n");
          exit(EXIT_FAILURE);
        }
        strcpy(var, $2);
      } else {
        symbol_table* s = new_symbol_table(var);
        s->desc[0] = INT_T;
      }
      s = new_symbol_table(varEnd);
      s->desc[0] = INT_T;
      printf("\tpop bx\n");
      printf("storew bx,%s\n", varEnd);
      printf("\tpop bx\n");
      printf("storew bx,%s\n", var);
      boucle[size_end] = pour;
      varBoucle[size_end] = var;
      boucleEnd[size_end] = endFor;
      ++size_end;
      printf(":%s\n", pour);
      printf("\tloadw ax,%s\n", var);
      printf("\tloadw bx,%s\n", varEnd);
      printf("\tconst cx,%s\n", endFor);
      printf("\tcmp ax,bx\n");
      printf("\tjmpc cx\n");
    } else {
      fprintf(stderr, "erreur interne boucle for\n");
      exit(EXIT_FAILURE);
    }
  }
  | lignes IF expr lignes FIN_IF {
    if ($3 == BOOL_T) {
      int nb = new_label_number();
      char fin[STACK_CAPACITY];
      create_label(fin, STACK_CAPACITY, "%s:%d", "finif", nb);
      finsi[size_fi] = fin;
      ++size_fi;
      printf("\tpop ax\n");
      printf("\tconst cx,%s\n", fin);
      printf("\tcmp ax,0\n");
      printf("\tjmpc cx\n");
    } else {
      fprintf(stderr, "erreur de typage\n");
      exit(EXIT_FAILURE);
    }
  }
  | lignes IF expr lignes ELSE lignes FIN_IF {
    if ($3 == BOOL_T) {
      int nb = new_label_number();
      char fin[STACK_CAPACITY];
      char sinon[STACK_CAPACITY];
      create_label(fin, STACK_CAPACITY, "%s:%d", "finif", nb);
      create_label(sinon, STACK_CAPACITY, "%s:%d", "sinon", nb);
      ifelse[size_else] = sinon;
      ++size_else;
      finsi[size_fi] = fin;
      ++size_fi;
      printf("\tpop ax\n");
      printf("\ttconst cx,%s\n", sinon);
      printf("\tcmp ax,0\n");
      printf("\tjmpc cx\n");
    } else {
      fprintf(stderr, "erreur de typage\n");
      exit(EXIT_FAILURE);
    }
  }
  | lignes WHILE ID comparaison expr lignes {
    if ($4 == INT_T) {
      printf("/tpop ax\n");
      int nb = new_label_number();
      char continuer[STACK_CAPACITY];
      char tant[STACK_CAPACITY];
      char endWhile[STACK_CAPACITY];
      create_label(tant, STACK_CAPACITY, "%s:%d", "while", nb);
      create_label(continuer, STACK_CAPACITY, "%s:%d", "continue", nb); 
      create_label(endWhile, STACK_CAPACITY, "%s:%d", "endWhile", nb);
      boucle[size_end] = tant;
      boucleEnd[size_end] = endWhile;
      ++size_end;
      symbol_table* s = search_symbol_table($3); 
      if (s == NULL) {
        fprintf(stderr, "variable indefined\n");
        exit(EXIT_FAILURE);
      }
      printf(":%s\n", tant);
      printf("\tconst ax,var:%s\n", $3);
      printf("\tloadw bx,ax\n");
      printf("\tpop ax\n");
      if ($3 == EQ_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
        printf("\†const ax,%s\n", endWhile);
        printf("/tjmp ax\n");
      } else if ($3 == LEQ_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
        printf("\tconst ax,%s/n", endWhile);
        printf("\tjmp ax/n");
      } else if ($3 == GEQ_T) {
        printf("\tconst cx,%s\n", endWhile);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
      } else if ($3 == LE_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tslees bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\const ax,%s\n", endWhile);
        printf("jmp ax\n");
      } else if ($3 == GRE_T) {
        printf("\tconst cx,%s\n", endWhile);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
      }
      printf(":%s\n", continuer);
    } else {
      fprintf(stderr, "erreur interne boucle while\n");
    }
  }
  | lignes WHILE expr comparaison ID lignes {
    if ($4 == INT_T) {
      printf("/tpop ax\n");
      int nb = new_label_number();
      char continuer[STACK_CAPACITY];
      char tant[STACK_CAPACITY];
      char endWhile[STACK_CAPACITY];
      create_label(tant, STACK_CAPACITY, "%s:%d", "while", nb);
      create_label(continuer, STACK_CAPACITY, "%s:%d", "continue", nb); 
      create_label(endWhile, STACK_CAPACITY, "%s:%d", "endWhile", nb);
      boucle[size_end] = tant;
      boucleEnd[size_end] = endWhile;
      ++size_end;
      symbol_table* s = search_symbol_table($4); 
      if (s == NULL) {
        fprintf(stderr, "variable indefined\n");
        exit(EXIT_FAILURE);
      }
      printf(":%s\n", tant);
      printf("\tconst ax,var:%s\n", $4);
      printf("\tloadw bx,ax\n");
      printf("\tpop ax\n");
      if ($3 == EQ_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
        printf("\†const ax,%s\n", endWhile);
        printf("/tjmp ax\n");
      } else if ($3 == LEQ_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
        printf("\tconst ax,%s/n", endWhile);
        printf("\tjmp ax/n");
      } else if ($3 == GEQ_T) {
        printf("\tconst cx,%s\n", endWhile);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
      } else if ($3 == LE_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tslees bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\const ax,%s\n", endWhile);
        printf("jmp ax\n");
      } else if ($3 == GRE_T) {
        printf("\tconst cx,%s\n", endWhile);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
      }
      printf(":%s\n", continuer);
    } else {
      fprintf(stderr, "erreur interne boucle while\n");
      exit(EXIT_FAILURE);
    }
  }
  | lignes RETURN expr lignes {
    if ($3 != INT_T && $3 != BOOL_T) {
      fprintf(stderr, "il y a une erreur dans l'expression retourné\n");
      exit(EXIT_FAILURE);
    }
    printf("\tconst ax,fin_function\n");
    printf("/tjmp ax\n");
  }
  | lignes FOR ID expr expr lignes{
    if ($4 == INT_T && $5 == INT_T) {
      int nb = new_label_number();
      char pour[STACK_CAPACITY];
      char endFor[STACK_CAPACITY];
      char varEnd[STACK_CAPACITY];
      char var[STACK_CAPACITY];
      create_label(pour, STACK_CAPACITY, "%s:%d", "for", nb);
      create_label(endFor, STACK_CAPACITY, "%s:%d", "endfor", nb);
      create_label(var, STACK_CAPACITY, "%s:%d", "ifor", nb);
      create_label(varEnd, STACK_CAPACITY, "%s:%d", "iendfor", nb);
      symbol_table* s = search_symbol_table($3);
      if (s != NULL) {
        if (s->desc[0] != INT_T) {
          fprintf(stderr, "erreur de typage\n");
          exit(EXIT_FAILURE);
        }
        strcpy(var, $3);
      } else {
        symbol_table* s = new_symbol_table(var);
        s->desc[0] = INT_T;
      }
      s = new_symbol_table(varEnd);
      s->desc[0] = INT_T;
      printf("\tpop bx\n");
      printf("storew bx,%s\n", varEnd);
      printf("\tpop bx\n");
      printf("storew bx,%s\n", var);
      boucle[size_end] = pour;
      varBoucle[size_end] = var;
      boucleEnd[size_end] = endFor;
      ++size_end;
      printf(":%s\n", pour);
      printf("\tloadw ax,%s\n", var);
      printf("\tloadw bx,%s\n", varEnd);
      printf("\tconst cx,%s\n", endFor);
      printf("\tcmp ax,bx\n");
      printf("\tjmpc cx\n");
    } else {
      fprintf(stderr, "erreur interne boucle for\n");
      exit(EXIT_FAILURE);
    }
  }
  | lignes FIN_BOUCLE lignes{
    printf("\tloadw ax,%s\n", varBoucle[size_end]);
    printf("\tadd ax,1\n");
    printf("\tstorew ax,%s\n", varBoucle[size_end]);
    printf("const cx,%s\n", boucle[size_end]);
    printf("\tjmp cx\n");
    printf(":%s\n", boucleEnd[size_end]);
    --size_end;
  }
  | IF expr lignes FIN_IF lignes {
    if ($2 == BOOL_T) {
      int nb = new_label_number();
      char fin[STACK_CAPACITY];
      create_label(fin, STACK_CAPACITY, "%s:%d", "finif", nb);
      finsi[size_fi] = fin;
      ++size_fi;
      printf("\tpop ax\n");
      printf("\tconst cx,%s\n", fin);
      printf("\tcmp ax,0\n");
      printf("\tjmpc cx\n");
    } else {
      fprintf(stderr, "erreur de typage\n");
      exit(EXIT_FAILURE);
    }
  }
  | FIN_IF lignes {
      printf(":%s\n", finsi[size_fi]);
      --size_fi;
  }
  | lignes FIN_IF lignes {
    printf(":%s\n", finsi[size_fi]);  
    --size_fi;
  }
  | IF expr lignes ELSE lignes FIN_IF {
    if ($2 == BOOL_T) {
      int nb = new_label_number();
      char fin[STACK_CAPACITY];
      char sinon[STACK_CAPACITY];
      create_label(fin, STACK_CAPACITY, "%s:%d", "finif", nb);
      create_label(sinon, STACK_CAPACITY, "%s:%d", "sinon", nb);
      ifelse[size_else] = sinon;
      ++size_else;
      finsi[size_fi] = fin;
      ++size_fi;
      printf("\tpop ax\n");
      printf("\ttconst cx,%s\n", sinon);
      printf("\tcmp ax,0\n");
      printf("\tjmpc cx\n");
    } else {
      fprintf(stderr, "erreur de typage\n");
      exit(EXIT_FAILURE);
    }
  }
  | lignes ELSE lignes {
    printf("\tconst ax,%s\n", finsi[size_fi]);
    printf("\tjmp ax\n");
    printf(":%s\n", ifelse[size_else]);
    --size_else;
  }
  | WHILE ID comparaison expr lignes {
    if ($4 == INT_T) {
      printf("/tpop ax\n");
      int nb = new_label_number();
      char continuer[STACK_CAPACITY];
      char tant[STACK_CAPACITY];
      char endWhile[STACK_CAPACITY];
      create_label(tant, STACK_CAPACITY, "%s:%d", "while", nb);
      create_label(continuer, STACK_CAPACITY, "%s:%d", "continue", nb); 
      create_label(endWhile, STACK_CAPACITY, "%s:%d", "endWhile", nb);
      boucle[size_end] = tant;
      boucleEnd[size_end] = endWhile;
      ++size_end;
      symbol_table* s = search_symbol_table($2); 
      if (s == NULL) {
        fprintf(stderr, "variable indefined\n");
        exit(EXIT_FAILURE);
      }
      printf(":%s\n", tant);
      printf("\tconst ax,var:%s\n", $2);
      printf("\tloadw bx,ax\n");
      printf("\tpop ax\n");
      if ($3 == EQ_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
        printf("\†const ax,%s\n", endWhile);
        printf("/tjmp ax\n");
      } else if ($3 == LEQ_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
        printf("\tconst ax,%s/n", endWhile);
        printf("\tjmp ax/n");
      } else if ($3 == GEQ_T) {
        printf("\tconst cx,%s\n", endWhile);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
      } else if ($3 == LE_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tslees bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\const ax,%s\n", endWhile);
        printf("jmp ax\n");
      } else if ($3 == GRE_T) {
        printf("\tconst cx,%s\n", endWhile);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
      }
      printf(":%s\n", continuer);
    } else {
      fprintf(stderr, "erreur interne boucle while\n");
    }
  }
  | WHILE expr comparaison ID lignes {
    if ($4 == INT_T) {
      printf("/tpop ax\n");
      int nb = new_label_number();
      char continuer[STACK_CAPACITY];
      char tant[STACK_CAPACITY];
      char endWhile[STACK_CAPACITY];
      create_label(tant, STACK_CAPACITY, "%s:%d", "while", nb);
      create_label(continuer, STACK_CAPACITY, "%s:%d", "continue", nb); 
      create_label(endWhile, STACK_CAPACITY, "%s:%d", "endWhile", nb);
      boucle[size_end] = tant;
      boucleEnd[size_end] = endWhile;
      ++size_end;
      symbol_table* s = search_symbol_table($4); 
      if (s == NULL) {
        fprintf(stderr, "variable indefined\n");
        exit(EXIT_FAILURE);
      }
      printf(":%s\n", tant);
      printf("\tconst ax,var:%s\n", $4);
      printf("\tloadw bx,ax\n");
      printf("\tpop ax\n");
      if ($3 == EQ_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
        printf("\†const ax,%s\n", endWhile);
        printf("/tjmp ax\n");
      } else if ($3 == LEQ_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
        printf("\tconst ax,%s/n", endWhile);
        printf("\tjmp ax/n");
      } else if ($3 == GEQ_T) {
        printf("\tconst cx,%s\n", endWhile);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
      } else if ($3 == LE_T) {
        printf("\tconst cx,%s\n", continuer);
        printf("\tslees bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\const ax,%s\n", endWhile);
        printf("jmp ax\n");
      } else if ($3 == GRE_T) {
        printf("\tconst cx,%s\n", endWhile);
        printf("\tsless bx,ax\n");
        printf("\tjmpc cx\n");
        printf("\tcmp ax,bx\n");
        printf("\tjmpc cx\n");
      }
      printf(":%s\n", continuer);
    } else {
      fprintf(stderr, "erreur interne boucle while\n");
      exit(EXIT_FAILURE);
    }
  }
  | lignes FIN_BOUCLE_WHILE lignes {
    printf("\tconst ax,%s\n", boucle[size_end]);
    printf("\tjmp ax\n");
    printf(":%s\n", boucleEnd[size_end]);
    --size_end;
  }
  | RETURN expr {
    if ($2 != INT_T && $2 != BOOL_T) {
      fprintf(stderr, "il y a une erreur dans l'expression retourné\n");
      exit(EXIT_FAILURE);
    }
    printf("\tconst ax,fin_function\n");
    printf("\tjmp ax\n");
  }
;
comparaison:
  EQ {
    $$ = EQ_T;
  }
  | LEQ {
    $$ = LEQ_T;
  }
  | GRE {
    $$ = GRE_T;
  }
  | GEQ {
    $$ = GEQ_T;
  }
  | LE {
    $$ = LE_T;
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
    if ($1 == INT_T && $3 == INT_T) {
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
      printf("\tconst ax,0\n");
      printf("\tpush ax\n");
      printf("\tconst ax,%s\n", fgeq);
      printf("\tjmp ax\n");
      printf(":%s\n", geq);
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
      printf(":%s\n", geq);
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


