---
title: "AWS Landing Zone erweitern: Ein Beispiel aus der Praxis"
author: "Soenke Ruempler"
date: 2018-08-03
---

Nachdem wir [einen grundlegenden Blick auf AWS Landing Zone]({{< ref "aws-landing-zone.md" >}}) geworfen haben, und wie es bei Deployments von Enterprise AWS Setups hilft, wollen wir euch heute ein Beispiel liefern, wie ihr Landing Zone erweitern koennt.

In diesem Tutorial wollen wir ein Problem aus der realen Welt loesen: Manche Resourcen muessen pro AWS Account und/oder Region einmal erstellt werden, um dann weitere Funktionalitaet zu ermoeglichen.

Ein Beispiel ist das Logging des AWS API Gateways Dienstes: Man muss je AWS Account einmalig eine IAM Rolle anlegen und pro Region diese am API Gateway Dienst konfigurieren, so dass dieser dann Logs und Metriken nach CloudWatch schreiben kann. Das ist gerade zum Debugging von Serverless Anwendungen sehr wichtig, aber nicht gerade intuitiv ([Set up API Logging in API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html)).

Waere es nicht gut, wenn solche grundlegenden Einstellungen direkt fuer jeden AWS Account in eurer Organisation vorkonfiguriert waeren, ohne manuelle Schritte, oder "Howto" Wiki Seiten?

AWS Landing Zone bietet genau hierfuer grundlegende Funktionilitaet, um eigene AWS Resourcen oder Einstellungen ueber Sub-Accounts und Regionen hinweg zu verteilen. Damit kann einmal aufgebautes zentrales Wissen kodifiziert und dann automatisch verteilt werden: Dev-Teams koennen schneller mit der eigentlichen Arbeit anfangen, ohne sich langwieriges Grundsetup muehsam zu erarbeiten.

Zurueck zum Beispiel. Fuer ein grundlegendes Setup des API Gateways braucht ihr neben einem eingerichteten AWS Landing Zone Setup zwei Dinge:

 - Eine IAM Rolle, die global ausgerollt wird - und nicht je Region - da IAM ein globaler Dienst ist. Hierfuer nehmen wir die CloudFormation Resource `AWS::IAM::Role`
 - Die regionale Grundkonfiguration des API Gateways Dienstes, damit der Dienst Logs und Metriken zu CloudWatch schreiben kann. Dafuer dient der Resource `AWS::ApiGateway::Account
`.

Beginnen wir mit der globalen IAM Rolle, die einmal pro AWS Account (aber nicht je Region) vorhanden sein muss. Dafuer definiert ihr in eurem Manifest `manifest.yaml` eurer Landing Zone Konfiguration:

```yaml
  - name: APIGatewayCloudWatchRole
    baseline_products:
      - AWS-Landing-Zone-Account-Vending-Machine
    template_file: templates/superluminar/apigw-cloudwatch-role.template
    deploy_method: stack_set
```

Im Manifest ist das CloudFormation Template `templates/superluminar/apigw-cloudwatch-role.template` referenziert. Dieses beschreibt die globale IAM Rolle fuer den API Gateway Dienst:

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

Sobald ihr diese Aenderung in unsere Landing Zone Konfiguration eingespielt habt, startet die CodePipeline und erstellt jetzt per CloudFormation StackSets in jedem Sub-Account einen neuen CloudFormation Stack aus dem Template oben:

{{< figure src="/img/aws-landing-zone/lz-stacksets.png" title="CloudFormation StackSet mit Stack Instance je Sub Account">}}

Nachdem die IAM Rolle in jedem von Landing Zone verwalteten AWS Account ausgerollt wurde, muesst ihr sie noch jeweils auch dem API Gateway Service bekannt machen, so dass er diese Rolle nutzt. Das kann ueber folgendes CloudFormation Template passieren:

```yaml
AWSTemplateFormatVersion: 2010-09-09

Resources:
  ApiGwAccount:
    Type: AWS::ApiGateway::Account
    Properties:
      CloudWatchRoleArn: !Sub "arn:aws:iam::${AWS::AccountId}:role/AmazonAPIGatewayPushToCloudWatch"
```
In diesem Template referenziert ihr die IAM Rolle, die ihr im Schritt zuvor angelegt habt.

Auch dieses Template muesst ihr im Landing Zone Manifest referenzieren und als eigene Baseline spezifizieren:

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

In diesem Fall wird pro AWS Account ein CloudFormation Stack in der Region `eu-central-1` ausgerollt. Ab jetzt koennen dort API Gateways Logs an CloudWatch senden.

## Wie gehen Updates?

Ab und zu muesst ihr ggf. ein CloudFormation Template updaten. Hier ist nichts besonderes zu beachten: Aenderungen einchecken und die CodePipeline verteilt die Aenderungen per CloudFormation StackSets.

Auch Aenderungen am Manifest werden automatisch ausgerollt. Beispielsweise koenntet ihr die Grundkonfiugration aus `APIGatewayAccountSetup` auch noch in der London Region `eu-west-2` ausrollen. Dafuer erweitert ihr die Liste der Regionen:

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

## Und loeschen?   

Durch das Loeschen des Codes einer Baseline Resource im Manifest werden auch die entsprechenden CloudFormation Stacks geloescht.

Ein Test mit Loeschen von einzelnen Regionen aus der Liste in einer Baseline hat bei uns allerdings ergeben, dass diese bestehen bleibt. Die Vermutung ist, das das Loeschen einer Region bei der Zustandskonvergierung noch nicht in Landing Zone implentniert ist implementiert ist.

## Fazit

AWS Landing Zone bietet eine solide Grundlage, um Organisationsweit sogenannte Baselines, also Grundlegende Setups, die jw AWS Account gleich sein sollen, zentral zu pflegen und auszurollen. Damit ist es moeglich, dass sich im Unternehmen bezaehrte Good/Best Practises einfach kodifizieren lassen und somit Wissensinseln vermeiden.