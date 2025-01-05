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

	public function getOutputJson(): array
	{
		return (array) json_decode($this->output, true, 512, JSON_THROW_ON_ERROR);
	}
}
