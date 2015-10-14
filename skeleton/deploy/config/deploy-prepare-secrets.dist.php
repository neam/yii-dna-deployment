<?php

namespace neam\bootstrap;

use Exception;

// Non-versioned secrets

$_ENV["TUTUM_USER"] = "";
$_ENV["TUTUM_EMAIL"] = "";
$_ENV["TUTUM_PASSWORD"] = "";
$_ENV["TUTUM_APIKEY"] = "";

$_ENV["DEVELOPMENT_SMTP_HOST"] = "mailcatcher";
$_ENV["DEVELOPMENT_SMTP_PORT"] = "25";
$_ENV["DEVELOPMENT_SMTP_USERNAME"] = "foo";
$_ENV["DEVELOPMENT_SMTP_PASSWORD"] = "bar";
$_ENV["DEVELOPMENT_SMTP_ENCRYPTION"] = "foo";

$_ENV["PRODUCTION_SMTP_HOST"] = "smtp.example.com";
$_ENV["PRODUCTION_SMTP_PORT"] = "587";
$_ENV["PRODUCTION_SMTP_USERNAME"] = "changeme";
$_ENV["PRODUCTION_SMTP_PASSWORD"] = "changeme";
$_ENV["PRODUCTION_SMTP_ENCRYPTION"] = "tls";

$_ENV["DEVELOPMENT_GA_TRACKING_ID"] = "";
$_ENV["PRODUCTION_GA_TRACKING_ID"] = "";

// Amazon RDS administration
$_ENV["DEV_RDS_HOST"] = "";
$_ENV["PROD_RDS_HOST"] = "";
$_ENV["DEV_RDS_HOST_ROOT_USER"] = "master";
$_ENV["DEV_RDS_HOST_ROOT_PASSWORD"] = "";
$_ENV["PROD_RDS_HOST_ROOT_USER"] = "master";
$_ENV["PROD_RDS_HOST_ROOT_PASSWORD"] = "";
