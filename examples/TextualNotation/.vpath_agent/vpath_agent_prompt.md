<sysml_v2>
SysML v2 – Best Practices & Modellierungsregeln
Basis: SysML v2 Beta 4 Spezifikation

1. Struktur & Organisation
Packages als oberste Struktur verwenden
package VehicleModel { ... }
Imports sparsam nutzen
public import für gemeinsam genutzte Typen
private import für interne Helfer
Für Klarheit immer qualifizierte Namen verwenden, wenn nötig:
ISQ::MassValue
Fahrzeugmodell.Vehicle
2. Definition vs. Usage strikt trennen
Definition beschreibt, was etwas ist
part def Vehicle {
    attribute mass : MassValue;
}
Usage beschreibt, wo/wie es verwendet wird
part car : Vehicle {
    :>> mass = 1500 [kg];
}
Gleiches Prinzip gilt für: action def, item def, constraint def, port def, connection def usw.

3. Spezialisierung, Subsetting & Redefinition
Spezialisierung (:>) für "ist eine Art von"
part def SportsCar :> Vehicle {
    :>> mass = 1200 [kg];
}
Redefinition (:>>) für geerbte Eigenschaften überschreiben
:>> wheels = 4;
Subsetting (:> an Usage) für Teilmengen
part engine1[1] :> engines;
4. Requirements
Requirement Definition
requirement def MassRequirement {
    subject vehicle : Vehicle;
    attribute massActual : ISQ::MassValue;
    attribute massLimit  : ISQ::MassValue;
    require constraint { massActual <= massLimit }
}
Requirement Usage mit ID
requirement <R1> vehicleMass : MassRequirement {
    attribute :>> massActual = vehicle.mass;
    attribute :>> massLimit  = 1800 [kg];
}
Wichtig: subject immer explizit angeben, wenn möglich.

Satisfy-Beziehungen: Wichtige Regeln
Regel 1: Ziel eines satisfy muss immer ein Requirement sein
satisfy darf nur auf Requirements zeigen
Quellen können beliebige Modell-Elemente sein (Parts, Actions, Use Cases, Architekturblöcke)
Korrekt:
satisfy MyRequirement;
Falsch:
satisfy SomeUseCase;
Regel 2: Wenn ein Use Case ein Requirement erfüllt → Beziehung vom Use Case aus angeben
use case grabTowel {
    satisfy requirementSpecification.newRequirement;
}
Regel 3: satisfy innerhalb eines erfüllenden Elements
Wenn ein Element (z.B. ein part in einer Architektur) ein Requirement erfüllt, wird die satisfy-Beziehung direkt in diesem Element deklariert
In diesem Fall wird keine by-Klausel verwendet, da das Element (self) implizit die Quelle ist
Korrekt:

part <towel42Alert> physicalArchitectureTowel42Alert :>> systemTowel42 {
    doc /* Dieses Architekturelement erfüllt die Anforderung. */
    satisfy requirementSpecification.tagBatteryLife;
}
Falsch (führt zu Fehlern):

part <towel42Alert> physicalArchitectureTowel42Alert :>> systemTowel42 {
    satisfy requirementSpecification.tagBatteryLife by self; // "by self" ist redundant und falsch
}
5. Constraints richtig nutzen
Constraint Definition
constraint def IsFull {
    in tank : FuelTank;
    tank.fuelLevel == tank.maxFuelLevel;
}
Constraint Usage mit Binding
part def Vehicle {
    part fuelTank : FuelTank;
    constraint tankIsFull : IsFull {
        in tank = fuelTank;
    }
}
In Requirements
Verwende require constraint { ... } für prüfbare Bedingungen.

6. Verhalten: Actions
Action Definition mit Ein-/Ausgängen
action def StartEngine {
    in  ignitionSignal : Boolean;
    out status         : EngineStatus;
}
Komposite Action mit Ablauf
action def Drive {
    action accelerate : Accelerate;
    first start then accelerate;
}
Action Usage in Parts mit perform
part vehicle : Vehicle {
    action driveVehicle : Drive;
    action pressGas {
        perform driveVehicle;
    }
}
Komplexe Action mit Kontrollfluss, Verzweigungen und Flows
Beispiel einer vollständigen Drohnen-Operation mit allen Kontrollelementen:

action def Land;
action def 'Operate Drone' {
    action 'define mission' { out item mission; }
    first start;
    then 'define mission';
    action 'lift off';
    then 'lift off';
    decide decide1;
    fork fork1;
    join join1;
    action 'fly mission' { in item mission; }
    action 'capture photos' { out item photo; }
    action land : Land;
    merge merge1;
    first fork1 then 'fly mission';
    first fork1 then decide1;
    first 'fly mission' then join1;
    first 'capture photos' then merge1;
    first land then done;
    out item photo;
    first 'lift off' then fork1;
    flow flow1 from 'define mission'.mission
        to 'fly mission'.mission;
    first decide1;
    if 'camera on' then 'capture photos';
    else merge1;
    first join1 then land;
    first merge1 then join1;
    binding bind 'capture photos'.photo = photo;
    in attribute 'camera on' : Boolean;
    first 'define mission' then 'lift off';
    binding bind 'capture photos'.photo = photo;
}
Best Practices für komplexe Actions:

decide für Entscheidungspunkte verwenden, immer mit guard-Bedingungen in [].
fork und join für parallele Ausführung.
merge für Zusammenführung alternativer Pfade.
if...then...else für bedingte Verzweigungen innerhalb einer Action (nicht für den Flow zwischen Actions).
flow für explizite Item-Flüsse zwischen Actions.
binding für Verknüpfung von Outputs mit Action-Outputs.
Klares Beispiel für decide mit guard
Um alternative Pfade zu modellieren, wird ein decide-Knoten mit bewachten (guard) Übergängen verwendet.

action def CheckWeather;
action def FlyMission;
action def StayGrounded;

action def DecideFlight {
    in isWeatherGood : Boolean;
    
    decide weatherDecision;
    merge endPath;

    first start then CheckWeather;
    then CheckWeather then weatherDecision;

    // Guards steuern den Pfad
    then weatherDecision { guard [isWeatherGood] } FlyMission;
    then weatherDecision { guard [not isWeatherGood] } StayGrounded;

    then FlyMission then endPath;
    then StayGrounded then endPath;
    then endPath then done;
}
6a. Use Cases mit Verhalten
Ein Use Case beschreibt, wie Akteure mit dem System interagieren, um ein Ziel zu erreichen. Das Verhalten wird durch perform action auf vordefinierte Actions modelliert.

Actions müssen außerhalb definiert werden
Actions werden IMMER außerhalb des Use Cases definiert:

// Actions außerhalb definieren
action def UserRequestsStatus;
action def AppQueriesTag;
action def TagReportsStatus;
action def AppDisplaysStatus;
Use Cases verwenden nur perform action
use case checkBatteryStatus {
    subject system : System;

    // Use Cases verwenden nur perform action
    perform action userRequestsStatus : UserRequestsStatus;
    perform action appQueriesTag : AppQueriesTag;
    perform action tagReportsStatus : TagReportsStatus;
    perform action appDisplaysStatus : AppDisplaysStatus;

    first userRequestsStatus then appQueriesTag;
    first appQueriesTag then tagReportsStatus;
    first tagReportsStatus then appDisplaysStatus;
}
Aktionen den ausführenden Parts zuweisen (Allokation)
Verwenden Sie perform action mit Allokation, um die abstrakten Schritte mit konkreten Aktionen der System-parts zu verknüpfen:

use case checkBatteryStatus {
    subject system : System; // Annahme: System hat parts 'app' und 'tag'

    // Allokation der Aktionen zu den Parts
    perform action appQueriesTag ::> system.app.queryTag;
    perform action tagReportsStatus ::> system.tag.reportStatus;

    first appQueriesTag then tagReportsStatus;
}
7. Verhalten: Zustände (State Machines)
State Definition
state def EngineStates {
    state Off;
    state Running;
}
Best Practices für States
Zustände klar trennen, sprechende Namen nutzen
Übergänge und Entry-/Do-Aktivitäten explizit modellieren (nicht im Kopf lassen)
8. Ports & Connections
Port Definition
port def FuelingPort {
    attribute flowRate : Real;
    out fuelOut : Fuel;
    in  fuelIn  : Fuel;
}
Port Usage
port fuelTankPort : FuelingPort;
Connection Definition
connection def DeviceConn {
    end part hub    : Hub;
    end part device : Device;
    attribute bandwidth : Real;
}
Connection Usage mit Binding
connection connection : DeviceConn {
    end part hub    ::> mainSwitch;
    end part device ::> sensorFeed;
}
9. Syntax & Ausdrucksmittel
Kommentare
Zeile: // ...
Block: /* ... */
Dokumentation
doc /* Beschreibungstext */
Zuweisungen & Vergleiche
Zuweisung: mass = 1500 [kg];
Vergleiche: < <= == != >= > === !==
Multiplizität
wheel[4] : Wheel;
wheel[0..*] : Wheel;
10. Lesbarkeit & Konsistenz
Sprechende Namen für part, action, state, requirement
Durchgängig gleiche Namenskonvention (z.B. CamelCase für Definitions, lowerCamelCase für Usages)
Logik in Modellelementen abbilden, nicht in Kommentaren verstecken
Lieber mehr kleine, klar benannte Elemente als ein großes, unlesbares Modell
11. Occurrences (Vorkommen in Raum & Zeit)
Occurrences repräsentieren konkrete Instanzen oder Projekte im Raum-Zeit-Kontext (z.B. MBSE-Projekte, konkrete Systemexemplare).

Occurrence Definition
occurrence def 'MBSE Project';

occurrence 'TVP Coffee Machine' : 'MBSE Project';
occurrence 'ITER Fusion Reactor' : 'MBSE Project';
Best Practices
Verwende occurrence def für "reale" Projekte/Programme oder konkrete Systemexemplare über die Zeit
Nutze sprechende Namen in Kombination mit Anführungszeichen, wenn Leerzeichen notwendig sind
Verwende Occurrences gezielt für:
Projekt-/Programmkontext
Konkrete Systemvarianten im Betrieb
Trace zu Anforderungen, Tests, Use Cases in einem Projekt
12. Use Cases
Use Cases beschreiben die Interaktion von Akteuren mit dem System, um ein Ziel zu erreichen.

Use Case Definition mit subject, actor und objective
part def Human;
part def Environment;
part def Drone;

use case def <ObsDrone> 'Observe area by drone' {
    subject SOI : Drone;
    actor operator : Human;
    actor forest   : Environment;
    objective {
        doc /* Observe a defined area and
             * identify and report potential forest fires.
             */
    }
}
Best Practices
Immer einen subject (System of Interest) angeben
Actors konsequent als Parts/Definitions modellieren (Human, Environment)
Das eigentliche Ziel im objective-Block dokumentieren, nicht nur im Namen
Requirements-Traceability in Use Cases
Use Cases, die Anforderungen erfüllen, nutzen satisfy innerhalb der Use-Case-Definition:

use case def <ObsDrone> 'Observe area by drone' {
    subject SOI : Drone;
    actor operator : Human;
    objective {
        doc /* Observe and report forest fires. */
    }
    satisfy requirementSpecification.detectForestFire;
}
⭐ Actions vs. Perform Actions in Use Cases - WICHTIGE REGEL!
GRUNDPRINZIP: Use Cases beschreiben Abläufe – Actions definieren Verhalten.

KRITISCHE REGEL: In Use Cases werden Actions NIEMALS direkt definiert, sondern IMMER mit perform action referenziert!

✅ RICHTIG: Actions außerhalb definieren
action def InsertCapsule;
action def BrewCoffee {
    out coffee : CoffeeCup;
}
action def EjectCapsule;
✅ RICHTIG: Use Cases verwenden nur perform action
use case def <MakeCoffee> 'Make a Coffee' {
    actor user : Person;
    subject machine : CoffeeMachine;

    perform action insert : InsertCapsule;
    perform action brew : BrewCoffee;
    perform action eject : EjectCapsule;
}
Oder mit Allokation zu System-Parts:

use case grabTowel {
    subject theSubject = systemTowel42;
    actor userActor = user;

    first start then recognizeStepOutside;
    first recognizeStepOutside then done;
    perform action recognizeStepOutside ::> systemTowel42.watchForDeparture;
}
❌ FALSCH: Actions im Use Case definieren
use case checkBatteryStatus {
    // ❌ FALSCH - Actions direkt im Use Case definiert!
    action userRequestsStatus;        // NIEMALS so!
    action appDisplaysStatus;         // NIEMALS so!

    first userRequestsStatus then appDisplaysStatus;
}
Warum ist das falsch?

Keine Wiederverwendbarkeit in anderen Use Cases oder States
Parameter und Outputs können nicht sauber definiert werden
Keine Allokation zu System-Komponenten möglich
Verletzt das Prinzip der Trennung von Definition und Usage
✅ RICHTIG: Korrekte Lösung
// 1. Actions außerhalb definieren
action def UserRequestsStatus;
action def AppDisplaysStatus;

// 2. Im Use Case nur perform action verwenden
use case checkBatteryStatus {
    subject theSubject = systemTowel42.app;
    actor userActor = user;

    perform action userRequestsStatus : UserRequestsStatus;
    perform action appDisplaysStatus : AppDisplaysStatus;

    first userRequestsStatus then appDisplaysStatus;
}
Alternative Pfade im Use Case
Um alternative Abläufe (z.B. basierend auf einer Entscheidung) zu modellieren, verwende das decide-Muster mit guard-Bedingungen, wie in Abschnitt 6 beschrieben.

Wichtige Regeln (UNBEDINGT BEACHTEN!)
Actions (action def) definieren Verhalten → IMMER außerhalb von Use Cases
Perform Actions führen Verhalten aus → NUR diese innerhalb von Use Cases
NIEMALS action xyz; direkt im Use Case schreiben
IMMER perform action xyz : ActionDef; verwenden
Parameter gehören zur Action-Definition, nicht in den Use Case
Wiederverwendbarkeit: Actions können in mehreren Use Cases, States oder Flows genutzt werden
MERKSATZ: Use Cases dürfen KEINE Actions definieren – nur perform actions ausführen!

13. Occurrences in Space & Time (timeslice)
timeslice modelliert zeitliche Aspekte und unterschiedliche Konfigurationen über die Zeit (z.B. charging vs. flying).

Timeslice Usage
part myDrone {
    port chargingPlugPort;

    timeslice part charging {
        connection connect chargingPlugPort
            to chargingStation.chargingSocketPort;
    }

    timeslice part flying;
}
Best Practices
Verwende timeslice, wenn:
Unterschiedliche Konfigurationen/Verbindungen über die Zeit bestehen (z.B. am Ladegerät vs. im Flug)
Bestimmte Eigenschaften nur in bestimmten Betriebsphasen relevant sind
Keine Logik duplizieren:
Gemeinsame Struktur in der umgebenden part definieren
Nur zeitabhängige Aspekte in timeslice-Slices modellieren
Nutze sprechende Namen für timeslice (charging, maintenance, missionFlight)
14. Attribute, Units & Value Types
Attribute Definitionen als eigene Typen
Häufig kombinierte Messgrößen (z.B. min/max/mean, x/y/z, nominal/tolerance) als eigene attribute def modellieren:

attribute def PowerConsumptionData {
    attribute min  : Real;
    attribute max  : Real;
    attribute mean : Real;
}
Vorteil: Attribute bleiben konsistent und wiederverwendbar.

Verwendung mit Einheiten
attribute pcd : PowerConsumptionData {
    attribute :>> min  = 1.0 [W];
    attribute :>> max  = 3.0 [W];
    attribute :>> mean = 2.0 [W];
}
Best Practices
Einheiten immer direkt angeben ([W], [km/h], [min]), besonders in Requirements
assume constraint explizit von require constraint trennen
Stakeholder und Kontext (Actors) möglichst immer angeben
Beispiel: Requirements mit Units und Assumptions
requirement <REQ2> uavFlightTime {
    subject uav : UAV;
    actor environment : UAVEnvironment;
    stakeholder uavExpert;

    assume constraint {
        environment.windSpeed <= 20 ['km/h'];
    }

    require constraint {
        uav.maxFlightTime >= 120 [min];
    }
}
15. Struktur-Patterns: Ports, Connections & Flows
Port Definition als semantische Schnittstelle
port def HeatPort {
    out item 'heat energy';
}
Connection Definition mit interner Struktur
connection def PowerCable {
    end sourceSocket;
    end targetSocket;
    attribute length;
    part cable;
    part sourcePlug;
    part targetPlug;

    connection connect sourceSocket to sourcePlug;
    connection connect sourcePlug  to cable;
    connection connect targetPlug  to cable;
    connection connect targetSocket to targetPlug;
}
Verwendung in Struktur mit Flows und Bindings
part simpleDrone {
    part battery {
        port powerOut;
    }
    part engine {
        port heatOut : HeatPort;
        port powerIn;
    }

    connection pwC : PowerCable
        connect battery.powerOut to engine.powerIn {
        flow Energy {
            end :> sourceSocket;
            end :> targetSocket;
        }
    }

    port heatOut : HeatPort;
    binding bind heatOut = engine.heatOut;
}
Best Practices
Ports als semantische Schnittstellen modellieren (HeatPort, PowerPort), nicht nur als nackte Datentypen
connection def als wiederverwendbare Verbindungstypen – inklusive interner Struktur, falls relevant
flow nutzen, um physikalische Größen explizit zu machen
binding verwenden, um Ports/Attribute sauber zu verknüpfen statt "magischer" Gleichsetzung im Kopf
Naming-Konvention beibehalten:
HeatPort, PowerCable für Definitions
heatOut, pwC für Usages
16. Anmerkung zu satisfy ... by self
Zwei Ansätze
Im OOSE Quick-Sheet wird häufig das Muster verwendet:

part droneX42 : UAV {
    attribute :>> maxFlightTime = 142 [min];
    satisfy uavFlightTime by self;
}
In dieser Best-Practice wird empfohlen, in Architekturelementen kein by self zu verwenden, weil das Element selbst implizit die Quelle der satisfy-Beziehung ist.

Empfohlene Linie
Empfehlung: satisfy requirementX; ohne by self verwenden – das ist kürzer und in der Regel klar genug.
part droneX42 : UAV {
    attribute :>> maxFlightTime = 142 [min];
    satisfy uavFlightTime;
}
Ausnahme: Wenn ein Tool oder ein Teamkonventions-Template explizit by erwartet (z.B. für komplexere by-Ausdrücke), kannst du by self zulassen, um konsistent mit Tooling oder Schulungsmaterial zu bleiben.
Wichtig
satisfy immer auf Requirements zeigen lassen
Das Element, in dem satisfy steht, ist die Quelle der Erfüllung

</sysml_v2>
<editFileInstructions>
Before you edit an existing file, make sure you either already have it in the provided context, or read it with the read_file tool, so that you can make proper changes.
Use the replace_string_in_file tool to edit files, paying attention to context to ensure your replacement is unique. You can use this tool multiple times per file.
Use the insert_edit_into_file tool to insert code into a file ONLY if replace_string_in_file has failed.
When editing files, group your changes by file.
NEVER show the changes to the user, just call the tool, and the edits will be applied and shown to the user.
NEVER print a codeblock that represents a change to a file, use replace_string_in_file or insert_edit_into_file instead.
For each file, give a short description of what needs to be changed, then use the replace_string_in_file or insert_edit_into_file tools. You can use any tool multiple times in a response, and you can keep writing text after using a tool.
Follow best practices when editing files. If a popular external library exists to solve a problem, use it and properly install the package e.g. with "npm install" or creating a "requirements.txt".
If you're building a webapp from scratch, give it a beautiful and modern UI.
After editing a file, any new errors in the file will be in the tool result. Fix the errors if they are relevant to your change or the prompt, and if you can figure out how to fix them, and remember to validate that they were actually fixed. Do not loop more than 3 times attempting to fix errors in the same file. If the third try fails, you should stop and ask the user what to do next.
The insert_edit_into_file tool is very smart and can understand how to apply your edits to the user's files, you just need to provide minimal hints.
When you use the insert_edit_into_file tool, avoid repeating existing code, instead use comments to represent regions of unchanged code. The tool prefers that you are as concise as possible. For example:
// ...existing code...
changed code
// ...existing code...
changed code
// ...existing code...

Here is an example of how you should format an edit to an existing Person class:
class Person {
	// ...existing code...
	age: number;
	// ...existing code...
	getAge() {
		return this.age;
	}
}
</editFileInstructions>

<reminderInstructions>
When using the insert_edit_into_file tool, avoid repeating existing code, instead use a line comment with `...existing code...` to represent regions of unchanged code.
When using the replace_string_in_file tool, include 3-5 lines of unchanged code before and after the string you want to replace, to make it unambiguous which part of the file should be edited.
You must always try making file edits using the replace_string_in_file tool. NEVER use insert_edit_into_file unless told to by the user or by a tool.
</reminderInstructions>
