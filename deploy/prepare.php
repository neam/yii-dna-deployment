<?php

namespace neam\bootstrap;

// Required in order to prepare the deployment

Config::expect("BRANCH_TO_DEPLOY", $default = null, $required = true);
Config::expect("DRONE_BUILD_DIR", $default = null, $required = true);

// Affects the resulting deployment subdomain

Config::expect("DATA", $default = null, $required = true);
Config::expect("GRANULARITY", $default = "project-branch-specific", $required = false);

// Necessary to include in config since these are defined in secrets.php

Config::expect("DEVELOPMENT_GA_TRACKING_ID", $default = "UA-XXXXXX-X", $required = true);
Config::expect("PRODUCTION_GA_TRACKING_ID", $default = "UA-XXXXXX-X", $required = true);

Config::expect("DEVELOPMENT_SMTP_HOST", $default = "", $required = true);
Config::expect("DEVELOPMENT_SMTP_PORT", $default = "", $required = true);
Config::expect("DEVELOPMENT_SMTP_USERNAME", $default = "", $required = true);
Config::expect("DEVELOPMENT_SMTP_PASSWORD", $default = "", $required = false);
Config::expect("DEVELOPMENT_SMTP_ENCRYPTION", $default = "", $required = false);
Config::expect("PRODUCTION_SMTP_HOST", $default = "", $required = true);
Config::expect("PRODUCTION_SMTP_PORT", $default = "", $required = true);
Config::expect("PRODUCTION_SMTP_USERNAME", $default = "", $required = true);
Config::expect("PRODUCTION_SMTP_PASSWORD", $default = "", $required = true);
Config::expect("PRODUCTION_SMTP_ENCRYPTION", $default = "", $required = true);

Config::expect("DEV_RDS_HOST", $default = "", $required = true);
Config::expect("DEMO_RDS_HOST", $default = "", $required = false);
Config::expect("PROD_RDS_HOST", $default = "", $required = true);

// Necessary only during build/deploy process (not by app itself) - thus we require it here, but not for setting app config

Config::expect("TUTUM_USER", $default = null, $required = true);
Config::expect("TUTUM_EMAIL", $default = null, $required = true);
Config::expect("TUTUM_PASSWORD", $default = null, $required = true);
Config::expect("TUTUM_APIKEY", $default = null, $required = true);

// Include the secrets file containing non-versioned secrets

require(getenv('BUILD_DIR') . DIRECTORY_SEPARATOR . 'deploy/config/deploy-prepare-secrets.php');
