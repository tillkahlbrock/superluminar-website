---
title: "Eine Deploy-Pipeline mit AWS CodePipeline"
author: "Jan Brauer"
date: 2017-12-01
---
## Das Problem
Wer kennt es nicht. Die Stories sind alle abgearbeitet, das BurnDown-Chart geht gegen null, die Product Ownerin frohlockt.
Dann kommt die Frage:

> "Ist es denn schon live?"
> "Öh, jein. Wir müssen nur noch deployen..."

Hektische Betriebsamkeit macht sich breit. Das Release-Datum wird um zwölf Wochen verschoben. Die bisherigen Schätzungen waren alle falsch.

## Geht es auch anders? 
Doch so muss es nicht sein. Für uns gehört der Deployment-Prozess als vollwertiger Bestandteil zur Produktentwicklung dazu. Also sollte er zum Beginn des Entwicklungsprozesses geplant und mit etwas Liebe bedacht werden.
Im folgenden Zeigen wir Euch, wie die Deployment-Pipeline für eben diese [Webseite](superluminar.io) funktioniert und aufgebaut ist.

## Continuous Delivery
Für eine [Continuous Delivery Pipeline](https://continuousdelivery.com/principles/) benötigen wir zum einen ein herkömmliches CI-System wie zum Beispiel [Jenkins](https://jenkins.io/) oder [Travis](https://travis-ci.com/). Zum Anderen ein Skript, was unser Projekt baut, testet und live stellt. Hierfür genügt ein Bash-Skript oder ein Makefile.
Jenkins ist für gewöhnlich mit operativem Mehraufwand verbunden und nicht ohne weiteres verfügbar. Travis ist mit relativ hohen Kosten verbunden, die sich erst ab einer gewissen Größe lohnen.

## Eine Pipeline mit AWS-Bordmitteln 
Wir setzen aber vollends auf unseren Cloud-Provider AWS. Amazon stellt mit der [AWS CodePipeline](https://aws.amazon.com/codepipeline/) einen CI/CD-Service zur Verfügung, der obigen Alternativen in nichts nachsteht. Im Gegenteil - die CodePipeline lässt sich per API konfigurieren und somit durch Code beschreiben. Wir nutzen für AWS-Automatisierungsaufgaben [CloudFormation](https://aws.amazon.com/cloudformation). Hier integriert sich die CodePipeline perfekt.

Eine Pipeline gliedert sich in mehrere Phasen, sogenannte *Stages*. Eine Stage wiederum besteht aus ein oder mehreren Aktionen. AWS CodePipeline unterstützt folgende [Aktionen](http://docs.aws.amazon.com/codepipeline/latest/userguide/integrations-action-type.html):

* `Source` - den Source-Code auschecken
* `Build` - ein Artefakt bauen
* `Test` - Tests durchführen
* `Deploy` - Deployment durchführen
* `Approval` - Bestätigung durch Nutzer/Rolle einholen
* `Invoke` - eine AWS Lambda Funktion ausführen

Für unsere Webseite genügen uns zwei Stages. Eine `Source`-Stage die Code von GitHub auscheckt. Und eine `DeployWebsite`-Stage, die das Artefakt baut und die Webseite in einen S3-Bucket kopiert. In der AWS-Konsole sieht das ganze so aus:

![Code Pipeline](/img/code-pipeline.png)

Die Konfiguration für die `Source`-Stage sieht wie folgt aus:
```yaml
- Name: Source
  Actions:
    - Name: SourceAction
      ActionTypeId:
        Category: Source
        Owner: ThirdParty
        Version: 1
        Provider: GitHub
      InputArtifacts: []
      OutputArtifacts:
        - Name: SourceOutput
      Configuration:
        Owner: superluminar-io 
        Repo: superluminar-website 
        Branch: master 
        OAuthToken: !Ref GithubOauthToken
      RunOrder: 1
```

Hier wird eine Action vom Typ `Source` verwendet. Damit wird der Source-Code unserer [Webseite](https://github.com/superluminar-io/superluminar-website) ausgecheckt. Wichtig ist hierbei der Parameter `OAuthToken`. Dies muss ein OAuth Token für GitHub mit dem Scope `repo` sein. Weitere Informationen dazu lassen sich [hier](http://docs.aws.amazon.com/codepipeline/latest/userguide/integrations-action-type.html#integrations-source) finden.

Die Konfiguration für die darauffolgende `DeployWebsite`-Stage sieht wie folgt aus:
```yaml
- Name: DeployWebsite
  Actions:
  - Name: DeployWebsiteAction
    ActionTypeId:
      Category: Build
      Owner: AWS
      Version: 1
      Provider: CodeBuild
    InputArtifacts:
      - Name: SourceOutput
    OutputArtifacts:
      - Name: DeployWebsiteActionOutput
    Configuration:
      ProjectName:
        Ref: DeployWebsiteBuild
    RunOrder: 2
```

Hier verwenden wir eine Action vom Typ `Build`. Dies mag widersprüchlich sein, aber wir kombinieren den Build- und den Deploy-Step in einen. Würden wir auf EC2-Instanzen deployen wollen, wäre eine Action vom Typ `Deploy` angebracht.  Der spannende Teil hieran ist im Parameter `Configuration` mit dem Namen `DeployWebsiteBuild` zu finden. Hier wird folgender Teil referenziert:

```
  DeployWebsiteBuild:
    Type: AWS::CodeBuild::Project
    Properties:
      Artifacts:
        Type: CODEPIPELINE
      Environment:
        ComputeType: BUILD_GENERAL1_SMALL
        Image: aws/codebuild/ubuntu-base:14.04
        Type: LINUX_CONTAINER
        EnvironmentVariables:
          - Name: WEBSITE_BUCKET
            Value: !Ref WebsiteBucket
      Name: !Sub DeployWebsiteBuild-${DeploymentStage}
      ServiceRole: !Ref DeployWebsiteRole
      Source:
        Type: CODEPIPELINE
        BuildSpec: |
          version: 0.1
          phases:
            install:
              commands:
                - make install
            build:
              commands:
                - make build 
            post_build:
              commands:
                - make deploy 
```

Der eigentliche Build-Step sieht so aus. Die [Spezifikation](http://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html) beschreibt das Format. Dies ähnelt dem Format wie Ihr es z.B. von Travis kennt.

```
  version: 0.1
  phases:
    install:
      commands:
        - make install
    build:
      commands:
        - make build 
    post_build:
      commands:
        - make deploy 
```

Drei Schritte: die Abhängigkeiten installieren, das Artefakt (unsere Webseite) bauen, die Website in einen S3-Bucket kopieren.  Das [Makefile](Makefile) für unsere Webseite stellt die obigen drei Targets bereit. Ausgeführt wird das ganze in einem Docker-Container (`Image: aws/codebuild/ubuntu-base:14.04`, s.o.). Es stehen verschiedene [Docker-Images](http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html) zur Auswahl. Das gesamte Cloudformation-Template findet Ihr [hier](superluminar-website-prod.yaml).

## Fazit

Zugegebenermaßen hat AWS CloudFormation eine steile Lernkurve. Doch die Investition macht sich bezahlt. Wir haben eine Pipeline für unsere Webseite ohne weitere Komponenten gebaut. Ab jetzt können wir unsere Webseite nach Gusto ändern. Gefällt uns etwas nicht, ändern wir es einfach auf [GitHub](https://github.com/superluminar-io/superluminar-website). Unsere Pipeline stellt sicher, das Änderungen binnen Minuten live sind. Eine Sorge weniger. Bis zum nächsten Artikel!
