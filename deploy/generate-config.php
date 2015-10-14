<?php

namespace neam\bootstrap;

// Expect the "paas" config

require(dirname(
        __FILE__
    ) . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'remote' . DIRECTORY_SEPARATOR . 'include.php');

// Add deployment-only overrides

$deploymentEnvPath = "deployments/" . Config::read("APPVHOST", null, $required = true);
$_ENV['CONFIG_INCLUDE'] = "config/remote/include.php";
Config::expect("CONFIG_INCLUDE", $default = null, $required = true);
Config::expect("ENV", $default = $deploymentEnvPath, $required = false);

// Add config metadata

Config::expect("BRANCH_TO_DEPLOY", $default = null, $required = true);
Config::expect("PROJECT_GIT_REPO", $default = null, $required = true);
Config::expect("COMMITSHA", $default = null, $required = true);

// Include the secrets file containing non-versioned secrets
require(getenv('BUILD_DIR') . DIRECTORY_SEPARATOR . 'deploy/config/secrets.php');
