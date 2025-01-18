<!-- Begin toolbar -->
<div class="toolbar">
	<div class="toolbar-inner">
		<div class="toolbar-buttons">
			<?php if ($read_only !== "true") { ?>
				<a href="/add/cron/" class="button button-secondary js-button-create">
					<i class="fas fa-circle-plus icon-green"></i><?= _("Add Cron Job") ?>
				</a>
				<?php if ($panel[$user_plain]["CRON_REPORTS"] == "yes") { ?>
					<a class="button button-secondary" href="/delete/cron/reports/?token=<?= $_SESSION["token"] ?>">
						<i class="fas fa-toggle-on icon-green"></i><?= _("Disable Notifications") ?>
					</a>
				<?php } else { ?>
					<a class="button button-secondary" href="/add/cron/reports/?token=<?= $_SESSION["token"] ?>">
						<i class="fas fa-toggle-off"></i><?= _("Enable Notifications") ?>
					</a>
				<?php } ?>
			<?php } ?>
		</div>
		<div class="toolbar-right">
			<div class="toolbar-sorting">
				<button class="toolbar-sorting-toggle js-toggle-sorting-menu" type="button" title="<?= _("Sort items") ?>">
					<?= _("Sort by") ?>:
					<span class="u-text-bold">
						<?php if ($_SESSION['userSortOrder'] === 'name') { $label = _('Command'); } else { $label = _('Date'); } ?>
						<?= $label ?> <i class="fas fa-arrow-down-a-z"></i>
					</span>
				</button>
				<ul class="toolbar-sorting-menu js-sorting-menu u-hidden">
					<li data-entity="sort-name">
						<span class="name <?php if ($_SESSION['userSortOrder'] === 'name') { echo 'active'; } ?>"><?= _("Command") ?> <i class="fas fa-arrow-down-a-z"></i></span><span class="up"><i class="fas fa-arrow-up-a-z"></i></span>
					</li>
					<li data-entity="sort-date" data-sort-as-int="1">
						<span class="name <?php if ($_SESSION['userSortOrder'] === 'date') { echo 'active'; } ?>"><?= _("Date") ?> <i class="fas fa-arrow-down-a-z"></i></span><span class="up"><i class="fas fa-arrow-up-a-z"></i></span>
					</li>
				</ul>
				<?php if ($read_only !== "true") { ?>
					<form x-data x-bind="BulkEdit" action="/bulk/cron/" method="post">
						<input type="hidden" name="token" value="<?= $_SESSION["token"] ?>">
						<select class="form-select" name="action">
							<option value=""><?= _("Apply to selected") ?></option>
							<?php if ($panel[$user_plain]['CRON_REPORTS'] == 'yes') echo '<option value="delete-cron-reports">' . _('Disable Notifications') . '</option>'; ?>
							<?php if ($panel[$user_plain]['CRON_REPORTS'] == 'no') echo '<option value="add-cron-reports">' . _('Enable Notifications') . '</option>'; ?>
							<option value="suspend"><?= _("Suspend") ?></option>
							<option value="unsuspend"><?= _("Unsuspend") ?></option>
							<option value="delete"><?= _("Delete") ?></option>
						</select>
						<button type="submit" class="toolbar-input-submit" title="<?= _("Apply to selected") ?>">
							<i class="fas fa-arrow-right"></i>
						</button>
					</form>
				<?php } ?>
			</div>
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

	<h1 class="u-text-center u-hide-desktop u-mt20 u-pr30 u-mb20 u-pl30"><?= _("Cron Jobs") ?></h1>
	<div class="units-table js-units-container">
		<div class="units-table-header">
			<div class="units-table-cell">
				<input type="checkbox" class="js-toggle-all-checkbox" title="<?= _("Select all") ?>" <?= $display_mode ?>>
			</div>
			<div class="units-table-cell"><?= _("Command") ?></div>
			<div class="units-table-cell"></div>
			<div class="units-table-cell u-text-center"><?= _("Minute") ?></div>
			<div class="units-table-cell u-text-center"><?= _("Hour") ?></div>
			<div class="units-table-cell u-text-center"><?= _("Day") ?></div>
			<div class="units-table-cell u-text-center"><?= _("Month") ?></div>
			<div class="units-table-cell u-text-center"><?= _("Day of Week") ?></div>
		</div>
		<!-- Begin cron job list item loop -->
		<?php
		foreach ($data as $key => $value) {
			++$i;
			if ($data[$key]['SUSPENDED'] == 'yes') {
				$status = 'suspended';
				$spnd_action = 'unsuspend';
				$spnd_action_title = _('Unsuspend');
				$spnd_icon = 'fa-play';
				$spnd_icon_class = 'icon-green';
				$spnd_confirmation = _('Are you sure you want to unsuspend this cron job?') ;
			} else {
				$status = 'active';
				$spnd_action = 'suspend';
				$spnd_action_title = _('Suspend');
				$spnd_icon = 'fa-pause';
				$spnd_icon_class = 'icon-highlight';
				$spnd_confirmation = _('Are you sure you want to suspend this cron job?') ;
			}
		?>
			<div class="units-table-row <?php if ($status == 'suspended') echo 'disabled'; ?> js-unit"
				data-sort-date="<?= strtotime($data[$key]['DATE'].' '.$data[$key]['TIME']) ?>"
				data-sort-name="<?= htmlspecialchars($data[$key]['CMD'], ENT_NOQUOTES) ?>">
				<div class="units-table-cell">
					<div>
						<input id="check<?= $i ?>" class="js-unit-checkbox" type="checkbox" title="<?= _("Select") ?>" name="job[]" value="<?= $key ?>" <?= $display_mode ?>>
						<label for="check<?= $i ?>" class="u-hide-desktop"><?= _("Select") ?></label>
					</div>
				</div>
				<div class="units-table-cell units-table-heading-cell u-text-bold">
					<span class="u-hide-desktop"><?= _("Command") ?>:</span>
					<?php if ($read_only === "true" || $data[$key]["SUSPENDED"] == "yes") { ?>
						<?= htmlspecialchars($data[$key]["CMD"], ENT_NOQUOTES) ?>
					<?php } else { ?>
						<a href="/edit/cron/?job=<?= $data[$key]["JOB"] ?>&token=<?= $_SESSION["token"] ?>" title="<?= _("Edit Cron Job") ?>: <?= htmlspecialchars($data[$key]["CMD"], ENT_NOQUOTES) ?>">
							<?= htmlspecialchars($data[$key]["CMD"], ENT_NOQUOTES) ?>
						</a>
					<?php } ?>
				</div>
				<div class="units-table-cell">
					<?php if (!$read_only) { ?>
						<ul class="units-table-row-actions">
							<?php if ($data[$key]["SUSPENDED"] == "no") { ?>
								<li class="units-table-row-action shortcut-enter" data-key-action="href">
									<a
										class="units-table-row-action-link"
										href="/edit/cron/?job=<?= $data[$key]["JOB"] ?>&token=<?= $_SESSION["token"] ?>"
										title="<?= _("Edit") ?>"
									>
										<i class="fas fa-pencil icon-orange"></i>
										<span class="u-hide-desktop"><?= _("Edit") ?></span>
									</a>
								</li>
							<?php } ?>
							<li class="units-table-row-action shortcut-s" data-key-action="js">
								<a
									class="units-table-row-action-link data-controls js-confirm-action"
									href="/<?= $spnd_action ?>/cron/?job=<?= $data[$key]["JOB"] ?>&token=<?= $_SESSION["token"] ?>"
									title="<?= $spnd_action_title ?>"
									data-confirm-title="<?= $spnd_action_title ?>"
									data-confirm-message="<?= sprintf($spnd_confirmation, $key) ?>"
								>
									<i class="fas <?= $spnd_icon ?> <?= $spnd_icon_class ?>"></i>
									<span class="u-hide-desktop"><?= $spnd_action_title ?></span>
								</a>
							</li>
							<li class="units-table-row-action shortcut-delete" data-key-action="js">
								<a
									class="units-table-row-action-link data-controls js-confirm-action"
									href="/delete/cron/?job=<?= $data[$key]["JOB"] ?>&token=<?= $_SESSION["token"] ?>"
									title="<?= _("Delete") ?>"
									data-confirm-title="<?= _("Delete") ?>"
									data-confirm-message="<?= sprintf(_("Are you sure you want to delete this cron job?"), $key) ?>"
								>
									<i class="fas fa-trash icon-red"></i>
									<span class="u-hide-desktop"><?= _("Delete") ?></span>
								</a>
							</li>
						</ul>
					<?php } ?>
				</div>
				<div class="units-table-cell u-text-center-desktop">
					<span class="u-hide-desktop u-text-bold"><?= _("Minute") ?>:</span>
					<?= $data[$key]["MIN"] ?>
				</div>
				<div class="units-table-cell u-text-center-desktop">
					<span class="u-hide-desktop u-text-bold"><?= _("Hour") ?>:</span>
					<?= $data[$key]["HOUR"] ?>
				</div>
				<div class="units-table-cell u-text-center-desktop">
					<span class="u-hide-desktop u-text-bold"><?= _("Day") ?>:</span>
					<?= $data[$key]["DAY"] ?>
				</div>
				<div class="units-table-cell u-text-center-desktop">
					<span class="u-hide-desktop u-text-bold"><?= _("Month") ?>:</span>
					<?= $data[$key]["MONTH"] ?>
				</div>
				<div class="units-table-cell u-text-center-desktop">
					<span class="u-hide-desktop u-text-bold"><?= _("Day of Week") ?>:</span>
					<?= $data[$key]["WDAY"] ?>
				</div>
			</div>
		<?php } ?>
	</div>

	<div class="units-table-footer">
		<p>
			<!-- If cronjobs could not be retrieved, display an error message with --> 
			<?php if ($retrieve_error) { ?>
				<?php show_alert_message($_SESSION); ?>
			<?php } else { ?>
				<?php printf(ngettext("%d cron job", "%d cron jobs", $i), $i); ?>
			<?php } ?>
			
		</p>
	</div>

</div>
