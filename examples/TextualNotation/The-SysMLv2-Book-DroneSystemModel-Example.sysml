package <DSM> DroneSystemModel {
    doc
    /* 
     *  Root package of the Drone System Model Example model from "The SysML v2 Book" published by MBSE4U.
     *
     *  MBSE4U: https://mbse4u.com
     *  Book on Leanpub: https://leanpub.com/sysmlv2
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *  http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     *
     * Copyright 2025 Tim Weilkiens, Vince Molnar
     *
     */
    dependency DependsOnBaseArchitecture from DSRE to DSBA {
        doc /* Specifies that the system requirements depends on the base architecture. */
    }
    dependency DSPA, DSFA to DSRE;
    package <DSUC> DroneSystem_UseCases;

    package <DSP> DroneSystem_Project {
        private import MBSEMethodology::*;
        occurrence def UAVProject {
            part stakeholders [*] : CommonStakeholder;
            part airTrafficControlAuthority :> stakeholders;
            part uavSpecialist :> stakeholders {
                attribute :>> risk = risk::high;
                attribute :>> effort = risk::low;
                attribute :>> kind = kind::Expert;
                attribute :>> contact = "u.av@mbse4u.com";
            }
            part droneSystemContext : DSS::DroneSystemContext;
            requirement uavSystemRequirements : DSRE::TextualRequirements::UAVSystemRequirements {
                subject :>> theUAV :> droneSystemContext.droneSystem;
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
    package <DSD> DroneSystem_Domain {
        attribute def Coordinate;
    }
    package <DSS> DroneSystem_System {
        private import MBSEMethodology::*;
        private import DSBA::*;        

        part def DroneSystemContext :> CommonUAVSystemContext {
            part droneSystem : DroneSystem :>> uavSystem;
        }
        part def DroneSystem;
    }
    package <DSRE> 'DroneSystem_System Requirements' {
        private import MBSEMethodology::*;
        private import DSP::*;
        private import DSBA::*;
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
    package <DSFA> 'DroneSystem_Functional Architecture';    
    package <DSLA> DroneSystem_LogicalArchitecture {
        part def DroneSystem {
            part navigationModule;
            part flightModule;
            part missionModule;
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
                    attribute numberOfStops : ScalarValues::Integer;
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
            ref bind chargePort = battery.chargeInPort;
        }
        constraint def PowerConstraint {
            in part powerProducer : PowerProducer;
            in part powerConsumers : PowerConsumer [*];
            attribute totalPowerUsage :> ISQElectromagnetism::electricPower;
            totalPowerUsage <= powerProducer.maxPower
        }
        constraint def PowerConstraintWithActions {
            in part powerProducer : PowerProducer;
            in part powerConsumers : PowerConsumer [*];
            attribute totalPowerUsage :> ISQElectromagnetism::electricPower;
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
        allocate DSLA::DroneSystem::navigationModule to Drone::controlUnit;
        allocate DSLA::DroneSystem::missionModule to Drone::controlUnit;
        allocate DSLA::DroneSystem::flightModule to Drone::controlUnit;
        package <MC> MobileCharger {
            package <MCPA> 'MobileCharger_Physical Architecture' {
                part def Wheel {
                    doc /* A Wheel specifies a wheel. */
                }
                part def 'Mobile Charger' {
                    part 'wheels[6] : Wheel';
                    part chargingUnit;
                    part body;
                    part dronePlatform {
                        /* Serves as landing and charging interface for drones */
                    }
                }
            }
        }
    }
}
package 'Surveillance Drone Product' {
    private import DSM::DSPA::*;
    part surveillanceDrone : Drone;
    part charger : Charger;
}
package MBSEMethodology {
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