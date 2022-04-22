#ifndef __TYPE__
#define __TYPE__

#include <stdbool.h>
#include <stdlib.h>
#include <errno.h>

#define MAX_PARAMS 10

typedef enum {
    INT_T,
    BOOL_T,
    FUNCTION_T,
    ERR_TYPAGE,
    ERR_DIV_0
} type;

typedef enum { GLOBAL_VARIABLE, LOCAL_VARIABLE, FUNCTION } symbol_class;

typedef struct symbol_table {
  const char *name;
  symbol_class scope;
  unsigned int add;
  // Number of parameters for functions
  size_t nParams;
  // Number of local variables for function
  // (parameters are excluded from this count)
  size_t nLocalVariables; 
  // Variable: type is in desc[0]
  // Function: desc[0] is the return type,
  //           desc[i] the type of the ith parameter
  type desc[MAX_PARAMS+1];
  struct symbol_table *next;
} symbol_table;

#endif