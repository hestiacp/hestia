<?php
declare(strict_types=1);

namespace Hestia\WebApp;

interface InstallerInterface {
	public function getInstallationTarget(): InstallationTarget;
	public function install(array $options = null): void;
	public function withDatabase(): bool;
}
