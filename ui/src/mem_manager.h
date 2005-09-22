/*************************************************
 * file    : mem_manager.h 
 * role    : protoypes of functions to manage the
 *           memory usage
 * author  : Alexis Sukrieh (sukria)
 * created : 2002/12/04
 * updated : 2002/12/04
 * cvs tag : $Id$
 *************************************************/

#ifndef CONFIG_H_DEFINED
#  include "configuration.h"
#endif
#define MEM_MANAGER 1


/* mem_hadler is a structure to store each event related to memory usage */
struct mem_handler {
	int		nb_alloc;
	int		nb_free;
	int		current_place;
	int		total_bytes;
	char*		start_adress;
	char*		stop_adress;
	void*		elements[MEM_MAX_ELEMENTS];
	int		sizes[MEM_MAX_ELEMENTS];
} memory;

/* wrap malloc() to trace what is allocated */
void*	mem_alloc		(int size);

/* wrap free() to trace what is freed */
int	mem_free		(void* ptr);

/* free each pointer referenced */
int	mem_free_all		(void);

/* print the content of the memory table */
void	mem_print_status	(void);


int	get_position		(void*	pointer); 
int	add_element		(void* pointer, int size); 
int	remove_element		();

