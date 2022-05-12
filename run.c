#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include "stypes.h"
#include "stable.h"

#define BUFFER_SIZE 255

void get_name(char* file, char* dest);

int main(int argc, char* argv[]) {
  if (argc < 2) {
    fprintf(stderr, "pas assez d'argument\n");
    exit(EXIT_FAILURE);
  }
  char name[BUFFER_SIZE];
  get_name(argv[1], name);
  symbol_table* s = search_symbol_table(name);
  if (s == NULL) {
    fprintf(stderr, "pas de fonction de ce nom\n");
    exit(EXIT_FAILURE);
  }
  if (argc != 2 + s->nParams) {
    fprintf(stderr, "nombre de paramètre pour la fonction incorrecte\n");
    exit(EXIT_FAILURE);
  }
  int fd = open(argv[1], O_RDONLY);
  if (fd == -1) {
    fprintf(stderr, "open()\n");
    exit(EXIT_FAILURE);
  }
  if(dup2(STDIN_FILENO, fd) == -1) {
    fprintf(stderr, "dup2()\n");
    exit(EXIT_FAILURE);
  }
  if (close(fd) == -1) {
    fprintf(stderr, "close()\n");
    exit(EXIT_FAILURE);
  }
  printf("");
}

// retourne le nom du fichier sans extension
void get_name(char* file, char* dest) {
  while (*file != '.') {
    *dest = *file;
    ++file;
    ++dest;
  }
}