# Release History

* 20160416, V0.8.8
    * Added support for controlling multiple zones
    * Added DenonAvrInputSelector, DenonAvrZoneSwitch, DenonAvrZoneVolume device classes
    * Updated and extended README documentation
    * Added release history and license information

* 20160323, V0.8.7
    * Implemented auto-discovery for pimatic 0.9
    * Updated peerDependencies property for compatibility with pimatic 0.9
    * Fixed compatibility issue with Coffeescript 1.9 as required for pimatic 0.9
    * Updated dependencies

* 20160305, V0.8.6
    * Replaced deprecated usage of Promis.settle() function
    * Updated dependencies
    * Added travis build descriptor
    * Minor formatting changes of READMEfile

* 20151215, V0.8.5
    * Replaced promise retryer to get proper retry cycles
    * Bug fix: Guard connect() method instead of _connect()
    * Bug fix: Use 'when ... then' instead of 'when ...' with switch statement to get proper case breaks generated
    * Fixed typos

* 20151213, V0.8.4
    * Proper synchronization of flush() methods to prevent multiple send outs of the same command set
    * Enforce wait time of 2 seconds after PWON for subsequent commands
    * Enforce minimum value of 10 for interval property
    * Updated to pimatic-plugin-commons@0.8.2
    * Refactoring: use commons where applicable, remove dead code
    * Updated README

* 20151213, V0.8.3
    * Added MasterMute device
    * Fixed connection handling
    * Refactoring

* 20151212, V0.8.2
    * Added volumeDecibel property on PresenceSensor to optionally display volume in dB
    * Fixed changeStateTo() state handling
    * Improved errror handling on _requestUpdate() calls

* 20151212, V0.8.1
    * Improved connection handling. Close connection on idle to allow for multiple applications using the control port.
    * Fixed update scheduling.
    * Various fixes.

* 20151212, V0.8.0
    * Initial version