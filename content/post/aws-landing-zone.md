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

Die Installation erfolgt ueber ein CloudFormation template, das sogenannte Initiation Template

Hier wählt man einige Grundsetups aus.

Die Initialisierung schreibt ein Config-Template in ein S3 Bucket. Dieses dient als Quelle fuer eine CodePipeline, die ebenfalls automatisch über das Initiation Template angelegt wird.

Diese Config kann später angepassst werden und ist die "Single Source of Truth" fuer eure Landing Zone. Bei jeder Aenderung der Config laeuft die CodePipeline los und wendet die Aenderungen auf die Infrastruktur an. Neben dem Manifest sind auch CloudFormation Templates, z. B. fuer VPCs, Teil der Konfiguration (und koennen somit auch angepasst oder erweitert werden, wenn gewuenscht). 

Fuer den ersten Test empfehlen wir uebrigens, den Parameter`BuildLandingZone` auf False zu stellen, so dass nicht direkt die Pipeline "losrennt". So koennt ihr erst einmal die generierte Config inspizieren und ggf. noch anpassen, bevor es losgeht. Weiterhin solltet ihr `LockStackSetsExecutionRole` ggf. auch erst auf `false` setzen, denn sonst geht euch ggf. der direkte Zugriff auf die Sub-Accounts verloren. Spaeter ist es allerdings empfehlenswert, den Schalter auf `true` zu setzen, da hierdurch der Zugriff auf die Administroren-Rollen in Sub-Accounts auf die Landing Zone Resourcen beschraenkt wird.  

Das Grundsetup legt folgende Accounts an: 

 - Security:
 - Shared Services: Hier 
 - Logging: Hier landen zentral die Logs, z. B. CLoudTrail Audit Logs

![](https://d1.awsstatic.com/aws-answers/answers-images/landing-zone-implementation-architecture.6bfa23d88aef1ce97035d0333f476898739697b9.png)

### Account Baseline

In alle Accounts wird eine sogenallte Baseline provisioniert, diese enthaelt:

 - CloudTrail Setup (Audit Logs)
 - AWS Config und ein grundlegendes Ruleset ("Governance"), z. B. um einen Alert zu senden, wenn CloudTrail deaktiviert wurde
 - IAM Passwort Policy fuer IAM User
 - Cross Account Access vom Security Account
 - optional eine VPC laut Spezifikation
 - Notifications und Alarme, z. B. bei Stammbenutzer Logins. 

### Einen neuen Account anlegen.

TBS

## Was uns gefällt:

 - Kodifizierung: Die gesamte Lösung ist durch Code dokumentiert und es gibt keine manuellen Schritte (Ausnahme: Das Umbiegen der CodePipeline auf etwas anderes als S3 als Quelle ist gerade ein geklickter Schritt)
 - Erweiterbarkeit: Landing Zone ist eine fundierte Basis fuer das Ausrollen z. B. von eigenen CloudFormation Stacks.
 - Best Practises direkt von AWS: Hier hat AWS seine Erfahrungen kodifiziert 
 - Landing Zone wird laufend von AWS gepflegt und erweitert: So kam kurz nach unserem Test eine neue Version heraus, die 2 Bugs gefixt hat, auf die wir auch gestossen waren. Allerdings gibt es derzeit noch keine Notifications oder Changelogs.
 - Anwendung auf bestehende Setups: Grundlegend ist es moeglich, bestehende Multi-Account Setups auf AWS Landing Zone zu migrieren und somit die Vorteile auch fuer Bestandssetups zu geniessen.
 - Idempotenz: Wir hatten waehrend des Tests mehrere Fehler, wo es nicht weiterging, z. B. in der Pipeline, aber nach Fixen es Codes konnten wir die Pipeline neu anstossen und es ging weiter. Wir kamen also nie in eine Sackgasse. Dies ist wohl auch dem konsequenten Einsatz von Lambda und Step Functions zu danken, die eine gewisse Idempotenz erzwingen.
 - Konsequenter Einsatz von CloudFormation StackSets zum Cross-Account Ausrollen von CloudFormation Stacks.

## Was uns nicht so gut gefaellt:

Unter anderen sind uns bei ersten Testen folgende Dinge aufgefallen:

 - Komplexität durch viele eingesetzte Services: So ist es mitunter etwas muehsam, zu verstehen, was passiert. Ein beispielhafter Aufruf: Service Catalog triggert CloudFormation, welches Custom Resources hat, die Lambda triggern, welches eine Step Functions State Machine triggert, welche u.a. CloudFormation StackSets aufrufen.
 - Nicht so richtig Open Source: Die Solution ist zwar öffentlich abrufbar, aber "versteckt". Sie kann aber trotzdem benutzt werden und unsere ersten Tests haben eine grundlegende "Production readiness" ergeben.
 - Die AWS SSO Loesung ist gerade auf die `us-east-1` beschraenkt, benoetigt ein Active Directory und kann von Haus aus kein Multi-Factor-Auth. 

## Und die Kosten?

Landing Zone richtet standmaessig ein paar Resourcen ein, die Geld kosten. Die groessten Kostenverursacher sind:

 - Acitve Directory Service
 - AD Connector im Master Account
 - AWS Config Rules je 
 - EC2 Instanz als Remote Desktop Gateway/JumpHost, um zum Active Directory zu verbinden

## Wie könnt ihr es selbst testen?

Ihr koennt AWS Landing Zone selbst testen. Wir empfehlen, erst in einem frisch angelegten Account mit einer neuen Organisation zu testen, damit ihr in der "Sandkiste" Erfahrungen sammeln koennt. Landing Zone selbst kommt als CloudFormation template und ist somit "On-Click" installierbar:

[![Launch Stack](https://raw.githubusercontent.com/s0enke/cloudformation-templates/master/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=aws-landing-zone-initiation&templateURL=https://s3.amazonaws.com/solutions-reference/aws-landing-zone/latest/aws-landing-zone-initiation.template)

(ggf. muesst ihr noch die Region in der URL aendern, wenn ihr die Landing Zone nicht )

Hier sind die Dokus von AWS:

 - [AWS Landing Zone Developer Guide](https://s3.amazonaws.com/solutions-reference/aws-landing-zone/latest/aws-landing-zone-developer-guide.pdf)
 - [AWS Landing Zone Implementation Guide](https://s3.amazonaws.com/solutions-reference/aws-landing-zone/latest/aws-landing-zone-implementation-guide.pdf)
 - [AWS Landing Zone  User Guide](https://s3.amazonaws.com/solutions-reference/aws-landing-zone/latest/aws-landing-zone-user-guide.pdf)

superluminar ist AWS Consulting Partner und unterstützt euch gerne, euer neues oder bestehendes Multi-Account Setup mit AWS Landing Zone zu automatisieren oder zu optimieren. 

### Zusammenfassung und Ausblick

TBD Zusamenfassung

In folgenden Beiträgen wollen wir uns weitere Aspekte anschauen:

 - Wie funktioniert die eingebaute SSO Lösung? Was ist zu beachten?
 - Wie bekommt ihr eine bestehendes AWS Multi Account Setup in die Landing Zone?
 - Wie updated ihr Landing Zone bei neuen Releases? Was passiert bei einem Update?
 - Wie kann ich unterschiedliche Account-Settings fuer unterschiedliche Umgebungen (z. B. dev/prod) oder Teams/OUs erreichen?
 - Wie kann ich Landing Zone erweitern, zum Beispiel eigene CloudFormation Stacks global ueber alle Accounts ausrollen und aktuell halten?




 
