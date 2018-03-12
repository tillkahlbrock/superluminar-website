---
title: "Sechs Dinge, die euch das Leben mit AWS auf der Kommandozeile erleichtern"
author: "Soenke Ruempler"
date: 2018-03-10
---

Im Rahmen unserer [Coaching- und Beratungsdienstleistungen](/unser-angebot/) sowie unserer [Workshops](/serverless/) beobachten wir häufig wiederkehrende Zeitfresser oder umständliches Handling , wenn man mit der AWS CLI unterwegs ist. Hier wollen wir euch ein paar Tipps mitgeben, die die tägliche Arbeit erleichtern und euch einiges an Zeit sparen werden.

## Autovervollständigung der AWS CLI

Die AWS CLI hat eine eingebaute Autovervollständigung. Wie ihr sie einrichtet, erfahrt ihr in der [AWS Doku](https://docs.aws.amazon.com/cli/latest/userguide/cli-command-completion.html). Einmal eingerichtet, wundert ihr euch, wie ihr jemals ohne arbeiten konntet. 

## Idempotentes CloudFormation Stack Deployment Kommando "to rule them all"

Lange Zeit gab es kein eingebautes AWS CLI Kommando, welches es erlaubt, einen CloudFormation Stack entweder zu erstellen, wenn er noch nicht existiert, oder aber zu aktualisieren, wenn er denn schon existiert ("create or update").

Mit neueren AWS CLI Version geht das so:

```
aws cloudformation deploy \ 
    --stack-name <stack-name> \ 
    --template-file my-template.yml \
    --parameter-overrides Foo=Bar Spam=Eggs \
    --no-fail-on-empty-changeset 
```

Dieses Kommando ist idempotent, d.h. egal von welchem vorherigen Zustand (Stack schon da oder nicht) oder wie oft es ausgeführt wird, es kommt mit den gleichen Eingabeparametern immer das gleiche Ergebnis raus.

## Wer bin ich?

Nutzt ihr mehrere AWS Accounts oder CLI Profile, so kann es vorkommen, dass ihr herausfinden müsst, als wer ihr gerade angemeldet seid. Dafür stellt der Simple Token Service (STS) von AWS eine API bereit, die sich `GetCallerIdentity` nennt:

```
$ aws sts get-caller-identity
{
    "Account": "123456789012", 
    "UserId": "AIDAICWPPPKW6OQS7YMQQ", 
    "Arn": "arn:aws:iam::123456789012:user/soenke"
}
```
In diesem Fall bin ich im AWS Account `123456789012` als IAM User `soenke` mit dem zugehörigen ARN `arn:aws:iam::123456789012:user/soenke` unterwegs.

## Kein Default Profile - Disaster und Mehrdeutigkeit verhindern

Die AWS CLI unterstützt [Profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html), um z.B. das Handling mehrerer AWS Accounts und/oder IAM Rollen zu erleichtern. Zumeist beginnt man mit einem Account, der dann das `default` Profil wird. D.h. gebt ihr explizit kein Profil aws bei `aws` Befehlen, so wird dieses verwendet. Unsere Erfahrung hat gezeigt, dass dies gefährlich sein kann, denn ihr sagt der AWS CLI nicht explizit, wo Dinge passieren sollen. Im schlimmsten Fall ist das Default-Profil ein Produktions-Account, und z. B. ein `aws rds delete-instance` ohne CLI Profil Angabe löscht die Produktionsdatenbank. Also der Tipp: Kein Default Profil, immer explizit das Profil angeben, z.B. so:

```
$ AWS_PROFILE=dev aws ...
```

oder so:

```
$ aws --profile prod ...
```

## Eingebaute Query-Filter 

Die AWS CLI hat ein mächtiges Toolset, um Ergebnisse von Abfragen zu filtern oder weiter einzuschränken.
Hier ein Beispiel, wir ihr einen Output aus einem CloudFormation Stack herauslesen könnt, ohne schlimme `sed/awk` Verrenkungen zu machen:

Nehmen wir als Beispiel die Ausgabe von `aws cloudformation describe-stacks`:

```
$ aws cloudformation describe-stacks --stack-name <stackname>
{
    "Stacks": [
        {
            ...
            "Outputs": [
                {
                    "Description": "CdnDomain", 
                    "OutputKey": "CdnDomain", 
                    "OutputValue": "d1jh034fae5kze.cloudfront.net"
                }, 
                {
                    "Description": "ID of the Cognito UserPool Client ID for the Edge functions", 
                    "OutputKey": "UserPoolEdgeClientId", 
                    "OutputValue": "something"
                }
            ], 
            ...
        }
    ]
}
```

Was macht ihr jetzt, wenn ihr zum Beispiel *nur* den Wert des Outputs `CdnDomain` aus diesem Stack haben wollt? Dafür könnt ihr die Option `--query` verwenden. Diese erlaubt die sogenannte [JMESPath Syntax](http://jmespath.org/).

```
$ aws cloudformation describe-stacks \ 
    --stack-name=cfn-edge-t \
    --query 'Stacks[0].Outputs[?OutputKey == `CdnDomain`].OutputValue' \
    --output text

d1jh034fae5kze.cloudfront.net
```

In diesem Beispiel wurde aus dem CloudFormation Stack `cfn-edge-t` der Output `CdnDomain` gelesen.

## awsinfo

[`awsinfo`](https://github.com/flomotlik/awsinfo) ist ein Kommandozeilen-Tool, welches auf der AWS CLI basiert und die tägliche Arbeit erleichtert, um Informationen über AWS Ressourcen herauszufinden. 

Wollt ihr beispielsweise die letzten Events eines CloudFormation Stacks herausfinden? Das geht so (in diesem Fall die Events im Stack `jeffconf-demo-ruempler-eu-prod`):

```
$ awsinfo cfn events jeffconf-demo-ruempler-eu-prod
Selected Stack jeffconf-demo-ruempler-eu-prod
Most recent events are on the bottom
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                             DescribeStackEvents                                                                            |
+--------------------------+--------------------------------------+---------------------------------+----------------------------------------+-------------------------------+
|        1.Timestamp       |              2.Status                |           3.LogicalId           |            4.ResourceType              |             5.Log             |
+--------------------------+--------------------------------------+---------------------------------+----------------------------------------+-------------------------------+
|  2017-09-20T09:38:35.604Z|  CREATE_IN_PROGRESS                  |  jeffconf-demo-ruempler-eu-prod |  AWS::CloudFormation::Stack            |  User Initiated               |
|  2017-09-20T09:38:39.582Z|  CREATE_IN_PROGRESS                  |  WebsiteCdnLogBucket            |  AWS::S3::Bucket                       |                               |
|  2017-09-20T09:38:39.742Z|  CREATE_IN_PROGRESS                  |  WebsiteCertificate             |  AWS::CertificateManager::Certificate  |                               |
|  2017-09-20T09:38:40.326Z|  CREATE_IN_PROGRESS                  |  WebsiteCertificate             |  AWS::CertificateManager::Certificate  |  Resource creation Initiated  |
```

Oder aber ein `tail -f` auf die CloudWatch Logs einer Lambda Funktion (hier die Funktion `us-east-1.cfn-edge-t-CdnViewerRequest` in der Region `eu-central-1`):

```
$ awsinfo logs --region eu-central-1 /aws/lambda/us-east-1.cfn-edge-t-CdnViewerRequest
Selected LogGroup /aws/lambda/us-east-1.cfn-edge-t-CdnViewerRequest
/aws/lambda/us-east-1.cfn-edge-t-CdnViewerRequest START RequestId: 360d3f65-2488-11e8-944b-35b37602945c Version: 1
/aws/lambda/us-east-1.cfn-edge-t-CdnViewerRequest END RequestId: 360d3f65-2488-11e8-944b-35b37602945c
/aws/lambda/us-east-1.cfn-edge-t-CdnViewerRequest REPORT RequestId: 360d3f65-2488-11e8-944b-35b37602945c	Duration: 12.42 ms	Billed Duration: 100 ms 	Memory Size: 128 MB	Max Memory Used: 19 MB	
```
Es verhält sich übrigens wirklich wie `tail -f`, d. h. es wartet auf neue Logeinträge.

## Fazit

Ihr kennt noch weitere gute Tricks auf der Kommandozeile oder habt Anmerkungen? Lasst sie uns in den Kommentaren wissen!
