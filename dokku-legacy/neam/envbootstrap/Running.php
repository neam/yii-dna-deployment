<?php

namespace neam\envbootstrap;

abstract class Running
{

    static public function asUser()
    {
        $return = $_ENV["user"];
        return self::mustNotBeEmpty($return);
    }

    static public function onHostname()
    {
        $return = php_uname("n");
        return self::mustNotBeEmpty($return);
    }

    static public function asCli()
    {
        return php_sapi_name() == 'cli';
    }

    static public function inPath()
    {
        if (self::asCli()) {
            $return = $_SERVER['PWD'];
        } else {
            $return = $_SERVER['DOCUMENT_ROOT'];
        }
        return self::mustNotBeEmpty($return);
    }

    static public function inRealPath()
    {
        if (self::asCli()) {
            $return = realpath($_SERVER['PWD']);
        } else {
            $return = realpath($_SERVER['DOCUMENT_ROOT']);
        }
        return self::mustNotBeEmpty($return);
    }

    static public function usingDomainName()
    {
        if (self::asCli()) {
            $http_host = getenv('HTTP_HOST');
            if (empty($http_host)) {
                throw new \CException("Environment variable HTTP_HOST needs to be set");
            }
            $return = $http_host;
        } else {
            $return = $_SERVER['HTTP_HOST'];
        }
        return self::mustNotBeEmpty($return);
    }

    static private function mustNotBeEmpty($val)
    {
        if (empty($val)) {
            throw new \Exception("Must have non-empty property");
        }
        return $val;
    }

    /**
     * Env Param that comes from server virtual host,
     * currently support only apache
     * @param $param
     * @return string
     */
    static public function envParam( $param )
    {
        if( function_exists( 'apache_getenv' ) )
            return apache_getenv($param);
        else
            return '';
    }

    static public function onWebserver()
    {
    }

}