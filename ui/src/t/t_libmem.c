
#include <stdio.h>
#include "../mem_manager.h"

int
main (int argc, char *argv[])
{
	char *str1, *str2, *str3, *str4;

	printf("3 mem_alloc a la suite\n");
	str1 = (char *) mem_alloc_with_name(10, "str1");
	str2 = (char *) mem_alloc(3);
	str4 = (char *) mem_alloc_with_name(3, "str4");
	mem_print_status();
	
	printf("mem_free\n");
	mem_free(str2);
	mem_print_status();
	
	printf("mem_alloc_with_name(str3)\n");
	str3 = (char *) mem_alloc_with_name(255, "str3");

	mem_print_status();
	mem_free_all();
	mem_print_status();
}
