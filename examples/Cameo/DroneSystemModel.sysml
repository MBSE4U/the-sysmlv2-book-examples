package <DSM> DroneSystemModel {
    dependency DependsOnBaseArchitecture from DSRE to DSBA {
        doc /* Specifies that the system requirements depends on the base architecture. */
    }
    dependency DSPA, DSFA to DSRE;
    package <DSUC> DroneSystem_UseCases;
    package <DSC> DroneSystem_SystemContext;
    package <DSFA> 'DroneSystem_Functional Architecture';
    package <DSD> DroneSystem_Domain {
        attribute def Coordinate;
    }
    package <DSPC> DroneSystem_ProjectContext {
        private import MBSE::*;
        occurrence def UAVProject {
            part stakeholders [*] : CommonStakeholder;
            part airTrafficControlAuthority :> stakeholders;
            part uavSpecialist :> stakeholders {
                attribute :>> risk = risk::high;
                attribute :>> effort = risk::low;
                attribute :>> kind = kind::Expert;
                attribute :>> contact = "u.av@mbse4u.com";
            }
            part droneSystemContext : DSRE::DroneSystemContext;
            requirement uavSystemRequirements : DSRE::TextualRequirements::UAVSystemRequirements {
                subject :>> theUAV = droneSystemContext.droneSystem;
                requirement :>> uavFlightTime {
                    subject :>> theUAV :> droneSystemContext.droneSystem;
                    stakeholder :>> uavExpert = uavSpecialist;
                }
                requirement :>> maximumTakeOffWeight {
                    subject :>> theUAV :> droneSystemContext.droneSystem;
                    stakeholder :>> uavExpert = uavSpecialist;
                }
                requirement :>> observeArea {
                    subject :>> theUAV :> droneSystemContext.droneSystem;
                    stakeholder :>> uavExpert = uavSpecialist;
                }
            }
            part droneSOI : DSPA::Drone {
                satisfy uavSystemRequirements.uavFlightTime;
            }
            satisfy uavSystemRequirements.maximumTakeOffWeight by droneSOI;
        }
    }
    package <DSBA> 'DroneSystem_Base Architecture' {
        part def CommonUAVSystemContext {
            part uavSystem : CommonUAVSystem;
            part environment : 'UAV Environment';
            connect environment to uavSystem;
        }
        part def CommonUAVSystem {
            part uav [*] : CommonUAV;
            part remoteControl [*];
            part charger [*];
        }
        part def CommonUAV {
            attribute maxFlightTime :> ISQBase::duration;
            attribute actualMass :> ISQBase::mass;
            attribute callsign : ScalarValues::String;
        }
        part def 'UAV Environment' {
            attribute windSpeed :> ISQSpaceTime::speed;
        }
    }
    package <DSRE> 'DroneSystem_System Requirements' {
        private import MBSE::*;
        private import DSPC::*;
        private import DSBA::*;
        part def DroneSystemContext :> CommonUAVSystemContext {
            part droneSystem : DroneSystem :>> uavSystem;
        }
        part def DroneSystem;
        package FormalizedRequirements {
            requirement def UAVSystemRequirements {
                subject theUAV : CommonUAV;
                requirement <REQ2> uavFlightTime : CommonRequirement {
                    doc
                    /* When standard conditions apply, the UAV shall 
                     * fly for at least 2 hours. 
                     */
                    subject uav : CommonUAV :> theUAV;
                    stakeholder uavExpert : CommonStakeholder;
                    actor uavEnvironment : 'UAV Environment';
                    attribute :>> motivation = "Drones are primarily used for long lasting observation missions";
                    attribute :>> priority = priority::high;
                    attribute :>> stability = stability::stable;
                    attribute :>> kind = kind::performance;
                    require constraint {
                        uav.maxFlightTime >= 120 [SI::min]
                    }
                    assume constraint {
                        uavEnvironment.windSpeed <= 20 [SI::'km/h']
                    }
                }
                requirement <REQ3> maximumTakeOffWeight : CommonRequirement {
                    doc /* The maximum takeoff weight shall not exceed 42 kg. */
                    subject uav : CommonUAV :> theUAV;
                    stakeholder uavExpert : CommonStakeholder;
                    attribute :>> motivation = "Due to preliminary analyzes, efficient drones cannot be developed at higher weights.";
                    attribute :>> priority = priority::high;
                    attribute :>> stability = stability::stable;
                    attribute :>> kind = kind::performance;
                    require constraint {
                        uav.actualMass <= 42 [SI::kg]
                    }
                }
            }
        }
        package TextualRequirements {
            requirement def UAVSystemRequirements {
                subject theUAV : CommonUAV;
                requirement <REQ2> uavFlightTime : CommonRequirement {
                    doc
                    /* When standard conditions apply, the UAV shall 
                     * fly for at least 2 hours. 
                     */
                    subject theUAV : CommonUAV;
                    stakeholder uavExpert : CommonStakeholder;
                    attribute :>> motivation = "Drones are primarily used for long lasting observation missions";
                    attribute :>> priority = priority::high;
                    attribute :>> stability = stability::stable;
                    attribute :>> kind = kind::performance;
                }
                requirement <REQ3> maximumTakeOffWeight : CommonRequirement {
                    subject theUAV : CommonUAV;
                    stakeholder uavExpert : CommonStakeholder;
                    attribute :>> motivation = "Due to preliminary analyzes, efficient drones cannot be developed at higher weights.";
                    attribute :>> priority = priority::high;
                    attribute :>> stability = stability::stable;
                    require constraint {
                        language "English" /* The maximum takeoff weight shall not exceed 42 kg. */
                    }
                }
                requirement <REQ23> observeArea : CommonRequirement {
                    doc /* The drone must be able to monitor a defined area. */
                    subject theUAV : CommonUAV;
                    stakeholder uavExpert : CommonStakeholder;
                    attribute :>> motivation = "Observing an area is one of the main mission functions of the system.";
                    attribute :>> priority = priority::high;
                    attribute :>> stability = stability::stable;
                }
            }
        }
    }
    package MBSE {
        part def CommonStakeholder {
            attribute risk : LevelKind;
            attribute effort : LevelKind;
            derived attribute priority : ScalarValues::Integer = risk * effort;
            attribute kind : StakeholderCategoryKind;
            attribute contact : ScalarValues::String;
        }
        enum def LevelKind :> ScalarValues::Integer {
            undefined = 0;
            low = 1;
            middle = 2;
            high = 3;
        }
        enum def StakeholderCategoryKind {
            Expert;
            RequirementOwner;
            User;
            Other;
        }
        requirement def CommonRequirement {
            attribute motivation : ScalarValues::String;
            attribute priority : LevelKind;
            attribute stability : StabilityKind;
            attribute kind : RequirementKind;
        }
        enum def StabilityKind {
            stable;
            unstable;
            undefined;
        }
        enum def RequirementKind {
            functional;
            performance;
            safety;
            legal;
            physical;
        }
    }
    package <DSPA> 'DroneSystem_Physical Architecture' {
        private import DSRE::*;
        item def Payload {
            attribute mass :> ISQBase::mass = box.mass + content.mass;
            attribute description : ScalarValues::String;
            item box : PackageBox;
            item content : PayloadContent;
        }
        part def 'Drone System' {
            part drones [*] : Drone {
                connect powerDistributionSystem to battery;
                connect powerDistributionSystem to engines;
            }
            part transportBox : 'Drone Transport Box';
            part chargers [*] : Charger;
            connect chargers to drones.battery;
        }
        item def PackageBox {
            attribute mass :> ISQBase::mass;
        }
        item def PayloadContent {
            attribute mass :> ISQBase::mass;
        }
        part def PayloadAttachment {
            item payload [0..1] : Payload;
        }
        part def 'Drone Transport Box' {
            item battery : Battery;
        }
        part def Drone :> DSBA::CommonUAV {
            attribute :>> actualMass = 50 [SI::kg];
            attribute :>> maxFlightTime = 150 [SI::min];
            assert constraint {
                actualMass <= 62000 [SI::g]
            }
            part engines [*];
            attribute flightStatus : FlightStatus;
            part controlUnit {
                part navigationApp {
                    attribute waypoints [*] nonunique : DSD::Coordinate;
                    attribute numberOfStops : ScalarValues::Integer = SequenceFunctions::size(waypoints);
                }
            }
            part powerDistributionSystem : PowerDistributionSystem;
            part battery : Battery;
            part body {
                part 'frame';
                part payloadAttachment : PayloadAttachment;
            }
            connect battery to engines;
            interface powerInterface connect battery.energyOutPort to powerDistributionSystem.energyInPort {
                flow of ElectricalPower from battery.energyOutPort.electricalEnergy to powerDistributionSystem.energyInPort.electricalEnergy;
            }
            port chargePort : ~EnergyPort {
                attribute :>> nominalVoltage = 240 [SI::V];
            }
            bind chargePort = battery.chargeInPort;
        }
        constraint def PowerConstraint {
            in part powerProducer : PowerProducer;
            in part powerConsumers : PowerConsumer [*];
            attribute totalPowerUsage :> ISQElectromagnetism::electricPower = QuantityCalculations::sum(powerConsumers.maxPowerUse);
            totalPowerUsage <= powerProducer.maxPower
        }
        constraint def PowerConstraintWithActions {
            in part powerProducer : PowerProducer;
            in part powerConsumers : PowerConsumer [*];
            attribute totalPowerUsage :> ISQElectromagnetism::electricPower = QuantityCalculations::sum(powerConsumers.maxPowerUse);
            action getMaxPower : RetrieveMaximumPowerProduction { in part :>> producer = powerProducer; }
            totalPowerUsage <= getMaxPower.maxPower
        }
        action def RetrieveMaximumPowerProduction {
            in part producer : PowerProducer;
            out attribute maxPower :> ISQElectromagnetism::electricPower;
        }
        part def PowerProducer {
            attribute maxPower :> ISQElectromagnetism::electricPower;
        }
        part def PowerConsumer {
            attribute maxPowerUse :> ISQElectromagnetism::electricPower;
        }
        connection def PowerDistribution {
            end producer [1] : PowerProducer;
            end consumers [1..*] : PowerConsumer;
            assert constraint powerConsumption : PowerConstraint {
                in part :>> powerProducer = producer;
                in part :>> powerConsumers = consumers;
            }
        }
        part def PowerDistributionSystem {
            port energyInPort : ~EnergyPort {
                attribute :>> nominalVoltage = 22.2 [SI::V];
            }
        }
        part def Battery {
            attribute voltage :> ISQElectromagnetism::voltage;
            port energyOutPort : EnergyPort {
                attribute :>> voltage = 22.2 [SI::V];
            }
            port chargeInPort : ~EnergyPort {
                attribute :>> voltage = 240 [SI::V];
            }
        }
        port def EnergyPort {
            out item electricalEnergy : ElectricalPower;
            attribute nominalVoltage :> ISQElectromagnetism::voltage;
            attribute allowableVoltageVariation : ScalarValues::Real default 0.1;
            assert constraint {
                NumericalFunctions::abs(electricalEnergy.voltage - nominalVoltage) <= nominalVoltage * allowableVoltageVariation
            }
        }
        item def ElectricalPower {
            attribute voltage :> ISQElectromagnetism::voltage;
        }
        part def Charger;
        attribute def FlightStatus {
            attribute speed :> ISQSpaceTime::speed;
            attribute altitude :> ISQSpaceTime::height;
            attribute flightTime :> ISQBase::duration;
            attribute <erft> estimatedRemainingFlightTime :> ISQBase::duration;
        }
        part def Wheel {
            doc /* A Wheel specifies a wheel. */
        }
        allocate DSLA::DroneSystem::navigationModule to Drone::controlUnit;
        allocate DSLA::DroneSystem::missionModule to Drone::controlUnit;
        allocate DSLA::DroneSystem::flightModule to Drone::controlUnit;
    }
    package <DSLA> DroneSystem_LogicalArchitecture {
        part def DroneSystem {
            part navigationModule;
            part flightModule;
            part missionModule;
        }
    }
}
package 'Surveillance Drone Product' {
    private import DSM::DSPA::*;
    part surveillanceDrone : Drone;
    part charger : Charger;
}
package 'The SysMLv2 Book Views' {
    view BookViews : 'SysML Standard Diagrams'::gv;
    view FigAllocation : 'SysML Standard Diagrams'::gv;
    view FigAttributeDefinition : 'SysML Standard Diagrams'::gv;
    view FigAttributeEnumeration : 'SysML Standard Diagrams'::gv;
    view FigAttributeNonuniqueDerived : 'SysML Standard Diagrams'::gv;
    view FigBaseSystem : 'SysML Standard Diagrams'::gv;
    view FigCommonRequirement : 'SysML Standard Diagrams'::gv;
    view FigCommonRequirementUsage : 'SysML Standard Diagrams'::gv;
    view FigConnectionSimple : 'SysML Standard Diagrams'::gv;
    view FigConstraintActions : 'SysML Standard Diagrams'::gv;
    view FigConstraintDefinition : 'SysML Standard Diagrams'::gv;
    view FigConstraintDefinitionWithActions : 'SysML Standard Diagrams'::gv;
    view FigConstraintUsage : 'SysML Standard Diagrams'::gv;
    view FigDependency : 'SysML Standard Diagrams'::gv;
    view FigDocumentation : 'SysML Standard Diagrams'::gv;
    view FigFormalizedRequirement : 'SysML Standard Diagrams'::gv;
    view FigImportNamespace : 'SysML Standard Diagrams'::gv;
    view FigItemDefinition : 'SysML Standard Diagrams'::gv;
    view FigNamedElements : 'SysML Standard Diagrams'::gv;
    view FigPackageStructure : 'SysML Standard Diagrams'::gv;
    view FigPartItem : 'SysML Standard Diagrams'::gv;
    view FigPartBreakdownStructure : 'SysML Standard Diagrams'::gv;
    view FigPartConnections : 'SysML Standard Diagrams'::gv;
    view FigPayloadAttachment : 'SysML Standard Diagrams'::gv;
    view FigPortUsages : 'SysML Standard Diagrams'::gv;
    view FigQuantity : 'SysML Standard Diagrams'::gv;
    view FigRequirementActor : 'SysML Standard Diagrams'::gv;
    view FigRequirementGroup : 'SysML Standard Diagrams'::gv;
    view FigRequirementSatisfaction : 'SysML Standard Diagrams'::gv;
    view FigRequirementUsage : 'SysML Standard Diagrams'::gv;
    view FigStakeholderDefinition : 'SysML Standard Diagrams'::gv;
    view FigStakeholderModelProject : 'SysML Standard Diagrams'::gv;
    view FigUnit : 'SysML Standard Diagrams'::gv;
    view FigUnitConversion : 'SysML Standard Diagrams'::gv;
    /* Showing parameter in a compartment not possible*/
    /* Constraint expression should be depicted in a separate compartment*/
    /* assert constraint compartment cannot be shown*/
    view 'FigG-Subclassification' : 'SysML Standard Diagrams'::gv;
    view 'FigG-ReferenceSubsetting' : 'SysML Standard Diagrams'::gv;
}
package 'Drone System Views' {
    view 'Drone System Model' : 'SysML Standard Diagrams'::gv;
}
