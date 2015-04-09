<?php

namespace neam\bootstrap;

use Exception;

// Optionally include a identity file containing identity-related deployment defaults

$path = dirname(__FILE__) . DIRECTORY_SEPARATOR . 'identity.php';
if (is_readable($path)) {
    require($path);
}

// Non-versioned secrets

$_ENV["SAUCE_ACCESS_KEY"] = "";
$_ENV["SAUCE_USERNAME"] = "";

$_ENV["USER_DATA_BACKUP_UPLOADERS_ACCESS_KEY"] = "";
$_ENV["USER_DATA_BACKUP_UPLOADERS_SECRET"] = "";
$_ENV["PUBLIC_FILE_UPLOADERS_ACCESS_KEY"] = "";
$_ENV["PUBLIC_FILE_UPLOADERS_SECRET"] = "";
$_ENV["PUBLIC_FILES_S3_REGION"] = "eu-west-1";

$_ENV["COMPOSER_GITHUB_TOKEN"] = "";
$_ENV["TUTUM_USER"] = "";
$_ENV["TUTUM_EMAIL"] = "";
$_ENV["TUTUM_PASSWORD"] = "";
$_ENV["TUTUM_APIKEY"] = "";
$_ENV["NEW_RELIC_LICENSE_KEY"] = "";

$_ENV["DEVELOPMENT_SMTP_URL"] = "smtp://mailcatcher:25";
$_ENV["PRODUCTION_SMTP_URL"] = "";

$_ENV["FILEPICKER_API_KEY"] = "";

$_ENV["DEVELOPMENT_GA_TRACKING_ID"] = "";
$_ENV["PRODUCTION_GA_TRACKING_ID"] = "";

$_ENV["SENTRY_DSN"] = "";

// Deployment-specifics
$_ENV['WEB_SERVER_POSIX_USER'] = "www-data";
$_ENV['WEB_SERVER_POSIX_GROUP'] = "www-data";

// SMS Messaging service Twilio
$_ENV["TWILIO_ACCOUNT_SID"] = "AC8c7a2821177ed021d4b2441f9b837a90";
$_ENV["TWILIO_FROM_NUMBER"] = "+46769446600";
$_ENV["TWILIO_AUTH_TOKEN"] = "";

// Heywatch
$_ENV["HEYWATCH_API_USERNAME"] = "";
$_ENV["HEYWATCH_API_KEY"] = "";
$_ENV["ENCODING_FILES_S3_API_KEY"] = "";
$_ENV["ENCODING_FILES_S3_SECRET"] = "";
$_ENV["ENCODING_FILES_S3_BUCKET"] = "s3://encoding.adoveo.com";
$_ENV["ENCODING_FILES_S3_REGION"] = "eu-west-1";

// Smtp url
if (Config::read("BRANCH_TO_DEPLOY") === "master") {
    $_ENV["SMTP_URL"] = $_ENV["PRODUCTION_SMTP_URL"];
    $_ENV["GA_TRACKING_ID"] = $_ENV["DEVELOPMENT_GA_TRACKING_ID"];
} else {
    $_ENV["SMTP_URL"] = $_ENV["DEVELOPMENT_SMTP_URL"];
    $_ENV["GA_TRACKING_ID"] = $_ENV["DEVELOPMENT_GA_TRACKING_ID"];
}

// Amazon RDS administration

$_ENV["DEV_RDS_HOST"] = "";
$_ENV["PROD_RDS_HOST"] = "";
$_ENV["DATABASE_ROOT_USER"] = "";
$_ENV["DATABASE_ROOT_PASSWORD"] = ""; // Tmp using hardcoded details for rds dev-1

// Amazon RDS app access details

$app = Config::read("APPVHOST");
switch ($app) {
    case "develop-foo.adoveodev.com":
        $_ENV["DATABASE_HOST"] = "";
        $_ENV["DATABASE_PORT"] = "";
        $_ENV["DATABASE_USER"] = "";
        $_ENV["DATABASE_NAME"] = "";
        $_ENV["DATABASE_PASSWORD"] = "";
        break;
    default:
        throw new Exception("Amazon RDS deploy database access credentials missing for app '{$app}'");
        $_ENV["DATABASE_HOST"] = "";
        $_ENV["DATABASE_PORT"] = "";
        $_ENV["DATABASE_USER"] = "";
        $_ENV["DATABASE_NAME"] = "";
        $_ENV["DATABASE_PASSWORD"] = "";
        break;
    case "";
        // During prepare-step APPVHOST will be empty, which is fine, we don't need database credentials at that stage
        break;
}
