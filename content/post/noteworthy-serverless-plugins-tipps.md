---
title: "Serverless Framework und AWS: Tipps und Plugins aus der Praxis"
author: "Soenke Ruempler"
date: 2018-05-25
---

Das [Serverless Framework](https://serverless.com) erfreut sich großer Beliebtheit und kommt auch bei uns und unseren Kunden häufig zum Einsatz. Nicht zuletzt wegen des großen Plugin Ökosystems und der guten AWS Unterstützung.

In diesem Artikel wollen wir euch ein paar Tipps sowie Plugins vorstellen, die wir im bisherigen Praxiseinsatz als sehr hilfreich empfunden haben.

## IAM Variablen in der `serverless.yml`

Ab und zu kann es vorkommen, dass ihr IAM Rollen/Policies in der `serverless.yml` definieren müsst, die spezielle Bedingungen haben, z. B. mit [IAM Variablen](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_variables.html). Diese sehen z. B. so aus: `${aws:username}` - genau das ist aber die Variablen Syntax in der `serverless.yml`!

Dafür gibt es folgenden Workaround: Ihr definiert die [Variablensyntax in der `serverless.yml`](https://serverless.com/framework/docs/providers/aws/guide/variables/#using-custom-variable-syntax) um:
```
provider:
  ...
  variableSyntax: "\\${{([ ~:a-zA-Z0-9._\\'\",\\-\\/\\(\\)]+?)}}"
```
Jetzt ist die `${blah}` Syntax für IAM "frei" und ihr könnt `serverless.yml` Variablen mit `${{myvar}}` referenzieren.

## Sprechende Domains für AWS API Gateways

Aus der Tüte fallen bei AWS API Gateways keine schoenen Domainnamen, sondern sowas wie `tkuvma5x55.execute-api.us-east-1.amazonaws.com`. Allerdings bietet AWS alle Bausteine, um auch sprechende Domains, die ggf. bestehenden Namenschemata wie `<service>.<enviroment>.mycompany.com` entsprechen. Dafür braucht es zumindest die Dienste ACM, Route53, und das API Gateway Domain Mapping. 

Der [serverless-domain-manager](https://github.com/amplify-education/serverless-domain-manager) vereinfacht den Prozess. Bis auf die Einrichtung des TLS Zertifikats in ACM und die Route53 Zone nimmt er euch die Arbeit ab. 

## Lambda Python Projekte ohne Probleme paketieren und deployen

Falls es Probleme beim Paketieren von Python Projekten gibt, weil z. B. Python Versionen nicht übereinstimmen oder irgendetwas mit `pip` nicht geht, dann hilft das [serverless-python-requirements](https://www.npmjs.com/package/serverless-python-requirements) Plugin. Es nimmt euch das Handling von `requirements.txt` ab und kann auch isoliert in einer Docker Umgebung paketieren (mit `dockerizePip`). Das funktioniert übrigens auch in [CodeBuild](https://ruempler.eu/2016/12/19/aws-codebuild-the-missing-link-for-deployment-pipelines-in-aws/), dem Build Service von AWS, denn dieser unterstützt 'Docker in Docker'.

## Harte Kodierung von AWS Account Ids oder Region verhindern

Des öfteren muss man bestehende Resourcen referenzieren, und dafür z. B. deren ARN synthetisieren. Beispiel könnte eine Referenz auf einen bestehenden Kinesis Stream sein, der außerhalb der `serverless.yml` angelegt wurde:

```
functions:
  hello:
    handler: handler.hello
    events:
    - stream:
      - arn: arn:aws:kinesis:eu-central-3:1234567012:stream/mystream
        type: kinesis
``` 
Hier sind jetzt die Region `eu-central-3` und die AWS Account ID `1234567012` hard kodiert, was die Wiederverwendbarkeit der `serverless.yml` zunichte macht. 

Abhilfe schafft das [serverless-pseudo-parameters](https://www.npmjs.com/package/serverless-pseudo-parameters) Plugin, was er erlaubt, die sogenannten [CloudFormation Pseudo Parameter](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html) innerhalb der `serverless.yml` zu verwenden.

Das Beispiel von oben können wir nun so umschreiben:
```
plugins:
- serverless-pseudo-parameters
functions:
  compute:
    handler: handler.compute
    events:
    - stream:
      - arn: arn:aws:kinesis:#{AWS::Region}:#{AWS::AccountId}:stream/mystream
        type: kinesis
``` 

## Lambda Kaltstarts vorbeugen

Eines der aktuell größten Herausforderungen für Serverless Anwendungen scheinen derzeit Kaltstarts zu sein, zumindest bei synchronen Request/Response Aufrufen, wie z. B. über das API Gateway. Das bedeutet, dass beim Aufruf einer Lambdafunktion diese erst intern auf der AWS Infrastruktur hochgefahren werden muss - wenn diese einige Zeit nicht aufgerufen wurde - was einige 100ms bis zu einigen Sekunden dauern kann. Gerade bei Services, die nur sporadisch aufgerufen werden, kann dies also zu signifikanter Latenz oder sogar zu Timeouts bei aggressiv eingestellten Aufrufern führen.
 
 Gerade für Sprachen mit "Class Loaders" (z. B. [JVM oder .NET basierte Sprachen](https://read.acloud.guru/does-coding-language-memory-or-package-size-affect-cold-starts-of-aws-lambda-a15e26d12c76)) schlagen Kaltstarts besonders zu. Hierfür gibt es das [Warmup Plugin](https://github.com/FidelLimited/serverless-plugin-warmup), welches dafür sorgt, dass Lambda Funktionen "vorgewärmt" werden. Das ist sicher nur ein Workaround, aber erkauft uns Zeit, bis die Cloud Provider hier besser werden. Solange hilft es auch, den Lambdafunktionen mehr RAM zu geben.

## API Gateway Logging und Metriken programmatisch aktivieren

Das AWS API Gateway kann [Metriken](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/api-gateway-metrics-dimensions.html) und [Logs](https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-cloudwatch-logs/) an CloudWatch senden, allerdings gibt es bisher noch keine native Funktion im Serverless Framework, um dies programmatisch zu lösen. 

Ein Workaround geht über "Custom Resources", wo wir "low level" an die CloudFormation Resourcen herankommen, die das Serverless Framework verwaltet. Weiterhin braucht ihr das `serverless-plugin-bind-deployment-id` Plugin.
```
plugins:
- serverless-plugin-bind-deployment-id

resources:

  Resources:

    __deployment__:
      Properties:
        Description: This is my deployment
    ApiGatewayStage:
      Type: AWS::ApiGateway::Stage
      Properties:
        DeploymentId:
          Ref: __deployment__
        RestApiId:
          Ref: ApiGatewayRestApi
          StageName: dev 
        MethodSettings:
          - HttpMethod: "*"
            ResourcePath: "/*"
            MetricsEnabled: true
            LoggingLevel: INFO
            DataTraceEnabled: true
```

In diesem Beispiel setzen wir das Log Level auf `INFO` und aktivieren CloudWatch Metriken per `MetricsEnabled: true`.

(Quelle: [Dieser GitHub Issue](https://github.com/serverless/serverless/issues/1918))

## Fazit

In diesem Artikel haben wir in der Praxis wiederkehrende Probleme und Lösungen oder zumindest Workarounds im Zusammenhang mit dem Serverless Framework für euch gesammelt.

Ihr habt weitere schöne Plugins oder Tricks? Schreibt sie gerne in die Kommentare!

