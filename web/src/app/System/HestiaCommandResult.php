<?php

declare(strict_types=1);

namespace Hestia\System;
use RuntimeException;
use Symfony\Component\Process\Process;
use function chmod;
use function Hestiacp\quoteshellarg\quoteshellarg;
use function implode;
use function json_decode;
use function unlink;
use const PHP_EOL;

class HestiaCommandResult {

	public function __construct(
		public readonly string $command,
		public readonly int $exitCode,
		public readonly string $output,
	){
	}

	public function getOutputJson(): string
	{
		return json_decode($this->output, true);
	}
}
