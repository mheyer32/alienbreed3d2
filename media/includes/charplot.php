<?php


function span(string $sBinData, int $cCode, int $iRow): string {
	if ($iRow < 0) {
		return sprintf('CHR:%3d ', $cCode);
	}

	$sBuffer = '';
	$iSpan = ord($sBinData[$iRow + ($cCode << 3)]);
	for ($iBit = 128; $iBit > 0; $iBit >>= 1) {
		$sBuffer .= $iSpan & $iBit ? 'X' : '.';
	}
	return $sBuffer;
}

$sBinData = file_get_contents('scrollfont');
for ($iChar = 0; $iChar < 256; $iChar += 16) {
	for ($iRow = -1; $iRow < 8; ++$iRow) {
		for ($iColumn = 0; $iColumn < 16; $iColumn++) {
			echo span($sBinData, $iChar + $iColumn, $iRow), " ";
		}
		echo "\n";	
	}
	echo "\n";
}
