<?php

namespace neam\bootstrap;

// Expect the adoveo-web "paas" config

require(dirname(
        __FILE__
    ) . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'paas' . DIRECTORY_SEPARATOR . 'include.php');

// Expect the pages config

// TODO

// Add deployment-only overrides

$deploymentEnvPath = "deployments/" . Config::read("APPVHOST");
$_ENV['CONFIG_INCLUDE'] = "config/paas/include.php";
Config::expect("CONFIG_INCLUDE", $default = null, $required = true);
Config::expect("ENV", $default = $deploymentEnvPath, $required = false);

// Loads sensitive (non-versioned) environment variables from .env to getenv(), $_ENV.
//\Dotenv::makeMutable();
//\Dotenv::load($project_root . '/' . $deploymentEnvPath);

// Include the secrets file containing non-versioned secrets
require(getenv('BUILD_DIR') . DIRECTORY_SEPARATOR . 'deploy/config/secrets.php');
