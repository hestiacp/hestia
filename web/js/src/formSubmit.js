import { enableUnlimitedInputs } from './unlimitedInput';
import { updateAdvancedTextarea } from './toggleAdvanced';
import { showSpinner } from './helpers';

export default function handleFormSubmit() {
	const pageForm = document.querySelector('#vstobjects');
	if (pageForm) {
		pageForm.addEventListener('submit', () => {
			// Show loading spinner
			showSpinner();

			// Enable any disabled unlimited inputs and set their value to "unlimited"
			enableUnlimitedInputs();

			// Update the "advanced options" textarea with "basic options" input values
			const basicOptionsWrapper = document.querySelector('.js-basic-options');
			if (basicOptionsWrapper && !basicOptionsWrapper.classList.contains('u-hidden')) {
				updateAdvancedTextarea();
			}
		});
	}

	const bulkEditForm = document.querySelector('[x-bind="BulkEdit"]');
	if (bulkEditForm) {
		bulkEditForm.addEventListener('submit', () => {
			// Show loading spinner
			showSpinner();
		});
	}
}
