#include <stdlib.h>
#include <string.h>
#include "types.h"

static symbol_table *table = NULL;

symbol_table *search_symbol_table(const char *name) {
  symbol_table *ste = table;
  for ( ste = table;
        ste!=NULL && strcmp(ste->name, name);
        ste = ste->next)
    ;
  return ste;
}

symbol_table *new_symbol_table(const char *name) {
  symbol_table *n;
  if ((n = malloc(sizeof(symbol_table))) == NULL) {
    fail_with("new_symbol_table: %s", strerror(errno));
  } else {
    if ((n->name = malloc(strlen(name)+1)) == NULL) {
      fail_with("new_symbol_table: %s", strerror(errno));
    } else {
      strcpy((char *)(n->name), name);
      // Last declared symbol needs to be first in the list,
      // in order to have the scope of local variables correctly
      // taken into account
      n->next = table;
      table = n;
    }
  }
  return n;
}

void free_first_symbol_table(void) {
  symbol_table *ste = table->next;
  free(table);
  table = ste;
}

symbol_table* get_symbol_table(void) {
	return table;
}