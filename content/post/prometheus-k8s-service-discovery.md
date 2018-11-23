---
title: "Prometheus Service Discovery on Kubernetes"
author: "Till Kahlbrock"
date: 2018-11-16
---

Prometheus ist der de facto Standard, wenn es um die Überwachung und Alarmierung von selbst gehosteten Kubernetes-Clustern und deren Workloads geht. Dies liegt vor allem daran, dass Prometheus auf Kubernetes einfach einzurichten und zu bedienen ist, gute Service-Discovery-Optionen bietet und es aufgrund der weiten Verbreitung viele Anwendungen gibt, die ihre Metriken in einem für Prometheus konsumierbarem [Format] ( https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-based-format) anbieten. 

## Service Discovery
In der Prometheus-Konfiguration ist es möglich, mehrere `scrape_configs` zu definieren, jeweils für ein bestimmtes Ziel (`target`). Ein Ziel kann ein Datenbankserver, eine Web-Anwendung oder eine Gruppe verwandter Applikationen sein. Das Ziel kann wiederum aus viele Endpunkten (`endpoints`) bestehen, was die konkreten Instanzen der Anwendung darstellt.

Die Herausforderung besteht darin, dynamisch auf das Hinzufügen und Entfernen von Endpunkten zu reagieren und die Konfiguration entsprechend anzupassen. Hier kommt Service Discovery ins Spiel.

Die Service-Discovery-Optionen werden werden mit den Konfigurationsdirektiven `*_sd_config` festgelegt. In der [offiziellen Dokumentation] (https://prometheus.io/docs/prometheus/latest/configuration/configuration/) sind insgesamt 12 verschiedene Arten der Service Discovery aufgeführt, z. B. `DNS`, `Consul`, `AWS` `EC2` oder `File`. Hier konzentrieren wir uns allerdings auf die `kubernetes_sd_config`-Methode und wie sie mit dem Prometheus-Operator benutzt werden kann.

Eine verkürzte Scrape-Konfiguration könnte der folgenden ähneln:
```
scrape_configs:
- job_name: 'web-app'
  metrics_path: /app/metrics
  scrape_interval: 10s
  kubernetes_sd_config:
    role: endpoints
    namespaces:
      names: [ns_a, ns_b, ns_c]
```
Diese Konfiguration erstellt einen Job namens `web-app`. Prometheus sucht über die Kubernetes API nach Endpunkten in den Namensräumen `ns_a`, `ns_b` und `ns_c` und versucht, alle versuchten Endpunkte unter dem Pfad `/ app/metrics` alle 10 Sekunden abzufragen.


## Prometheus Operator
Um die Verwaltung von Prometheus zu erleichtern, verwenden wir den [Prometheus Operator](https://github.com/coreos/prometheus-operator). 

Das [Operator-Pattern] (https://coreos.com/blog/introducing-operators.html) wurde von coreos eingeführt und zielt darauf ab, den Betrieb komplexer Software auf Kubernetes-Clustern zu vereinfachen. Kubernetes Operator sollen Aufgaben automatisieren, die traditionell von menschlichen Bedienern durchgeführt werden. 
Mit anderen Worten:
> [... ] An Operator is an application-specific controller that extends the Kubernetes API to create, configure, and manage instances of complex stateful applications on behalf of a Kubernetes user. It builds upon the basic Kubernetes resource and controller concepts but includes domain or application-specific knowledge to automate common tasks.

Ein Kubernetes Controller (auch ein Operator) erweitert die Kubernetes API, indem er [Custom Resource Definitions (CRD)] (https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) festlegt und auf deren Änderung reagiert. Ein gängiges Beispiel für einen benutzerdefinierten Controller ist der [Nginx IngressController] (https://kubernetes.github.io/ingress-nginx/), der zum Einsatz kommt, wenn eine Ingress-Ressource erstellt, geändert oder gelöscht wird und die nginx-Konfiguration entsprechend neu schreibt.

Um die Konfiguration von Prometheus Service Discovery zu erleichtern, wurde der Custom Resource `ServiceMonitor` eingeführt ( https://github.com/coreos/prometheus-operator/blob/master/Documentation/design.md#servicemonitor), die wiederum vom Prometheus Operator (https://github.com/coreos/prometheus-operator) verarbeitet wird. Der Prometheus-Operator agiert hier also als Controller.

## Custom Resource Definition (CRD)
Prometheus-Operator kommt mit vier CDs: `Prometheus`, `ServiceMonitor`, `PrometheusRule` und `Alertmanager`. Nur die ersten beiden sind relevant für die Konfiguration der Prometheus Service Discovery. Die CRD `Prometheus` wird vom Prometheus-Operator verwendet, um die Prometheus-Instanzen zu konfigurieren: 
```
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  labels:
    app: prometheus-operator
  name: prometheus-main
  namespace: monitoring
spec:
  # [...]
  serviceMonitorNamespaceSelector:
    matchLabels:
      monitoring: prometheus-main
  serviceMonitorSelector:
    matchLabels:
      monitoring: prometheus
```
Mit diesem Prometheus CRD bestimmen wir, dass der Prometheus-Operator nach `ServiceMonitor` CRDs mit dem Label `monitoring = prometheus` im Namensraum mit dem Label `monitoring = prometheus-main` suchen soll.

Ein `ServiceMonitor` CRD resultiert in genau einem `scrape_config`-Eintrag in der Prometheus-Konfigurationsdatei.
```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: prometheus-operator-alertmanager
  name: loping-echidna-prometheus-alertmanager
  namespace: default
spec:
  endpoints:
  - interval: 30s
    path: /metrics
    port: web
  namespaceSelector:
    matchNames:
    - default
    - monitoring
  selector:
    matchLabels:
      app: prometheus-operator-alertmanager
      release: loping-echidna
```
Wenn der obige `ServiceMonitor` neu erstellt wird, erkennt der Prometheus-Operator dieses Ereignis und aktualisiert die Prometheus-Konfiguration, so dass ein neuer `scrape_config`-Eintrag mit einer entsprechenden `kubernetes_sd_config`-Direktive erstellt wird. Dadurch wird Prometheus dazu veranlasst, seinen internen Service-Discovery-Mechanismus zu starten und die entsprechenden Namensräume (mit den konfigurierten Labels) nach Endpunkten zu scannen. Prometheus beginnt dann, diese Endpunkte abzufragen und speichert die gesammelten Metriken in seiner [internen Datenbank](https://fabxc.org/tsdb/).

## Fazit
Die Verwendung von Prometheus-Operator in Verbindung mit `ServiceMonitor` CRDs macht das Hinzufügen von neuen und das Entfernen alter Ziele in der Prometheus-Konfiguration zum Kinderspiel. Es ergibt sich außerdem die Möglichkeit den Programmcode einer Applikation und die Monitoring-Konfiguration, am selben Ort zu speichern.

Auch die Möglichkeit der Verwendung von [Helm-Templates](https://helm.sh/) zur automatisierten Erstellung der Prometheus-Konfiguration ist ein nicht zu unterschätzender Vorteil. So wird es dem Benutzer einer Applikation möglich, das Abfragen von Metriken per Schalter einfach an- oder auszuschalten. Ein Verständnis der Details der Prometheus-Konfiguration ist damit nicht nötig.