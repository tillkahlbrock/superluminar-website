---
title: "FaaS Plattform Binaris: unser Interview mit Avner Braverman"
author: "Hendric Rüsch"
date: 2018-04-23
---

Avner Braverman ist CEO des in Kalifornien und Israel ansässigen Unternehmens **Binaris**, das eine für niedrige, vorhersagbare Latenz optimierte FaaS-Plattform betreibt. Wir trafen sein Team auf der [JeffConf in Hamburg](https://hamburg.jeffconf.com).

**superluminar:** Hallo Avner, kannst du uns kurz etwas über dich erzählen? 

**Avner:**
Den größten Teil meiner bisherigen Laufbahn habe ich mich mit den Bereichen High-Performance-Computing und Betriebssysteme beschäftigt. Meine ersten Codezeilen schrieb ich in der zweiten Klasse, und mit verteilten Systemen kam ich während meiner Masterarbeit 1995 in Berührung. Im Laufe der Jahre hatte ich mehrfach das Glück, Teil großartiger Gründerteams zu sein. Das war etwa bei Unternehmen wie XIV der Fall, wo wir an verteilten Unternehmensspeicher-Systemen arbeiteten, oder bei ParallelM, wo wir leistungsstarke Batch Analytics Cluster entwickelt haben.

**superluminar:** Wie bist du auf das Thema Serverless gekommen?

**Avner:**
Ich hatte mich eine Weile mit Workloads bei der Ereignisverarbeitung befasst, aber den ersten echten Kontakt mit dem Thema Serverless hatte ich im Mai 2016 in New York bei der allerersten Serverless-Konferenz. Damals herrschte richtige Aufbruchsstimmung, und man hatte das Gefühl, Neuland zu betreten. Serverless war genau das, wonach mein Geschäftspartner Michael und ich gesucht hatten. Es zeigte sich außerdem, dass wir die richtigen Ideen hatten, um das Konzept „Serverless“ in vielversprechende Projekte zu übersetzen.

**superluminar:** Welche Probleme mit serverlosen Anwendungen möchtet ihr mit Binaris angehen und wo genau setzen eure Lösungen an?

**Avner:**
Serverless ist ein hervorragendes Tool für die Datenaufnahme und Cloud-Automatisierung. Mit dem entsprechenden Programmiermodell können Entwickler sehr viel schneller arbeiten, da sie sich auf Funktionen konzentrieren können und nicht über Server nachdenken müssen. Damit die zugrunde liegende Logik von Anwendungen serverlos laufen kann, müssen Plattformen allerdings drei wichtige Dinge in den Griff bekommen:
Die Performance muss deutlich gesteigert werden. Das Starten serverloser Funktionen dauert heute bis zu mehrere hundert Millisekunden. Und ich rede nicht von kalter Latenzzeit, sondern von einem optimalen Szenario. Insofern bietet sich Serverless zwar wunderbar für Automatisierung oder Hintergrundarbeiten an, ist aber für die Implementierung von APIs, mobilen oder Web-Backends und im Grunde allen interaktiven Mikroservices denkbar ungeeignet.
Die Kosten müssen deutlich sinken. Einmalige Automatisierungsfunktionen werden sich kaum nennenswert auf die Rechnung des Cloud-Anbieters auswirken. Jede echte Arbeitslast würde jedoch 5- bis 50-mal mehr kosten als die Ausführung derselben Funktionen auf eigenen Instanzen.
Anwendungssemantiken sind in den bestehenden Plattformen noch unterentwickelt. Die Beschreibung gängiger Abläufe wie Fan-out und Fan-in muss sich ebenso verbessern wie die Verwaltung der entsprechenden Laufzeitstatus. Auch die Art der Verwaltung von Versionierung und Konfiguration muss sich verbessern, und wir brauchen mehr Transparenz bei Protokollierung, Überwachung und Sicherheit. Alle diese Punkte müssen auf Plattformebene gelöst werden.

**superluminar:** Ihr seid zurzeit in einer Private-Alpha. Was können Leute erwarten, die sich registrieren?

**Avner:**
Da wir eine Plattform für serverlose Funktionen bieten, ist die Nutzererfahrung nicht sehr viel anders als bei AWS Lambda. Die Eigenschaften und APIs unserer Funktionen sind für die Anwendungsentwicklung ausgelegt. Sie vereinfachen das Schreiben, die Bereitstellung und das Aufrufen von Funktionen. Und natürlich ist alles sehr viel schneller. Wir rufen Funktionen in zwei bis drei Millisekunden auf. Die Bereitstellung und Aktualisierung von Code erfolgt innerhalb von Sekunden. Es ist einfach alles für effizienteres und einfacheres Arbeiten optimiert.

**superluminar:** Ihr betreibt auch die Benchmark „FaaSMark“. Kannst du uns etwas mehr dazu erzählen?

**Avner:**
FaaSMark wurde zum Messen von Aufrufzeiten auf FaaS-Plattformen entwickelt. Da gibt es verschiedene Metriken. Manche Leute konzentrieren die Diskussion auf die kalten Latenzzeiten. Andere messen Aufrufzeiten innerhalb eines einzelnen Knotens. In beiden Fällen wird nicht die Metrik gemessen, die für das Anwendungsdesign entscheidend ist: die aus der Perspektive des Aufrufenden gemessenen 99 % “warm invocation latency”.
Wenn man, was der Normalfall ist, viele Mikroservices hat, sollte die Latenz nicht nur niedrig, sondern unbedingt auch vorhersagbar sein. FaaSMark konzentriert sich genau auf diesen Punkt.

**superluminar:** Was würdest du jemandem empfehlen, für den oder die Serverless Computing neu ist?

**Avner:**
Suche nach der richtigen Kombination aus Plattform und Werkzeugen, um das höchstmögliche Arbeitstempo zu erreichen. Bei Serverless macht man schnell Fehler, doch die Fehler bleiben auf einen kleinen Teil deiner App beschränkt, nämlich auf eine Funktion. Das sollte man für die Optimierung der Entwicklungsgeschwindigkeit wirksam einsetzen.

**superluminar:** Bitte vervollständige den Satz: Im Jahr 2020 wird Serverless ... 

**Avner:**
... der Standard für das Erstellen von Apps sein.

**superluminar:** Vielen Dank, Avner! 

**Avner:**
Danke! Unter [binaris.com](https://binaris.com) könnt ihr mehr über uns erfahren und euch für die Alpha-Version registrieren.
