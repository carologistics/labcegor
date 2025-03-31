# Bericht Praktikum: Centralized Goal Reasoning for Logistics Robots

Im Rahmen des Praktikums *Centralized Goal Reasoning for Logistics Robots* habe ich mich mit der Steuerung und Koordination mehrerer mobiler Roboter in einer simulierten Logistikumgebung beschäftigt. Das Szenario ist dabei der RoboCup Logistics League entlehnt. Ziel war es, ein zentrales System zu entwickeln, das Aufträge effizient an die Roboter verteilt, um logistische Aufgaben wie das Transportieren von Objekten zu erfüllen.

Mein Projektansatz war es, herauszufinden, wie weit man Roboter bringen kann, ohne ein höheres, planbasiertes Verständnis der Umgebung zu implementieren. Aus diesem Grund habe ich mich bewusst gegen die Nutzung von PDDL entschieden. Stattdessen ähnelt mein Steuerungskonzept eher einer nichtdeterministischen Zustandsmaschine. Dadurch muss am Ende kein Roboter explizit einer Aufgabe zugewiesen werden – stattdessen ergeben sich die Zustände und möglichen Aktionen jedes Roboters aus den vorhergegangenen Ereignissen.

Die Intention dahinter war, eventuelle Erfahrungsdefizite meinerseits auszugleichen und den Robotern zu erlauben, auch solche Aktionen durchzuführen, die ich selbst im Vorfeld nicht in Betracht gezogen habe.

Diese Entscheidung einige Nachteile. Eine zentrale Erkenntnis war, dass das Debugging in einem solchen System sehr aufwendig ist. Fehler treten häufig auf, sind schwer zu lokalisieren und haben kritische Auswirkungen. Auch wenn sich die gewählte Idee im Nachhinein als wenig robust erwiesen hat, konnten die Roboter immerhin die grundlegende Aufgaben erfolgreich ausführen.

## Ablauf

Die Anwendung kann bereits vor dem Spielbeginn oder während der Setup-Phase gestartet werden. Danach warten die Roboter, bis die Production-Phase beginnt.  
Roboter 1 beginnt mit der Bearbeitung aller Aufträge. Roboter 2 und 3 starten parallel mit der Vorbereitung der Cap-Stations. Anschließend kümmern sie sich um das Payment oder füllen die Cap-Stations auf, nachdem Roboter 1 eine Cap montiert hat.

Dieser Zyklus wird bis zum Ende des Spiels durchlaufen.  
Geplant war, dass ein Roboter nach Abschluss seiner aktuellen Aufgabe prüft, welche Task als Nächstes am dringendsten ist, und diese dann übernimmt. So könnte z.B. Roboter 2 nach dem Auffüllen der Cap- und Ring-Station einen Auftrag übernehmen. Roboter 1 könnte dann wiederum nach der Auslieferung seines Auftrags die Cap-Station erneut befüllen.

## Probleme

Gelegentlich passiert es, dass Roboter 1 Order 1 bearbeitet, diese aber mit anderen Aufträgen vermischt wird.
Roboter 2 und 3 haben zudem gelegentlich das Problem, dass sie keinen Weg zu ihrem Ziel finden. Leider war ich bisher nicht in der Lage die Tatsächliche Ursache für diese Probleme herauszufinden, da sie eher selten auftreten und schwer zu reproduzierbar waren.

## Fazit

**Wenn der Mond richtig steht, dann funktioniert das auch.**  
Obwohl die Umsetzung nicht immer stabil war, konnte ich wertvolle Erfahrungen in der Robotiksteuerung, Systemintegration und im Umgang mit komplexen Multi-Agenten-Systemen sammeln.
Und mit noch etwas mehr zeit, könnte es passieren, dass die Roboter ein ganzes Spiel überstehen.
