---
title: "Sieben Tipps für effizientes Arbeiten mit git"
slug: "sieben-tipps-fuer-effizientes-arbeiten-mit-git"
author: "Soenke Ruempler"
date: 2018-05-02
---

Im folgenden wollen wir ein paar Kniffe, die wie über die Zeit mit `git` gelernt haben, mit euch teilen. 

## Wie ihr nicht Guitar Hero mit git spielt!

<center>{{< tweet 694184106440200192  >}}</center>

So oder ähnlich sehen häufig git Historien von Projekten aus. Eigentlich haben Versionskontrollsysteme die Eigenschaft, dass man durch sie herausfinden kann, wann welche Änderung wo gemacht wurde, im besten Falle sogar noch, was die Intention der Autor\*innen war, doch solche Historien verwirren oft mehr als dass sie nützen. Ein beisteuernder Faktor dazu können die git Standardeinstellungen sein, welche "merge commits" erzeugen. 
 
Dies bedeutet: Wenn ihr Änderungen lokal eingecheckt habt, und auch beim Remote Änderungen vorliegen, so macht git standardmäßig einen Merge Commit, der aber keine weitere Information enthält.  Hier eine Grundeinstellung, die euch hilft, den "noise" zu verringern.
```
$  git config --global pull.rebase true
```
Durch diese Einstellung ändert ihr das Default-Verhalten auf `rebase`, was bedeutet, dass eure Änderungen an das, was neu vom Remote "hereinkommt", neu anhängt. Dadurch wird die Historie wieder linear. 

## Nerviges Stashing mit Auto-Stash loswerden

Ihr habt nicht commitete Änderungen lokal, wollt aber aktuelle Änderungen vom Remote laden - dann kennt ihr bestimmt:
```
$ git pull
error: ...
error: please commit or stash them.
```
Kennt ihr? Dann schaltet doch `autostash` ein (Achtung, geht nur mit der Einstellung oben in Kombination):
```
$ git config --global rebase.autoStash true
```
und nun macht git für euch die nervige Stash-Arbeit:
```
$ git pull
Created autostash: 9481831
HEAD is now at b7d36d6 Update README.md
First, rewinding head to replay your work on top of it...
Fast-forwarded aadsa to 69eeb22cf0a1b24e3865515445a9b1b8872db956.
Applied autostash.
```

## Default Push Branch

In der Regel will ich bei einem `push` in den Branch mit dem gleichen Namen auf dem Remote die Änderungen pushen. Dafür gibt's auch ein Config Flag:
```
git config --global push.default current
```
Nun reicht es, `git push` einzugeben:
```
$ git checkout -b new_branch
Switched to a new branch 'new_branch'
$ git push
Total 0 (delta 0), reused 0 (delta 0)
To github.com:s0enke/playground.git
 * [new branch]      new_branch -> new_branch
```

## Wie/wo ist `<phrase>` in den Code gekommen (oder wurde es gelöscht)?

Häufig stellt sich diese Frage, oft in kritischen Situationen, wo es auf Zeit ankommt (z.B. in Incidents).
`git log -S<keyword>` hilft euch. Hier ein Beispiel aus unserer Website, übrigens Open Source auf Github ist:
```
$ git log -SKommandozeile --oneline 
2730a80 Sechs Dinge, die euch das Leben mit der AWS Kommandozeile erleichtern… (#35)
```
Hier suche ich nach Commits, in der die Phrase `Kommandozeile` entweder hinzugefügt oder gelöscht wurde, und git findet den Commit `2730a80`.

## Was war gleich der Branch, auf dem ich zuletzt unterwegs war?

Um auf den letzten Branch vor dem aktuellen zu wechseln, könnt ihr folgenden Befehl verwenden:
```
$ git checkout -
```
Das `-` ist also ein Platzhalter für "letzter ausgecheckter Branch". 

Den kanntet ihr schon? Wusstet ihr euch, dass das auch mit `git merge -` oder `git rebase -` geht? Und sogar `git cherry-pick - `, welches den letzten Commit des letzten Branches "cherry pickt".

## Zuviel auf einmal gemacht, wie kann ich mehrere Commits machen?

Viele kleine Commits, die logische Einheiten bilden und daher einzeln angewendet, deployed oder auch "reverted" werden können, ist eine weit verbreitete best practise. Nicht zuletzt, weil es schnelles Feedback unterstützt. Nun habt ihr eine Änderung, die eigentlich 2 logische Änderungen sind? ```git add -p``` to the rescue!

In folgenden Beispiel seht ihr eine Datei mit 2 nicht commiteten Änderungen:
```
$ git diff
diff --git a/A b/A
index 50d64f3..1a3bb26 100644
--- a/A
+++ b/A
@@ -1,5 +1,7 @@
+first change
 AAAA
 AAA
 SSS
 SSSS
 BBB
+second change

```
Mit `git add -p` könnt ihr jetzt daraus auch 2 einzelne Commits machen:

Erster Commit:
```
$ git add -p
diff --git a/A b/A
index 50d64f3..1a3bb26 100644
--- a/A
+++ b/A
@@ -1,5 +1,7 @@
+first change
 AAAA
 AAA
 SSS
 SSSS
 BBB
+second change
Stage this hunk [y,n,q,a,d,/,s,e,?]? s
Split into 2 hunks.
@@ -1,5 +1,6 @@
+first change
 AAAA
 AAA
 SSS
 SSSS
 BBB
Stage this hunk [y,n,q,a,d,/,j,J,g,e,?]? y
@@ -1,5 +2,6 @@
 AAAA
 AAA
 SSS
 SSSS
 BBB
+second change
Stage this hunk [y,n,q,a,d,/,K,g,e,?]? n

$ git commit -m"first change"
[master fd0fc93] first change
 1 file changed, 1 insertion(+)
$ git add -p
diff --git a/A b/A
index e36bf24..1a3bb26 100644
--- a/A
+++ b/A
@@ -4,3 +4,4 @@ AAA
 SSS
 SSSS
 BBB
+second change
Stage this hunk [y,n,q,a,d,/,e,?]? y
```
Zweiter Commit:
```
$ git commit -m"second change"
[master eebf4da] second change
 1 file changed, 1 insertion(+)
```
PS: `-p` geht übrigens auch mit mindestens `git commit` und `git reset`!

## Zu guter letzt: `hub`

Häufig kommt heutzutage GitHub und der Pull Request Workflow zum Einsatz. Pull Requests zu erstellen kann hier mehrmals am Tag oder sogar in der Stunde vorkommen und somit langwieriges Navigieren in der GitHub UI verursachen.

Mit [hub](https://github.com/github/hub) von GitHub kann man den Prozess vereinfachen, denn mit `hub pull-request` gibt es einen one-liner:
```
$ git checkout -b my_pr
Switched to a new branch 'my_pr'
$ git commit -m"my new pull request"
[my_pr 71bef3d] my new pull request
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 C
$ git push
Counting objects: 15, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (10/10), done.
Writing objects: 100% (15/15), 1.32 KiB | 449.00 KiB/s, done.
Total 15 (delta 1), reused 0 (delta 0)
remote: Resolving deltas: 100% (1/1), done.
To github.com:s0enke/playground.git
 * [new branch]      my_pr -> my_pr
$ hub pull-request
https://github.com/s0enke/playground/pull/1
```
Nun hat `hub` einen Pull Request erzeugt und zeigt auch direkt den Link an: https://github.com/s0enke/playground/pull/1 

`hub` kann auch noch viel mehr, z.B. vereinfachtes Erstellen oder Klonen von Projekten auf GitHub.

## Fazit

Ihr habt weitere Git Tricks auf Lager? Schreibt sie gerne in die Kommentare!

PS: Ihr wollt verstehen, wie ihr Git(Hub) möglichst effektiv einsetzen könnt? superluminar bietet Schulungen und Workshops zum Thema git an. [Schreibt uns einfach](mailto:workshops@superluminar.io)! 

