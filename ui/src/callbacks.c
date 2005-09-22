#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <gtk/gtk.h>

#include "callbacks.h"
#include "interface.h"
#include "support.h"

void
on_configuration_window_destroy        (GtkObject       *object,
                                        gpointer         user_data)
{
	exit(0);
}


/* Fill all the entries with the values of the file given */
void
on_confw_load_button_clicked           (GtkButton       *button,
                                        gpointer         user_data)
{

}


/* Reset every entries with the values from the file */
void
on_confw_reset_button_clicked          (GtkButton       *button,
                                        gpointer         user_data)
{

}

/* Save changes to the configuration file */
void
on_confw_save_button_clicked           (GtkButton       *button,
                                        gpointer         user_data)
{

}

/* choose a directory */
void
on_confw_BM_REPOSITORY_ROOT_button_clicked
                                        (GtkButton       *button,
                                        gpointer         user_data)
{
	
}


void
on_confw_BM_REPOSITORY_SECURE_yes_toggled
                                        (GtkToggleButton *togglebutton,
                                        gpointer         user_data)
{

}


void
on_confw_BM_REPOSITORY_SECURE_no_toggled
                                        (GtkToggleButton *togglebutton,
                                        gpointer         user_data)
{

}

