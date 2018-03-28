---
title: "Monitoring von Serverless Apps: unser Interview mit epsagon"
author: "Hendric Rüsch"
date: 2018-03-28
---

Nitzan Shapira ist Mit-Gründer von [epsagon](http://epsagon.com/). Das israelische Startup hat sich auf eine KI-basierte Lösung zur Überwachung serverloser Anwendungen spezialisiert. Wir trafen Nitzan bei der [JeffConf in Hamburg](https://hamburg.jeffconf.com).

**superluminar:** Hallo Nitzan, kannst du uns kurz etwas über dich erzählen? 

**Nitzan:** Ich bin 30 Jahre alt, komme aus Tel Aviv und habe Informatik studiert. In den letzten 12 Jahren war ich Software-Entwickler, habe in der Forschung gearbeitet und Teams im Bereich R&D geleitet. Ich war für Intel, die israelische Armee und ein Startup tätig.

**superluminar:** Wie bist du zu dem Thema Serverless gekommen?

**Nitzan:** Mein Geschäftspartner Ran hatte bereits Erfahrung als Entwickler für die Alexa-Plattform von Amazon gesammelt. Er kannte sich also mit Serverless Architekturen aus. Im letzten Jahr haben wir uns dann eingehend mit dem Serverless-Bereich beschäftigt. Wir haben beide viele Jahre Erfahrung mit Infrastrukturtechnologien, Cyber-Sicherheit und R&D. Es lag für uns also nahe, Probleme im Zusammenhang mit Cloud-Infrastrukturen und Serverless näher zu untersuchen.

**superluminar:** Was war die Initialzündung für die Gründung von epsagon?

**Nitzan:** Das war eher ein Prozess über mehrere Monate, in dem wir mit vielen Kunden (Serverless-Nutzern) gesprochen haben. Wir wollten verstehen, wo ihre Schmerzpunkte sind und wie sie mit ihnen umgehen. Nach vielen Gesprächen wurde uns klar, dass Serverless-User oft nicht verstehen, was in ihrer Produktionsumgebung passiert, weil Serverless Architekturen so komplex sind. Daraus ergeben sich etwa bei der Überwachung oder der Fehlerbehebung besondere Herausforderungen. Wir beschlossen also, nach Lösungen für diese Herausforderungen zu suchen.

**superluminar:** Welche Probleme bei der Überwachung von Serverless Anwendungen möchtet ihr mit epsagon angehen?

**Nitzan:** Das Hauptproblem liegt in der Natur von Serverless Apps. Da spielen viele Aspekte wie zum Beispiel Compute-Einheiten (etwa Funktionen), Cloud-Ressourcen und externe APIs, die von der Architektur verwendet werden, eine Rolle. Diese Architekturen sind hochgradig verteilt und ereignisgesteuert. Auch wenn man einzelne Funktionen analysieren kann, ist es daher sehr schwer, tiefe Einblicke in die End-to-End-Performance eines Systems zu erhalten oder Fehler zu beheben. Die entscheidende Aufgabe ist, alle diese asynchronen Ereignisse zu verknüpfen – und zwar automatisch.

**superluminar:** Übrigens haben wir Teilnehmer der JeffConf Hamburg befragt und das Ergebnis sieht vielversprechend für epsagon aus:  jeder zweite Teilnehmer wünscht sich mehr Skills rund ums Monitoring und rangiert beim Bedarf vor Security und Integrationen auf Platz 1.


**Nitzan:** Das überrascht mich nicht. Es entspricht genau unserem Fazit aus vielen Kundengesprächen. Und wenn wir heute mit neuen Kunden reden, bekommen wir das gleiche Feedback.


**superluminar:** Ihr habt als Startup im Stealth-Modus 4,1 Millionen US-Dollar an Beteiligungskapital beschafft. Das ist ziemlich beeindruckend. Uns würde interessieren, wie Investoren auf eure Pläne für Serverless Monitoring reagiert haben. Oder ging es ihnen nur um die KI, weil sie glauben, dass Serverless noch in einem frühen Stadium ist?


**Nitzan:** Es stimmt, dass Serverless ein neues Feld ist und in vielerlei Hinsicht noch am Anfang steht. Allerdings gibt es wichtige Akteure wie zum Beispiel Cloud-Anbieter, die das Thema mit aller Macht vorantreiben. Das gilt auch für innovative Unternehmen, die Serverless bereits in großem Umfang in geschäftskritischen Produktionssystemen einsetzen. Es ist zwar neu, aber bereits sehr präsent. Viele Kapitalgeber glauben, dass Serverless künftig der Weg ist, Applikationen in der Cloud zu entwickeln und auszuführen. Das denke ich auch. Die KI war im Grunde nicht das Wichtigste. Der springende Punkt ist, dass Serverless sich auf breiter Basis durchsetzen wird und dass viele Leute schon jetzt Schwierigkeiten mit der Überwachung von Severless Apps haben. Es wird daher schon sehr bald ein ganz großes Thema sein.


**superluminar:** Kommen wir noch einmal auf euer Produkt zu sprechen: Was bietet eure private Beta-Version zurzeit und was steht als Nächstes an? 

**Nitzan:** Mithilfe unserer privaten Beta-Version, die bereits in Produktionsumgebungen läuft, können Nutzer verstehen, was in ihrer Produktionsumgebung passiert. Die Lösung identifiziert automatisch alle Elemente im System, einschließlich Funktionen, Datenbanken, Queues, Speicherelementen, verwendeten externen APIs und anderes mehr. Unsere Algorithmen bieten Visualisierungen der gesamten serverlosen Architektur und End-to-End-Verfolgung asynchroner Transaktionen. Dadurch können Fehler und Probleme sehr schnell behoben und die Leistung unterschiedlicher Flows im System analysiert werden. So lassen sich Engpässe wie zum Beispiel eine ineffiziente Lambda-Funktion oder eine langsame API, die gerade verwendet wird, erkennen. Wir arbeiten aktuell daran, immer mehr APIs in unser Supportangebot zu integrieren. Außerdem entwickeln wir unsere KI weiter, um Probleme zu ermitteln, die den Nutzern aufgrund fehlender Transparenz heute noch gar nicht bewusst sind. Wir unterstützen die wichtigsten Programmiersprachen, die derzeit im Bereich Serverless verwendet werden.

**superluminar:** Was würdest du jemandem empfehlen, für den oder die Serverless Computing neu ist?

**Nitzan:** Man sollte sich erst einmal ein paar Dokumentationen durchlesen. Vor allem sollte man aber einfach damit beginnen, Funktionen bereitzustellen und Cloud-Ressourcen und APIs zu nutzen. Ihr werdet erstaunt sein, wie einfach es ist!

**superluminar:** Bitte vervollständige den Satz: Im Jahr 2020 wird Serverless ... 

**Nitzan:** ... der Standard-Weg bei Entwicklung, Bereitstellung und Betrieb von Cloud-Anwendungen sein.

**superluminar:** Vielen Dank, Nitzan! Wir hoffen, dich bald mal wieder zu treffen.

**Nitzan:** Danke! Es war mir ein Vergnügen. Ich komme gerne wieder nach Hamburg! 
Ihr könnt uns jederzeit [kontaktieren](http://epsagon.com/). Alle Nachrichten werden beantwortet. Ich präsentiere gerne unsere Demo und erkläre offene Punkte.

