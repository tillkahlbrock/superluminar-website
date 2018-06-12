---
title: "Lambda Orchestration mit Step Functions"
author: "Deniz Adrian"
date: 2018-06-12
---

Heute moechte ich Euch anhand eines praktischen Beispiels eine Einfuehrung in AWS Step Functions geben. Wir werden eine bestehende AWS Lambda Funktion in ihre einzelnen Bestandteile aufsplitten und in eine State Machine umbauen, die es uns ermoeglicht die Logik der Lambda Funktion ueber die Limits einer einzelnen Lambda Funktion hinaus zu skalieren.

Stellt Euch folgende Situation vor: Ihr habt unter Zuhilfenahme des Serverless Frameworks eine Lambda Funktion deployed, die per Cloudwatch Events 1x pro Tag aufgerufen wird, strukturierte Daten von einer externen Datenquelle liest, und zur Weiterverarbeitung nach S3 schreibt. Die externe Datenquelle stellt eine API mit Paginierung bereit und Euer Code sieht in etwa so aus:

```
data = []
offset = 0

while (True):
  rows = fetch_from_external_datasource(offset)
  if len(rows) == 0:
    break

  data.extend(rows)
  offset = offset + 25

persist_to_s3(data)
```

Nun stellt Ihr beim Betrachten der Metriken Eurer Funktion in AWS Cloudwatch fest, dass sich sowohl die Ausfuehrungszeiten, als auch der Speicherverbrauch der Lambda Funktion gefaehrlich nahe am Limit bewegen. Antwortet die externe Datenquelle einmal langsamer als erwartet, oder werden die zurueckgelieferten Daten deutlich mehr, wird Eure Funktion nach maximaler Ausfuehrungsdauer oder Erreichen des Speicher-Limits abgebrochen, ohne Ihren Job vollstaendig ausgefuehrt zu haben.

Hier kommen uns Step Functions zu Hilfe. Step Functions sind State Machines mit einer maximalen Ausfuehrungsdauer von N Jahren (https://docs.aws.amazon.com/step-functions/latest/dg/limits.html#service-limits-state-machine-executions). Indem wir unsere Logik also in kleinere Stuecke zerlegen, die jeweils die maximale Ausfuehrungsdauer einer Lambda Funktion ausnutzen koennen, haben wir eine Moeglichkeit unserem Import Job die benoetigte Zeit zur Verfuegung zu stellen.

## Aus eins mach viele!

Schauen wir uns den Code oben noch einmal in Ruhe an. Wir initialisieren eine leere Datenstruktur, die wir nach und nach mit Daten fuellen (`data = []`) und einen Iterator den wir fuer die Paginierung des externen Datensets benutzen (`offset = 0`). Wir extrahieren:

```
def initialize:
  data = []
  offset = 0
```

Als naechstes fragen wir unsere Datenquelle nach Daten in 25er Inkrementen an. Unsere Abbruchbedingung hier ist schlicht "bekommen wir noch Daten?". Wir extrahieren:

```
def fetch(offset):
  rows = fetch_from_external_datasource(offset)
  if len(rows) == 0:
    break

  data.extend(rows)
  offset = offset + 25

```

Zu guter Letzt schreiben wir die gesammelten Daten in unsere Persistenz (hier S3). Wir extrahieren:

```
def persist:
  persist_to_s3(data)
```

## Shared State

Beim Design unserer State-Machine muessen wir bedenken, dass wir zwischen Lambda Funktionen keinen echten Shared Memory zur Verfuegung haben. Allerdings bekommen wir durch Step Functions den aktuellen State in jede Funktion als ersten Parameter hereingereicht, und geben aus Funktionen neuen State zurueck. Somit koennen Funktionen den State Lesen und Schreiben!

### Migration: offset

Dies machen wir uns zu Nutzen, und migrieren als Erstes `offset` in den State. `initialize` wird zu:

```
def initialize(state):
  data = []
  state['offset'] = 0
  return state
```

Dieser "shared state" ist allerdings limitiert (https://docs.aws.amazon.com/step-functions/latest/dg/limits.html#service-limits-task-executions), und eignet sich somit nicht fuer das Durchreichen der von der externen Datenquelle gelieferten Nutzdaten (`data`). Doch hierzu spaeter mehr.

Unsere `fetch` Funktion bauen wir nun entsprechend um, so dass sie das nun im State gehaltene `offset` liest und nach jedem Aufruf inkrementiert:

```
def fetch(state):
  rows = fetch_from_external_datasource(state['offset'])
  if len(rows) == 0:
    break

  data.extend(rows)
  state['offset'] = state['offset'] + 25
```

### Migration: data

Bleibt die Frage wo wir nun die Nutzdaten speichern, wir haben ja keinen Shared Memory, und das State Objekt ist zu klein um alle Daten zu halten. Wir entscheiden uns hier als "Cache" eine Datei in S3 zu nutzen, die wir waehrend der Initialisierung (`initialize`) leeren, in unserem Interator (`fetch`) befuellen, und in unserer Persistierung (`persist`) an den Ziel-Ort verschieben. (Bei Bedarf koennen wir spaeter vor unseren `persist` Schritt auch noch Validierung oder Sanitisierung hinzufuegen). Wir aendern:

```
def initialize(state):
  empty_s3_cache()

  state['offset'] = 0
  return state
```

```
def fetch(state):
  data = read_from_s3_cache()

  rows = fetch_from_external_datasource(state['offset'])
  if len(rows) == 0:
    break

  data.extend(rows)
  write_to_s3_cache(data)
  state['offset'] = state['offset'] + 25
  return state
```

```
def persist(state):
  copy_s3_cache_to_final_location()
```  

## Flow und Abbruchbedingung

Wir haben nun die Einzelbestandteile unserer Job Logik in einzelne Funktionen ausgelagert. Als naechstes muessen wir die Orchestrierung in einer State Machine abbilden. Hierfuer brauchen wir zunaechst eine Abbruchbedingung. Schauen wir in unseren Code - bisher brechen wir simpel aus der Ausfuehrung aus, sobald wir keine Daten mehr von der externen Datenquelle erhalten (`if len(rows) == 0: break`). Wir behalten die Logik bei, schreiben aber das Ergebnis unseres "sind wir schon fertig?" Checks in den State, damit unsere State Machine sich um den Abbruch kuemmern kann:

```
def initialize(state):
  empty_s3_cache()

  state['continue'] = True
  state['offset'] = 0
  return state
```

```
def fetch(state):
  data = read_from_s3_cache()

  rows = fetch_from_external_datasource(state['offset'])
  if len(rows) == 0:
    state['continue'] = False

  data.extend(rows)
  write_to_s3_cache(data)
  state['offset'] = state['offset'] + 25
  return state
```

Mit Hilfe des serverless Plugins `serverless-step-functions` koennen wir unsere State-Machine direkt in unserer `serverless.yml` definieren. Wir sitzen nun auf allen Bestandteilen um die finale State Machine zusammenstecken zu koennen. Wir haben unsere einzelnen Funktionen (`initialize`, `fetch`, `persist`), unseren Iterator (`offset`) und eine Abbruchbedingung (`continue`) im State. Fuer den Abbruch benutzen wir eine der Step Functions Primitiven (`Choice`) und pruefen auf unsere Abbruchbedingung `continue`. Unsere fertige State Machine sieht danach so aus:

```
stateMachines:
  fetchDataFromExternalDatasource:
    definition:
      StartAt: Initialize
      States:
        Initialize:
          Type: Task
          Resource: arn:aws:lambda:......
        Fetch:
          Type: Task
          Resource: arn:aws:lambda:......
        PersistOrContinue:
          Type: Choice
          Choices:
          - Variable: "$.continue"
            BooleanEquals: true
            Next: Fetch
          - Variable: "$.continue"
            BooleanEquals: false
            Next: Persist
        Persist:
          Type: Task
          Resource: arn:aws:lambda:......
```

Zusammenfassung: Step Functions eignet sich hervorragend, um komplexere oder laenger laufende Applikationen mit Hilfe von Lambda zu orchestrieren, jedoch auch fuer eine Vielzahl weiterer Anwendungsfaelle. Habt Ihr selber schon mit Step Functions experimentiert, oder benutzt Ihr Step Functions bereits in Produktion? Lasst uns gerne per Kommentar wissen wie Eure Erfahrungen sind!
