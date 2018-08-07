---
title: "AWS Landing Zone erweitern: Ein Beispiel aus der Praxis"
author: "Soenke Ruempler"
date: 2018-08-03
---
In diesem Tutorial wollen wir ein Problem aus der realen Welt loesen: Manche Resourcen muessten pro AWS Account und/oder Region einmal erstellt werden, um dann weitere Funktionalitaet zu ermoeglichen.

Ein Beispiel ist das Logging des AWS API Gateways Dienstes. Man muss je AWS Account einmalig eine IAM Rolle anlegen und pro Region diese am API Gateway Dienst konfigurieren, so dass dieser dann Logs und Metriken nach CloudWatch schreiben kann. Das ist gerade zum Debugging von Serverless Anwendungen sehr wichtig, aber nicht gerade intuitiv.

Waere es nicht gut, wenn solche grundlegenden Einstellungen direkt fuer jeden AWS Account in eurer Organisation vorkonfiguriert waeren, ohne manuelle Schritte, oder "Howto" Wiki Seiten?

AWS Landing Zone bietet genau hierfuer grundlegende Funktionilitaet, um eigene eigene Resources oder Einstellungen ueber Sub-Accounts und Regionen hinweg zu verteilen. Damit kann einmal aufgebautes zentrales Wissen kodifiziert und dann automatisch verteilt werden. Dev-Teams koennen schneller mit der eigentlichen Arbeit anfangen, ohne sich langwieriges Grundsetup muehsam zu erarbeiten.

Zurueck zum Beispiel. Fuer unser grundlegendes Setup des API Gateways unsere zwei Dinge:

 - Eine IAM Rolle, die global ausgerollt wird - und nicht je Region - da IAM ein globaler Dienst ist. Hierfuer nehmen wir die CloudFormation Resource `AWS::IAM::Role`
 - Die regionale Grundkonfiguration des API Gateways Dienstes, damit der Dienst Logs und Metriken zu CloudWatch schreiben kann. Dafuer dient der Resource `AWS::ApiGateway::Account
`.

Beginnen wir mit der globalen IAM Rolle, die einmal pro Account (aber nicht je Region) vorhanden sein muss. Dafuer definieren wir in unserem Manifest `manifest.yaml` unserer Landing Zone Konfiguration:

```yaml
  - name: APIGatewayCloudWatchRole
    baseline_products:
      - AWS-Landing-Zone-Account-Vending-Machine
    template_file: templates/superluminar/apigw-cloudwatch-role.template
    deploy_method: stack_set
    regions:
      - eu-west-1 # specify only one region since the template provisions global IAM resources
```
Im Beipiel haben wir als Region `eu-west-1` als arbitraere Region ausgewaehlt, weil CloudFormation immer eine Region braucht, auch wenn es globale Resourcen provisioniert. Im Manifest ist das Template `templates/superluminar/apigw-cloudwatch-role.template` referenziert. Dieses beschreibt die globale IAM Rolle fuer den API Gateway Dienst:

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

Haben wir diese Aenderung in unsere Landing Zone Konfiguration eingespielt, so startet die CodePipeline und erstellt jetzt per CloudFormation StackSets in jedem Sub-Account einen neuen CloudFormation Stack aus dem Template oben:

{{< figure src="/img/aws-landing-zone/lz-stacksets.png" title="CloudFormation StackSet mit Stack Instance je Sub Account">}}

Nachdem die IAM Rolle in jedem von Landing Zone verwalteten AWS Account ausregollt wurde, muessen wir sie noch dem API Gateway Service bekannt machen, so dass er diese nutzt. Das kann ueber folgendes CloudFormation Template passieren:

```yaml
AWSTemplateFormatVersion: 2010-09-09

Resources:
  ApiGwAccount:
    Type: AWS::ApiGateway::Account
    Properties:
      CloudWatchRoleArn: !Sub "arn:aws:iam::${AWS::AccountId}:role/AmazonAPIGatewayPushToCloudWatch"
```
Hier ist die Besonderheit

Auch dieses Template muesst ihr im Landing Zone Manifest spezifizieren:

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

Ab und zu muesst ihr ggf. ein CloudFormation Template updaten. Hier ist nichts besonderes zu beachten. Aenderungen einchecken und die CodePipeline verteilt die Aenderungen (per CloudFormation StackSets).

Auch Aenderungen am Manifest werden automatisch ausgerollt. Beispielsweise koenntet 

## Und loeschen?   

## Interna

Intern funktioniert es uebrigens so, dass in der Konfiguration im Template `aws-landing-zone-configuration/templates/aws_baseline/aws-landing-zone-avm.template.j2` eine Schleife ueber die `baseline_resources` im Manifest iteriert wird und darueber festgelegt wird, welche Stack Sets im CloudFormation Template fuer die Account Vending Machine, welche die verwalteten Sub-Accounts provisioniert, landen.

Hier der Prozess im Einzelnen:

 1. Aenderung der Config
 1. Trigger der Landing Zone CodePipeline
 1. CodeBuild Step rendert die Jinja (`j2`)Templates.
 'StackSetEnableSuperluminarRules':
     'DependsOn':
     - 'Organizations'
     - 'DetachSCP'
     - 'StackSetEnableConfig'
     'Type': 'Custom::StackInstance'
     'Properties':
       'StackSetName': 'AWS-Landing-Zone-Baseline-EnableSuperluminarRules'
       'TemplateURL': ''
       'AccountList':
       - 'Fn::GetAtt': 'Organizations.AccountId'
       'RegionList':
       - 'eu-west-1'
       'ServiceToken': 'arn:aws:lambda:eu-west-1:123456789012:function:LandingZone'
 4.  und gibt diese als Artefakt an die naechsten Pipeline Schritte weiter. 

<CloudFormation ScreenShot here>

Da reingerendert wird, fuehrt der Service Catalog jetzt 
