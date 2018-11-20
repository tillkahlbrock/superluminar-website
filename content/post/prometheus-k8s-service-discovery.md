---
title: "Prometheus Service Discovery on Kubernetes"
author: "Till Kahlbrock"
date: 2018-11-16
---

Prometheus is the de facto standard when it comes to monitoring and alerting of self hosted Kubernetes clusters and their workloads.
This is mainly because Prometheus is easy to setup and operate on Kubernetes, has good service discovery options and - because of its broad adoptions - there are many applications exposing their metrics in a [format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-based-format) understood by Prometheus.

## Service Discovery
In the Prometheus configuration it is possible to define multiple `scrape_configs`, each for a  specific `target`. A target can be an application like a database server or a web app or a group of related apps. The target can have many `endpoints`, which represents the concrete instances of the application.

But how does Prometheus get to know the targets it has to scrape? This is where Service Discovery comes into play. 

The service discovery configuration is provided with the `*_sd_config` configuration directives. The [official documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/) list a total of 12 different possible types of service discovery e.g: DNS, Consul, AWS EC2 or File. Here we will focus on the  `kubernetes_sd_config` method and how it integrates with the Prometheus Operator.

A shortened scrape configuration could be similar to the following:
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

It defines a job called `web-app`. Prometheus will query the Kubernetes API and look for endpoints in the namespaces `ns_a`, `ns_b` and `ns_c`. It will try to scrape all discovered endpoints under the path `/app/metrics` every 10 seconds.


## Prometheus Operator
To make the configuration of this certain aspect of Prometheus easier, the CustomResource ServiceMonitor where introduced (https://github.com/coreos/prometheus-operator/blob/master/Documentation/design.md#servicemonitor) which is consumed by the Prometheus Operator (https://github.com/coreos/prometheus-operator).

To make the management of Prometheus easier we will use the [Prometheus Operator](https://github.com/coreos/prometheus-operator). 

The [Operator-Pattern](https://coreos.com/blog/introducing-operators.html) was introduced by coreos and aims to simplify operation of complex software running on Kubernetes clusters. At its core it was designed to automated tasks traditionally done by human operators by writing software. In other words:
> [... ] An Operator is an application-specific controller that extends the Kubernetes API to create, configure, and manage instances of complex stateful applications on behalf of a Kubernetes user. It builds upon the basic Kubernetes resource and controller concepts but includes domain or application-specific knowledge to automate common tasks.

A Kubernetes Controller (also an Operator) extends the K8s api by defining [Custom Resources (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) and reacting to their modification. A common example of a custom Controller is the [Nginx IngressController](https://kubernetes.github.io/ingress-nginx/), that comes to action when a Ingress resource gets created, modified or deleted and rewrites the nginx configuration appropriately.

## Custom Resource Definition (CRD)
Prometheus Operator comes with four CRDs: `Prometheus`, `ServiceMonitor`, `PrometheusRule` and `Alertmanager`. The former two are relevant for configuring how Prometheus discovers its targets. The `Prometheus` CRD is used by Prometheus Operator to configure the Prometheus Instances:
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
With this Prometheus CRD we tell the Prometheus Operator, that it should look for ServiceMonitor CRDs with the label `monitoring=prometheus` in the namespace with the label `monitoring=prometheus-main`.

A ServiceMonitor CRD maps to exactly one scrape_config entry in the prometheus configuration file.
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
When the above new ServiceMonitor is created, the Prometheus Operator recognizes this event and updates the Prometheus configuration stored in a kubernetes secret, so that a new scrape config with a corresponding `kubernetes_sd_config` directive is created. 
This triggers Prometheus to start its internal service-discovery mechanism and scan the respective namespaces for endpoints with the configured labels. Prometheus then starts to scrape this endpoints and the stores the collected metrics in its time series database.

## Conclusion
The usage of ServiceMonitors allows us to store the monitoring configuration of our apps next to the apps themselves. It is also possible to automate the creation of Prometheus scrape configuration by using helm charts. It is also possible to give the user of the chart the possibility to simply enable or disable metric scraping with a flag, without the need to understand the details of Prometheus configuration.
