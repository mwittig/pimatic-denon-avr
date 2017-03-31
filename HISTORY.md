# Release History

* 20170331, V0.9.7
    * Changed the minimum interval time for status updates from 10 to 2 seconds
    * Added coffeelint style checker to build process
    * Coding style fixes
    * Revised README
    
* 20170307, V0.9.6
    * Added "xAttributeOptions" to config schema for DenonAvrPresenceSensor, DenonAvrMasterVolume, 
      and DenonAvrZoneVolume
    * Revised README, documented the relevant predicates and actions available for each device type 
    
* 20170225, V0.9.5
    * Added action to select the input source as part of rules
    
* 20170210, V0.9.4
    * Changed behavior of master volume to avoid video disruption, issue #16 
    * Improved Error Handling, issue #17
    
* 20161020, V0.9.3
    * Dependency updates
    
* 20161020, V0.9.2
    * Updated to restler-promise@0.0.4
    * Revised README
    
* 20161001, V0.9.1
    * Added HTTP transport which can be used with '11, '12, '13, and X series AVR and newer models released since 2014
    * Improved volume control mapping between absolute, dB, and slider levels
    * Added support for undocumented MVMAX (telnet transport, only)
    * Added proper removal of event listeners to device destroy() methods to avoid potential resource leak
    
* 20160714, V0.9.0
    * Dependency Update for pimatic-plugin-commons which corrects handling of continuous attribute values
    * Removed dependency on bluebird as pimatic 0.9 supports bluebird v3.x
    * Reversed order of release history
    * Removed Travis build for node.js 0.10
    
* 20160419, V0.8.9
    * Added call super() on destroy()
    
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