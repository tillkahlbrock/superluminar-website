---
title: Erweiterung von CloudFormation durch Custom Resources
author: Jan Brauer
date: 2018-08-21
---

# Erweiterung von CloudFormation durch Custom Resources

[Inspiration](https://aws.amazon.com/de/blogs/mt/multi-account-strategy-using-aws-cloudformation-custom-resources-to-create-amazon-route-53-resources-in-another-account/)

## Custom Resources

Eine Custom Resource ist ein Erweiterungspunkt für CloudFormation, der es Templates ermöglicht beliebigen Code auszuführen.
CloudFormation bietet dazu zwei Möglichkeiten:

1. den Aufruf einer AWS Lambda Funktion
2. die Benachrichtigung eines AWS SNS-Topics

Beispielhaft wollen wir uns das Aufrufen einer Lambda-Funktion genauer ansehen.
Der Ablauf ist wie folgt:

1. CloudFormation ruft unsere Lambda-Funktion mit einer Nachricht auf.
2. Die Funktion reagiert auf die Nachricht und verrichtet ihre Arbeit.
3. Je nach Erfolg schickt sie eine Nachricht mit **SUCCESS** oder **FAILED** an eine S3-URL, die sie der eingegangenen Nachricht aus Schritt 1 entnommen hat.
4. CloudFormation markiert die Ressource als erfolgreich oder fehlerhaft erstellt.
5. Gemäß dem Ergebnis aus 4 geht der CloudFormation-Stack in einen neuen Zustand über.

## Erzeugen eines Stacks

Was beim Erzeugen eines Stacks passiert, wollen wir uns im Detail hier anschauen.

Zunächst definieren wir unser Template.

```
Resources:
  MyCustomResource:
    Type: Custom::MyResource
    Properties:
      ServiceToken: <ARN of Lambda func>
      Foo: Bar
      List:
        - 1
        - 2
        - 3
```

Der `Type` muss mit "Custom::" beginnen, der Rest kann beliebig gewählt werden. Das `ServiceToken` ist die ARN einer Lambda-Funktion. Alle weiteren Parameter werden unter dem Schlüssel `ResourceProperties` in der Nachricht an die Lambda-Funktion übermittelt.

Die Nachricht die an unsere Funktion gesendet wird sieht dann so aus:

```
{
   "RequestType" : "Create",
   "ResponseURL" : "http://pre-signed-S3-url-for-response",
   "StackId" : "arn:aws:cloudformation:us-west-2:EXAMPLE/stack-name/guid",
   "RequestId" : "unique id for this create request",
   "ResourceType" : "Custom::MyResource",
   "LogicalResourceId" : "MyCustomResource",
   "ResourceProperties" : {
      "Foo" : "Bar",
      "List" : [ "1", "2", "3" ]
   }
}
```

Der Lebenszyklus einer CloudFormation Resource besteht aus drei Phasen: **Create**, **Update** und **Delete**. Diese steht im Feld `RequestType`.
Die Funktion kann jetzt die Parameter aus `ResourceProperties` auslesen und damit eine Resource erstellen. Ist sie mit der Bearbeitung fertig, muss sie CloudFormation über das Ergebnis benachrichtigen.

Dazu muss sie folgende Payload an die `ResponseURL` schicken:

```
{
   "Status" : "SUCCESS",
   "PhysicalResourceId" : "MyCustomResourceId",
   "StackId" : "arn:aws:cloudformation:us-west-2:EXAMPLE:stack/stack-name/guid",
   "RequestId" : "unique id for this create request",
   "LogicalResourceId" : "MyCustomResource",
   "Data" : {
      "SomeKey" : "Use Fn::GetAtt to access this via CloudFormation",
      "OutputName2" : "Value2",
   }
}
```

Der Status kann **SUCCESS** oder **FAILED** sein. Die `PhysicalResourceId` muss ein eindeutiger, stabiler Bezeichner sein. Felder unterhalb `Data` können im aufrufenden Template weiterverarbeitet werden. Ändert sich die PhysicalRedourceId geht CloudFormation von einem Replacement aus. Die alte Resource wird dann gelöscht.

