<!-- Begin toolbar -->
<div class="toolbar">
	<div class="toolbar-inner">
		<div class="toolbar-buttons">
			<a class="button button-secondary button-back js-button-back" href="/list/web/">
				<i class="fas fa-arrow-left icon-blue"></i><?= _("Back") ?>
			</a>
		</div>
		<div class="toolbar-buttons">
			<a href="/delete/web/cache/?domain=<?= htmlentities($v_domain);?>&token=<?= $_SESSION['token'];?>" class="button button-secondary js-clear-cache-button <?php if (!($v_nginx_cache == 'yes' || (($v_proxy_template == 'caching' || is_int(strpos($v_proxy_template, 'caching-'))) && $_SESSION['PROXY_SYSTEM'] == 'nginx'))) { echo "u-hidden"; } ?>">
				<i class="fas fa-trash icon-red"></i><?= _("Purge NGINX Cache") ?>
			</a>
			<?php if ($_SESSION["PLUGIN_APP_INSTALLER"] !== "false") { ?>
				<a href="/add/webapp/?domain=<?= htmlentities($v_domain) ?>" class="button button-secondary">
					<i class="fas fa-magic icon-blue"></i><?= _("Quick Install App") ?>
				</a>
			<?php } ?>
			<button type="submit" class="button" form="main-form">
				<i class="fas fa-floppy-disk icon-purple"></i><?= _("Save") ?>
			</button>
		</div>
	</div>
</div>
<!-- End toolbar -->

<div class="container">

	<form
		x-data="{
			statsAuthEnabled: <?= !empty($v_stats_user) ? "true" : "false" ?>,
			redirectEnabled: <?= !empty($v_redirect) ? "true" : "false" ?>,
			sslEnabled: <?= $v_ssl == "yes" ? "true" : "false" ?>,
			letsEncryptEnabled: <?= $v_letsencrypt == "yes" || $v_letsencrypt == "on" ? "true" : "false" ?>,
			showCertificates: <?= $v_letsencrypt == "yes" || $v_letsencrypt == "on" ? "false" : "true" ?>,
			showAdvanced: false,
			nginxCacheEnabled: <?= $v_nginx_cache == "yes" ? "true" : "false" ?>,
			proxySupportEnabled: <?= !empty($v_proxy) ? "true" : "false" ?>,
			statsProxyUrlFilled: <?= !empty($v_proxy_template == 'reverse_proxy') ? "true" : "false" ?>,
			customDocumentRootEnabled: <?= !empty($v_custom_doc_root) ? "true" : "false" ?>
		}"
		id="main-form"
		name="v_edit_web"
		method="post"
		class="<?= $v_status ?> js-enable-inputs-on-submit"
	>
		<input type="hidden" name="token" value="<?= $_SESSION["token"] ?>">
		<input type="hidden" name="save" value="save">

		<div class="form-container">
			<h1 class="u-mb20"><?= _("Edit Web Domain") ?></h1>
			<?php show_alert_message($_SESSION); ?>
			<div class="u-mb10">
				<label for="v_domain" class="form-label"><?= _("Domain") ?></label>
				<input type="text" class="form-control" name="v_domain" id="v_domain" value="<?= htmlentities(trim($v_domain, "'")) ?>" disabled required>
				<input type="hidden" name="v_domain" value="<?= htmlentities(trim($v_domain, "'")) ?>">
			</div>
			<div class="u-mb10">
				<label for="v_aliases" class="form-label"><?= _("Aliases") ?></label>
				<textarea class="form-control" name="v_aliases" id="v_aliases"><?= htmlentities(trim($v_aliases, "'")) ?></textarea>
			</div>
			<?php if ($v_letsencrypt == "yes" || $v_letsencrypt == "on") { ?>
				<div class="alert alert-info u-mb10" role="alert">
					<i class="fas fa-exclamation"></i>
					<p><?= _("If the aliases changes, Let's Encrypt will obtain a new SSL certificate.") ?></p>
				</div>
			<?php } ?>
			<div class="u-mb20">
				<label for="v_ip" class="form-label"><?= _("IP Address") ?></label>
				<select class="form-select" name="v_ip" id="v_ip">
					<?php
						foreach ($ips as $ip => $value) {
							$display_ip = htmlentities(empty($value['NAT']) ? $ip : "{$value['NAT']}");
							$ip_selected = ((!empty($v_ip) && $ip == $v_ip) || $v_ip == "'{$ip}'")	? 'selected' : '';
							echo "\n\t\t\t\t\t\t\t\t\t\t\t\t<option value=\"{$ip}\" {$ip_selected}>{$display_ip}</option>\n";
						}
					?>
				</select>
			</div>
			<div class="u-mb10">
				<label for="v_stats" class="form-label"><?= _("Web Statistics") ?></label>
				<select class="form-select js-stats-select" name="v_stats" id="v_stats">
					<?php
						foreach ($stats as $key => $value) {
							$svalue = "'".$value."'";
							echo "\t\t\t\t<option value=\"".htmlentities($value)."\"";
							if (empty($v_stats)) $v_stats = 'none';
							if (( $value == $v_stats ) || ($svalue == $v_stats )){
								echo ' selected' ;
							}
						echo ">". htmlentities(_($value)) ."</option>\n";
						}
					?>
				</select>
			</div>
			<div class="u-mb10 js-stats-auth" style="<?php if ($v_stats == "none") { ?>display:none<?php } ?>">
				<div class="form-check">
					<input x-model="statsAuthEnabled" class="form-check-input" type="checkbox" name="v_stats_auth" id="v_stats_auth">
					<label for="v_stats_auth">
						<?= _("Statistics Authorization") ?>
					</label>
				</div>
			</div>
			<div class="u-pl30 js-stats-auth">
				<div x-cloak x-show="statsAuthEnabled" name="v-add-web-domain-stats-user">
					<div class="u-mb10">
						<label for="v_stats_user" class="form-label"><?= _("Username") ?></label>
						<input type="text" class="form-control" name="v_stats_user" id="v_stats_user" value="<?= htmlentities(trim($v_stats_user, "'")) ?>">
					</div>
					<div class="u-mb20">
						<label for="v_password" class="form-label">
							<?= _("Password") ?>
							<button type="button" title="<?= _("Generate") ?>" class="u-unstyled-button u-ml5 js-generate-password">
								<i class="fas fa-arrows-rotate icon-green"></i>
							</button>
						</label>
						<div class="u-pos-relative">
							<input type="text" class="form-control js-password-input" name="v_stats_password" id="v_password" value="<?= trim($v_stats_password, "'") ?>">
						</div>
					</div>
				</div>
			</div>
			<div class="form-check u-mb10">
				<input x-model="redirectEnabled" class="form-check-input" type="checkbox" name="v-redirect-checkbox" id="v-redirect-checkbox">
				<label for="v-redirect-checkbox">
					<?= _("Enable domain redirection") ?>
				</label>
			</div>
			<div x-cloak x-show="redirectEnabled" id="v_redirect" class="u-pl30 u-mb10">
				<div class="form-check">
					<input class="form-check-input js-redirect-custom-value" type="radio" name="v-redirect" id="v-redirect-radio-1" value="<?='www.'.htmlentities($v_domain);?>" <?php if ($v_redirect == "www.".$v_domain) echo 'checked'; ?>>
					<label for="v-redirect-radio-1">
						<?= sprintf(_("Redirect visitors to %s"), "www." . htmlentities($v_domain)) ?>
					</label>
				</div>
				<div class="form-check">
					<input class="form-check-input js-redirect-custom-value" type="radio" name="v-redirect" id="v-redirect-radio-2" value="<?= htmlentities($v_domain);?>" <?php if ( $v_redirect == $v_domain) echo 'checked'; ?>>
					<label for="v-redirect-radio-2">
						<?= sprintf(_("Redirect visitors to %s"), htmlentities($v_domain)) ?>
					</label>
				</div>
				<div class="form-check">
					<input class="form-check-input js-redirect-custom-value" type="radio" name="v-redirect" id="v-redirect-radio-3" value="custom" <?php if ( !empty($v_redirect_custom)) echo 'checked'; ?>>
					<label for="v-redirect-radio-3">
						<?= _("Redirect visitors to a custom domain or web address") ?>
					</label>
				</div>
				<div class="u-pl30 js-custom-redirect-fields <?php if (empty($v_redirect_custom)) { echo 'u-hidden'; } ?>">
					<div class="u-mt15 u-mb10">
						<label for="v-redirect-custom" class="form-label"><?= _("Target domain or URL") ?></label>
						<input type="text" class="form-control" name="v-redirect-custom" id="v-redirect-custom" value="<?= $v_redirect_custom ?>">
					</div>
					<div class="u-mb20">
						<label for="v-redirect-code" class="form-label"><?= _("Status code") ?>:</label>
						<select class="form-select" name="v-redirect-code" id="v-redirect-code">
							<?php foreach ($redirect_code_options as $status_code): ?>
							<option value="<?= $status_code ?>"
								<?= trim($v_redirect_code) === $status_code || (empty($v_redirect_code) && $status_code === trim($v_redirect_code)) ? ' selected="selected" ' : "" ?>>
								<?= $status_code ?>
							</option>
							<?php endforeach; ?>
						</select>
					</div>
				</div>
			</div>
			<div class="form-check u-mb10">
				<input x-model="sslEnabled" class="form-check-input" type="checkbox" name="v_ssl" id="v_ssl">
				<label for="v_ssl">
					<?= _("Enable SSL for this domain") ?>
				</label>
			</div>
			<div x-cloak x-show="sslEnabled" class="u-pl30">
				<div class="form-check u-mb10">
					<input x-model="letsEncryptEnabled" class="form-check-input js-toggle-lets-encrypt" type="checkbox" name="v_letsencrypt" id="v_letsencrypt">
					<label for="v_letsencrypt">
						<?= _("Use Let's Encrypt to obtain SSL certificate") ?>
					</label>
				</div>
				<div class="form-check u-mb10">
					<input class="form-check-input" type="checkbox" name="v_ssl_forcessl" id="v_ssl_forcessl" <?php if ($v_ssl_forcessl == 'yes') echo 'checked' ?>>
					<label for="v_ssl_forcessl">
						<?= _("Enable automatic HTTPS redirection") ?>
					</label>
				</div>
				<div class="form-check u-mb20">
					<input class="form-check-input" type="checkbox" name="v_ssl_hsts" id="ssl_hsts" <?php if ($v_ssl_hsts == 'yes') echo 'checked' ?>>
					<label for="ssl_hsts">
						<?= _("Enable HTTP Strict Transport Security (HSTS)") ?>
						<a href="https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security" target="_blank">
							<i class="fas fa-question-circle"></i>
						</a>
					</label>
				</div>
				<div x-cloak x-show="showCertificates" class="js-ssl-details">
					<div class="u-mb10">
						<label for="ssl_crt" class="form-label">
							<?= _("SSL Certificate") ?>
							<span id="generate-csr"> / <a class="form-link" target="_blank" href="/generate/ssl/?domain=<?= htmlentities($v_domain) ?>"><?= _("Generate Self-Signed SSL Certificate") ?></a></span>
						</label>
						<textarea class="form-control u-min-height100 u-console" name="v_ssl_crt" id="ssl_crt"><?= htmlentities(trim($v_ssl_crt, "'")) ?></textarea>
					</div>
					<div class="u-mb10">
						<label for="v_ssl_key" class="form-label"><?= _("SSL Private Key") ?></label>
						<textarea class="form-control u-min-height100 u-console" name="v_ssl_key" id="v_ssl_key"><?= htmlentities(trim($v_ssl_key, "'")) ?></textarea>
					</div>
					<div class="u-mb20">
						<label for="v_ssl_ca" class="form-label">
							<?= _("SSL Certificate Authority / Intermediate") ?> <span class="optional">(<?= _("Optional") ?>)</span>
						</label>
						<textarea class="form-control u-min-height100 u-console" name="v_ssl_ca" id="v_ssl_ca"><?= htmlentities(trim($v_ssl_ca, "'")) ?></textarea>
					</div>
				</div>
				<?php if ($v_ssl != "no") { ?>
					<ul class="values-list">
						<li class="values-list-item">
							<span class="values-list-label"><?= _("Issued To") ?></span>
							<span class="values-list-value"><?= $v_ssl_subject ?></span>
						</li>
						<?php if ($v_ssl_aliases) {
							$v_ssl_aliases = str_replace(",", ", ", $v_ssl_aliases); ?>
							<li class="values-list-item">
								<span class="values-list-label"><?= _("Alternate") ?></span>
								<span class="values-list-value"><?= $v_ssl_aliases ?></span>
							</li>
						<?php } ?>
						<li class="values-list-item">
							<span class="values-list-label"><?= _("Not Before") ?></span>
							<span class="values-list-value"><?= $v_ssl_not_before ?></span>
						</li>
						<li class="values-list-item">
							<span class="values-list-label"><?= _("Not After") ?></span>
							<span class="values-list-value"><?= $v_ssl_not_after ?></span>
						</li>
						<li class="values-list-item">
							<span class="values-list-label"><?= _("Signature") ?></span>
							<span class="values-list-value"><?= $v_ssl_signature ?></span>
						</li>
						<li class="values-list-item">
							<span class="values-list-label"><?= _("Key Size") ?></span>
							<span class="values-list-value"><?= $v_ssl_pub_key ?></span>
						</li>
						<li class="values-list-item">
							<span class="values-list-label"><?= _("Issued By") ?></span>
							<span class="values-list-value"><?= $v_ssl_issuer ?></span>
						</li>
						<p x-cloak x-show="letsEncryptEnabled" id="letsinfo">
							<button
								type="button"
								class="form-link"
								x-on:click="showCertificates = !showCertificates"
								x-text="showCertificates ? '<?= _("Hide Certificate") ?>' : '<?= _("Show Certificate") ?>'">
								<?= _("Show Certificate") ?>
							</button>
						</p>
					</ul>
				<?php } ?>
			</div>
			<div class="u-mt15 u-mb20">
				<button x-on:click="showAdvanced = !showAdvanced" type="button" class="button button-secondary">
					<?= _("Advanced Options") ?>
				</button>
			</div>
			<div x-cloak x-show="showAdvanced">
				<?php if ($_SESSION["userContext"] === "admin" || ($_SESSION["userContext"] === "user" && $_SESSION["POLICY_USER_EDIT_WEB_TEMPLATES"] === "yes")) { ?>
					<div class="u-mb10">
						<label for="v_template" class="form-label">
							<?= _("Web Template") . "<span class='optional'>" . strtoupper($_SESSION["WEB_SYSTEM"]) . "</span>" ?>
						</label>
						<select class="form-select" name="v_template" id="v_template">
							<?php
								foreach ($templates as $key => $value) {
									echo "\t\t\t\t<option value=\"".htmlentities($value)."\"";
									$svalue = "'".$value."'";
									if ((!empty($v_template)) && ( $value == $v_template ) || ($svalue == $v_template)){
										echo ' selected' ;
									}
									echo ">".htmlentities($value)."</option>\n";
								}
							?>
						</select>
					</div>
					<?php if ($_SESSION["WEB_SYSTEM"] == "nginx") { ?>
						<div class="form-check u-mb10">
							<input x-model="nginxCacheEnabled" class="form-check-input" type="checkbox" name="v_nginx_cache_check" id="v_nginx_cache_check">
							<label for="v_nginx_cache_check">
								<?= _("Enable FastCGI cache") ?>
								<a href="https://hestiacp.com/docs/server-administration/web-templates.html#nginx-fastcgi-cache" target="_blank" class="u-ml5">
									<i class="fas fa-circle-question"></i>
								</a>
							</label>
						</div>
						<div x-cloak x-show="nginxCacheEnabled" id="v_nginx_duration" class="u-pl30">
							<div class="u-mb10">
								<label for="v_nginx_cache_duration" class="form-label">
									<?= _("Cache Duration") ?> <span class="optional">(<?= _("For example") ?>: 30s, 10m or 1d)</span>
								</label>
								<input type="text" class="form-control" name="v_nginx_cache_duration" id="v_nginx_cache_duration" value="<?= htmlentities(trim($v_nginx_cache_duration, "'")) ?>">
							</div>
						</div>
					<?php } ?>
					<?php if (!empty($_SESSION["WEB_BACKEND"])) { ?>
						<div class="u-mb10">
							<label for="v_backend_template" class="form-label">
								<?= _("Backend Template") . " <span class='optional'>" . strtoupper($_SESSION["WEB_BACKEND"]) . "</span>" ?>
							</label>
							<select class="form-select" name="v_backend_template" id="v_backend_template">
								<?php
									foreach ($backend_templates as $key => $value) {
										echo "\t\t\t\t<option value=\"".$value."\"";
										$svalue = "'".$value."'";
										if ((!empty($v_backend_template)) && ( $value == $v_backend_template ) || ($svalue == $v_backend_template)){
											echo ' selected' ;
										}
										if ((empty($v_backend_template)) && ($value == 'default')){
											echo ' selected' ;
										}
										echo ">".htmlentities($value)."</option>\n";
									}
								?>
							</select>
						</div>
					<?php } ?>
					<?php if (!empty($_SESSION["PROXY_SYSTEM"])) { ?>
						<div style="display: none;">
							<div class="form-check u-mb10">
								<input x-model="proxySupportEnabled" class="form-check-input" type="checkbox" name="v_proxy" id="v_proxy">
								<label for="v_proxy">
									<?= _("Proxy Support") . "<span class='optional'>" . strtoupper($_SESSION["PROXY_SYSTEM"]) . "</span>" ?>
								</label>
							</div>
						</div>
						<div x-cloak x-show="proxySupportEnabled" id="proxytable">
							<div class="u-mb10">
								<label for="v_proxy_template" class="form-label"><?= _("Proxy Template") ?></label>
								<select class="form-select js-proxy-template-select" name="v_proxy_template" id="v_proxy_template">
									<?php
										foreach ($proxy_templates as $key => $value) {
											echo "\t\t\t\t<option value=\"".htmlentities($value)."\"";
											$svalue = "'".$value."'";
											if ((!empty($v_proxy_template)) && ( $value == $v_proxy_template ) || ($svalue == $v_proxy_template)){
												echo ' selected' ;
											}
											if ((empty($v_proxy_template)) && ($value == 'default')){
												echo ' selected' ;
											}
											echo ">".htmlentities($value)."</option>\n";
										}
									?>
								</select>
							</div>
							<div x-show="statsProxyUrlFilled" class="u-mb10 js-proxy-url-field">
								<label for="v_proxy_url" class="form-label">
									<?php print _("Reverse Proxy Url"); ?>
								</label>
								<input type="text" class="form-control" name="v_proxy_url" id="v_proxy_url" value="<?= htmlentities(trim((!empty($v_proxy_url) ? $v_proxy_url : 'http://127.0.0.1:8080'), "'")) ?>">
								<small>http://localhost:8080</small>
							</div>
							<div class="u-mb10">
								<label for="v_proxy_ext" class="form-label"><?= _("Proxy Extensions") ?></label>
								<textarea class="form-control u-min-height100" name="v_proxy_ext" id="v_proxy_ext"><?php if (!empty($v_proxy_ext)) { echo htmlentities(trim($v_proxy_ext, "'"));} else { echo 'jpg, jpeg, gif, png, ico, svg, css, zip, tgz, gz, rar, bz2, exe, pdf, doc, xls, ppt, txt, odt, ods, odp, odf, tar, bmp, rtf, js, mp3, avi, mpeg, flv, html, htm'; } ?></textarea>
							</div>
						</div>
					<?php } ?>
				<?php } ?>
				<div class="form-check u-mb10">
					<input x-model="customDocumentRootEnabled" class="form-check-input" type="checkbox" name="v_custom_doc_root_check" id="v_custom_doc_root_check">
					<label for="v_custom_doc_root_check">
						<?= _("Custom document root") ?>
					</label>
				</div>
				<div x-cloak x-show="customDocumentRootEnabled" id="v_custom_doc_root" class="u-pl30">
					<div class="u-mb10">
						<label for="v-custom-doc-domain" class="form-label"><?= _("Point to") ?></label>
						<input type="hidden" class="js-custom-docroot-prepath" name="v-custom-doc-root_prepath" value="<?= $v_custom_doc_root_prepath ?>">
						<select class="form-select js-custom-docroot-domain" name="v-custom-doc-domain" id="v-custom-doc-domain">
							<?php foreach ($user_domains as $domain): ?>
							<option value="<?= htmlentities($domain) ?>"
								<?= $v_custom_doc_domain === $domain || (empty($v_custom_doc_domain) && $domain === $v_domain) ? ' selected="selected" ' : "" ?>>
								<?= htmlentities($domain) ?>
							</option>
							<?php endforeach; ?>
						</select>
					</div>
					<div class="u-mb10">
						<label for="v-custom-doc-folder" class="form-label">
							<?php print _("Directory"); ?> <span class="optional">(<?= _("Optional") ?>)</span>
						</label>
						<input type="text" class="form-control js-custom-docroot-dir" name="v-custom-doc-folder" id="v-custom-doc-folder" value="<?= htmlentities(trim($v_custom_doc_folder, "'")) ?>">
						<small class="js-custom-docroot-hint"></small>
					</div>
				</div>
				<?php if (in_array($_SESSION["FTP_SYSTEM"], ["vsftpd", "proftpd"])) { ?>
					<div class="form-check u-mb10">
						<input class="form-check-input js-toggle-ftp-accounts" type="checkbox" name="v_ftp" id="v_ftp" <?php if (!empty($v_ftp_user)) echo 'checked' ?>>
						<label for="v_ftp">
							<?= _("Additional FTP account(s)") ?>
						</label>
					</div>
					<div class="js-active-ftp-accounts">
						<?php foreach ($v_ftp_users as $i => $ftp_user): ?>
						<?php
							$v_ftp_user     = $ftp_user['v_ftp_user'];
							$v_ftp_password = $ftp_user['v_ftp_password'];
							$v_ftp_path     = $ftp_user['v_ftp_path'];
							$v_ftp_email    = $ftp_user['v_ftp_email'];
							$v_ftp_pre_path = $ftp_user['v_ftp_pre_path'];
						?>
						<div class="js-ftp-account js-ftp-account-nrm" name="v_add_domain_ftp" style="<?php if (empty($v_ftp_user)) { echo 'display: none;'; } ?>">
							<div class="u-mb10">
								<?= _("FTP") ?> #<span class="js-ftp-user-number"><?= $i + 1; ?></span>
								<button type="button" class="form-link form-link-danger u-ml5 js-delete-ftp-account"><?= _("Delete") ?></button>
								<input type="hidden" class="js-ftp-user-deleted" name="v_ftp_user[<?= $i ?>][delete]" value="0">
								<input type="hidden" class="js-ftp-user-is-new" name="v_ftp_user[<?= $i ?>][is_new]" value="<?= htmlentities($ftp_user['is_new']) ?>">
							</div>
							<div class="u-pl30 u-mb10">
								<label for="v_ftp_user[<?= $i ?>][v_ftp_user]" class="form-label">
									<?= _("Username") ?><br>
									<span style="color:#777;"><?= sprintf(_('Prefix %s will be added to username automatically'),$user_plain."_");?></span>
								</label>
								<input type="text" class="form-control js-ftp-user" <?= $ftp_user['is_new'] != 1 ? 'disabled="disabled"' : '' ?>
								name="v_ftp_user[<?= $i ?>][v_ftp_user]" id="v_ftp_user[<?= $i ?>][v_ftp_user]" value="<?= htmlentities(trim($v_ftp_user, "'")) ?>">
								<small class="hint js-ftp-user-hint"></small>
							</div>
							<div class="u-pl30 u-mb10">
								<label for="v_ftp_user[<?= $i ?>][v_ftp_password]" class="form-label">
									<?= _("Password") ?>
									<button type="button" title="<?= _("Generate") ?>" class="u-unstyled-button u-ml5 js-ftp-password-generate">
										<i class="fas fa-arrows-rotate icon-green"></i>
									</button>
								</label>
								<input type="text" class="form-control js-ftp-user-psw" name="v_ftp_user[<?= $i ?>][v_ftp_password]" id="v_ftp_user[<?= $i ?>][v_ftp_password]" value="<?= htmlentities(trim($v_ftp_password, "'")) ?>">
							</div>
							<div class="u-pl30 u-mb10">
								<label for="v_ftp_user[<?= $i ?>][v_ftp_path]" class="form-label"><?= _("Path") ?></label>
								<input type="hidden" name="v_ftp_pre_path" value="<?=!empty($v_ftp_pre_path) ? htmlentities(trim($v_ftp_pre_path, "'")) : '/'; ?>">
								<input type="hidden" name="v_ftp_user[<?= $i ?>][v_ftp_path_prev]" value="<?php if (!empty($v_ftp_path)) echo ($v_ftp_path[0] != '/' ? '/' : '').htmlentities(trim($v_ftp_path, "'")) ?>">
								<input type="text" class="form-control js-ftp-path" name="v_ftp_user[<?= $i ?>][v_ftp_path]" id="v_ftp_user[<?= $i ?>][v_ftp_path]" value="<?php if (!empty($v_ftp_path)) echo ($v_ftp_path[0] != '/' ? '/' : '').htmlentities(trim($v_ftp_path, "'")) ?>">
								<span class="hint-prefix"><?= htmlentities(trim($v_ftp_pre_path, "'")) ?></span><span class="hint js-ftp-path-hint"></span>
							</div>
							<?php if ($ftp_user['is_new'] == 1): ?>
								<div class="u-pl30 u-mb10">
									<label for="v_ftp_user[<?= $i ?>][v_ftp_email]" class="form-label"><?= _("Send FTP credentials to email") ?></label>
									<input type="email" class="form-control js-email-alert-on-psw" name="v_ftp_user[<?= $i ?>][v_ftp_email]" id="v_ftp_user[<?= $i ?>][v_ftp_email]" value="<?= htmlentities(trim($v_ftp_email, "'")) ?>">
								</div>
							<?php endif; ?>
						</div>
						<?php endforeach; ?>
					</div>

					<button type="button" class="form-link u-mt20 js-add-ftp-account" style="<?php if (empty($v_ftp_user)) echo 'display: none;' ?>">
						<?= _("Add FTP account") ?>
					</button>
				<?php } ?>
			</div>
		</div>

	</form>

</div>

<div class="u-hidden js-ftp-account-template">
	<div class="js-ftp-account js-ftp-account-nrm" name="v_add_domain_ftp">
		<div class="u-mb10">
			<?= _("FTP") ?> #<span class="js-ftp-user-number"></span>
			<button type="button" class="form-link form-link-danger u-ml5 js-delete-ftp-account"><?= _("Delete") ?></button>
			<input type="hidden" class="js-ftp-user-deleted" name="v_ftp_user[%INDEX%][delete]" value="0">
			<input type="hidden" class="js-ftp-user-is-new" name="v_ftp_user[%INDEX%][is_new]" value="1">
		</div>
		<div class="u-pl30 u-mb10">
			<label for="v_ftp_user[%INDEX%][v_ftp_user]" class="form-label">
				<?= _("Username") ?><br>
				<span style="color:#777;"><?= sprintf(_("Prefix %s will be added to username automatically"), $user_plain . "_") ?></span>
			</label>
			<input type="text" class="form-control js-ftp-user" name="v_ftp_user[%INDEX%][v_ftp_user]" id="v_ftp_user[%INDEX%][v_ftp_user]" value="">
			<small class="hint js-ftp-user-hint"></small>
		</div>
		<div class="u-pl30 u-mb10">
			<label for="v_ftp_user[%INDEX%][v_ftp_password]" class="form-label">
				<?= _("Password") ?>
				<button type="button" title="<?= _("Generate") ?>" class="u-unstyled-button u-ml5 js-ftp-password-generate">
					<i class="fas fa-arrows-rotate icon-green"></i>
				</button>
			</label>
			<input type="text" class="form-control js-ftp-user-psw" name="v_ftp_user[%INDEX%][v_ftp_password]" id="v_ftp_user[%INDEX%][v_ftp_password]">
		</div>
		<div class="u-pl30 u-mb10">
			<label for="v_ftp_user[%INDEX%][v_ftp_path]" class="form-label"><?= _("Path") ?></label>
			<input type="hidden" name="v_ftp_pre_path" value="">
			<input type="text" class="form-control js-ftp-path" name="v_ftp_user[%INDEX%][v_ftp_path]" id="v_ftp_user[%INDEX%][v_ftp_path]" value="">
			<span class="hint-prefix"><?= htmlentities(trim($v_ftp_pre_path_new_user, "'")) ?></span><span class="hint js-ftp-path-hint"></span>
		</div>
		<div class="u-pl30 u-mb10">
			<label for="v_ftp_user[%INDEX%][v_ftp_email]" class="form-label"><?= _("Send FTP credentials to email") ?></label>
			<input type="email" class="form-control js-email-alert-on-psw" name="v_ftp_user[%INDEX%][v_ftp_email]" id="v_ftp_user[%INDEX%][v_ftp_email]" value="">
		</div>
	</div>
</div>
