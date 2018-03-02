---
title: "Passwortgeschuetze statische Websites mit AWS CloudFront und Lambda@Edge"
author: "Soenke Ruempler"
date: 2018-02-26
---

Statische Websites sind nicht zuletzt durch durch Site Generatoren weiterhin ein fester Bestandteil des Webs. Weiterhin gibt es oft Anforderungen, dass Content geschuetzt werden soll, z. B. fuer Mock-ups oder Kunden-Demos.

Leider gibt es bei AWS (noch) keinen nativen Service, der folgende Anforderungen unterstuetzt:
HTTPS/TLS Website Hosting (Verschluesselung in Transit)
Passwortschutz (z. B. per HTTP Basic Auth).
Serverless

Serverless bedeutet uebrigens nicht nur, dass keine Server, VMs oder Container zu erstellen oder zu pflegen sind, sondern auch, dass nur das bezahlt wird, was auch benutzt wird. Hat die statische Website keine Besucher, so entstehen auch keine Kosten. Ausgenommen die Kosten fuer den Objektspeicher S3.

Die AWS Bausteine
In diesem Artikel will ich euch zeigen, wie man mit den AWS Bausteinen CloudFront und Lambda@Egde sowie AWS Cognito Userpools als User-Verwaltung und S3 als Objektspeicher eine Loesung fuer passwortgeschuetze statische Websites selbst zusammenbauen kann.

Lambda@Edge ist hier der eigentliche Star. Dadurch kann beliebiger Code als sogenannter Hook waehrend des HTTP request/response Zyklus ausgefuehrt werden und Request/Response auch veraendert werden. Dies ermoeglicht eine totale Programmierung des CDNs und erlaubt im Extrem die Aufuehrung kompletter Anwendungen im direkt auf CDN-Knoten von AWS. Nicht zuletzt, weil selbst Netzwerkverkehr erlaubt ist. Somit koennen Lambda@Edge Funktionen auch weitere Services anfragen, wie in diesem Beispiel AWS Cognito Userpools.

AWS Bausteine zusammensetzen
Ok, was brauchen wir? Zu erst einmal brauchen wir ein S3 Bucket. Dieses enthaelt den schuetzenswerten Content. Diesen kann man zum Beispiel mit dem AWS Kommandozeilenwerkzeug “aws s3 cp” hochladen.

Als weiteren Schritt brauchen wir eine sogenannte CloudFront Distribution, also das CDN.
Diese wird so konfiguriert, dass sie das S3 Bucket schützt (ein sogenannter “Shield”). Durch eine “Origin Access Identity” wird sichergestellt, dass nur diese CloudFront Distribution auf das S3 Bucket zugreifen kann. Die Kommunikation zwischen CloudFront und S3 ist dadurch vertraulich, dass beide nur über HTTPS kommunizieren.
Weiterhin kann CloudFront auf HTTPS-only konfiguriert werden und auch automatisch redirects von HTTP auf HTTPS veranlassen, ohne große Konfiguration. Ein “ViewerProtocolPolicy: redirect-to-https” reicht hier.

Somit ist sichergestellt, dass die Kommunikation “in transit” zwischen Client (Browser) und Speicher (S3) komplett verschluesselt ist.

Soweit so gut. Wie kommt jetzt aber der Passwortschutz da rein? Hier kommt Lambda@Edge ins Spiel: Wir installieren jetzt eine sogenannte “Function Association” in unsere CloudFront Distribution. Lambda@Edge erlaubt es, an 4 Stellen in den Request/Response Zyklus einzugreifen:



Hier erfahrt ihr genaures darueber. Fuer unser Beispiel eignet sich der “Viewer request”. Den Beispiel-Code koennt ihr hier einsehen. Was tut dieser?

1. Aufruf des Codes durch Lambda@Edge
2. Checken, ob ein Authorization HTTP header gesetzt ist. Wenn nein, dann wird ein 401 Unautorized zurueckgliefert:

```javascript
if (typeof request.headers['authorization'] !== "object"
  || typeof request.headers['authorization'][0] !== "object"
  || typeof request.headers['authorization'][0].value !== "string"
) {
  const response = {
    status: '401',
    statusDescription: 'Unauthorized',
    headers: {
      'www-authenticate': [{
        key: 'WWW-Authenticate',
        value: 'Basic realm="Lambda@Edge ist 1 nices CDN vong programmierbarkeit her."'
      }],
    },
  };
  callback(null, response);
  return;
}
```
3. Decoding des Authorization Headers und Autorisierung gegen einen Cognito Userpool (der Benutzerverwaltungs-Dienst aus dem AWS Portfolio)

```
cognitoidentityserviceprovider.adminInitiateAuth(params, function(err, data) {
  if (err) {
    console.log(err);
    const response = {
      status: '401',
      statusDescription: 'Unauthorized',
      headers: {
      'www-authenticate': [{
        key: 'WWW-Authenticate',
        value: 'Basic realm="Lambda@Edge ist 1 nices CDN vong programmierbarkeit her."'
      }],
      },
    };
    callback(null, response);
  } else {
    console.log(data);
    if (!path.extname(request.uri)) {
      // we assume a path and add index.html to the request uri, if there is no file extension
      const path_parts = path.parse(request.uri)
      const new_uri = path.join(path_parts.dir, path_parts.base, 'index.html')
      console.log('rewriting ' + request.uri + ' to ' + new_uri)
      request.uri = new_uri
    }
    callback(null, request);
  }
});
```


Zum guten Ton gehoert es heutezutage, dass Installationen automatisiert sind. Dazu haben wir fuer euch ein CloudFormation Template zur freien Vervendung zusammengestellt. Wollt ihr einmal ausprobieren? Dann klickt hier. Ihr muesst dazu in die AWS Console eingeloggt sein.

Ihr wollt mehr zum Thema serverless lernen? Meldet euch zu unserem Serverless-Workshop an!

PS: Zur weiteren Vertiefung des Themas koennt ihr euch diesen Mittschnitt von einem Talk auf der JeffConf Mailand von Soenke ansehen, welcher genau diese Problemstellung behandelt.



Weitere Hinweise:
Das static website hosting feature von S3 wurde nicht verwendet, weil derzeit es keine sichere HTTPS Verbindung und keine “Origin Access Identity” unterstuetzt.
Wichtig zu wissen ist allerdings, wo die Logs der Lambda@Edge Funktionen ankommen. 
Requst/Response veraendert man dadurch, was man zurueckgibt.
NO_SRP_AUTH



