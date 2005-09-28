
#include <stdio.h>
#include "../src/bm_configuration_manager.h"
#include "../src/mem_manager.h"

int main (int argc, char **argv) 
{
	char *conf_file = "/etc/backup-manager.conf";
	
	mem_handler_init();
	bm_load_conf(conf_file);

	bm_display_config();

	printf("la clef BM_NAME_FORMAT vaut : %s\n", bm_get_variable_data("BM_NAME_FORMAT"));
	bm_set_variable_data("BM_NAME_FORMAT", "ceci est un test");
	
	printf("la clef BM_NAME_FORMAT vaux maintenant : %s\n", bm_get_variable_data("BM_NAME_FORMAT"));
	bm_write_conf("/tmp/toto.conf");
	
	mem_print_status();
	bm_free_config();
	mem_print_status();
}
