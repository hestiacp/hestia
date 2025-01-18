// Simple hide/show input listeners specific to Edit Web Domain form
// TODO: Replace these with Alpine.js usage consistently
// NOTE: Some functions use inline styles, as Alpine.js also uses them
export default function handleEditWebListeners() {
	// Listen to "Web Statistics" select menu to hide/show
	// "Statistics Authorization" checkbox and inner fields
	const statsSelect = document.querySelector('.js-stats-select');
	const statsAuthContainers = document.querySelectorAll('.js-stats-auth');
	if (statsSelect && statsAuthContainers.length) {
		statsSelect.addEventListener('change', () => {
			if (statsSelect.value === 'none') {
				statsAuthContainers.forEach((container) => {
					container.style.display = 'none';
				});
			} else {
				statsAuthContainers.forEach((container) => {
					container.style.display = 'block';
				});
			}
		});
	}

	// Listen to "Enable domain redirection" radio items to show
	// additional inputs if radio with value "custom" is selected
	document.querySelectorAll('.js-redirect-custom-value').forEach((element) => {
		element.addEventListener('change', () => {
			const customRedirectFields = document.querySelector('.js-custom-redirect-fields');
			if (customRedirectFields) {
				if (element.value === 'custom') {
					customRedirectFields.classList.remove('u-hidden');
				} else {
					customRedirectFields.classList.add('u-hidden');
				}
			}
		});
	});

	// Listen to "Use Lets Encrypt to obtain SSL certificate" checkbox to
	// hide/show SSL textareas
	const toggleLetsEncryptCheckbox = document.querySelector('.js-toggle-lets-encrypt');
	const sslDetails = document.querySelector('.js-ssl-details');
	if (toggleLetsEncryptCheckbox && sslDetails) {
		toggleLetsEncryptCheckbox.addEventListener('change', () => {
			if (toggleLetsEncryptCheckbox.checked) {
				sslDetails.style.display = 'none';
			} else {
				sslDetails.style.display = 'block';
			}
		});
	}

	// Listen to "Advanced Options -> Proxy Template" select menu to
	// show "Purge Nginx Cache" button if "caching" selected
	const proxyTemplateSelect = document.querySelector('.js-proxy-template-select');
	const clearCacheButton = document.querySelector('.js-clear-cache-button');
	if (proxyTemplateSelect && clearCacheButton) {
		proxyTemplateSelect.addEventListener('change', () => {
			// NOTE: Match "caching" and "caching-*" values
			if (proxyTemplateSelect.value === 'caching' || proxyTemplateSelect.value.match(/^caching-/)) {
				clearCacheButton.classList.remove('u-hidden');
			} else {
				clearCacheButton.classList.add('u-hidden');
			}
		});
	}

	// Listen to "Advanced Options -> Proxy Template" select menu to
	// show "Proxy url" input if "reverse_proxy" selected
	const proxyUrl = document.querySelector('.js-proxy-url-field');
	if (proxyTemplateSelect && proxyUrl) {
		proxyTemplateSelect.addEventListener('change', () => {
			// NOTE: Match "reverse_proxy" and "reverse_proxy-*" values
			if (proxyTemplateSelect.value === 'reverse_proxy' || proxyTemplateSelect.value.match(/^reverse_proxy-/)) {
				proxyUrl.style.display = 'block';
			} else {
				proxyUrl.style.display = 'none';
			}
		});
	}
}
