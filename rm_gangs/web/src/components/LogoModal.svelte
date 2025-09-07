<script lang="ts">
	import { PLAYER } from '@stores/stores';
	import Modal from '@layouts/Modal.svelte';
	import { createForm } from 'svelte-forms-lib';
	import { isImageUrlValid } from '@utils/misc';
	import { SendEvent } from '@utils/eventsHandlers';
	import locales from '@utils/locales';

	export let show: boolean;
	export let logoURL: string;

	const { form, errors, handleChange, handleSubmit } = createForm({
		initialValues: {
			logoURL: logoURL ?? '',
		},
		validate: async (values) => {
			let errs = {};
			if (!values.logoURL || values.logoURL.trim().length === 0) {
				errs['logoURL'] = locales.url_cannot_be_empty;
			} else if (values.logoURL === logoURL) {
				errs['logoURL'] = locales.url_cannot_be_same;
			} else if (!(await isImageUrlValid(values.logoURL))) {
				errs['logoURL'] = locales.url_not_accessible;
			} else if (values.logoURL.includes('discord') || values.logoURL.includes('imgur')) {
				errs['logoURL'] = locales.url_blocked_cdn;
			}
			return errs;
		},
		onSubmit: (values) => {
			if (values.logoURL && values.logoURL !== logoURL) SendEvent('updateLogoURL', { url: values.logoURL });
			show = false;
		},
	});
</script>

<Modal bind:show>
	<div class="min-w-[30vw] flex flex-col gap-4 py-2 px-4">
		<div class="flex justify-center">
			<img
				class="w-[10vw] h-[10vw] border-gray-700 border"
				src={$form.logoURL}
				on:error={(event) => {
					// @ts-ignore
					event.target.src = 'https://placehold.co/500';
				}}
				alt="logo url"
			/>
		</div>
		<div class="flex flex-col gap-4">
			<div class="w-full text-center text-gray-400 flex items-center gap-2 text-lg">
				<i class="fas fa-image" />
				{locales.group_logo_url}
			</div>
			<form on:submit={handleSubmit} class="flex flex-col gap-4">
				<div class="flex items-center border border-gray-600">
					<i class="text-gray-500 fa-solid fa-link px-2" />
					<input type="text" class="bg-transparent text-gray-300 w-full py-2.5" placeholder="https://placehold.co/500" disabled={!$PLAYER.gang.isboss} on:change={handleChange} bind:value={$form.logoURL} />
				</div>
				{#if $errors.logoURL}
					<div class="flex gap-1 text-red-500">
						<i class="fa-solid fa-triangle-exclamation" />
						<small>{$errors.logoURL}</small>
					</div>
				{/if}
				<button class="bg-lime-500 text-black rounded font-bold py-1 px-2 text-xl hover:bg-lime-600" disabled={!$PLAYER.gang.isboss} type="submit">{locales.update}</button>
			</form>
		</div>
	</div>
</Modal>
