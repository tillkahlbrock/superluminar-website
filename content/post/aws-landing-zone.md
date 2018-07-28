---
title: "Multi Accounts AWS Setups mit Landing Zone - fuer euch getestet."
author: "Soenke Ruempler"
date: 2018-08-01
---

> Was sind AWS Best Practises? Wie kann ich meine Workloads absichern? Wie kann ich Teams groesstmoegliche Autonomie geben, waehrend nicht die Sicherheit/Einheitlichkeit leidet? Welches Grunddesign sollte ich in AWS verwenden?  Wie verwalte ich Benutzer und Zugriffsrechte? Wie geht AWS Multi Account?

Dies sind viele Fragen, die wir regelmaessig hoeren, gerade von Kunden, die neu auf AWS unterwegs sind, und sich im Zoo der ganzen Konzepte und Services zurechtfinden muessen.

Hier und da existieren Blog Posts zu Best Practises, auch von AWS selbst - manche aktuell, manche outdated - aber waere es nicht toll, wenn es da etwas automatisertes gaebe, so dass man einen Quickstart hat und direkt mit der eigentlichen Arbeit starten kann?

Wir sehen regemaessig, dass aufgrund verschiedener Umstaende das AWS Grundsetup dann in der AWS Web Console "geklickt" wird, d.h. manuell erstellt und damit wenig nachvollzielbar oder reproduzierbar ist. Weiterhin basiert dann das Einarbeiten von Good/Best Practises hauefig auf zufaelligen Events, z. B. hat ein\*e Mitarbeiter\*in einen Blog Post gelesen, verlinkt den Artikel in den Dev-Chat nach dem Motto "man muesste mal". Gemacht wirds dann nicht, weil "keine Zeit" oder "nicht im Scope" oder der Aufwand zu gross ist. Oder es wird gemacht, aber dann wiederrum "geklickt", womit das Wissen dann haeufig im Kopf der "Klicker\*innen" bleiben.    

Bisher gab es fuer die Setups keine kodifizierte Loesung, doch mit AWS Landing Zone aendert sich dies: Landing Zone eine "AWS Solution", welche aktuelle Best Practises kodifiziert und automatisiert ausrollt. 

## Was verspricht Landing Zone?

 - Automatisiertes AWS Multi Account Setup
 - Grundlegende Sicherheitsrichtlinien
 - Kodifizierte Best Practises (inkl. Updates direkt von AWS) - zB automatisiertes CloudTrail Setup und VPC/Netzwerk-Design 
 - DevOps Best Practises: Infrastructure-as-Code durch kodifizierte Templates und Continous Delivery, wodurch auch eigene Erweiterungen global ausgerollt werden koennen.

 - Single Sign On und zentrale Verwaltung von Zugriffsrechten (optional)

## Der erste Eindruck

Waehrend viele Blog Posts nur nochmal mehr oder weniger die News von AWS kopieren, haben wir Landing Zone direkt fuer euch ausprobiert.

### Die Installation

Hier waehlt man einige Grundsetups aus. Die Initialisierung schreibt ein Config-Template nach in ein S3 Bucket. Dieses dient als Quelle fuer eine CodePipeline, die ebenfalls automatisch ueber das Initiation Template angelegt wird (Diese Config kann spaeter angepassst werden.)

Das Grundsetup legt folgende Accounts an: 

TBS

### Einen neuen Account anlegen.

TBS

### Was uns gefaellt:

 - Konsequenter Einsatz von CloudFormation StackSets zum Cross-Account Ausrollen von CloudFormation Stacks.
 - Configuration per Manifest:
 - Kodifizierung: Die gesamte Loesung ist durch Code dokumentiert und es gibt keine manuellen Schritte (Ausnahme: Das Umbiegen der CodePipeline auf etwas anderes als S3 als Quelle ist gerade ein geklickter Schritt)
 - Erweiterbarkeit: Landing Zone ist eine fundierte Basis fuer das Ausrollen z. B. von eigenen CloudFormation Stacks.
 - Best Practises direkt von AWS

Was nicht so gut ist:

 - Komplexitaet durch viele eingesetzte Services.
 - Nicht so richtig Open Source: Die Solution ist zwar oeffentlich abrufbar, aber "versteckt". Sie kann aber trotzdem benutzt werden und unsere ersten Tests haben eine grundlegende "Production readiness" ergeben.

### Und die Kosten?



### Wie koennt ihr es selbst testen?

superluminar ist AWS Consulting Partner und unterstuetzt euch gerne, euer neues oder bestehendes Multi-Account Setup mit AWS Landing Zone zu automatisieren oder zu optimieren. 

### Zusammenfassung und Ausblick

TBD Zusamenfassung

In folgenden Beitraegen wollen wir uns folgende Aspekte anschauen:

 - Wie funktioniert die eingebaute SSO Loesung? Was ist zu beachten?
 - Wie bekommt ihr eine bestehendes AWS Multi Account Setup in die Landing Zone?
 - Wie updated ihr Landing Zone bei neuen Releases? Was passiert bei einem Update?
 - Wie kann ich Landing Zone erweitern, zum Beispiel eigene CloudFormation Stacks global ueber alle Accounts ausrollen und aktuell halten?




 
