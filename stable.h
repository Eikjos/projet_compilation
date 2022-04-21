#ifndef _STABLE_H
#define _STABLE_H

#include "types.h"

symbol_table *search_symbol_table(const char *name);
symbol_table *new_symbol_table(const char *name);
symbol_table *get_symbol_table(void);
void free_first_symbol_table(void);

#endif