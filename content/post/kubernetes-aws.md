---
title: "Kubernetes und AWS"
author: "Jan Brauer"
date: 2018-05-14
---
Während allerorts fieberhaft auf Preview-Zugänge zu Amazon EKS gewartet wird, haben wir an dieser Stelle eine Liste nützlicher Werkzeuge zusammengestellt, mit denen man sich direkt in das Abenteuer Kubernetes stürzen kann.

## kops

Es gibt unterschiedliche Ansätze Kubernetes-Cluster bei AWS aufzusetzen. Einer davon ist [kops](https://github.com/kubernetes/kops). `kops` steht für Kubernetes-Operations und wird aktiv durch die Kubernetes-Community gepflegt.
`kops` erstellt alle benötigten AWS-Ressourcen, wie z.B. VPC, EC2-Instanzen, ELBs etc. 
Die Anzahl der Master und Knoten lässt sich per Kommandozeile festlegen.
Der folgende Befehl erstellt einen Kubernetes-Cluster in der AWS-Region `eu-central` mit sechs Knoten und drei Mastern.
```
export CLUSTER_NAME=my-first-cluster
kops create cluster \
	--zones=eu-central-1a,eu-central-1b,eu-central-1c \
	--master-zones=eu-central-1a,eu-central-1b,eu-central-1c \
	--node-count=6 \
	--master-count=3 \
	--node-size=m4.2xlarge \
	--master-size=m4.large \
	--topology=private \
	--name=$(CLUSTER_NAME)
```
`kops` kann auch den Lebenszyklus eines Clusters verwalten und z.B. Ausskalieren oder Kubernetes durch rollende Upgrades auf neue Versionen bringen. Eine detaillierte Anleitung findet sich [hier](https://github.com/kubernetes/kops/blob/master/docs/aws.md).

## kube2iam

Wenn Pods, die auf Kubernetes laufen, AWS-APIs konsumieren, ist der Einsatz von [kube2iam](https://github.com/jtblin/kube2iam) angezeigt. `kube2iam` erlaubt Pods IAM-Rollen anzunehmen, so wie sonst EC2-Instanzen über Instanzprofile Rollen annehmen können.
`kube2iam` simuliert die Instance-Metadata API ([http://169.254.169.254/latest/meta-data/
](https://docs.aws.amazon.com/de_de/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)) und isoliert Pods voneinander, so dass diese nur ihre Ihnen zugedachten Berechtigungen erhalten. `kube2iam` wird als DaemonSet auf jeder Node installiert. Per Annotation am Pod oder Deployment wird den Containern die jeweilige Rolle zugeordnet.

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  annotations:
    iam.amazonaws.com/role: role-arn
spec:
  containers:
  - image: nginx 
    name: nginx
```

`kube2iam` liest die Annotation `iam.amazonaws.com/role` aus und ordnet dem Pod die Rolle `role-arn` zu. Damit das funktioniert, müssen die ec2-Instanzen selber eine IAM-Rolle haben, die ihnen erlaubt weiter Rollen anzunehmen. Details sind der [Dokumentation](https://github.com/jtblin/kube2iam#usage) zu entnehmen.

## ExternalDNS
Um auf Services, die auf Kubernetes laufen, durch das öffentliche Internet zugreifen zu können, ist es üblich diese mit DNS-Einträgen zu versehen. [`ExternalDNS`](https://github.com/kubernetes-incubator/external-dns) erlaubt eben dies. Per Annotation oder Konvention werden Services mit DNS-Einträgen versehen. `ExternalDNS` delegiert diese dann an AWS Route53 oder andere DNS-Services. Die Rechte, die `ExternalDNS` benötigt, um DNS-Einträge mit Route53 zu machen, lassen sich auch per `kube2iam` vergeben.
`ExternalDNS` kann sowohl Ingress- als auch Service-Ressourcen DNS-Einträge zuordnen. Damit `ExternalDNS` funktioniert, braucht es Verwaltungsrechte für die öffentlich gehostete Zone. Im folgenden Beispiel wird der Ingress-Ressource der Name `cool-website.` in der Zone `example.com.` zugeordnet. Bei Ingress-Ressourcen wird das `host`-Keyword aus den Regeln ausgelesen und ein passender DNS-Eintrag erstellt.

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx
spec:
  rules:
  - host: cool-website.example.com
    http:
      paths:
      - backend:
          serviceName: nginx
          servicePort: 80	
```

Eine Anleitung wie `ExternalDNS` im Zusammenhang mit AWS Route53 zu konfigurieren ist, findet sich [hier](https://github.com/kubernetes-incubator/external-dns/blob/master/docs/tutorials/aws.md).

## Log-Aggregation via Fluentd
Um Container-Logs so wie die Logs der einzelnen Kubernetes-Services zu aggregieren, empfiehlt sich [Fluentd](https://www.fluentd.org/) und die [Kinesis Firehose](https://aws.amazon.com/de/kinesis/data-firehose).
Fluentd wird als DaemonSet konfiguriert und schickt alle Logs an Kinesis Firehose. Von dort lassen sich die Logs weiterverarbeiten. Zum Beispiel können sie in S3 zur Archivierung abgelegt werden oder an ElasticSearch weitergeleitet werden, um Diagnostik zu betreiben.
Dazu muss der offizielle `fluentd`-Container mit dem [fluent-plugin-kinesis](https://github.com/awslabs/aws-fluent-plugin-kinesis) erweitert werden.

```
FROM fluent/fluentd-kubernetes-daemonset:stable-cloudwatch

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        ruby-dev \
        libffi-dev \
	&& gem install fluentd -v 0.12.43 \
	&& gem install fluent-plugin-kinesis -v 2.1.1 \
	&& gem install fluent-plugin-route -v 0.2.0 \
	&& apk del .build-deps
```

Jetzt wird die ursprüngliche Konfiguration `fluent.conf` dahingehend verändert, dass die Logs an Kinesis geleitet werden.

```
<match **>
    type kinesis_firehose
    delivery_stream_name my-kinesis-stream 
</match>
```

Nun sollten die Logs in Kinesis auftauchen.

## Authentifizierung mit guard
Authentifizierung läuft bei Kubernetes entweder per Client-Zertifikat, Basic Auth oder unterschiedlichsten Bearer Tokens. Auch lassen sich OIDC-Provider anschließen, wie z.B. Google G Suite oder MS Active Directory. Ein weiterer Mechanismus ist die [Webhook-Authentifizierung](https://kubernetes.io/docs/admin/authentication/#webhook-token-authentication). Hierzu wird der Kubernetes API Server derart konfiguriert, dass eingehende Tokens per Webhook von einer dritten Partei überprüft werden. Der API-Server schickt eine als JSON serialisiertes `authentication.k8s.io/v1beta1/TokenReview`-Objekt, welches den Token enthält. In der Antwort wird der Nutzer entweder bestätigt und Gruppenzugehörigkeiten aufgelöst oder der Zugriff verweigert.
[`guard`](https://appscode.com/products/guard/0.1.2/welcome/) ist ein solcher Server. So lassen sich Nutzer beispielsweise per GitHub authentifizieren. Nutzer erstellen einen GitHub-API Token und hinterlegen diesen in ihrer [`kubeconfig`](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/). `kubectl` schickt den Token an den Kubernetes API Server. Dieser schickt den Token per Webhook an `guard`. `guard` wiederum validiert den Token mit Hilfe der GitHub-API.
[Hier](https://appscode.com/products/guard/0.1.2/setup/install-kops/) gibt es eine detaillierte Anleitung, wie `guard` für einen mit `kops` aufgesetzten Kubernetes-Cluster konfiguriert wird.

## Fazit

Mit Hilfe der obigen Tools sollte der Betrieb eines Kubernetes-Clusters auf AWS leichter fallen. Mit Sicherheit gibt es noch mehr hilfreiche Tools aus dem Kubernetes-Umfeld, die einem dass Leben mit AWS einfacher gestalten. Kennt ihr welche? Schreibt sie gerne in die Kommentare!
