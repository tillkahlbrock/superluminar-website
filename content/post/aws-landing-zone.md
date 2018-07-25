Multi Accounts AWS Setups mit Landing Zone - fuer euch getestet.

AWS Multi Account Setups sind heutzutage der Standard fuer AWS Workloads. Die Vorteile liegen auf der Hand: 

 - groesstmoeg;lioche Autonomie fuer Produkteams
 - Abschottung ("compartmentalization" / "blast radius reduction") von Dev/Test/Prod Environments
 - Sicherheit: Auslagerung von zB Audit Logs
 - Grundlegende High Level Design Struktur

Auch wenn wir denken, dass die Vorteile hier stark ueberwiegen, kommt dieses Setup auch mit einigen Nachteilen:

 - Setup Aufwand fuer neue AWS Accounts
 - Sicherheits-Baseline fuer neue Accounts: zB die Einrichtung von Audit Logs und Compliance
 - Verwaltung von Zugriffsrechten / Verhinderung von "Account Sprawl"

Wie sehen regemaessig, dass diese Setups "geklickt" werden, d.h. wenig nachvollzielbar oder reproduzierbar sind und daher dann auch keine einheitliche Baseline mehr vorhanden ist.

Bisher gab es fuer die Setups keine "Infrastructure as Code" Loesung, doch mit AWS Landing Zone aendert sich dies. Landing Zone ist kein AWS Produkt, sondern eine sogennate "Solution", also ein Komglomeerat von zusammengestecken AWS Services, welches so etwas wie ein Produkt ergibt.

Was verspricht Landing Zone?

 - Einheitliches Setup
 - Single Sign On (optional)
 - einheitliches VPC Setup
 - Erweiterbarkeit durch Templates

Der erste Eindruck

Waehrend die bestehnden Blog Posts nur nochmal mehr oder weniger die News von AWS kopieren, haben wir Landing Zone direkt fuer euch ausprobiert.

Die Installation

Hier waehlt man einige Grundsetups aus. Die Initialisierung schreibt ein Config-Template nach in ein S3 Bucket. Dieses dient als Quelle fuer eine CodePipeline, die ebenfalls automatisch ueber das Initiation Template angelegt wird.

Diese Config kann spaeter angepassst werden.

Was uns gefaellt:

 - Konsequenter Einsatz von StackSets
 - Configuration per Manifest:

Was nicht so gut ist:

 - Komplexitaet durch viele eingesetzte Services. 

Ausblick

In folgenden Beitraegen wollen wir uns folgende Aspekte anschauen?

 - Wie bekommt ihr eine bestehende Organisation in die Landing Zone?
 - Wie update ich Landing Zone bei neuen Releases?
 - Wie kann ich Landing Zone erweitern, zum Beispiel eigene CloudFormation Stacks ausrollen?




 
