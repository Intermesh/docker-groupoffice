<?php
require "docker-config.php";

$config['db_port'] = 3306;
$config['file_storage_path'] = "/var/lib/groupoffice";
$config['tmpdir'] = "/tmp/groupoffice";
$config['debug'] = false;
$config['business'] = array (
	'studio' =>
		array (
			'package' => 'studio',
		)
);