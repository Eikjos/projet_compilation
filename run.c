#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
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
  // OUVERTURE DU FICHIER DE LA FONCTION 
  int fd = open(argv[1], O_RDONLY);
  if (fd == -1) {
    fprintf(stderr, "fichier - open()\n");
    exit(EXIT_FAILURE);
  }
  if(dup2(fd, STDIN_FILENO) == -1) {
    fprintf(stderr, "dup2()\n");
    exit(EXIT_FAILURE);
  }
  if (close(fd) == -1) {
    fprintf(stderr, "close()\n");
    exit(EXIT_FAILURE);
  }
  // OUVERTURE DU FICHIER POUR EXECUTER LA FONCTION
  char executablePath[BUFFER_SIZE];
  sprintf(executablePath, "%s_main.asm", name);
  fd = open(executablePath, O_RDWR | O_CREAT , S_IRWXU);
  if (fd == -1) {
    fprintf(stderr, "executable - open()\n");
    exit(EXIT_FAILURE);
  }
  if(dup2(fd, STDOUT_FILENO) == -1) {
    fprintf(stderr, "dup2()\n");
    exit(EXIT_FAILURE);
  }
  if (close(fd) == -1) {
    fprintf(stderr, "close()\n");
    exit(EXIT_FAILURE);
  }
  int tab[argc - 2];
  for (int i = 2; i < argc; ++i) {
    if (sscanf(argv[i], "%d", &tab[i - 2]) != 1) {
      fprintf(stderr, "erreur lors de la conversion de string en int\n");
      exit(EXIT_FAILURE);
    }
  }
  // initialisation de la pile
  printf("\tconst bp,pile\n");
  printf("\tconst sp,pile\n");
  printf("\tconst ax,2\n");
  printf("\tsub sp,ax\n");
  // affectation des valeurs avant l'appel de la fonction
  printf(":debut\n");
  for (int i = 0; i < argc - 2; ++i) {
    printf("\tconst ax,%d\n", tab[i]);
    printf("\tpush ax\n");
  }
  // appel de la fonction
  printf("\tconst ax,%s\n", name);
  printf("\tjmp ax\n");
  // retour de la fonction avec affichage du résultat
  printf(":fin_function\n");
  printf("\tcp ax,sp\n");
  printf("\tcallprintfd ax\n");
  printf("\tconst ax,ral\n");
  printf("\tcallprintfs ax\n");
  printf("\tend\n");
  // déclaration de la fonction (lecture du fichier)
  char buf[BUFFER_SIZE];
  while(fgets(buf, BUFFER_SIZE, stdin) != NULL) {
    printf("%s", buf);
  }
  // déclaration des valeurs
  symbol_table* s = get_symbol_table();
  while (s != NULL) {
    printf("var:%s\n", s->name);
    printf("@int 0\n");
    s = s->next;
  }
  printf(":ral\n");
  printf("@string \"\\n\"\n");
  // déclaration de la pile
  printf(":pile\n");
  printf("@int 0\n");
  printf("\n");
}

// retourne le nom du fichier sans extension
void get_name(char* file, char* dest) {
  while (*file != '.') {
    *dest = *file;
    ++file;
    ++dest;
  }
  *dest = '\0';
}
