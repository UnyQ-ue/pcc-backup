Es gibt BackupHP und BackupNP.
HP wird auf dem Hauptplatz verwendet und NP auf dem Nebenplatz.

Die HP-Skripte sollten erst dann ausgeführt werden, nachdem die Prozesse auf dem NP beendet wurden, da sonst das Zipping nicht sauber durchgeführt werden kann.

Die Skripte werden nach C:\Scripts kopiert.

=============================================================
BACKUP-HP SETUP
=============================================================
1. Im Ordner backupHP befindet sich ein Unterordner namens backup, der alle Skripte zur Ausführung des Backup-Prozesses sowie die Konfigurationsdateien enthält.
Falls keine backup_config.json vorhanden ist, starte backup.exe, um eine Beispielkonfiguration zu erstellen, und passe diese anschließend an deine Anforderungen an.

2. Nun muss eine Aufgabe geplant werden, die zu einem bestimmten Zeitpunkt bzw. an einem bestimmten Tag (monatlich, täglich, wöchentlich) ausgeführt wird.
Im Ordner backupHP befindet sich die Datei task_config.ini.
Passe diese Datei entsprechend deinen Anforderungen an (achte darauf, dass der Backup-Task erst ausgeführt wird, nachdem die Prozesse auf dem NP beendet wurden).

3. Führe die setup.bat aus, um die Aufgaben entsprechend der konfigurierten Uhrzeit und dem gewählten Intervall einzurichten.

4. Öffne die Aufgabenplanung (Task Scheduler) und überprüfe, ob alles korrekt eingerichtet ist.
Du kannst die Aufgabe auch direkt im Task Scheduler ausführen, um sie zu testen.


=============================================================
BACKUP-NP SETUP
=============================================================
1. Im Ordner BackupNP befindet sich die Datei task_config.ini.
Hier kannst du das Intervall und die Uhrzeit festlegen, zu denen die Aufgaben ausgeführt werden sollen.

2. Nachdem du die Konfigurationsdatei angepasst hast, kannst du die setup.bat im Ordner BackupNP ausführen.
Anschließend kannst du die Aufgabe – wie bei HP – im Task Scheduler (Aufgabenplanung) testen.

