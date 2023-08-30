#!/usr/bin/env -S -- php
<?php
chdir(__DIR__);

$f = basename(__FILE__);
printf("HELO :: VIA -- {$f}\n");

$sh = join(
  " ",
  array_map("escapeshellarg", [
    "bat",
    "--color=always",
    "--decorations=always",
    "--",
    __FILE__,
  ])
);
$code = -1;
assert(passthru($sh, $code) == null);
assert($code == 0);


?>
