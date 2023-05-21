<!-- Begin toolbar -->
<div class="toolbar">
	<div class="toolbar-inner">
		<div class="toolbar-buttons">
			<?php if ($read_only !== "true") { ?>
				<a href="/schedule/backup/?token=<?= $_SESSION["token"] ?>" class="button button-secondary"><i class="fas fa-circle-plus icon-green"></i><?= _("Create Backup") ?></a>
				<a href="/list/backup/exclusions/" class="button button-secondary"><i class="fas fa-folder-minus icon-orange"></i><?= _("Backup Exclusions") ?></a>
			<?php } ?>
		</div>
		<div class="toolbar-right">
			<?php if ($read_only !== "true") { ?>
				<form x-data x-bind="BulkEdit" action="/bulk/backup/" method="post">
					<input type="hidden" name="token" value="<?= $_SESSION["token"] ?>">
					<select class="form-select" name="action">
						<option value=""><?= _("Apply to selected") ?></option>
						<option value="delete"><?= _("Delete") ?></option>
					</select>
					<button type="submit" class="toolbar-input-submit" title="<?= _("Apply to selected") ?>">
						<i class="fas fa-arrow-right"></i>
					</button>
				</form>
			<?php } ?>
			<div class="toolbar-search">
				<form action="/search/" method="get">
					<input type="hidden" name="token" value="<?= $_SESSION["token"] ?>">
					<input type="search" class="form-control js-search-input" name="q" value="<? echo isset($_POST['q']) ? htmlspecialchars($_POST['q']) : '' ?>" title="<?= _("Search") ?>">
					<button type="submit" class="toolbar-input-submit" title="<?= _("Search") ?>">
						<i class="fas fa-magnifying-glass"></i>
					</button>
				</form>
			</div>
		</div>
	</div>
</div>
<!-- End toolbar -->

<div class="container">
	<div class="units">
		<div class="header units-header">
			<div class="l-unit__col l-unit__col--right">
				<div>
					<div class="clearfix l-unit__stat-col--left super-compact">
						<input type="checkbox" class="js-toggle-all-checkbox" title="<?= _("Select all") ?>" <?= $display_mode ?>>
					</div>
					<div class="clearfix l-unit__stat-col--left wide-4"><b><?= _("File Name") ?></b></div>
					<div class="clearfix l-unit__stat-col--left compact-4 u-text-right"><b>&nbsp;</b></div>
					<div class="clearfix l-unit__stat-col--left u-text-center"><b><?= _("Date") ?></b></div>
					<div class="clearfix l-unit__stat-col--left u-text-center"><b><?= _("Size") ?></b></div>
					<div class="clearfix l-unit__stat-col--left u-text-center"><b><?= _("Type") ?></b></div>
					<div class="clearfix l-unit__stat-col--left u-text-center"><b><?= _("Runtime") ?></b></div>
				</div>
			</div>
		</div>

		<!-- Begin user backup list item loop -->
		<?php
			foreach ($data as $key => $value) {
				++$i;
				$web = _('No');
				$dns = _('No');
				$mail = _('No');
				$db = _('No');
				$cron = _('No');
				$udir = _('No');

				if (!empty($data[$key]['WEB'])) $web = _('Yes');
				if (!empty($data[$key]['DNS'])) $dns = _('Yes');
				if (!empty($data[$key]['MAIL'])) $mail = _('Yes');
				if (!empty($data[$key]['DB'])) $db = _('Yes');
				if (!empty($data[$key]['CRON'])) $cron = _('Yes');
				if (!empty($data[$key]['UDIR'])) $udir = _('Yes');
			?>
			<div class="l-unit animate__animated animate__fadeIn">
				<div class="l-unit__col l-unit__col--right">
					<div>
						<div class="clearfix l-unit__stat-col--left super-compact">
							<input id="check<?= $i ?>" class="js-unit-checkbox" type="checkbox" title="<?= _("Select") ?>" name="backup[]" value="<?= $key ?>" <?= $display_mode ?>>
						</div>
						<div class="clearfix l-unit__stat-col--left wide-4 truncate">
							<b>
								<?php if ($read_only === "true") { ?>
									<?= $key ?>
								<?php } else { ?>
									<a href="/list/backup/?backup=<?= $key ?>&token=<?= $_SESSION["token"] ?>" title="<?= _("Restore") ?>"><?= $key ?></a>
								<?php } ?>
							</b>
						</div>
						<!-- START QUICK ACTION TOOLBAR AREA -->
						<div class="clearfix l-unit__stat-col--left compact-4 u-text-right">
							<div class="l-unit-toolbar__col l-unit-toolbar__col--right u-noselect">
								<div class="actions-panel clearfix">
									<?php if ($_SESSION["userContext"] === "admin" && $_SESSION["look"] === "admin" && $read_only === "true") { ?>
										<!-- Restrict ability to restore or delete backups when impersonating 'admin' account -->
										&nbsp;
									<?php } else { ?>
										<div class="actions-panel__col actions-panel__download shortcut-d" data-key-action="href"><a href="/download/backup/?backup=<?=$key?>&token=<?=$_SESSION['token']?>" title="<?= _("Download") ?>"><i class="fas fa-file-arrow-down icon-lightblue icon-dim"></i></a></div>
										<?php if ($read_only !== 'true') {?>
											<div class="actions-panel__col actions-panel__list shortcut-enter" data-key-action="href"><a href="/list/backup/?backup=<?=$key?>&token=<?=$_SESSION['token']?>" title="<?= _("Restore") ?>"><i class="fas fa-arrow-rotate-left icon-green icon-dim"></i></a></div>
											<div class="actions-panel__col actions-panel__delete shortcut-delete" data-key-action="js">
												<a
													class="data-controls js-confirm-action"
													href="/delete/backup/?backup=<?= $key ?>&token=<?= $_SESSION["token"] ?>"
													data-confirm-title="<?= _("Delete") ?>"
													data-confirm-message="<?= sprintf(_("Are you sure you want to delete backup %s?"), $key) ?>"
												>
													<i class="fas fa-trash icon-red icon-dim"></i>
												</a>
											</div>
										<?php } ?>
									<?php } ?>
								</div>
							</div>
						</div>
						<!-- END QUICK ACTION TOOLBAR AREA -->
						<div class="clearfix l-unit__stat-col--left u-text-center"><b><?= translate_date($data[$key]["DATE"]) ?></b></div>
						<div class="clearfix l-unit__stat-col--left u-text-center"><b><?= humanize_usage_size($data[$key]["SIZE"]) ?></b> <span class="u-text-small"><?= humanize_usage_measure($data[$key]["SIZE"]) ?></span></div>
						<div class="clearfix l-unit__stat-col--left u-text-center"><?= $data[$key]["TYPE"] ?></div>
						<div class="clearfix l-unit__stat-col--left u-text-center"><?= humanize_time($data[$key]["RUNTIME"]) ?></div>
					</div>
				</div>
			</div>
		<?php } ?>
	</div>
</div>

<footer class="app-footer">
	<div class="container app-footer-inner">
		<p>
			<?php printf(ngettext("%d backup", "%d backups", $i), $i); ?>
		</p>
	</div>
</footer>
