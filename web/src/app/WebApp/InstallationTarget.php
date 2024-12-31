<?php

declare(strict_types=1);

namespace Hestia\WebApp;

use Hestia\System\Util;

class InstallationTarget
{
	public function __construct(
		public readonly string $domainName,
		public readonly string $domainPath,
		public readonly string $installationDirectory,
		public readonly string $ipAddress,
		public readonly bool $isSslEnabled,
	) {
	}

	public function getUrl(): string
	{
		return ($this->isSslEnabled ? "https://" : "http://") . $this->domainName;
	}

	public function getPort(): int
	{
		return $this->isSslEnabled ? 443 : 80;
	}

	public function getDocRoot(string $appendedPath = ''): string
	{
		if (empty($this->installationDirectory)) {
			return Util::join_paths($this->domainPath, "public_html", $appendedPath);
		}

		return Util::join_paths(
			$this->domainPath,
			"public_html",
			$this->installationDirectory,
			$appendedPath,
		);
	}
}
