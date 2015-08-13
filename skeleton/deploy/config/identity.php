<?php

namespace neam\bootstrap;

// Identity-related deployment defaults

switch (Config::read('TOPLEVEL_DOMAIN')) {

    case "example.com":
        $_ENV['BRAND_HOME_URL'] = "http://example.com";
        $_ENV['SITENAME'] = "Example Site";
        $_ENV['SUPPORT_EMAIL'] = "info@example.com";
        $_ENV['MAIL_SENDER_EMAIL'] = "info@example.com";
        $_ENV['MAIL_SENDER_NAME'] = "Example";
        break;

    case "exampledev.com":
        $_ENV['BRAND_HOME_URL'] = "http://exampledev.com";
        $_ENV['SITENAME'] = "DEV Example Site";
        $_ENV['SUPPORT_EMAIL'] = "info+dev@example.com";
        $_ENV['MAIL_SENDER_EMAIL'] = "info+dev@example.com";
        $_ENV['MAIL_SENDER_NAME'] = "DEV Example";
        break;

}
