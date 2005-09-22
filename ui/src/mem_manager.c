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

#include "mem_manager.h"
#include <stdio.h>
#include <stdlib.h>

/* initialize the memory handler */
void*
mem_handler_init
			() 
{
	extern struct mem_handler memory;
	memory.current_place = 0;
	memory.nb_alloc = 0;
	memory.nb_free = 0;
	memory.total_bytes = 0;
}

/* wrap malloc() to trace what is allocated */
void*	
mem_alloc
		(int size) 
{
	extern struct mem_handler memory;
	void*         new_pointer;
	
	if ((memory.current_place) > (MEM_MAX_ELEMENTS - 1)) {
		printf ("[mem_handler] ERROR: not enough room, enlarge MEM_MAX_ELEMENTS, already %d elements allocated.\n", MEM_MAX_ELEMENTS);
		mem_print_status();
		exit (0);
	}

	if (size <= 0) {
		printf ("[mem_handler] ERROR: cannot allocate a size == 0\n");
		return (0);
	}

	new_pointer = malloc (size);
	add_element (new_pointer, size);
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
mem_free_all		
		(void) 
{
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
		#ifdef MEM_DEBUG 
		printf ("[mem_handler] DEBUG: there were still %d elements allocated (%d bytes).\n", counter, bytes);
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
	
	#ifdef MEM_DEBUG 
	printf ("---------------------------------\n");
	printf ("****       m e m o r y       ****\n");
	printf ("---------------------------------\n");
	printf ("%d pointers for %d bytes\n", memory.current_place, memory.total_bytes);
	printf ("---------------------------------\n");
	for (i=0; i<memory.current_place; i++) {
		printf ("Element #%03d - 0x%x (%d bytes)\n", i, (int) memory.elements[i], memory.sizes[i]);
	}
	#endif
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
		if (pointer == memory.elements[current_pos]) {
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
add_element
		(void* pointer, int size) 
{
	extern struct mem_handler memory;
	
	if (memory.elements[memory.current_place] != 0) {
		printf ("[mem_handler] ERROR: the current field is not free [0x%x, index #%d]\n", 
				(int) memory.elements[memory.current_place], 
				memory.current_place);
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



