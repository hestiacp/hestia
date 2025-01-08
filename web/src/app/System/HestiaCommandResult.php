<?php

declare(strict_types=1);

namespace Hestia\System;
use function json_decode;

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
