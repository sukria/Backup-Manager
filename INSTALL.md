Dependencies
------------

- If you want to enable the localisation, you need gettext.
- Perl is needed for FTP and SSH uploads.
- Everything else is written in Bash.


How to install backup-manager
-----------------------------

    sudo make install
    sudo cp /usr/share/backup-manager/backup-manager.conf.tpl /etc/backup-manager.conf

You can then edit `/etc/backup-manager.conf` to fit your needs.

Please refer to the wiki for details:
https://github.com/sukria/Backup-Manager/wiki


For Apple macOS with Fink
-------------------------

1) Install Fink.
   http://www.finkproject.org/

2) Download Backup-Manager:

    curl -L https://github.com/sukria/Backup-Manager/archive/0.7.15.zip > ~/Desktop/Backup-manager-0.7.15.zip
    cd ~/Desktop
    unzip backup-manager-0.7.15.zip
    cd Backup-Manager-0.7.15

3) Then "make install", and install the needed packages asked by Fink,
as all the needed packages are not installed with the basic Fink install.

    make install -e FINK=/sw

4) After complete install, copy, edit the `backup-manager.conf` file:

    cp /usr/share/backup-manager/backup-manager.conf.tpl /etc/backup-manager.conf
    vim /etc/backup-manager.conf

5) Then you can start Backup Manager with:

    env PATH=/sw/lib/coreutils/bin:$PATH backup-manager -v

6) Backup Manager is now installed in `/usr/share/backup-manager`.
