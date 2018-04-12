---
title: "Serverless Framework und Event-Gateway: Interview mit Philipp Müns"
author: "Hendric Rüsch"
date: 2018-04-12
---

**superluminar:** Moin Philipp, stell dich uns bitte in 1-2 Sätzen vor.

**Philipp:** Hallo zusammen! Ich bin [Philipp Müns](https://twitter.com/pmmuens), 29 Jahre alt und komme aus Paderborn. Derzeit arbeite ich als “Software Engineer” bei [Serverless, Inc.](https://serverless.com) wo ich mich primär um unsere Open Source Projekte wie z.B. das Serverless Framework sowie dessen Weiterentwicklung kümmere.

**Superluminar:** Wie bist du mit serverless, inc. in Verbindung gekommen und was machst du jetzt dort?

**Philipp:** Nach dem Studium der Informatik in Mannheim habe ich mich mit meinem ersten Unternehmen selbständig gemacht. Während der Arbeit an verschiedenen Softwareprojekten bei denen stets die neuesten Technologien eingesetzt wurden bin ich damals auf das JAWS Projekt, das gerade frisch gestartet wurde, aufmerksam geworden (JAWS wurde später in Serverless umbenannt).
Da ich für verschiedenste Prototypen JAWS benutzte und es Open Source Software war habe ich mich direkt an die Arbeit gemacht und durch unterschiedliche Codeanpassungen das Framework erweitert und stabilisiert. Als schließlich Serverless, Inc. aus diesem Projekt gegründet wurde stieg ich direkt als “Software Engineer” mit ein.

Neben der Arbeit an unseren Open Source Projekten kümmere ich mich außerdem um die Entwicklung verschiedener Prototypen, die die Zukunft unserer Projekte ebnen werden.

**Superluminar:** Kannst du eure Lösungen in ein paar Sätzen beschreiben? An welche Zielgruppe richtet ihr euch beim Framework?

**Philipp:** Das Serverless Framework ist ein CLI-Tool, das es ermöglicht Serverless Anwendungen mithilfe einer sogenannten serverless.yml Konfigurationsdatei zu beschreiben.
Die Beschreibung der anwendungsspezifischen Infrastrukturkomponenten und deren Zusammenspiel ist dabei stark abstrahiert um eine effektive Arbeitsweise zu ermöglichen.
Beim Deployment-Prozess wird diese Konfigurationsdatei vom Serverless Framework analysiert und in die entsprechenden Cloud-Provider spezifische API Befehle umgewandelt, sodass die serverless Anwendung schließlich in der ziel-Cloud aufgesetzt wird.

Das Serverless Framework bietet hierbei die Möglichkeit serverless Applikationen in verschiedene Clouds wie z.B. Google Cloud oder AWS aufzusetzen. Des Weiteren ist das Framework zu 100% durch Plugins erweiter- und modifizierbar, was ermöglicht die Funktionalität auf die eigenen Bedürfnisse anzupassen.

**superluminar:** ...und dann gibt es ja auch noch das Event-Gateway? Für wen ist es gedacht und was macht es? 

**Philipp:** Das Event Gateway ist unser zweites, großes Open Source Projekt das eine zentrale Rolle in modernen Serverless Projekten spielt.
Aktuell sind wir als Entwickler von serverless Anwendungen auf die Events der jeweiligen Cloud Provider angewiesen. So reagieren wir z.B. auf ein Event, dass ein Storage Bucket sendet wenn eine Datei in diesen geladen wurde. Diese Events sind oftmals Cloud Provider / Cloud-Service spezifisch. Unser Applikations-Workflow spielt sich somit in den Services des Cloud Providers ab. Eine Lösung in der wir eigene Events nutzen oder gar Cloud-übergreifende Applikationen implementieren können ist nur mit sehr viel Aufwand umsetzbar.
Das Event Gateway löst dieses Problem, indem es ermöglicht eigene Events zu definieren und Funktionen zu registrieren die aufgerufen werden, wann immer das entsprechende Event in das Event Gateway eingespeist wird.
Betrieben wird das Event Gateway als eigener Service (bei Bedarf auch on-prem) der einen L7 Proxy darstellt. Über zwei HTTP Endpunkte kann es konfiguriert werden und Events empfangen. 
Beim Eintreffen eines Events via HTTP werden automatisch die Daten geparst und die jeweiligen registrierten Funktionen in den entsprechenden Clouds aufgerufen.

**Superluminar:** Wir mögen den agnostischen Ansatz. Kannst du noch ein paar Sätze zu den Motiven sagen?

**Philipp:** Das initiale Motiv war es den sogenannten “Vendor Lock-in” zu reduzieren. Nutzer sollen sich beim Entwickeln ihrer Serverless-Applikation frei zwischen den Cloud Providern bewegen können ohne einen “All-In” Ansatz fahren zu müssen.
Dies führt uns auch direkt zum nächsten Motiv. Cloud Provider bieten heutzutage die unterschiedlichsten Services - von Datenbanken, bis hin zu Bilderkennung an. Beim Entwerfen der Systemarchitektur hat man dank des Event Gateways die Möglichkeit Multi-Cloud Applikationen zu designen, die verschiedene Services auf verschiedenen Clouds nutzen.
Dieser “Multi-Cloud” Ansatz schließt übrigens Legacy Systeme ein. Jede Software, die eine HTTP Library nutzen kann hat die Möglichkeit ein Event an das Event Gateway zu senden und kann somit in die Serverless Welt eingebunden werden!

**Superluminar:** Simon Wardley hat auf der JeffConf Hamburg einmal mehr die Einsparpotenziale durch Serverless betont.  Habt ihr Erfahrungsberichte von euren Usern?

**Philipp:** Einer unserer Nutzer ist Coca Cola. Haupteinsatzgebiet von Serverless Architekturen bei Coca Cola ist der Betrieb von Marketing-Websites bzw. entsprechender Web-Apps. Ein bekannter Anwendungsfall ist der bei dem der Käufer einer Coca Cola Flasche durch einen Code im Deckel an einem Gewinnspiel teilnehmen kann. Diese Anwendungen werden sowohl durch Social Media Kampagnen als auch traditionelle Fernseh-, Radio- oder Printwerbung  vermarktet.
Ein Serverless Ansatz bietet hier dank der Autoskalierungs-Charakteristik enorme Vorteile, da der Traffic sehr schwer abschätzbar ist. Zum einen läuft die Anwendung nicht Gefahr durch zu viele User-Anfragen unerreichbar zu sein, zum anderen entfällt kostspieliges Over-Provisioning. Des Weiteren muss keine Zeit in das Implementieren von Auto-Scaling oder Failover Strategien investiert werden.

Ein anderer, auf den ersten Blick vielleicht eher untypische Einsatzbereich ist der eines Nutzers der eine Serverless-Architektur betreibt um kostengünstig alte SQL Datenbanken in neue NoSQL Datenbanken zu migrieren. Die Daten werden aus der alten Datenbank in batches ausgelesen und per Lambda Funktionen in das neue Datenbankschema transformiert. Neben dem Nutzen dieser Strategie zur Datenmigration kann der Nutzer ebenfalls relativ einfach Teile seiner Produktivdatenbank in eine neue, leere Datenbank importieren um schnell neue Produktfeatures testen und evaluieren zu können.

**Superluminar:** Was sollte sich ein CTO oder Tech Team-Lead der bisher mit Serverless noch keine Berührungspunkte hatte unbedingt anschauen? Und was sollte sich ein Junior-Dev anschauen?

**Philipp:** Wir bei Serverless, Inc. haben mitte letzten Jahres angefangen einen Serverless-Guide zu erstellen, um es Einsteigern einfacher zu machen in der Serverless-Welt Fuß zu fassen.
Hauptaugenmerk beim Erstellen des Guides war es, dass dieser neutral unterschiedliche Technologien und Anbieter darstellt und diskutiert. Der Leser soll sich mithilfe des Guides sein eigenes Bild vom Status Quo machen und anhand der Daten die für sich sinnvolle Technologien auswählen können.

Der Guide ist Open Source und sowohl für CTO / Tech Team-Leads als auch Junior-Devs geeignet:

https://serverless.github.io/guide/

https://github.com/serverless/guide

Ansonsten ist das Serverless Framework, was wir als Serverless, Inc. ins Leben gerufen haben ein guter Einstieg, um sich mit der Thematik als Entwickler vertraut zu machen. Wir betreuen neben dem Framework repository auch ein “examples” repository, in dem unterschiedliche Use-Cases dargestellt werden. Das Serverless Framework ist ebenfalls Open Source und kostenlos nutzbar:

https://github.com/serverless/serverless

https://github.com/serverless/examples

**Superluminar:** vervollständige den Satz: Serverless/FaaS wird 2020…

**Philipp:** ...omnipräsent sein, da es Nutzern ermöglicht sich auf die Wertschöpfung zu konzentrieren anstatt kostbare Zeit und Ressourcen in Infrastrukturmanagement und dessen Betrieb zu investieren.

Zum Abschluss: auf der JeffConf Hamburg hielt Philipp einen sehenswerten Talk über das Event-Gateway:

{{< youtube h1PIqbi93eE >}}

 
