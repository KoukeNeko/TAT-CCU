<?php
// Test site only: fixed credentials, data on tmpfs, debugging on.
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'db';
$CFG->dbname    = 'moodle';
$CFG->dbuser    = 'moodle';
$CFG->dbpass    = 'moodle';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = ['dbcollation' => 'utf8mb4_unicode_ci'];

// OrbStack ends TLS and forwards plain HTTP to the container.
$CFG->wwwroot  = 'https://ecourse2.tatccu.orb.local';
$CFG->sslproxy = true;
$CFG->dataroot = '/var/www/moodledata';
$CFG->admin    = 'admin';
$CFG->directorypermissions = 0777;

$CFG->debug = E_ALL;
$CFG->debugdisplay = 0;

require_once(__DIR__ . '/lib/setup.php');
