---
title: "AWS Landing Zone erweitern: Ein Beispiel aus der Praxis"
author: "Soenke Ruempler"
date: 2018-08-14
---

Nachdem wir [einen grundlegenden Blick auf AWS Landing Zone]({{< ref "aws-landing-zone.md" >}}) geworfen haben, und wie es bei Deployments von Enterprise AWS Setups hilft, wollen wir euch heute ein Beispiel liefern, wie ihr Landing Zone erweitern könnt.

In diesem Tutorial wollen wir ein Problem aus der realen Welt lösen: Manche Ressourcen müssen pro AWS Account und/oder Region einmal erstellt werden, um dann weitere Funktionalität zu ermöglichen.

Ein Beispiel ist das Logging des AWS API Gateways Dienstes: Man muss je AWS Account einmalig eine IAM Rolle anlegen und pro Region diese am API Gateway Dienst konfigurieren, so dass dieser dann Logs und Metriken nach CloudWatch schreiben kann. Das ist gerade zum Debugging von Serverless Anwendungen sehr wichtig, aber nicht gerade intuitiv ([Set up API Logging in API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html)).

Wäre es nicht gut, wenn solche grundlegenden Einstellungen direkt für jeden AWS Account in eurer Organisation vorkonfiguriert wären, ohne manuelle Schritte, oder "Howto" Wiki Seiten?

AWS Landing Zone bietet genau hierfür grundlegende Funktionalität, um eigene AWS Ressourcen oder Einstellungen über Sub-Accounts und Regionen hinweg zu verteilen. Damit kann einmal aufgebautes zentrales Wissen kodifiziert und dann automatisch verteilt werden: Dev-Teams können schneller mit der eigentlichen Arbeit anfangen, ohne sich langwieriges Grundsetup mühsam zu erarbeiten.

Zurück zum Beispiel: Für ein grundlegendes Setup des API Gateways braucht ihr neben einem eingerichteten AWS Landing Zone Setup zwei Dinge:

 - Eine IAM Rolle, die global ausgerollt wird - und nicht je Region - da IAM ein globaler Dienst ist. Hierfür nehmen wir die CloudFormation Ressource `AWS::IAM::Role`
 - Die regionale Grundkonfiguration des API Gateways Dienstes, damit der Dienst Logs und Metriken zu CloudWatch schreiben kann. Dafür dient die Cloudformation Ressource `AWS::ApiGateway::Account
`.

Beginnen wir mit der globalen IAM Rolle, die einmal pro AWS Account (aber nicht je Region) vorhanden sein muss. Dafür definiert ihr in eurem Manifest `manifest.yaml` eurer Landing Zone Konfiguration:

```yaml
  - name: APIGatewayCloudWatchRole
    baseline_products:
      - AWS-Landing-Zone-Account-Vending-Machine
    template_file: templates/superluminar/apigw-cloudwatch-role.template
    deploy_method: stack_set
```

Im Manifest ist das CloudFormation Template `templates/superluminar/apigw-cloudwatch-role.template` referenziert. Dieses beschreibt die globale IAM Rolle für den API Gateway Dienst:

```yaml
AWSTemplateFormatVersion: 2010-09-09

Resources:
  ApiGwIamRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: AmazonAPIGatewayPushToCloudWatch
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Principal:
              Service: apigateway.amazonaws.com
            Action: sts:AssumeRole
```

Sobald ihr diese Änderung in unsere Landing Zone Konfiguration eingespielt habt, startet die CodePipeline und erstellt jetzt per CloudFormation StackSets in jedem Sub-Account einen neuen CloudFormation Stack aus dem Template oben:

{{< figure src="/img/aws-landing-zone/lz-stacksets.png" title="CloudFormation StackSet mit Stack Instance je Sub Account">}}

Nachdem die IAM Rolle in jedem von Landing Zone verwalteten AWS Account ausgerollt wurde, müsst ihr sie noch jeweils auch dem API Gateway Service bekannt machen, so dass er diese Rolle nutzt. Das kann über folgendes CloudFormation Template passieren:

```yaml
AWSTemplateFormatVersion: 2010-09-09

Resources:
  ApiGwAccount:
    Type: AWS::ApiGateway::Account
    Properties:
      CloudWatchRoleArn: !Sub "arn:aws:iam::${AWS::AccountId}:role/AmazonAPIGatewayPushToCloudWatch"
```
In diesem Template referenziert ihr die IAM Rolle, die ihr im Schritt zuvor angelegt habt.

Auch dieses Template müsst ihr im Landing Zone Manifest referenzieren und als eigene Baseline spezifizieren:

```yaml
  - name: APIGatewayAccountSetup
    baseline_products:
      - AWS-Landing-Zone-Account-Vending-Machine
    depends_on:
      - APIGatewayCloudWatchRole
    template_file: templates/superluminar/apigw-account-setup.template
    deploy_method: stack_set
    regions:
      - eu-central-1
```

In diesem Fall wird pro AWS Account ein CloudFormation Stack in der Region `eu-central-1` ausgerollt. Ab jetzt können dort API Gateways Logs an CloudWatch senden.

## Wie gehen Updates?

Ab und zu müsst ihr ggf. ein CloudFormation Template updaten. Hier ist nichts besonderes zu beachten: Änderungen einchecken und die CodePipeline verteilt die Änderungen per CloudFormation StackSets.

Auch Änderungen am Manifest werden automatisch ausgerollt. Beispielsweise könntet ihr die Grundkonfiguration aus `APIGatewayAccountSetup` auch noch in der London Region `eu-west-2` ausrollen. Dafür erweitert ihr die Liste der Regionen:

```yaml
  - name: APIGatewayAccountSetup
    baseline_products:
      - AWS-Landing-Zone-Account-Vending-Machine
    depends_on:
      - APIGatewayCloudWatchRole
    template_file: templates/superluminar/apigw-account-setup.template
    deploy_method: stack_set
    regions:
      - eu-central-1
      - eu-west-2
```

Das Ergebnis ist, dass der Stack jetzt sowohl in `eu-central-1` als auch neu in `eu-west-2` ausgerollt wird:

{{< figure src="/img/aws-landing-zone/stack-sets-2-regions.png" title="CloudFormation StackSet mit Stack Instance je Sub Account in 2 Regionen">}}

## Und Löschen?   

Durch das Löschen des Codes einer Baseline Ressource im Manifest werden auch die entsprechenden CloudFormation Stacks gelöscht.

Ein Test mit Löschen von einzelnen Regionen aus der Liste in einer Baseline hat bei uns allerdings ergeben, dass diese bestehen bleibt. Die Vermutung ist, dass das Löschen einer Region bei der Zustands-Konvergierung noch nicht in Landing Zone implementiert ist.

## Fazit

AWS Landing Zone bietet eine solide Grundlage, um organisationsweit sogenannte Baselines, also grundlegende Setups, die in jedem AWS Sub-Account gleich sein sollen, zentral zu pflegen und auszurollen. Damit wird es möglich, dass sich im Unternehmen bewährte Good/Best Practises einfach kodifizieren und somit Wissensinseln vermeiden lassen.