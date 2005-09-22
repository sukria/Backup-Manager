#include <gtk/gtk.h>


void
on_nouveau1_activate                   (GtkMenuItem     *menuitem,
                                        gpointer         user_data);

void
on_ouvrir1_activate                    (GtkMenuItem     *menuitem,
                                        gpointer         user_data);

void
on_enregistrer1_activate               (GtkMenuItem     *menuitem,
                                        gpointer         user_data);

void
on_enregistrer_sous1_activate          (GtkMenuItem     *menuitem,
                                        gpointer         user_data);

void
on_quitter1_activate                   (GtkMenuItem     *menuitem,
                                        gpointer         user_data);

void
on_couper1_activate                    (GtkMenuItem     *menuitem,
                                        gpointer         user_data);

void
on_copier1_activate                    (GtkMenuItem     *menuitem,
                                        gpointer         user_data);

void
on_coller1_activate                    (GtkMenuItem     *menuitem,
                                        gpointer         user_data);

void
on_supprimer1_activate                 (GtkMenuItem     *menuitem,
                                        gpointer         user_data);

void
on____propos1_activate                 (GtkMenuItem     *menuitem,
                                        gpointer         user_data);

void
on_configuration_window_destroy        (GtkObject       *object,
                                        gpointer         user_data);

void
on_confw_load_button_clicked           (GtkButton       *button,
                                        gpointer         user_data);

void
on_confw_reset_button_clicked          (GtkButton       *button,
                                        gpointer         user_data);

void
on_confw_save_button_clicked           (GtkButton       *button,
                                        gpointer         user_data);

void
on_confw_BM_REPOSITORY_ROOT_button_clicked
                                        (GtkButton       *button,
                                        gpointer         user_data);

void
on_confw_BM_REPOSITORY_SECURE_yes_toggled
                                        (GtkToggleButton *togglebutton,
                                        gpointer         user_data);

void
on_confw_BM_REPOSITORY_SECURE_no_toggled
                                        (GtkToggleButton *togglebutton,
                                        gpointer         user_data);

void 
on_confw_repository_filesel_ok_button 
					(GtkWidget *widget, 
					gpointer user_data);
