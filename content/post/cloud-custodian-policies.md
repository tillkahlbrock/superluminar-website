---
title: "Accountweit Richtlinien mit Cloud Custodian durchsetzen"
author: "Boris Erdmann"
date: 2018-05-21
---

Wer kennt dieses Durcheinander nicht: Man wollte etwas ausprobieren, es wurden Dinge geklickt und später nur halb wieder abgeräumt; trotz aller Bemühungen sich an die Vorschriften zu halten wurde an X Cloudformation-Templates eine bestimmte Einstellung vergessen; oder es haben sich nachträglich im Unternehmen eine oder mehrere Richtlinien geändert, und nun müsste jemand eigentlich mal alle Stacks aktualisieren… Schnell kann Account-Pflege in AWS zu einer lästigen Sache werden, bei der sich Entwickler über Vorgaben und Einschränkungen wundern oder Ops-Leute sich ärgern, dass sie Entwicklern hinterher wischen müssen.

## Cloud Custodian

Hier hilft [Cloud-Custodian](https://github.com/capitalone/cloud-custodian), ein Open-Source Tool von Capital One: Es wird benutzt, um bestimmte unerwünschte Zustände im AWS-Konto zu erkennen, darüber zu berichten oder den gewünschten Zustand (wieder) herzustellen.

Cloud Custodian ist mit
```
$ virtualenv --python=python2 custodian
$ source custodian/bin/activate
(custodian) $ pip install c7n
```
schnell installiert und organisiert sich in sogenannten Policies im YAML-Format:

```
$ cat policy.yml
policies:
- name: cloudwatch-set-log-group-retention
  description: set retention period to 14 days on all log groups
  resource: log-group
  actions:
    - type: retention
      days: 14
```

In diesem Beispiel wird die Vorhaltezeit für Log-Dateien auf allen CloudWatch LogGroups auf 14 Tage gesetzt. Mittels
```
$ custodian run --dryrun -s out policy.yaml
2018-05-21 10:33:06,370: custodian.policy:INFO policy: cloudwatch-set-log-group-retention resource:log-group region:eu-central-1 count:207 time:0.00
```
wird die voraussichtliche Wirkung dieser Policy überprüft und ohne `--dryrun` umgesetzt. Wie man an diesem Beispiel sehen kann, hat Custodian in unserem Konto 207 Ressourcen gefunden, für die es die Vorhaltezeit setzen würde. Wollte wir diese Aktion regelmäßig durchführen, so würden jedesmal alle 207 Ressourcen angefasst. Das kann bei größeren Mengen an Ressourcen schnell mal zu einer Rate-Limit Überschreitung bei AWS führen. Daher kann es sinnvoll sein, die Menge der Ressourcen mit Hilfe von Filtern einzuschränken:
```
$ cat policy.yml
policies:
- name: cloudwatch-set-log-group-retention
  resource: log-group
  filters:
    - type: value
      key: "retentionInDays"
      op: not-equal
      value: 14
  actions:
    - type: retention
      days: 14

$ custodian run --dryrun -s out policy.yaml 
2018-05-21 10:45:34,735: custodian.policy:INFO policy: cloudwatch-set-log-group-retention resource:log-group region:eu-central-1 count:0 time:0.00
```
Wir sehen also, dass in unserem Konto die Log-Retention schon überall richtig gesetzt war -- sehr gut.

Möchten wir diese Policy nun regelmäßig überprüfen und anwenden, so kann Custodian auch das für uns tun:
```
$ cat policy.yml
policies:
- name: cloudwatch-set-log-group-retention
  mode:
    type: periodic
    schedule: "rate(1 hour)"
    role: arn:aws:iam::{account_id}:role/cloud-custodian-execution
  resource: log-group
  filters:
    - type: value
      key: "retentionInDays"
      op: not-equal
      value: 14
  actions:
    - type: retention
      days: 14

$ custodian run -s out policy.yaml 
2018-05-03 14:19:54,523 - custodian.policy - INFO - Provisioning policy lambda cloudwatch-set-log-group-retention
```

In diesem Beispiel provisioniert Custodian für uns eine Lambda-Funktion, die einmal stündlich alle LogGroup Ressourcen prüft und gegebenenfalls auf 14 Tage korrigiert. Damit diese Funktion ihre Aufgabe auch verrichten kann, benötigt sie die notwendigen Berechtigungen (im Beispiel oben unter `role:` referenziert):
```
AWSTemplateFormatVersion: '2010-09-09'
Description: Cloud Custodian Pipeline and Execution Roles

Resources:
  CloudCustodianExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: "rol-cloud-custodian-execution"
      ManagedPolicyArns:
        - "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        - "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          Effect: Allow
          Principal:
            Service: lambda.amazonaws.com
          Action: sts:AssumeRole
```
Die Lambda-Funktion darf also ausgeführt werden, sowie Cloudwatch-Ressourcen lesen und verändern.

Wir haben nun an einem einfachen Beispiel gesehen, wie wir codifiziert, automatisiert und ereignis-basiert Richtlinien in unserem AWS Konto etablieren können. Dabei unterstützt Cloud Custodian:

- über 100 AWS Services und Ressourcen.
- über 300 Filter, die beliebig geschachtelt werden können
- über 400 Aktionen auf Services und Ressourcen
- die Integration mit AWS Config und Cloudwatch Events durch Lambda-Funktionen
- Die Anwendung bestimmter Regeln nur zu bestimmten Uhrzeiten
- strukturierte Log-Ausgaben nach S3 zur automatisierten Weiterverarbeitung

Damit wird Custodian zu einem mächtigen Werkzeug und wertvollen Helfer bei der Durchsetzung von Governance und Compliance-Richtlinien im AWS Konto: Tätigkeiten, die normalerweise schnell unüberschaubar und lästig werden, können nun relativ einfach codifiziert, automatisiert und ereignis-basiert bzw. periodisch durchgeführt werden; unerwünschte Zustände in der Konto-Konfiguration können erkannt und automatisch behoben oder gemeldet werden. Die nachträgliche Änderung von Richtlinien stellt kein Problem mehr da oder wird wesentlich vereinfacht. Durch die Codifizierung sind alle Richtlinien dokumentiert und können einfach kommuniziert werden.

Je nach Handhabung können bestimmte Vorfälle im Konto auch einfach nach dem Tag-Notify-Act Pattern behandelt werden: Somit kann ein definierter Prozess zur informierten Behandlung bestimmter Ereignisse etabliert werden, ohne dass Ressourcen z.B. direkt automatisch abgeschaltet oder zerstört werden müssten. Dies ermöglicht dann auch wieder das händische Klicken, ausprobieren und experimentieren im Account ohne die Angst im Nacken, dass die geklickten Ressourcen das Experiment nicht überleben.

In einigen Folge-Artikeln werden wir weitere Beispiele zur Anwendung und zur Integrationen von Cloud-Custodian beleuchten.
