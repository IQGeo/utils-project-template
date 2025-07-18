// NMTCFI WFM Integration
// Load comsof (which includes comms) first 
import 'modules/comsof/js/main.mywcom';

// Load workflow manager
import 'modules/workflow_manager/js/main.base';
import LicenseManagerPlugin from './plugins/licenseManagerPlugin';

const plugins = myw.applicationDefinition.plugins;
plugins['licenseManager'] = LicenseManagerPlugin;
