#include "bm.h"
#include "mem_manager.h"

int main (int argc, char **argv) {

	char *conf_file = "/etc/backup-manager.conf";
	
	mem_handler_init();
	bm_load_conf(conf_file);

	bm_display_config();

	printf("la clef BM_NAME_FORMAT vaux : %s\n", bm_get_variable_data("BM_NAME_FORMAT"));
	
	bm_set_variable_data("BM_NAME_FORMAT", "ce ci est un test");
	
	printf("la clef BM_NAME_FORMAT vaux maintenant : %s\n", bm_get_variable_data("BM_NAME_FORMAT"));
	
	bm_write_conf("/tmp/toto.conf");
	
	bm_free_config();

	mem_print_status();
	
}
