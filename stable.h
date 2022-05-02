#ifndef _STABLE_H
#define _STABLE_H


#include <stdbool.h>
#include <stdlib.h>
#include <errno.h>

#define MAX_PARAMS 10

#include "stypes.h"

symbol_table *search_symbol_table(const char *name);
symbol_table *new_symbol_table(const char *name);
symbol_table *get_symbol_table(void);
void free_first_symbol_table(void);
void fail_with(const char *format, ...);

#endif
