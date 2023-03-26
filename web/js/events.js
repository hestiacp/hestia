const VE = {
	core: {
		/**
		 * Main method that invokes further event processing
		 * @param root is root HTML DOM element that. Pass HTML DOM Element or css selector
		 * @param event_type (eg: click, mouseover etc..)
		 */
		register: (root, event_type) => {
			root = !root ? 'body' : root; // if elm is not passed just bind events to body DOM Element
			event_type = !event_type ? 'click' : event_type; // set event type to "click" by default
			$(root).bind(event_type, (evt) => {
				VE.core.dispatch(evt, $(evt.target), event_type); // dispatch captured event
			});
		},
		/**
		 * Dispatch event that was previously registered
		 * @param evt related event object
		 * @param elm that was catched
		 * @param event_type (eg: click, mouseover etc..)
		 */
		dispatch: (evt, elm, event_type) => {
			if ('undefined' == typeof VE.callbacks[event_type]) {
				return VE.helpers.warn(
					'There is no corresponding object that should contain event callbacks for "' +
						event_type +
						'" event type'
				);
			}
			// get class of element
			const classes = $(elm).attr('class');
			// if no classes are attached, then just stop any further processings
			if (!classes) {
				return; // no classes assigned
			}
			// split the classes and check if it related to function
			$(classes.split(/\s/)).each((i, key) => {
				VE.callbacks[event_type][key] && VE.callbacks[event_type][key](evt, elm);
			});
		},
	},
	navigation: {
		state: {
			active_menu: 1,
			menu_selector: '.main-menu-item',
			menu_active_selector: '.active',
		},
		enter_focused: () => {
			if ($('.units').hasClass('active')) {
				location.href = $(
					'.units.active .l-unit.focus .actions-panel__col.actions-panel__edit a'
				).attr('href');
			} else {
				if ($(VE.navigation.state.menu_selector + '.focus a').attr('href')) {
					location.href = $(VE.navigation.state.menu_selector + '.focus a').attr('href');
				}
			}
		},
		move_focus_left: () => {
			let index = parseInt(
				$(VE.navigation.state.menu_selector).index($(VE.navigation.state.menu_selector + '.focus'))
			);
			if (index == -1)
				index = parseInt(
					$(VE.navigation.state.menu_selector).index($(VE.navigation.state.menu_active_selector))
				);

			if ($('.units').hasClass('active')) {
				$('.units').removeClass('active');
				index++;
			}

			$(VE.navigation.state.menu_selector).removeClass('focus');

			if (index > 0) {
				$($(VE.navigation.state.menu_selector)[index - 1]).addClass('focus');
			} else {
				VE.navigation.switch_menu('last');
			}
		},
		move_focus_right: () => {
			const max_index = $(VE.navigation.state.menu_selector).length - 1;
			let index = parseInt(
				$(VE.navigation.state.menu_selector).index($(VE.navigation.state.menu_selector + '.focus'))
			);
			if (index == -1)
				index =
					parseInt(
						$(VE.navigation.state.menu_selector).index($(VE.navigation.state.menu_active_selector))
					) || 0;
			$(VE.navigation.state.menu_selector).removeClass('focus');

			if ($('.units').hasClass('active')) {
				$('.units').removeClass('active');
				index--;
			}

			if (index < max_index) {
				$($(VE.navigation.state.menu_selector)[index + 1]).addClass('focus');
			} else {
				VE.navigation.switch_menu('first');
			}
		},
		move_focus_down: () => {
			const max_index = $('.units .l-unit:not(.header)').length - 1;
			let index = parseInt($('.units .l-unit').index($('.units .l-unit.focus')));

			if (index < max_index) {
				$('.units .l-unit.focus').removeClass('focus');
				$($('.units .l-unit:not(.header)')[index + 1]).addClass('focus');

				$('html, body').animate({ scrollTop: $('.units .l-unit.focus').offset().top - 200 }, 200);
			}
		},
		move_focus_up: () => {
			let index = parseInt($('.units .l-unit:not(.header)').index($('.units .l-unit.focus')));

			if (index == -1) index = 0;

			if (index > 0) {
				$('.units .l-unit.focus').removeClass('focus');
				$($('.units .l-unit:not(.header)')[index - 1]).addClass('focus');

				$('html, body').animate({ scrollTop: $('.units .l-unit.focus').offset().top - 200 }, 200);
			}
		},
		switch_menu: (position) => {
			position = position || 'first'; // last

			if (VE.navigation.state.active_menu == 0) {
				VE.navigation.state.active_menu = 1;
				VE.navigation.state.menu_selector = '.main-menu-item';
				VE.navigation.state.menu_active_selector = '.active';

				if (position == 'first') {
					$($(VE.navigation.state.menu_selector)[0]).addClass('focus');
				} else {
					const max_index = $(VE.navigation.state.menu_selector).length - 1;
					$($(VE.navigation.state.menu_selector)[max_index]).addClass('focus');
				}
			}
		},
		shortcut: (elm) => {
			/** @type {'js' | 'href'} */
			const action = elm.attr('key-action');

			switch (action) {
				case 'js':
					VE.core.dispatch(true, elm.find('.data-controls'), 'click');
					break;

				case 'href':
					location.href = elm.find('a').attr('href');
					break;

				default:
					break;
			}
		},
	},
	callbacks: {
		click: {
			do_suspend: (evt, elm) => {
				const ref = elm.hasClass('actions-panel') ? elm : elm.parents('.actions-panel');
				const url = $('input[name="suspend_url"]', ref).val();
				const dialog_elm = ref.find('.js-confirm-dialog-suspend');
				VE.helpers.createConfirmationDialog(dialog_elm, $(elm).parent().attr('title'), url);
			},
			do_unsuspend: (evt, elm) => {
				const ref = elm.hasClass('actions-panel') ? elm : elm.parents('.actions-panel');
				const url = $('input[name="unsuspend_url"]', ref).val();
				const dialog_elm = ref.find('.js-confirm-dialog-suspend');
				VE.helpers.createConfirmationDialog(dialog_elm, $(elm).parent().attr('title'), url);
			},
			do_delete: (evt, elm) => {
				const ref = elm.hasClass('actions-panel') ? elm : elm.parents('.actions-panel');
				const url = $('input[name="delete_url"]', ref).val();
				const dialog_elm = ref.find('.js-confirm-dialog-delete');
				VE.helpers.createConfirmationDialog(dialog_elm, $(elm).parent().attr('title'), url);
			},
			do_servicerestart: (evt, elm) => {
				const ref = elm.hasClass('actions-panel') ? elm : elm.parents('.actions-panel');
				const url = $('input[name="servicerestart_url"]', ref).val();
				const dialog_elm = ref.find('.js-confirm-dialog-servicerestart');
				VE.helpers.createConfirmationDialog(dialog_elm, $(elm).parent().attr('title'), url);
			},
			do_servicestop: (evt, elm) => {
				const ref = elm.hasClass('actions-panel') ? elm : elm.parents('.actions-panel');
				const url = $('input[name="servicestop_url"]', ref).val();
				const dialog_elm = ref.find('.js-confirm-dialog-servicestop');
				VE.helpers.createConfirmationDialog(dialog_elm, $(elm).parent().attr('title'), url);
			},
		},
	},
	helpers: {
		/**
		 * Create dialog box on the fly
		 * @param dialogElm The <dialog> element near the link which triggers the dialog
		 * @param dialogTitle The title of the dialog
		 * @param targetUrl URL that will be redirected to if user clicks "OK"
		 */
		createConfirmationDialog: (dialogElm, dialogTitle, targetUrl) => {
			const dialog = dialogElm[0];

			// Remove any existing inserted content
			dialog.querySelector('.modal-title')?.remove();
			dialog.querySelector('.modal-options')?.remove();

			// Create and insert the title
			const title = document.createElement('h2');
			title.textContent = dialogTitle;
			title.classList.add('modal-title');
			dialog.prepend(title);

			// Create and insert the options
			const optionsWrapper = document.createElement('div');
			optionsWrapper.classList.add('modal-options');
			const confirmButton = VE.helpers.createButton('OK', 'submit', ['button']);
			const cancelButton = VE.helpers.createButton('Cancel', 'button', [
				'button',
				'button-secondary',
				'cancel',
			]);
			optionsWrapper.appendChild(confirmButton);
			if (targetUrl) {
				optionsWrapper.appendChild(cancelButton);
			}
			dialog.appendChild(optionsWrapper);

			// Add event handlers (use onclick to avoid multiple handlers)
			confirmButton.onclick = () => {
				if (targetUrl) {
					window.location.href = targetUrl;
				}
				dialog.close();
			};
			cancelButton.onclick = () => {
				dialog.close();
			};
			document.addEventListener('keydown', (event) => {
				if (event.key === 'Escape') {
					dialog.close();
				}
			});

			dialog.showModal();
		},
		createButton: (text, type, classNames) => {
			const button = document.createElement('button');
			button.type = type;
			button.textContent = text;
			button.classList.add(...classNames);
			return button;
		},
		warn: (msg) => {
			alert('WARNING: ' + msg);
		},
		extendPasswordFields: () => {
			const references = ['.js-password-input'];

			$(document).ready(() => {
				$(references).each((i, ref) => {
					VE.helpers.initAdditionalPasswordFieldElements(ref);
				});
			});
		},
		initAdditionalPasswordFieldElements: (ref) => {
			const enabled = Cookies.read('hide_passwords') == 1 ? true : false;
			if (enabled) {
				Cookies.set('hide_passwords', 1, 365);
				$(ref).prop('type', 'password');
			}

			$(ref).prop('autocomplete', 'off');

			const html =
				'<span class="toggle-password"><i class="toggle-psw-visibility-icon fas fa-eye-slash ' +
				enabled
					? ''
					: 'u-opacity-50' +
					  '" onclick="VE.helpers.toggleHiddenPasswordText(\'' +
					  ref +
					  '\', this)"></i></span>';
			$(ref).after(html);
		},
		toggleHiddenPasswordText: (ref, triggering_elm) => {
			$(triggering_elm).toggleClass('u-opacity-50');

			if ($(ref).prop('type') == 'text') {
				Cookies.set('hide_passwords', 1, 365);
				$(ref).prop('type', 'password');
			} else {
				Cookies.set('hide_passwords', 0, 365);
				$(ref).prop('type', 'text');
			}
		},
	},
	tmp: {
		sort_par: 'sort-name',
		sort_direction: -1,
		sort_as_int: false,
	},
};

VE.helpers.extendPasswordFields();
