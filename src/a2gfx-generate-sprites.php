<?
	$im = imagecreatefrompng("moon.png");
	$width = imagesx($im);
	assert(($width % 7) === 0);
	$height = imagesy($im);
	assert((imagesx($im) % $width) === 0);

	$pattern = 1;

	for ($y = 0; $y < $height; $y++) {
		if ($y == 0) {
			printf("SPRITE");
		}

		$binary = "";
		$rowbinary = "";
		$hex = "";
		for ($x = 0; $x < imagesx($im); $x += 7) {
			$byte = ($pattern == 0) ? 0 : 0x80;
			for ($j = 0; $j < 7; $j++) {
				$v = imagecolorat($im, $x + 6 - $j, $y);
				if ($v != 0) {
					$byte |= (1 << (6 - $j));
					$binary .= "x";
				} else {
					$binary .= " ";
				}
			}

			$hex .= sprintf("%02x ", $byte);
			$rowbinary = $binary . $rowbinary;
			$binary = "";

			if (strlen($rowbinary) == 42) {
//				$binary = substr($binary, 7) . substr($binary, 0, 7);
				print "\thex $hex \t; " . $rowbinary . "\n";
				$rowbinary = "";
				$hex = "";
			}
		}
	}

	print "\n";
	imagedestroy($im);
