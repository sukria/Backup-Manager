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

#include "customconfig.h"
#define MEM_MANAGER 1

/* This is the maximum number of allocatable variables. */
#define MEM_MAX_ELEMENTS 2000

/* set MEM_DEBUG to 1 for printing on stdout what happens.
 * Obviously, this should be disabled for a stable release. then only 
 * errors would appear. */
#define MEM_DEBUG 1

/* mem_handler is a structure to store each event related to memory usage */
struct mem_handler {
	int		nb_alloc;			/* counter */
	int		nb_free;			/* counter */
	int		current_place;			/* index of the current element*/
	int		total_bytes;			/* bytes of all elements allocated */
	void*		element[MEM_MAX_ELEMENTS];	/* addresses of allocated elements */
	char*		name[MEM_MAX_ELEMENTS];		/* names of elements (if given) */
	int		size[MEM_MAX_ELEMENTS];		/* size of elements*/
} memory;

/* wrap malloc() to trace what is allocated */
void*	
mem_alloc (int size);

/* wrap free() to trace what is freed */
int	
mem_free (void* ptr);

/* free each pointer referenced */
int	
mem_free_all (void);

/* print the content of the memory table */
void	
mem_print_status (void);


int	
get_position (void* pointer); 

int
add_element (void* pointer, int size, const char *name);

int
remove_element ();

void*
mem_handler_init ();
