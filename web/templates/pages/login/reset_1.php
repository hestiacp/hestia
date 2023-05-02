<div class="login animate__animated animate__zoomIn">
	<a href="/" class="u-block u-mb40">
		<img src="/images/logo.svg" alt="<?= _("Hestia Control Panel") ?>" width="100" height="120">
	</a>
	<form method="post" action="/reset/">
		<input type="hidden" name="token" value="<?= $_SESSION["token"] ?>">
		<h1 class="login-title">
			<?= _("Forgot Password") ?>
		</h1>
		<?php show_error_message($ERROR); ?>
		<div class="u-mb10">
			<label for="user" class="form-label"><?= _("Username") ?></label>
			<input type="text" class="form-control" name="user" id="user" required>
		</div>
		<div class="u-mb20">
			<label for="email" class="form-label"><?= _("Email") ?></label>
			<input type="email" class="form-control" name="email" id="email" required>
		</div>
		<div class="u-side-by-side">
			<button type="submit" class="button">
				<?= _("Submit") ?>
			</button>
			<a href="/login/?logout" class="button button-secondary">
				<?= _("Back") ?>
			</a>
		</div>
	</form>
</div>

</body>

</html>
