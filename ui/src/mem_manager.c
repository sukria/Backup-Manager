/*************************************************
 * file    : mem_manager.c 
 * role    : definition of functions to manage the
 *           memory usage
 * author  : Alexis Sukrieh (sukria)
 * created : 2002/12/04
 * updated : 2002/12/04
 * cvs tag : $Id$
 *************************************************/

#include "mem_manager.h"
#include <stdlib.h>

/* initialize the memory handler */
int	mem_handler_init	() {
	extern struct mem_handler memory;
}

/* wrap malloc() to trace what is allocated */
void*	mem_alloc		(int size) {
	
	extern struct mem_handler memory;
	void*	new_pointer;
	
	if (memory.current_place == MEM_MAX_ELEMENTS) {
		printf ("ERREUR [mem_handler] : la plage mémoire est pleine\n");
		exit (0);
	}

	if (size <= 0) {
		printf ("ERREUR [mem_handler] : demande d'allocation d'une taille nulle\n");
		return (0);
	}

	
	new_pointer = malloc (size);
	if (CRAZY_DEBUG) printf ("allocation de %x\n", new_pointer);
	
	add_element (new_pointer, size);

	return (new_pointer);
	
}

/* wrap free() to trace what is freed */
int	mem_free		(void* ptr) {
	extern struct mem_handler memory;
	
	if (CRAZY_DEBUG) printf ("liberation de %x\n", ptr);
	
	if (ptr == 0) {
		printf ("ERREUR : libération d'un pointeur vide\n");
		return (0);
	}

	if (!element_exists (ptr)) {
		printf ("ERREUR : le pointeur demandé n'est pas référencé [%x] - (%d)\n", ptr);
		return (0);
	}
	
	remove_element (ptr);
	
	free (ptr);

	return (1);
}


/* free every remaining pointers */
int	mem_free_all		(void) {
	extern struct mem_handler memory;
	int	current_element;
	int	counter=0;
	int	bytes=0;
	
	for (current_element=memory.current_place-1; current_element>=0; current_element--) {
		free (memory.elements[current_element]);
		memory.total_bytes -= memory.sizes[current_element];
		bytes += memory.sizes[current_element];
		memory.elements[current_element] = 0;
		memory.current_place--;
		counter++;
	}

	if (DEBUG && counter>0) {
		printf ("WARNING : there was still %d elements allocated (%d bytes) !\n", counter, bytes);
	}
	
	return (1);
}

/* print the content of the memory table */
void	mem_print_status	(void) {
	extern struct 	mem_handler memory;
	int		i;
	
	printf ("---------------------------------\n");
	printf ("****       m e m o r y       ****\n");
	printf ("---------------------------------\n");
	printf ("%d pointeurs pour %d octets\n", memory.current_place, memory.total_bytes);
	printf ("---------------------------------\n");
	for (i=0; i<memory.current_place; i++) {
		printf ("%03d - %x (->%d octets)\n", i, (int) memory.elements[i], memory.sizes[i]);
	}
}




/* --------------------------------- */
/* PRIVATE FUNCTIONS FOR INTERNAL USE */

/* return the position in the memory table of the given pointer */
int	get_position		(void*	pointer) {
	
	extern struct mem_handler memory;
	int	current_pos;	
	
	for (current_pos=0; current_pos<memory.current_place; current_pos++) {
		if (pointer == memory.elements[current_pos]) {
			return (current_pos);
		}
	}

	return ( -1 );
}

/* check if the elements exists in the table */
int	element_exists		(void*	ptr) {
	extern struct mem_handler memory;
	int	exists;	
	
	if ( get_position (ptr) != -1) 
		return (1);

	return (0);
}

/* add the given value to the table */
int	add_element		(void* pointer, int size) {
	extern struct mem_handler memory;
	
	if (memory.elements[memory.current_place] != 0) {
		printf ("ERREUR : la case n'est pas libre [0x%x]\n", (int) memory.elements[memory.current_place]);
		return 0;
	}
	else {
		memory.sizes[memory.current_place] = size;
		memory.elements[memory.current_place] = pointer;
		memory.current_place++;
		memory.total_bytes += size;
	}

	return (1);
}

/* remove the given value from the table */
int	remove_element		(void* ptr) {
	extern struct mem_handler memory;
	int		position;
	
	if (ptr <= 0) {
		printf ("ERREUR : demande de libération d'un pointeur vide\n");
		return (0);
	}
	
	position = get_position (ptr);
	memory.total_bytes -= memory.sizes[position];

	for (position; position<memory.current_place; position++) {
		memory.elements[position] = memory.elements[position+1];
		memory.sizes[position] = memory.sizes[position+1];
	}
	
	memory.elements[position] = 0;
	memory.sizes[position] = 0;
	memory.current_place--;
	
	return (1);
}



