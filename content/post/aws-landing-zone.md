---
title: "Multi Accounts AWS Setups mit Landing Zone - für euch getestet."
author: "Soenke Ruempler"
date: 2018-08-01
---

> Was sind AWS Best Practises? Wie kann ich meine Workloads absichern? Wie kann ich Teams groesstmögliche Autonomie geben, waehrend nicht die Sicherheit/Einheitlichkeit leidet? Welches Grunddesign sollte ich in AWS verwenden?  Wie verwalte ich Benutzer und Zugriffsrechte? Wie geht AWS Multi Account?

Dies sind viele Fragen, die wir regelmäßig hören, gerade von Kunden, die neu auf AWS unterwegs sind, und sich im Zoo der ganzen Konzepte und Services zurechtfinden müssen.

Hier und da existieren Blog Posts zu Best Practises, auch von AWS selbst - manche aktuell, manche outdated - aber wäre es nicht toll, wenn es da etwas automatisertes gaebe, so dass man einen Quickstart hat und direkt mit der eigentlichen Arbeit starten kann?

Wir sehen häufig, dass aufgrund verschiedener Umstände das AWS Grundsetup dann in der AWS Web Console "geklickt" wird, d.h. manuell erstellt und damit wenig nachvollzielbar oder reproduzierbar ist. Weiterhin basiert dann das Einarbeiten von Good/Best Practises hauefig auf zufälligen Events, z. B. hat ein\*e Mitarbeiter\*in einen Blog Post gelesen, verlinkt den Artikel in den Dev-Chat nach dem Motto "man müsste mal". Gemacht wirds dann nicht, weil "keine Zeit" oder "nicht im Scope" oder der Aufwand zu groß sei. Oder es wird gemacht, aber dann wiederrum "geklickt", womit das Wissen dann häufig im Kopf der "Klicker\*innen" verbleibt.    

Bisher gab es für die Setups keine kodifizierte Lösung, doch mit AWS Landing Zone aendert sich dies: Landing Zone eine "AWS Solution", welche aktuelle Best Practises kodifiziert und automatisiert ausrollt. 

## Was verspricht Landing Zone?

 - Automatisiertes AWS Multi Account Setup
 - Grundlegende Sicherheitsrichtlinien
 - Kodifizierte Best Practises (inkl. Updates direkt von AWS) - z.B. automatisiertes CloudTrail Setup und VPC/Netzwerk-Design 
 - DevOps Best Practises: Infrastructure-as-Code durch kodifizierte Templates und Continous Delivery, wodurch auch eigene Erweiterungen global ausgerollt werden können.

 - Single Sign On und zentrale Verwaltung von Zugriffsrechten (optional)

## Der erste Eindruck

Während viele Blog Posts nur nochmal mehr oder weniger die News von AWS kopieren, haben wir Landing Zone direkt für euch ausprobiert.

### Die Installation

Hier wählt man einige Grundsetups aus. Die Initialisierung schreibt ein Config-Template nach in ein S3 Bucket. Dieses dient als Quelle fuer eine CodePipeline, die ebenfalls automatisch über das Initiation Template angelegt wird (Diese Config kann später angepassst werden.)

Das Grundsetup legt folgende Accounts an: 

TBS

### Einen neuen Account anlegen.

TBS

### Was uns gefällt:

 - Konsequenter Einsatz von CloudFormation StackSets zum Cross-Account Ausrollen von CloudFormation Stacks.
 - Configuration per Manifest:
 - Kodifizierung: Die gesamte Lösung ist durch Code dokumentiert und es gibt keine manuellen Schritte (Ausnahme: Das Umbiegen der CodePipeline auf etwas anderes als S3 als Quelle ist gerade ein geklickter Schritt)
 - Erweiterbarkeit: Landing Zone ist eine fundierte Basis fuer das Ausrollen z. B. von eigenen CloudFormation Stacks.
 - Best Practises direkt von AWS: Landing Zone wird laufend von AWS gepflegt und erweitert. 
 - Anwendung auf bestehende Setups: Grundlegend ist es moeglich, bestehende Multi-Account Setups auf AWS Landing Zone zu migrieren und somit die Vorteile auch fuer Bestandssetups zu geniessen.

### Was uns nicht so gut gefaellt:

 - Komplexität durch viele eingesetzte Services.
 - Nicht so richtig Open Source: Die Solution ist zwar öffentlich abrufbar, aber "versteckt". Sie kann aber trotzdem benutzt werden und unsere ersten Tests haben eine grundlegende "Production readiness" ergeben.

### Und die Kosten?

TBD

### Wie könnt ihr es selbst testen?

Ihr koennt AWS Landing Zone selbst testen. Wir empfehlen, erst in einem frisch angelegten Account mit einer neuen Organisation zu testen, damit ihr in der "Sandkiste" Erfahrungen sammeln koennt. 

Hier sind die Dokus von AWS:

 - TBD

superluminar ist AWS Consulting Partner und unterstützt euch gerne, euer neues oder bestehendes Multi-Account Setup mit AWS Landing Zone zu automatisieren oder zu optimieren. 

### Zusammenfassung und Ausblick

TBD Zusamenfassung

In folgenden Beiträgen wollen wir uns weitere Aspekte anschauen:

 - Wie funktioniert die eingebaute SSO Lösung? Was ist zu beachten?
 - Wie bekommt ihr eine bestehendes AWS Multi Account Setup in die Landing Zone?
 - Wie updated ihr Landing Zone bei neuen Releases? Was passiert bei einem Update?
 - Wie kann ich Landing Zone erweitern, zum Beispiel eigene CloudFormation Stacks global ueber alle Accounts ausrollen und aktuell halten?




 
