
## AWS Single Sign On

 - Integrierte Loesung 
 - Mappt Job Roles 
  (gehen auch custom roles?)
 - Kommt standardmaessig mit Active Directory
 - Mappt AD User / Gruppen auf Rollen in Sub-Accounts



## Vorteile

 - Funktioniert auf Anhieb
 - Wirkt von Aussen

## Nachteile

 - Umstaendliche Verwaltung per dauernd laufender Windows Instanz als Gateway zum Active Directory. Hier waere eine Integration der Userverwaltung in die AWS Console / APIs auf der Wunschliste, so dass man fuer alltaegliche Tasks gar nicht gegen das Active Directory verbinden muss.
 - Kein Multi Factor Auth 
 - CLI Access ist etwas umstaendlich