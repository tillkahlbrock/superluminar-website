---
title: "Multi Accounts AWS Setups mit Landing Zone - fuer euch getestet."
author: "Soenke Ruempler"
date: 2018-08-01
---

AWS Multi Account Setups sind heutzutage der Standard fuer AWS Workloads. Die Vorteile liegen auf der Hand: 

 - groesstmoeglioche Autonomie fuer Produkteams
 - Abschottung ("compartmentalization" / "blast radius reduction") von Dev/Test/Prod Environments
 - Sicherheit: Auslagerung von zB CloudTrail Audit Logs in Extra Accounts
 - Grundlegende High Level Design Struktur


Wie sehen regemaessig, dass diese Setups "geklickt" werden, d.h. wenig nachvollzielbar oder reproduzierbar sind und daher dann auch keine einheitliche Baseline mehr vorhanden ist.

Bisher gab es fuer die Setups keine kodi Loesung, doch mit AWS Landing Zone aendert sich dies. Landing Zone ist kein AWS Produkt, sondern eine sogennate "Solution", also ein Komglomeerat von zusammengestecken AWS Services, welches so etwas wie ein Produkt ergibt.

## Was verspricht Landing Zone?

 - Einheitliches vollautomatisertes AWS Sub-Account Setup
 - Kodifizierte Best Practises (inkl. Updates direkt von AWS) - zB automatisiertes CloudTrail Setup
 - Erweiterbarkeit durch Templates
 - kodiziertes globales Management von Org Units und Services Control Policies in AWS Organizations
 - Single Sign On (optional)

## Der erste Eindruck

Waehrend viele Blog Posts nur nochmal mehr oder weniger die News von AWS kopieren, haben wir Landing Zone direkt fuer euch ausprobiert.

### Die Installation

Hier waehlt man einige Grundsetups aus. Die Initialisierung schreibt ein Config-Template nach in ein S3 Bucket. Dieses dient als Quelle fuer eine CodePipeline, die ebenfalls automatisch ueber das Initiation Template angelegt wird (Diese Config kann spaeter angepassst werden.)

Das Grundsetup legt folgende Accounts an: 






### Einen neuen Account anlegen.

### Was uns gefaellt:

 - Konsequenter Einsatz von CloudFormation StackSets zum Cross-Account Ausrollen von CloudFormation Stacks.
 - Configuration per Manifest:
 - Kodifizierung: Die gesamte Loesung ist durch Code dokumentiert und es gibt keine manuellen Schritte (Ausnahme: Das Umbiegen der CodePipeline auf etwas anderes als S3 als Quelle ist gerade ein geklickter Schritt)
 - Erweiterbarkeit: Landing Zone ist eine fundierte Basis fuer das Ausrollen z. B. von eigenen CloudFormation Stacks.
 - Best Practises direkt von AWS

Was nicht so gut ist:

 - Komplexitaet durch viele eingesetzte Services.
 - Nicht so richtig Open Source.  


### Und die Kosten?



### Wie koennt ihr es selbst testen?

superluminar ist AWS Consulting Partner und unterstuetzt euch gerne, euer neues oder bestehendes Multi-Account Setup mit AWS Landing Zone zu automatisieren oder zu optimieren. 

### Ausblick

In folgenden Beitraegen wollen wir uns folgende Aspekte anschauen:

 - Wie bekommt ihr eine bestehendes AWS Multi Account Setup in die Landing Zone?
 - Wie update ich Landing Zone bei neuen Releases?
 - Wie kann ich Landing Zone erweitern, zum Beispiel eigene CloudFormation Stacks global ueber alle Accounts ausrollen und aktuell halten?




 
