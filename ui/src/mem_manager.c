/*
 * Memory Manager - a small library for handling malloc and free
 *
 * Copyright (C) 2003-2005 Alexis Sukrieh <sukria@sukria.net>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. 
 *
 */

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mem_manager.h"
#include "strLcpy.h"

/* initialize the memory handler */
void*
mem_handler_init () 
{
	extern struct mem_handler memory;
	int i = 0;
	
	memory.current_place = 0; /* where to add the next element */
	memory.nb_alloc = 0;
	memory.nb_free = 0;
	memory.total_bytes = 0;

	/* initialize all the arrays */
	for (i=0; i<MEM_MAX_ELEMENTS; i++) {
		memory.element[i] = (int) NULL;
		memory.size[i] = (int) NULL;
		memory.name[i] = NULL;
	}
}

void*
has_enough_room (void)
{
	extern struct mem_handler memory;
	
	if ((memory.current_place + 1) == MEM_MAX_ELEMENTS) {
		printf ("[mem_handler] ERROR: not enough room, enlarge MEM_MAX_ELEMENTS, already %d elements allocated.\n", MEM_MAX_ELEMENTS);
		mem_print_status();
		exit (0);
	}
}

/* wrap malloc() to trace what is allocated */
void*	
mem_alloc (int size) 
{
	extern struct mem_handler memory;
	void*         new_pointer;

	has_enough_room();

	if (size <= 0) {
		printf ("[mem_handler] ERROR: cannot allocate a size == 0\n");
		return (0);
	}

	new_pointer = malloc (size);
	add_element (new_pointer, size, "[unknown]");
	return (new_pointer);
}

void*
mem_alloc_with_name(int size, const char *name) 
{
	extern struct mem_handler memory;
	void*         new_pointer;

	has_enough_room();

	if (size <= 0) {
		printf ("[mem_handler] ERROR: cannot allocate a size == 0\n");
		return (0);
	}

	new_pointer = malloc (size);
	add_element (new_pointer, size, name);
	return (new_pointer);
}

/* wrap free() to trace what is freed */
int	
mem_free
		(void* ptr) 
{
	extern struct mem_handler memory;
	
	if (ptr == 0) {
		printf ("[mem_handler] ERROR: cannot free a null pointer.\n");
		return (0);
	}

	if (! element_exists (ptr)) {
		printf ("[mem_handler] ERROR: the given pointer is not registered [0x%x]\n", ptr);
		return (0);
	}
	
	remove_element (ptr);
	free (ptr);
	return (1);
}


/* free every remaining pointers */
int	
mem_free_all (void) 
{
	extern struct mem_handler memory;
	int	current_element;
	int	counter=0;
	int	bytes=0;
	
	for (current_element=memory.current_place-1; current_element>=0; current_element--) {
		
		free (memory.element[current_element]);
		memory.element[current_element] = NULL;
		
		free (memory.name[current_element]);
		memory.name[current_element] = NULL;
		
		memory.total_bytes -= memory.size[current_element];
		bytes += memory.size[current_element];
		memory.current_place--;
		
		counter++;
	}

	if (DEBUG && counter>0) {
		#ifdef MEM_DEBUG
		printf("[mem_handler] DEBUG: there were still %d elements allocated (%d bytes).\n", counter, bytes);
		#endif
	}
	
	return (1);
}

/* print the content of the memory table */
void
mem_print_status	
		(void) 
{
	extern struct 	mem_handler memory;
	int		i;
	
	printf ("---------------------------------\n");
	printf ("****       m e m o r y       ****\n");
	printf ("---------------------------------\n");
	printf ("%d pointers for %d bytes\n", memory.current_place, memory.total_bytes);
	printf ("---------------------------------\n");
	for (i=0; i<memory.current_place; i++) {
		printf ("Element #%03d @ 0x%x (%s, %d bytes)\n", i, (int) memory.element[i], memory.name[i], memory.size[i]);
	}
}



/* --------------------------------- */
/* PRIVATE FUNCTIONS FOR INTERNAL USE */

/* return the position in the memory table of the given pointer */
int	
get_position		
		(void*	pointer) 
{
	
	extern struct mem_handler memory;
	int           current_pos;	
	
	for (current_pos=0; current_pos<memory.current_place; current_pos++) {
		if (pointer == memory.element[current_pos]) {
			return (current_pos);
		}
	}
	return (-1);
}

/* check if the elements exists in the table */
int	
element_exists
		(void*	ptr) 
{
	extern struct mem_handler memory;
	int           exists;	
	
	if (get_position (ptr) != -1) 
		return (1);
	return (0);
}

/* add the given value to the table */
int	
add_element (void* pointer, int size, const char *name) 
{
	extern struct mem_handler memory;
	
	if (memory.element[memory.current_place] != NULL) {
		printf ("[mem_handler] ERROR: the current field is not free [0x%x, index #%d]\n", 
				(int) memory.element[memory.current_place], 
				memory.current_place);
		return 0;
	}
	else {
		
		/* save the pointer itself */
		memory.element[memory.current_place] = pointer;

		/* save the size allocated */
		memory.size[memory.current_place] = size;
		
		/* save the name of the pointer */
		memory.name[memory.current_place] = (char *) malloc (strlen(name) + 1);
		string_copy (memory.name[memory.current_place], name, (strlen(name) + 1));

		/* the current place is the next one */
		memory.current_place++;

		/* count the total bytes allocated */
		memory.total_bytes += size;
	}

	return (1);
}

/* set an element to default empty values */
void *
purge_element(int position)
{
	extern struct mem_handler memory;
	
	memory.element[position] = (int) NULL;
	memory.name[position] = NULL;	
	memory.size[position] = (int) NULL;;
}

/* drop the given element from the elements array, and shift all the remainings */
int	
remove_element (void* ptr) {
	extern struct mem_handler memory;
	int		position;
	
	if (ptr <= 0) {
		printf ("[mem_handler] ERROR: cannot free an empty pointer\n");
		return (0);
	}

	/* get the index of the element to remove */
	position = get_position (ptr);

	/* decrease the total amount of bytes allocatd */
	memory.total_bytes -= memory.size[position];

	/* shift every elements from the remove candidate to the last one */
	for (position; position<memory.current_place; position++) {
		
		if (memory.element[position + 1] != NULL) {
			/* pointer */
			memory.element[position] = memory.element[position + 1];
		
			/* size */
			memory.size[position] = memory.size[position + 1];
		}
		
		/* name */
		if (memory.name[position] != NULL)
			free (memory.name[position]);
		
		if (memory.name[position + 1] != NULL) {
			memory.name[position] = (char *) malloc(strlen(memory.name[position + 1]) + 1);
			string_copy(memory.name[position], memory.name[position + 1], strlen(memory.name[position + 1]) + 1);
		}
	}
	
	/* free all the stuff for the current place */
	memory.current_place--;
	purge_element(memory.current_place);

	return (1);
}



