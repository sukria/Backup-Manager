/*
 * DO NOT EDIT THIS FILE - it is generated by Glade.
 */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>

#include "callbacks.h"
#include "interface.h"
#include "support.h"

#define GLADE_HOOKUP_OBJECT(component,widget,name) \
  g_object_set_data_full (G_OBJECT (component), name, \
    gtk_widget_ref (widget), (GDestroyNotify) gtk_widget_unref)

#define GLADE_HOOKUP_OBJECT_NO_REF(component,widget,name) \
  g_object_set_data (G_OBJECT (component), name, widget)

GtkWidget*
create_filechooser (void)
{
  GtkWidget *filechooser;
  GtkWidget *dialog_vbox1;
  GtkWidget *dialog_action_area1;
  GtkWidget *button1;
  GtkWidget *button2;

  filechooser = gtk_file_chooser_dialog_new ("", NULL, GTK_FILE_CHOOSER_ACTION_OPEN, NULL);
  gtk_widget_set_name (filechooser, "filechooser");
  gtk_container_set_border_width (GTK_CONTAINER (filechooser), 2);
  gtk_window_set_type_hint (GTK_WINDOW (filechooser), GDK_WINDOW_TYPE_HINT_DIALOG);

  dialog_vbox1 = GTK_DIALOG (filechooser)->vbox;
  gtk_widget_set_name (dialog_vbox1, "dialog_vbox1");
  gtk_widget_show (dialog_vbox1);

  dialog_action_area1 = GTK_DIALOG (filechooser)->action_area;
  gtk_widget_set_name (dialog_action_area1, "dialog_action_area1");
  gtk_widget_show (dialog_action_area1);
  gtk_button_box_set_layout (GTK_BUTTON_BOX (dialog_action_area1), GTK_BUTTONBOX_END);

  button1 = gtk_button_new_from_stock ("gtk-cancel");
  gtk_widget_set_name (button1, "button1");
  gtk_widget_show (button1);
  gtk_dialog_add_action_widget (GTK_DIALOG (filechooser), button1, GTK_RESPONSE_CANCEL);
  GTK_WIDGET_SET_FLAGS (button1, GTK_CAN_DEFAULT);

  button2 = gtk_button_new_from_stock ("gtk-open");
  gtk_widget_set_name (button2, "button2");
  gtk_widget_show (button2);
  gtk_dialog_add_action_widget (GTK_DIALOG (filechooser), button2, GTK_RESPONSE_OK);
  GTK_WIDGET_SET_FLAGS (button2, GTK_CAN_DEFAULT);

  /* Store pointers to all widgets, for use by lookup_widget(). */
  GLADE_HOOKUP_OBJECT_NO_REF (filechooser, filechooser, "filechooser");
  GLADE_HOOKUP_OBJECT_NO_REF (filechooser, dialog_vbox1, "dialog_vbox1");
  GLADE_HOOKUP_OBJECT_NO_REF (filechooser, dialog_action_area1, "dialog_action_area1");
  GLADE_HOOKUP_OBJECT (filechooser, button1, "button1");
  GLADE_HOOKUP_OBJECT (filechooser, button2, "button2");

  gtk_widget_grab_default (button2);
  return filechooser;
}

GtkWidget*
create_configuration_window (void)
{
  GtkWidget *configuration_window;
  GtkWidget *vbox2;
  GtkWidget *notebook2;
  GtkWidget *confw_keys_vbox;
  GtkWidget *hbox2;
  GtkWidget *confw_BM_REPOSITORY_ROOT_label;
  GtkWidget *confw_BM_REPOSITORY_ROOT_entry;
  GtkWidget *confw_BM_REPOSITORY_ROOT_button;
  GtkWidget *hbox3;
  GtkWidget *confw_BM_REPOSITORY_SECURE_label;
  GtkWidget *confw_BM_REPOSITORY_SECURE_yes;
  GSList *confw_BM_REPOSITORY_SECURE_yes_group = NULL;
  GtkWidget *confw_BM_REPOSITORY_SECURE_no;
  GtkWidget *hbox4;
  GtkWidget *confw_BM_REPOSITORY_USER_label;
  GtkWidget *confw_BM_REPOSITORY_USER_entry;
  GtkWidget *hbox5;
  GtkWidget *confw_BM_REPOSITORY_GROUP_label;
  GtkWidget *confw_BM_REPOSITORY_GROUP_entry;
  GtkWidget *repository_note;
  GtkWidget *empty_notebook_page;
  GtkWidget *archives_note;
  GtkWidget *method_note;
  GtkWidget *upload_note;
  GtkWidget *burning_note;
  GtkWidget *common_note;
  GtkWidget *vbox3;
  GtkWidget *vbox4;
  GtkWidget *confw_file_label;
  GtkWidget *hbox1;
  GtkWidget *confw_file_entry;
  GtkWidget *confw_file_button;
  GtkWidget *hbuttonbox1;
  GtkWidget *confw_load_button;
  GtkWidget *confw_reset_button;
  GtkWidget *confw_save_button;
  GtkTooltips *tooltips;

  tooltips = gtk_tooltips_new ();

  configuration_window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_widget_set_name (configuration_window, "configuration_window");
  gtk_container_set_border_width (GTK_CONTAINER (configuration_window), 1);
  gtk_window_set_title (GTK_WINDOW (configuration_window), _("Backup Manager - Configuration Editor"));
  gtk_window_set_default_size (GTK_WINDOW (configuration_window), 250, 250);

  vbox2 = gtk_vbox_new (FALSE, 0);
  gtk_widget_set_name (vbox2, "vbox2");
  gtk_widget_show (vbox2);
  gtk_container_add (GTK_CONTAINER (configuration_window), vbox2);

  notebook2 = gtk_notebook_new ();
  gtk_widget_set_name (notebook2, "notebook2");
  gtk_widget_show (notebook2);
  gtk_box_pack_start (GTK_BOX (vbox2), notebook2, TRUE, TRUE, 0);

  confw_keys_vbox = gtk_vbox_new (FALSE, 0);
  gtk_widget_set_name (confw_keys_vbox, "confw_keys_vbox");
  gtk_widget_show (confw_keys_vbox);
  gtk_container_add (GTK_CONTAINER (notebook2), confw_keys_vbox);

  hbox2 = gtk_hbox_new (FALSE, 0);
  gtk_widget_set_name (hbox2, "hbox2");
  gtk_widget_show (hbox2);
  gtk_box_pack_start (GTK_BOX (confw_keys_vbox), hbox2, TRUE, TRUE, 0);

  confw_BM_REPOSITORY_ROOT_label = gtk_label_new (_("Repository: "));
  gtk_widget_set_name (confw_BM_REPOSITORY_ROOT_label, "confw_BM_REPOSITORY_ROOT_label");
  gtk_widget_show (confw_BM_REPOSITORY_ROOT_label);
  gtk_box_pack_start (GTK_BOX (hbox2), confw_BM_REPOSITORY_ROOT_label, FALSE, FALSE, 0);
  gtk_widget_set_size_request (confw_BM_REPOSITORY_ROOT_label, 82, -1);

  confw_BM_REPOSITORY_ROOT_entry = gtk_entry_new ();
  gtk_widget_set_name (confw_BM_REPOSITORY_ROOT_entry, "confw_BM_REPOSITORY_ROOT_entry");
  gtk_widget_show (confw_BM_REPOSITORY_ROOT_entry);
  gtk_box_pack_start (GTK_BOX (hbox2), confw_BM_REPOSITORY_ROOT_entry, TRUE, TRUE, 0);
  gtk_tooltips_set_tip (tooltips, confw_BM_REPOSITORY_ROOT_entry, _("Choose the location where the archives will be stored."), NULL);

  confw_BM_REPOSITORY_ROOT_button = gtk_button_new_with_mnemonic (_("..."));
  gtk_widget_set_name (confw_BM_REPOSITORY_ROOT_button, "confw_BM_REPOSITORY_ROOT_button");
  gtk_widget_show (confw_BM_REPOSITORY_ROOT_button);
  gtk_box_pack_start (GTK_BOX (hbox2), confw_BM_REPOSITORY_ROOT_button, FALSE, FALSE, 0);

  hbox3 = gtk_hbox_new (FALSE, 0);
  gtk_widget_set_name (hbox3, "hbox3");
  gtk_widget_show (hbox3);
  gtk_box_pack_start (GTK_BOX (confw_keys_vbox), hbox3, TRUE, TRUE, 0);

  confw_BM_REPOSITORY_SECURE_label = gtk_label_new (_("Secure mode: "));
  gtk_widget_set_name (confw_BM_REPOSITORY_SECURE_label, "confw_BM_REPOSITORY_SECURE_label");
  gtk_widget_show (confw_BM_REPOSITORY_SECURE_label);
  gtk_box_pack_start (GTK_BOX (hbox3), confw_BM_REPOSITORY_SECURE_label, FALSE, FALSE, 0);

  confw_BM_REPOSITORY_SECURE_yes = gtk_radio_button_new_with_mnemonic (NULL, _("Enabled"));
  gtk_widget_set_name (confw_BM_REPOSITORY_SECURE_yes, "confw_BM_REPOSITORY_SECURE_yes");
  gtk_widget_show (confw_BM_REPOSITORY_SECURE_yes);
  gtk_box_pack_start (GTK_BOX (hbox3), confw_BM_REPOSITORY_SECURE_yes, FALSE, FALSE, 0);
  gtk_tooltips_set_tip (tooltips, confw_BM_REPOSITORY_SECURE_yes, _("Enable this option if you want the repository to be only accessible for a given user and group."), NULL);
  gtk_radio_button_set_group (GTK_RADIO_BUTTON (confw_BM_REPOSITORY_SECURE_yes), confw_BM_REPOSITORY_SECURE_yes_group);
  confw_BM_REPOSITORY_SECURE_yes_group = gtk_radio_button_get_group (GTK_RADIO_BUTTON (confw_BM_REPOSITORY_SECURE_yes));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (confw_BM_REPOSITORY_SECURE_yes), TRUE);

  confw_BM_REPOSITORY_SECURE_no = gtk_radio_button_new_with_mnemonic (NULL, _("Disabled"));
  gtk_widget_set_name (confw_BM_REPOSITORY_SECURE_no, "confw_BM_REPOSITORY_SECURE_no");
  gtk_widget_show (confw_BM_REPOSITORY_SECURE_no);
  gtk_box_pack_start (GTK_BOX (hbox3), confw_BM_REPOSITORY_SECURE_no, FALSE, FALSE, 0);
  gtk_tooltips_set_tip (tooltips, confw_BM_REPOSITORY_SECURE_no, _("Disable this option if you don't want the repository to be only accessible for a given user and group."), NULL);
  gtk_radio_button_set_group (GTK_RADIO_BUTTON (confw_BM_REPOSITORY_SECURE_no), confw_BM_REPOSITORY_SECURE_yes_group);
  confw_BM_REPOSITORY_SECURE_yes_group = gtk_radio_button_get_group (GTK_RADIO_BUTTON (confw_BM_REPOSITORY_SECURE_no));

  hbox4 = gtk_hbox_new (FALSE, 0);
  gtk_widget_set_name (hbox4, "hbox4");
  gtk_widget_show (hbox4);
  gtk_box_pack_start (GTK_BOX (confw_keys_vbox), hbox4, TRUE, TRUE, 0);

  confw_BM_REPOSITORY_USER_label = gtk_label_new (_("User: "));
  gtk_widget_set_name (confw_BM_REPOSITORY_USER_label, "confw_BM_REPOSITORY_USER_label");
  gtk_widget_show (confw_BM_REPOSITORY_USER_label);
  gtk_box_pack_start (GTK_BOX (hbox4), confw_BM_REPOSITORY_USER_label, FALSE, FALSE, 0);
  gtk_widget_set_size_request (confw_BM_REPOSITORY_USER_label, 82, -1);

  confw_BM_REPOSITORY_USER_entry = gtk_entry_new ();
  gtk_widget_set_name (confw_BM_REPOSITORY_USER_entry, "confw_BM_REPOSITORY_USER_entry");
  gtk_widget_show (confw_BM_REPOSITORY_USER_entry);
  gtk_box_pack_start (GTK_BOX (hbox4), confw_BM_REPOSITORY_USER_entry, TRUE, TRUE, 0);
  gtk_tooltips_set_tip (tooltips, confw_BM_REPOSITORY_USER_entry, _("Enter the user who will own the repository."), NULL);

  hbox5 = gtk_hbox_new (FALSE, 0);
  gtk_widget_set_name (hbox5, "hbox5");
  gtk_widget_show (hbox5);
  gtk_box_pack_start (GTK_BOX (confw_keys_vbox), hbox5, TRUE, TRUE, 0);

  confw_BM_REPOSITORY_GROUP_label = gtk_label_new (_("Group: "));
  gtk_widget_set_name (confw_BM_REPOSITORY_GROUP_label, "confw_BM_REPOSITORY_GROUP_label");
  gtk_widget_show (confw_BM_REPOSITORY_GROUP_label);
  gtk_box_pack_start (GTK_BOX (hbox5), confw_BM_REPOSITORY_GROUP_label, FALSE, FALSE, 0);
  gtk_widget_set_size_request (confw_BM_REPOSITORY_GROUP_label, 82, -1);

  confw_BM_REPOSITORY_GROUP_entry = gtk_entry_new ();
  gtk_widget_set_name (confw_BM_REPOSITORY_GROUP_entry, "confw_BM_REPOSITORY_GROUP_entry");
  gtk_widget_show (confw_BM_REPOSITORY_GROUP_entry);
  gtk_box_pack_start (GTK_BOX (hbox5), confw_BM_REPOSITORY_GROUP_entry, TRUE, TRUE, 0);
  gtk_tooltips_set_tip (tooltips, confw_BM_REPOSITORY_GROUP_entry, _("Enter the group who will own the repository."), NULL);

  repository_note = gtk_label_new (_("Repository"));
  gtk_widget_set_name (repository_note, "repository_note");
  gtk_widget_show (repository_note);
  gtk_notebook_set_tab_label (GTK_NOTEBOOK (notebook2), gtk_notebook_get_nth_page (GTK_NOTEBOOK (notebook2), 0), repository_note);

  empty_notebook_page = gtk_vbox_new (FALSE, 0);
  gtk_widget_show (empty_notebook_page);
  gtk_container_add (GTK_CONTAINER (notebook2), empty_notebook_page);

  archives_note = gtk_label_new (_("Archives"));
  gtk_widget_set_name (archives_note, "archives_note");
  gtk_widget_show (archives_note);
  gtk_notebook_set_tab_label (GTK_NOTEBOOK (notebook2), gtk_notebook_get_nth_page (GTK_NOTEBOOK (notebook2), 1), archives_note);

  empty_notebook_page = gtk_vbox_new (FALSE, 0);
  gtk_widget_show (empty_notebook_page);
  gtk_container_add (GTK_CONTAINER (notebook2), empty_notebook_page);

  method_note = gtk_label_new (_("Method"));
  gtk_widget_set_name (method_note, "method_note");
  gtk_widget_show (method_note);
  gtk_notebook_set_tab_label (GTK_NOTEBOOK (notebook2), gtk_notebook_get_nth_page (GTK_NOTEBOOK (notebook2), 2), method_note);

  empty_notebook_page = gtk_vbox_new (FALSE, 0);
  gtk_widget_show (empty_notebook_page);
  gtk_container_add (GTK_CONTAINER (notebook2), empty_notebook_page);

  upload_note = gtk_label_new (_("Upload"));
  gtk_widget_set_name (upload_note, "upload_note");
  gtk_widget_show (upload_note);
  gtk_notebook_set_tab_label (GTK_NOTEBOOK (notebook2), gtk_notebook_get_nth_page (GTK_NOTEBOOK (notebook2), 3), upload_note);

  empty_notebook_page = gtk_vbox_new (FALSE, 0);
  gtk_widget_show (empty_notebook_page);
  gtk_container_add (GTK_CONTAINER (notebook2), empty_notebook_page);

  burning_note = gtk_label_new (_("Burning"));
  gtk_widget_set_name (burning_note, "burning_note");
  gtk_widget_show (burning_note);
  gtk_notebook_set_tab_label (GTK_NOTEBOOK (notebook2), gtk_notebook_get_nth_page (GTK_NOTEBOOK (notebook2), 4), burning_note);

  empty_notebook_page = gtk_vbox_new (FALSE, 0);
  gtk_widget_show (empty_notebook_page);
  gtk_container_add (GTK_CONTAINER (notebook2), empty_notebook_page);

  common_note = gtk_label_new (_("Common"));
  gtk_widget_set_name (common_note, "common_note");
  gtk_widget_show (common_note);
  gtk_notebook_set_tab_label (GTK_NOTEBOOK (notebook2), gtk_notebook_get_nth_page (GTK_NOTEBOOK (notebook2), 5), common_note);

  vbox3 = gtk_vbox_new (FALSE, 0);
  gtk_widget_set_name (vbox3, "vbox3");
  gtk_widget_show (vbox3);
  gtk_box_pack_start (GTK_BOX (vbox2), vbox3, TRUE, TRUE, 0);

  vbox4 = gtk_vbox_new (FALSE, 0);
  gtk_widget_set_name (vbox4, "vbox4");
  gtk_widget_show (vbox4);
  gtk_box_pack_start (GTK_BOX (vbox3), vbox4, TRUE, TRUE, 0);

  confw_file_label = gtk_label_new (_("Configuration File:"));
  gtk_widget_set_name (confw_file_label, "confw_file_label");
  gtk_widget_show (confw_file_label);
  gtk_box_pack_start (GTK_BOX (vbox4), confw_file_label, FALSE, FALSE, 0);

  hbox1 = gtk_hbox_new (FALSE, 0);
  gtk_widget_set_name (hbox1, "hbox1");
  gtk_widget_show (hbox1);
  gtk_box_pack_start (GTK_BOX (vbox4), hbox1, TRUE, TRUE, 0);

  confw_file_entry = gtk_entry_new ();
  gtk_widget_set_name (confw_file_entry, "confw_file_entry");
  gtk_widget_show (confw_file_entry);
  gtk_box_pack_start (GTK_BOX (hbox1), confw_file_entry, TRUE, TRUE, 0);
  gtk_tooltips_set_tip (tooltips, confw_file_entry, _("Configuration file to edit"), NULL);

  confw_file_button = gtk_button_new_with_mnemonic (_("..."));
  gtk_widget_set_name (confw_file_button, "confw_file_button");
  gtk_widget_show (confw_file_button);
  gtk_box_pack_end (GTK_BOX (hbox1), confw_file_button, FALSE, FALSE, 2);

  hbuttonbox1 = gtk_hbutton_box_new ();
  gtk_widget_set_name (hbuttonbox1, "hbuttonbox1");
  gtk_widget_show (hbuttonbox1);
  gtk_box_pack_start (GTK_BOX (vbox4), hbuttonbox1, TRUE, TRUE, 0);

  confw_load_button = gtk_button_new_with_mnemonic (_("Load"));
  gtk_widget_set_name (confw_load_button, "confw_load_button");
  gtk_widget_show (confw_load_button);
  gtk_container_add (GTK_CONTAINER (hbuttonbox1), confw_load_button);
  GTK_WIDGET_SET_FLAGS (confw_load_button, GTK_CAN_DEFAULT);
  gtk_tooltips_set_tip (tooltips, confw_load_button, _("Load an existing configuration file"), NULL);

  confw_reset_button = gtk_button_new_with_mnemonic (_("Reset"));
  gtk_widget_set_name (confw_reset_button, "confw_reset_button");
  gtk_widget_show (confw_reset_button);
  gtk_container_add (GTK_CONTAINER (hbuttonbox1), confw_reset_button);
  GTK_WIDGET_SET_FLAGS (confw_reset_button, GTK_CAN_DEFAULT);
  gtk_tooltips_set_tip (tooltips, confw_reset_button, _("Reset values from the configuration file"), NULL);

  confw_save_button = gtk_button_new_with_mnemonic (_("Save"));
  gtk_widget_set_name (confw_save_button, "confw_save_button");
  gtk_widget_show (confw_save_button);
  gtk_container_add (GTK_CONTAINER (hbuttonbox1), confw_save_button);
  GTK_WIDGET_SET_FLAGS (confw_save_button, GTK_CAN_DEFAULT);
  gtk_tooltips_set_tip (tooltips, confw_save_button, _("Save changes to the configuration file"), NULL);

  g_signal_connect ((gpointer) configuration_window, "destroy",
                    G_CALLBACK (on_configuration_window_destroy),
                    NULL);
  g_signal_connect ((gpointer) confw_BM_REPOSITORY_ROOT_button, "clicked",
                    G_CALLBACK (on_confw_BM_REPOSITORY_ROOT_button_clicked),
                    NULL);
  g_signal_connect ((gpointer) confw_BM_REPOSITORY_SECURE_yes, "toggled",
                    G_CALLBACK (on_confw_BM_REPOSITORY_SECURE_yes_toggled),
                    NULL);
  g_signal_connect ((gpointer) confw_BM_REPOSITORY_SECURE_no, "toggled",
                    G_CALLBACK (on_confw_BM_REPOSITORY_SECURE_no_toggled),
                    NULL);
  g_signal_connect ((gpointer) confw_load_button, "clicked",
                    G_CALLBACK (on_confw_load_button_clicked),
                    NULL);
  g_signal_connect ((gpointer) confw_reset_button, "clicked",
                    G_CALLBACK (on_confw_reset_button_clicked),
                    NULL);
  g_signal_connect ((gpointer) confw_save_button, "clicked",
                    G_CALLBACK (on_confw_save_button_clicked),
                    NULL);

  /* Store pointers to all widgets, for use by lookup_widget(). */
  GLADE_HOOKUP_OBJECT_NO_REF (configuration_window, configuration_window, "configuration_window");
  GLADE_HOOKUP_OBJECT (configuration_window, vbox2, "vbox2");
  GLADE_HOOKUP_OBJECT (configuration_window, notebook2, "notebook2");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_keys_vbox, "confw_keys_vbox");
  GLADE_HOOKUP_OBJECT (configuration_window, hbox2, "hbox2");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_BM_REPOSITORY_ROOT_label, "confw_BM_REPOSITORY_ROOT_label");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_BM_REPOSITORY_ROOT_entry, "confw_BM_REPOSITORY_ROOT_entry");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_BM_REPOSITORY_ROOT_button, "confw_BM_REPOSITORY_ROOT_button");
  GLADE_HOOKUP_OBJECT (configuration_window, hbox3, "hbox3");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_BM_REPOSITORY_SECURE_label, "confw_BM_REPOSITORY_SECURE_label");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_BM_REPOSITORY_SECURE_yes, "confw_BM_REPOSITORY_SECURE_yes");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_BM_REPOSITORY_SECURE_no, "confw_BM_REPOSITORY_SECURE_no");
  GLADE_HOOKUP_OBJECT (configuration_window, hbox4, "hbox4");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_BM_REPOSITORY_USER_label, "confw_BM_REPOSITORY_USER_label");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_BM_REPOSITORY_USER_entry, "confw_BM_REPOSITORY_USER_entry");
  GLADE_HOOKUP_OBJECT (configuration_window, hbox5, "hbox5");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_BM_REPOSITORY_GROUP_label, "confw_BM_REPOSITORY_GROUP_label");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_BM_REPOSITORY_GROUP_entry, "confw_BM_REPOSITORY_GROUP_entry");
  GLADE_HOOKUP_OBJECT (configuration_window, repository_note, "repository_note");
  GLADE_HOOKUP_OBJECT (configuration_window, archives_note, "archives_note");
  GLADE_HOOKUP_OBJECT (configuration_window, method_note, "method_note");
  GLADE_HOOKUP_OBJECT (configuration_window, upload_note, "upload_note");
  GLADE_HOOKUP_OBJECT (configuration_window, burning_note, "burning_note");
  GLADE_HOOKUP_OBJECT (configuration_window, common_note, "common_note");
  GLADE_HOOKUP_OBJECT (configuration_window, vbox3, "vbox3");
  GLADE_HOOKUP_OBJECT (configuration_window, vbox4, "vbox4");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_file_label, "confw_file_label");
  GLADE_HOOKUP_OBJECT (configuration_window, hbox1, "hbox1");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_file_entry, "confw_file_entry");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_file_button, "confw_file_button");
  GLADE_HOOKUP_OBJECT (configuration_window, hbuttonbox1, "hbuttonbox1");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_load_button, "confw_load_button");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_reset_button, "confw_reset_button");
  GLADE_HOOKUP_OBJECT (configuration_window, confw_save_button, "confw_save_button");
  GLADE_HOOKUP_OBJECT_NO_REF (configuration_window, tooltips, "tooltips");

  gtk_widget_grab_default (confw_load_button);
  return configuration_window;
}
